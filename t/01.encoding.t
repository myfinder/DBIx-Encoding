use strict;
use warnings;
use Carp;
use Test::More tests => 2;

use DBIx::Encoding;

use Encode qw(decode encode is_utf8);

######
# flagged test
my @dsn_utf8 = (
	'dbi:mysql:host=localhost;database=mysql;mysql_socket=/tmp/mysql.sock;',
	'root',
	'',
	{
		RootClass => 'DBIx::Encoding',
		encoding => 'utf8',
	},
);
my @dsn_cp932 = (
	'dbi:mysql:host=localhost;database=mysql;mysql_socket=/tmp/mysql.sock;',
	'root',
	'',
	{
		RootClass => 'DBIx::Encoding',
		encoding => 'cp932',
	},
);

my $dbh_utf8 = DBI->connect(@dsn_utf8) or die;
my $dbh_cp932 = DBI->connect(@dsn_cp932) or die;

my $sth_utf8 = $dbh_utf8->prepare("select 1");
my $sth_cp932 = $dbh_cp932->prepare("select 1");

$sth_utf8->execute();
$sth_cp932->execute();

my $rs_utf8 = $sth_utf8->fetchrow_hashref;
my $rs_cp932 = $sth_cp932->fetchrow_hashref;

ok(is_utf8($rs_utf8->{1}));
ok(is_utf8($rs_cp932->{1}));
