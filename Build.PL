use strict;
use warnings;
use Module::Build;

my $builder = Module::Build->new(
    module_name         => 'DBIx::Encoding',
    license             => 'perl',
    dist_author         => 'Tatsuro Hisamori <medianetworks@gmail.com>',
    dist_version_from   => 'lib/DBIx/Encoding.pm',
    requires => {
        'Test::More' => 0,
        'version'    => 0,
				'DBI'        => 0,
    },
    add_to_cleanup      => [ 'DBIx-Encoding-*' ],
);

$builder->create_build_script();
