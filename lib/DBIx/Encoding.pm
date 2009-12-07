use strict;
use warnings;
use Carp;

###
# DBIx::Encoding
#
package DBIx::Encoding;
use base qw(DBI);

use version;
our $VERSION = '0.04';

###
# DBIx::Encoding::db
#
package DBIx::Encoding::db;
use base qw(DBI::db);

sub connected {
	my ($self, $dsn, $user, $credential, $attrs) = @_;
	$self->{private_dbix_encoding} = { 'encoding' => $attrs->{encoding} || 'utf8' };
}

sub prepare {
	my ($self, @args) = @_;
	my $sth = $self->SUPER::prepare(@args) or return;
	$sth->{private_dbix_encoding} = $self->{private_dbix_encoding};
	
	return $sth;
}

###
# DBIx::Encoding::st
#
package DBIx::Encoding::st;
use base qw(DBI::st);

use Encode;

sub execute {
	my ($self, @args) = @_;
	my $encoding = $self->{private_dbix_encoding}->{encoding};
	
	@args = map { Encode::encode($encoding, $_) } @args;
	
	return $self->SUPER::execute(@args);
}

sub fetch {
	my ($self, @args) = @_;
	my $encoding = $self->{private_dbix_encoding}->{encoding};
	
	my $row = $self->SUPER::fetch(@args) or return;
	
	for my $val (@$row) {
		$val = Encode::decode($encoding, $val);
	}
	
	return $row;
}

sub fetchrow_arrayref {
	my ($self, @args) = @_;
	my $encoding = $self->{private_dbix_encoding}->{encoding};
	
	my $array_ref = $self->SUPER::fetchrow_arrayref(@args) or return;
	
	for my $val (@$array_ref) {
		$val = Encode::decode($encoding, $val);
	}
	
	return $array_ref;
}

sub fetchrow_array {
	my $self = shift;
	my $encoding = $self->{private_dbix_encoding}->{encoding};
	
	my @array = $self->SUPER::fetchrow_array or return;
	
	my @result_array;
	
	for my $val (@array) {
		push @result_array, Encode::decode($encoding, $val);
	}
	
	return @result_array;
}

sub fetchall_arrayref {
	my $self = shift;
	my $encoding = $self->{private_dbix_encoding}->{encoding};
	
	my $array_ref = $self->SUPER::fetchall_arrayref or return;
	
	for my $array (@$array_ref) {
		for my $val (@$array) {
			$val = Encode::decode($encoding, $val);
		}
	}
	
	return $array_ref;
}

1;
__END__

=head1 NAME

DBIx::Encoding - Doing encode/decode in the character code which you appointed in an attribute.

=head1 SYNOPSIS

	use DBIx::Encoding;
	
	my @dsn = (
			'dbi:mysql:host=localhost;database=mysql;mysql_socket=/tmp/mysql.sock;',
			'root',
			'',
			{
				RootClass => 'DBIx::Encoding',
				encoding => 'utf8',
			},
	);
	
	my $dbh = DBI->connect(@dsn) or die;

=head1 DESCRIPTION

DBIx::Encoding is encode/decode in the charset which you appointed in an attribute.
but, this module does not yet support blob.
I am going to support it in a future version.

=head1 AUTHOR

Tatsuro Hisamori E<lt>myfinder@cpan.orgE<gt>

=head1 SEE ALSO

DBI

=head1 LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
