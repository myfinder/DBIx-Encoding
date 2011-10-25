use strict;
use warnings;

use Carp;
use Test::More;
use Test::mysqld;

use utf8;
use Encode;
use Data::Dump qw/dump/;

use DBI qw(:sql_types);
use DBIx::Encoding;

###
# Test for MySQL
my $mysqld_utf8 = Test::mysqld->new(
    my_cnf => {
        'skip-networking'                     => "",
        'default-character-set'               => "utf8",
        'character-set-server'                => "utf8",
        'character-set-client'                => "utf8",
        'collation-server'                    => "utf8_general_ci",
        'skip-character-set-client-handshake' => "",
    },
) or plan skip_all => $Test::mysqld::errstr;

# utf8 DB
my @dsn_utf8 = (
    'dbi:mysql:test;mysql_socket=' . $mysqld_utf8->my_cnf->{socket},
    'root',
    '',
    {
        AutoCommit => 1,
        RaiseError => 1,
        PrintError => 0,
        RootClass  => 'DBIx::Encoding',
        encoding   => 'utf8',
    },
);

# utf8 DB no DBIx::Encoding
my @dsn_utf8_no_dbix_encoding = (
    'dbi:mysql:test;mysql_socket=' . $mysqld_utf8->my_cnf->{socket},
    'root',
    '',
    {
        AutoCommit => 1,
        RaiseError => 1,
        PrintError => 0,
    },
);

my $dbh_utf8  = DBI->connect(@dsn_utf8) or die;
my $dbh_utf8_no_dbix_encoding = DBI->connect(@dsn_utf8_no_dbix_encoding) or die;

###
# Generate Test Table

# utf8 table
my $sth_create_table_utf8 = $dbh_utf8->prepare(<<'SQL');
CREATE TABLE test_utf8 (
    id   INTEGER,
    text TEXT CHARACTER SET utf8 COLLATE utf8_general_ci
)
ENGINE = InnoDB
CHARACTER SET utf8
COMMENT = 'mysql test table(utf8)'
SQL

$sth_create_table_utf8->execute;


###
# Tests

my $text = "残念！さやかちゃんでした！";

my $insert_sql = <<'SQL';
INSERT INTO test_utf8 (id, text) VALUES (?, ?)
SQL

subtest("with utf8", sub {
    {
        $dbh_utf8_no_dbix_encoding->do($insert_sql, undef, (1, $text));

        my $sql = <<SQL;
SELECT * FROM test_utf8 WHERE id = 1
SQL
        my $res = $dbh_utf8_no_dbix_encoding->selectall_arrayref($sql, +{ Slice => +{}});
        ok ( ! Encode::is_utf8($res->[0]->{text}), "decoded with raw DBI" );
        isnt ( $res->[0]->{text}, $text, "text not encoded / decoded correctly" );
    }


    {
        $dbh_utf8->do($insert_sql, undef, (2, $text));

        my $sql = <<SQL;
SELECT * FROM test_utf8 WHERE id = 2
SQL

        my $res = $dbh_utf8->selectall_arrayref($sql, +{ Slice => +{}});
        ok ( Encode::is_utf8($res->[0]->{text}), "decoded with raw DBI::Encoding" );
        is ( $res->[0]->{text}, $text, "text encoded / decoded correctly" );
    }
});


done_testing;
