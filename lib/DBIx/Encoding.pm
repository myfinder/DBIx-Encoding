use strict;
use warnings;
use Carp;

###
# DBIx::Encoding
#
package DBIx::Encoding;
use base qw(DBI);

use version;
our $VERSION = qv('0.0.1');

###
# DBIx::Encoding::db
#
package DBIx::Encoding::db;
use base qw(DBI::db);

sub connected {
	my ($self, $dsn, $user, $credential, $attrs) = @_;
	
	$self->{private_dbix_endocing} = { 'encoding' => $attrs->{encoding} || 'utf8' };
}

sub prepare {
	my ($self, @args) = @_;
	my $sth = $self->SUPER::prepare(@args) or return;
	
	$sth->{private_dbix_endocing} = $self->{private_dbix_endocing};
	
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
	my $encoding = $self->{private_dbix_endocing}->{encoding};
	
	@args = map { Encode::encode($encoding, $_) } @args;
	
	return $self->SUPER::execute(@args);
}

sub fetch {
	my ($self, @args) = @_;
	my $encoding = $self->{private_dbix_endocing}->{encoding};
	
	my $row = $self->SUPER::fetch(@args) or return;
	for my $val (@$row) {
		$val = Encode::decode($encoding, $val);
	}
	
	return $row;
}

sub fetchrow_arrayref {
	my ($self, @args) = @_;
	my $encoding = $self->{private_dbix_endocing}->{encoding};
	
	my $array_ref = $self->SUPER::fetchrow_arrayref(@args) or return;
	for my $val (@$array_ref) {
		$val = Encode::decode($encoding, $val);
	}
	
	return $array_ref;
}


1;

__END__

=head1 NAME

DBIx::Encoding - Doing endoce/decode in the character code which you appointed in an attribute.


=head1 VERSION

This document describes DBIx::Encoding version 0.0.1


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


=head1 SEE ALSO

DBI

=head1 AUTHOR

Tatsuro HISAMORI  C<< <medianetworks@gmail.com> >>


=head1 LICENCE AND COPYRIGHT

Copyright (c) 2009, Tatsuro HISAMORI C<< <medianetworks@gmail.com> >>. All rights reserved.

This module is free software; you can redistribute it and/or
modify it under the same terms as Perl itself. See L<perlartistic>.


=head1 DISCLAIMER OF WARRANTY

BECAUSE THIS SOFTWARE IS LICENSED FREE OF CHARGE, THERE IS NO WARRANTY
FOR THE SOFTWARE, TO THE EXTENT PERMITTED BY APPLICABLE LAW. EXCEPT WHEN
OTHERWISE STATED IN WRITING THE COPYRIGHT HOLDERS AND/OR OTHER PARTIES
PROVIDE THE SOFTWARE "AS IS" WITHOUT WARRANTY OF ANY KIND, EITHER
EXPRESSED OR IMPLIED, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE. THE
ENTIRE RISK AS TO THE QUALITY AND PERFORMANCE OF THE SOFTWARE IS WITH
YOU. SHOULD THE SOFTWARE PROVE DEFECTIVE, YOU ASSUME THE COST OF ALL
NECESSARY SERVICING, REPAIR, OR CORRECTION.

IN NO EVENT UNLESS REQUIRED BY APPLICABLE LAW OR AGREED TO IN WRITING
WILL ANY COPYRIGHT HOLDER, OR ANY OTHER PARTY WHO MAY MODIFY AND/OR
REDISTRIBUTE THE SOFTWARE AS PERMITTED BY THE ABOVE LICENCE, BE
LIABLE TO YOU FOR DAMAGES, INCLUDING ANY GENERAL, SPECIAL, INCIDENTAL,
OR CONSEQUENTIAL DAMAGES ARISING OUT OF THE USE OR INABILITY TO USE
THE SOFTWARE (INCLUDING BUT NOT LIMITED TO LOSS OF DATA OR DATA BEING
RENDERED INACCURATE OR LOSSES SUSTAINED BY YOU OR THIRD PARTIES OR A
FAILURE OF THE SOFTWARE TO OPERATE WITH ANY OTHER SOFTWARE), EVEN IF
SUCH HOLDER OR OTHER PARTY HAS BEEN ADVISED OF THE POSSIBILITY OF
SUCH DAMAGES.