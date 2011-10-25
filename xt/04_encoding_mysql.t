use strict;
use warnings;

use Carp;
use Test::More;
use Test::mysqld;

use utf8;
use Encode;

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

my $mysqld_cp932 = Test::mysqld->new(
	my_cnf => {
		'skip-networking'                     => "",
		'default-character-set'               => "cp932",
		'character-set-server'                => "cp932",
		'character-set-client'                => "cp932",
		'collation-server'                    => "cp932_japanese_ci",
		'skip-character-set-client-handshake' => "",
	},
) or plan skip_all => $Test::mysqld::errstr;

###
# test
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

# cp932 DB
my @dsn_cp932 = (
	'dbi:mysql:test;mysql_socket=' . $mysqld_cp932->my_cnf->{socket},
	'root',
	'',
	{
		AutoCommit => 1,
		RaiseError => 1,
		PrintError => 0,
		RootClass => 'DBIx::Encoding',
		encoding => 'cp932',
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
my $dbh_cp932 = DBI->connect(@dsn_cp932) or die;

###
# Basic Flagged Test
my $sth_utf8  = $dbh_utf8->prepare("select 'テストテキスト' as string");
my $sth_cp932 = $dbh_cp932->prepare("select 'テストテキスト' as string");

$sth_utf8->execute;
$sth_cp932->execute;

my $rs_utf8  = $sth_utf8->fetchrow_hashref;
my $rs_cp932 = $sth_cp932->fetchrow_hashref;

ok(Encode::is_utf8($rs_utf8->{string}));
ok(Encode::is_utf8($rs_cp932->{string}));

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

# cp932 table
my $sth_create_table_cp932 = $dbh_cp932->prepare(<<'SQL');
CREATE TABLE test_cp932 (
	id   INTEGER,
	text TEXT CHARACTER SET cp932 COLLATE cp932_japanese_ci
)
ENGINE = InnoDB
CHARACTER SET cp932
COMMENT = 'mysql test table(cp932)'
SQL

$sth_create_table_cp932->execute;

###
# test text(Japanese)
my $test_text = "テストテキスト";

###
# insert

# utf8 table
my $sth_insert_utf8 = $dbh_utf8->prepare(<<'SQL');
insert into test_utf8 (id, text) values (1, ?)
SQL

$sth_insert_utf8->bind_param(1, $test_text, SQL_VARCHAR);
$sth_insert_utf8->execute;
$sth_insert_utf8->finish;

# cp932 table
my $sth_insert_cp932 = $dbh_cp932->prepare(<<'SQL');
insert into test_cp932 (id, text) values (1, ?)
SQL

$sth_insert_cp932->bind_param(1, $test_text, SQL_VARCHAR);
$sth_insert_cp932->execute;
$sth_insert_cp932->finish;

###
# flagged text

# utf8 table
my $sth_select_utf8 = $dbh_utf8->prepare(<<'SQL');
select * from test_utf8 where text = ?
SQL

$sth_select_utf8->bind_param(1, $test_text, SQL_VARCHAR);
$sth_select_utf8->execute;

my $sth_select_utf8_result = $sth_select_utf8->fetchrow_hashref;

$sth_select_utf8->finish;

is($sth_select_utf8_result->{text}, $test_text, 'inserted text is match');

# cp932 table
my $sth_select_cp932 = $dbh_cp932->prepare(<<'SQL');
select * from test_cp932 where text = ?
SQL

$sth_select_cp932->bind_param(1, $test_text, SQL_VARCHAR);
$sth_select_cp932->execute;

my $sth_select_cp932_result = $sth_select_cp932->fetchrow_hashref;

$sth_select_cp932->finish;

is($sth_select_cp932_result->{text}, $test_text, 'inserted text is match');

###
# not flagged text

# utf8 table
$sth_select_utf8 = $dbh_utf8->prepare(<<'SQL');
select * from test_utf8 where text = ?
SQL

$sth_select_utf8->bind_param(1, Encode::encode('utf8', $test_text), SQL_VARCHAR);
$sth_select_utf8->execute;

$sth_select_utf8_result = $sth_select_utf8->fetchrow_hashref;

$sth_select_utf8->finish;

isnt($sth_select_utf8_result->{text}, $test_text, 'inserted text is not match');

# cp932 table
$sth_select_cp932 = $dbh_cp932->prepare(<<'SQL');
select * from test_cp932 where text = ?
SQL

$sth_select_cp932->bind_param(1, Encode::encode('cp932', $test_text), SQL_VARCHAR);
$sth_select_cp932->execute;

$sth_select_cp932_result = $sth_select_cp932->fetchrow_hashref;

$sth_select_cp932->finish;

isnt($sth_select_cp932_result->{text}, $test_text, 'inserted text is not match');

###
# statement handle method with DBIx::Encoding

my $sth_select = $dbh_utf8->prepare(<<'SQL');
select * from test_utf8 where text = ?
SQL

my $result_set;

# fetchrow_array
$sth_select->bind_param(1, $test_text, SQL_VARCHAR);
$sth_select->execute;
my @result_set = $sth_select->fetchrow_array;

ok(Encode::is_utf8($result_set[1]));

# fetchrow_arrayref
$sth_select->bind_param(1, $test_text, SQL_VARCHAR);
$sth_select->execute;
$result_set = $sth_select->fetchrow_arrayref;

ok(Encode::is_utf8($result_set[1]));

# fetchrow_hashref
$sth_select->bind_param(1, $test_text, SQL_VARCHAR);
$sth_select->execute;
$result_set = $sth_select->fetchrow_hashref;

ok(Encode::is_utf8($result_set->{text}));

# fetchall_arrayref
$sth_select->bind_param(1, $test_text, SQL_VARCHAR);
$sth_select->execute;
$result_set = $sth_select->fetchall_arrayref;

ok(Encode::is_utf8(${ $result_set }[0][1]));

# fetchall_arrayref
$sth_select->bind_param(1, $test_text, SQL_VARCHAR);
$sth_select->execute;
$result_set = $sth_select->fetchall_arrayref(+{});

ok(Encode::is_utf8(${ $result_set }[0]->{text}));

###
# statement handle method without DBIx::Encoding

my $dbh_utf8_no_dbix_encoding = DBI->connect(@dsn_utf8_no_dbix_encoding) or die;

$sth_select = $dbh_utf8_no_dbix_encoding->prepare(<<'SQL');
select * from test_utf8 where text = ?
SQL

# fetchrow_array
$sth_select->bind_param(1, $test_text, SQL_VARCHAR);
$sth_select->execute;
@result_set = $sth_select->fetchrow_array;

ok(! Encode::is_utf8($result_set[1]));

# fetchrow_arrayref
$sth_select->bind_param(1, $test_text, SQL_VARCHAR);
$sth_select->execute;
$result_set = $sth_select->fetchrow_arrayref;

ok(! Encode::is_utf8($result_set[1]));

# fetchrow_hashref
$sth_select->bind_param(1, $test_text, SQL_VARCHAR);
$sth_select->execute;
$result_set = $sth_select->fetchrow_hashref;

ok(! Encode::is_utf8($result_set->{text}));

# fetchall_arrayref
$sth_select->bind_param(1, $test_text, SQL_VARCHAR);
$sth_select->execute;
$result_set = $sth_select->fetchall_arrayref;

ok(! Encode::is_utf8(${ $result_set }[0][1]));

# fetchall_arrayref
$sth_select->bind_param(1, $test_text, SQL_VARCHAR);
$sth_select->execute;
$result_set = $sth_select->fetchall_arrayref(+{});

ok(! Encode::is_utf8(${ $result_set }[0]->{text}));

done_testing;
