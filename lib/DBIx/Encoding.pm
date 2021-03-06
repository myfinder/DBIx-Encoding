use strict;
use warnings;
use Carp;

###
# DBIx::Encoding
#
package DBIx::Encoding;
use base qw(DBI);

use version;
our $VERSION = '0.05';

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

sub do {
    my ($self, $stmt, $attr, @args) = @_;
    my $encoding = $self->{private_dbix_encoding}->{encoding};

    @args = map { Encode::encode($encoding, $_) } @args;

    return $self->SUPER::do($stmt, $attr, @args);
}

###
# DBIx::Encoding::st
#
package DBIx::Encoding::st;
use base qw(DBI::st);

use Encode;

sub bind_param {
    my ($self, @args) = @_;
    my $encoding = $self->{private_dbix_encoding}->{encoding};
    
    $args[1] = Encode::encode($encoding, $args[1]);
    
    return $self->SUPER::bind_param(@args);
}

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

sub fetchrow_array {
    my $self = shift;
    my $encoding = $self->{private_dbix_encoding}->{encoding};
    
    my @array = $self->SUPER::fetchrow_array or return;
    
    return map { Encode::decode($encoding, $_) } @array;
}

sub fetchall_arrayref {
    my ($self, $slice, $max_rows) = @_;
    my $encoding = $self->{private_dbix_encoding}->{encoding};
    
    my $array_ref;
    
    if ($slice) {
        $array_ref = $self->SUPER::fetchall_arrayref($slice, $max_rows) or return;
    }
    else {
        $array_ref = $self->SUPER::fetchall_arrayref or return;
        for my $array (@{ $array_ref }) {
            @{ $array } = map { Encode::decode($encoding, $_) } @{ $array };
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
