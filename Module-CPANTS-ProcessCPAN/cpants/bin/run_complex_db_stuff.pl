#!/usr/bin/perl
use strict; 
use warnings;
use Module::CPANTS::ProcessCPAN;
use Module::CPANTS::DB;
use Module::CoreList;
use Parse::CPAN::Authors;
use Getopt::Long;

my %opts;
GetOptions(\%opts,qw(cpan=s));

die "Usage: run_complex_db_stuff.pl --cpan path/to/local/cpan/mirror" unless  $opts{cpan};

my $p=Module::CPANTS::ProcessCPAN->new($opts{cpan});
my $k=Module::CPANTS::Kwalitee->new;
my $available_kw=$k->available_kwalitee;
my @ind=$k->get_indicators;

my $dbh=$p->db->storage->dbh;

# build list of module->dist
my %modules;
{
    my $sth=$dbh->prepare("select module,dist from modules");
    $sth->execute;
    while (my ($module,$dist)=$sth->fetchrow_array) {
        $modules{$module}=$dist;
    }
}

# fill dist references in prereq
# todo: handle modules provided by core
{
    print "fill prereq with dist_ids\n";
    my $sth=$dbh->prepare("select distinct requires from prereq where in_dist = 0 order by requires");
    $sth->execute();
    while (my ($module)=$sth->fetchrow_array) {
        next unless $modules{$module};
        $dbh->do("update prereq set in_dist=? where requires=?",undef,$modules{$module},$module);
    }
}

{
    print "fill uses with dist_ids\n";
    my $sth=$dbh->prepare("select distinct module from uses where in_dist = 0 order by module");
    $sth->execute();
    while (my ($module)=$sth->fetchrow_array) {
        next unless $modules{$module};
        $dbh->do("update uses set in_dist=? where module=?",undef,$modules{$module},$module);

    }
}

# is_prereq
{
    print "is_prereq\n";
    my $sth=$dbh->prepare("select dist.id,author from dist,author where dist.author=author.id");
    $sth->execute;
    while (my ($distid,$authid)=$sth->fetchrow_array) {
        my $is_prereq=$dbh->selectrow_array("select count(prereq.id) from prereq,dist,author where prereq.dist=dist.id AND dist.author=author.id AND in_dist=? AND dist.author!=?",undef,$distid,$authid);
        $dbh->do("update kwalitee set is_prereq=1 where dist=?",undef,$distid) if $is_prereq>0; 
    }
}

# prereq_matches_use
if (1==2) {
    print "prereq_matches_use\n";
    my $sth=$dbh->prepare("select distinct dist.id from dist,uses where dist.id=uses.dist and uses.in_dist>0");
    $sth->execute;
    my $missing=0;
    my $count=0;
    while (my ($id)=$sth->fetchrow_array) {
        $count++;
        my $used_dists=$dbh->selectcol_arrayref("select distinct in_dist from uses where dist=? AND in_dist>0 and in_code=1",undef,$id);
        my $prereqed_dists=$dbh->selectcol_arrayref("select distinct in_dist from prereq where dist=? AND in_dist>0",undef,$id);
       
        if (@$used_dists > @$prereqed_dists) {
            $missing++;
            print "SOMETHING MISSING ($missing / $count)\n";
        }
    }
    print "Stats: Of $count dists, $missing have missing deps\n";
}

# calc final kwalitee 
{
    print "calc final kwalitee\n";   
    my $sth=$dbh->prepare("select id,".join(',',map {$_->{name} }@ind)." from kwalitee");
    $sth->execute;

    my @extra=map {$_->{name}} grep {$_->{is_extra}} @ind;
    my @core=map {$_->{name}} grep {!$_->{is_extra}} @ind;
   
    while (my $r=$sth->fetchrow_hashref) {
        my $id=$r->{id};
        my $core_kw=0;
        foreach (@core) {
            $core_kw++ if $r->{$_};
        }
        my $abs_kw=$core_kw;
        foreach (@extra) {
            $abs_kw++ if $r->{$_};
        }

        my $kw=100*$abs_kw / $available_kw;
        my $rel_core_kw=100*$core_kw / $available_kw;
        $dbh->do("update kwalitee set kwalitee=?,abs_kw=?,abs_core_kw=?,rel_core_kw=? where id=?",undef,$kw,$abs_kw,$core_kw,$rel_core_kw,$id);
    }
}


# fill_authors
{
    print "fill authors\n";
    my $pca = Parse::CPAN::Authors->new($p->cpan_01mailrc);
    foreach my $auth ($pca->authors) {
        my $pauseid=$auth->pauseid;
        my $a=$p->db->resultset('Author')->find_or_create(pauseid=>$pauseid);
        foreach (qw(name email)) {
            $a->$_($auth->$_);
        }
        foreach (qw(average_kwalitee num_dists rank)) {
            $a->$_(0) unless $a->$_;
        }
        $a->update;
    }
}

# AUTHOR: num_dists, average
{
    print "calc authors num_dists and average kwalitee\n";
    my $sth=$dbh->prepare("select count(*) as num_dists,avg(kwalitee.rel_core_kw) as average,dist.author as id from dist,kwalitee where dist.id=kwalitee.dist group by author");
    $sth->execute;
    while (my @r=$sth->fetchrow_array) {
        $dbh->do("update author set num_dists=?,average_kwalitee=? where id=?",undef,@r);
    }
    $sth->finish;
    $dbh->do("update author set num_dists=0 where num_dists is null");
}

# RANKS
{ 
    print "calc authors rank in cpants game\n";
    foreach my $query ("select average_kwalitee,id from author where num_dists>=5 order by average_kwalitee desc",
    "select average_kwalitee,id from author where num_dists<5 AND num_dists>0 order by average_kwalitee desc")
    {
        my $sth=$dbh->prepare($query);
        $sth->execute;
        my $pos=0;my $cnt=0;my $k=0;
        my @done;
        while (my ($avg,$id)=$sth->fetchrow_array) {
            $cnt++;
            if ($k!=$avg) {
                $k=$avg;
                $pos=$cnt;
            }
            push(@done,[$pos,$id]);
        }
        foreach (@done) {
            $dbh->do("update author set rank=? where id=?",undef,@$_);
        }
    }
}


# 

