use Test::More;

use Module::CPANTS::Analyse;
use File::Spec::Functions;
use Data::Dumper;

my @tests = (
#    {
#        dist => 't/eg/Acme-DonMartin-0.06.tar.gz',
#    },
    {
        dist => 't/eg/Text-CSV_XS-0.40.tgz',
        kwalitee => {
           'extracts_nicely' => 1,
           'has_buildtool' => 1,
           'has_readme' => 1,
           'manifest_matches_dist' => 1,
           'metayml_declares_perl_version' => 0,
           'has_example' => 1,
           'has_test_pod_coverage' => 1,
           'metayml_is_parsable' => 1,
           'proper_libs' => 1,
           'has_changelog' => 1,
           'no_pod_errors' => 1,
           'use_strict' => 1,
           'kwalitee' => 36,
           'no_stdin_for_prompting' => 1,
           'has_test_pod' => 1,
           'easily_repackageable' => 1,
           'easily_repackageable_by_fedora' => 1,
           'has_tests' => 1,
           'easily_repackageable_by_debian' => 1,
           'has_manifest' => 1,
           'no_symlinks' => 1,
           'has_version' => 1,
           'extractable' => 1,
           'buildtool_not_executable' => 1,
           'has_working_buildtool' => 1,
           'metayml_has_license' => 1,
           'has_humanreadable_license' => 1,
           'no_generated_files' => 1,
           'has_meta_yml' => 1,
           'metayml_conforms_spec_current' => 1,
           'use_warnings' => 1,
           'no_large_files' => 1,
           'no_cpants_errors' => 1,
           'has_tests_in_t_dir' => 1,
           'has_version_in_each_file' => 1,
           'fits_fedora_license' => 1,
           'has_proper_version' => 1,
           'metayml_conforms_to_known_spec' => 1
         },
    },
    {
        dist =>  't/eg/Pipe-0.03.tar.gz',
        kwalitee => {
           'extracts_nicely' => 1,
           'has_buildtool' => 1,
           'has_readme' => 1,
           'manifest_matches_dist' => 0,
           'metayml_declares_perl_version' => 0,
           'has_example' => 0,
           'has_test_pod_coverage' => 1,
           'metayml_is_parsable' => 0,
           'proper_libs' => 1,
           'has_changelog' => 1,
           'no_pod_errors' => 1,
           'use_strict' => 1,
           'kwalitee' => 24,
           'no_stdin_for_prompting' => 1,
           'has_test_pod' => 1,
           'easily_repackageable' => 0,
           'easily_repackageable_by_fedora' => 0,
           'has_tests' => 1,
           'easily_repackageable_by_debian' => 1,
           'has_manifest' => 1,
           'no_symlinks' => 1,
           'has_version' => 1,
           'extractable' => 1,
           'buildtool_not_executable' => 1,
           'has_working_buildtool' => 1,
           'metayml_has_license' => 0,
           'has_humanreadable_license' => 0,
           'no_generated_files' => 1,
           'has_meta_yml' => 0,
           'metayml_conforms_spec_current' => 0,
           'use_warnings' => 1,
           'no_large_files' => 1,
           'no_cpants_errors' => 1,
           'has_tests_in_t_dir' => 1,
           'has_version_in_each_file' => 0,
           'fits_fedora_license' => 0,
           'has_proper_version' => 1,
           'metayml_conforms_to_known_spec' => 0
        },
    },
    {
        dist => 't/eg/PPI-HTML-1.07.tar.gz',
        kwalitee => {
           'extracts_nicely' => 1,
           'has_buildtool' => 1,
           'has_readme' => 1,
           'manifest_matches_dist' => 1,
           'metayml_declares_perl_version' => 1,
           'has_example' => 0,
           'has_test_pod_coverage' => 0,
           'metayml_is_parsable' => 1,
           'proper_libs' => 1,
           'has_changelog' => 1,
           'no_pod_errors' => 1,
           'use_strict' => 1,
           'kwalitee' => 33,
           'no_stdin_for_prompting' => 1,
           'has_test_pod' => 1,
           'easily_repackageable' => 1,
           'easily_repackageable_by_fedora' => 1,
           'has_tests' => 1,
           'easily_repackageable_by_debian' => 1,
           'has_manifest' => 1,
           'no_symlinks' => 1,
           'has_version' => 1,
           'extractable' => 1,
           'buildtool_not_executable' => 1,
           'has_working_buildtool' => 1,
           'metayml_has_license' => 1,
           'has_humanreadable_license' => 1,
           'no_generated_files' => 1,
           'has_meta_yml' => 1,
           'metayml_conforms_spec_current' => 0,
           'use_warnings' => 0,
           'no_large_files' => 1,
           'no_cpants_errors' => 1,
           'has_tests_in_t_dir' => 1,
           'has_version_in_each_file' => 1,
           'fits_fedora_license' => 1,
           'has_proper_version' => 1,
           'metayml_conforms_to_known_spec' => 1
         },
    },
);

plan tests => 2 * @tests;

foreach my $t (@tests) {
    my $a=Module::CPANTS::Analyse->new({
        dist=> $t->{dist},
        _dont_cleanup=>$ENV{DONT_CLEANUP},
    });

    my $rv=$a->unpack;
    is($rv,undef,'unpack ok');

    $a->analyse;
    $a->calc_kwalitee;

    my $d=$a->d;
    my $kw=$a->d->{kwalitee};
    is_deeply($kw, $t->{kwalitee}, "kwalitee of $t->{dist}")
        or diag(Dumper $kw);
}



