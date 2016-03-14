package Business::Logic::PaymentMethod;

use 5.010001;
use strict;
use warnings;

use Carp;

require Exporter;

use Business::Logic;

our @ISA = qw(Exporter);

# Items to export into callers namespace by default. Note: do not export
# names by default without a very good reason. Use EXPORT_OK instead.
# Do not simply export all your public functions/methods/constants.

# This allows declaration	use Business::Logic::Cart ':all';
# If you do not need this, moving things directly into @EXPORT or @EXPORT_OK
# will save memory.
#our %EXPORT_TAGS = ( 'all' => [ qw(
#	
#) ] );

our @EXPORT_OK = ( 

);

our @EXPORT = qw(
	
);

our $VERSION = '0.01';


# Preloaded methods go here.

sub q_map
{
    my ($map,$p,$d) = @_;
    unless(defined $d){$d = $p;}
    return defined $map->{$p} ? $map->{$p} : $d;
}

sub new
{
    my($class, $params,$map) = @_;
    
    $map = (defined $map ? $map : {});
    
    my $parameters = {
	card_number=>'',
	card_type=>'',
	card_expiration=>'',
	card_security=>'',
	card_billing=>undef,
    };

    my $self = {};
    foreach my $parameter (keys %$parameters)
    {
	$self->{$parameter} = q_map($params,q_map($map,$parameter),$parameters->{$parameter});
    }
    
    $self->{'data'} = $params;

    bless($self, $class);
    
    return $self;
}

### Decrypt $str using $key  ###
### returns decrypted string ###
sub decrypt {
	my ($str, $key) = @_;
	return(RC4($key,$str));
}

### Encrypt $str using $key      ###
### Returns an encrypted string  ###
sub encrypt {
	my ($str, $key) = @_;
	return(RC4($key,$str));
}

sub RC4 {
    my $x = 0;
    my $y = 0;
    
    my $key = shift;
    my @k = unpack( 'C*', $key );
    my @s = 0..255;
    
    for ($x = 0; $x != 256; $x++) {
        $y = ( $k[$x % @k] + $s[$x] + $y ) % 256;
        @s[$x, $y] = @s[$y, $x];
    }

    $x = $y = 0;

    my $z = undef;
    
    for ( unpack( 'C*', shift ) ) {
        $x = ($x + 1) % 256;
        $y = ( $s[$x] + $y ) % 256;
        @s[$x, $y] = @s[$y, $x];
        $z .= pack ( 'C', $_ ^= $s[( $s[$x] + $s[$y] ) % 256] );
    }

return $z;
}

sub set_and_decrypt_number
{
    my ($self,$number,$salt) = @_;
    $self->{'card_number'} = decrypt($number,$salt);
    return ($self->{'card_number'});
}

sub decrypt_number
{
    my ($self,$security,$salt) = @_;
    $self->{'card_security'} = decrypt($security,$salt);
    return ($self->{'card_security'});
}

sub encrypted_number
{
    my ($self,$salt) = @_;
    return (encrypt($self->{'card_number'},$salt));
}


sub encrypted_security
{
    my ($self,$salt) = @_;
    return (encrypt($self->{'card_security'},$salt));
}

sub card_type
{
    my ($self) = @_;
    
    $self->get_card_type();
    
    return ($self->{'card_type'});
}

sub get_card_type
{
    my ($self) = @_;
    
    if(grep(/visa/i,$self->{'card_type'}))
    {
	return ('V');
    }

    if(grep(/master/i,$self->{'card_type'}))
    {
	return ('M');
    }

    if(grep(/discover/i,$self->{'card_type'}))
    {
	return ('D');
    }

    if(grep(/amex|american/i,$self->{'card_type'}))
    {
	return ('A');
    }

    my $card_number = $self->{'card_number'};
    
    if($card_number =~ /^3/)
    {
	$self->{'card_type'} = 'American Express';
	return ('A');
    }

    if($card_number =~ /^4/)
    {
	$self->{'card_type'} = 'Visa';
	return ('V');
    }

    if($card_number =~ /^5/)
    {
	$self->{'card_type'} = 'MasterCard';
	return ('M');
    }

    if($card_number =~ /^6/)
    {
	$self->{'card_type'} = 'Discover';
	return ('D');
    }
    
    return ('U'); #unknown

}

sub is_ok
{
    my ($self) = @_;
    
    # check card info
    if(!defined $self->{'card_number'} || $self->{'card_number'} eq '')
    {
	# no card number
	return (0);
    }

    if(!defined $self->{'card_expiration'} || $self->{'card_expiration'} eq '')
    {
	# no card expiration
	return (0);
    }

    if(!defined $self->{'card_security'} || $self->{'card_security'} eq '')
    {
	# no card security code
	return (0);
    }

    
    return (1);
}

1;
__END__
# Below is stub documentation for your module. You'd better edit it!

=head1 NAME

Business::Logic::Cart - Perl extension for blah blah blah

=head1 SYNOPSIS

  use Business::Logic::Customer;
  blah blah blah

=head1 DESCRIPTION

Stub documentation for Business::Logic::Cart, created by h2xs. It looks like the
author of the extension was negligent enough to leave the stub
unedited.

Blah blah blah.

=head2 EXPORT

None by default.



=head1 SEE ALSO

Mention other useful documentation such as the documentation of
related modules or operating system documentation (such as man pages
in UNIX), or any relevant external documentation such as RFCs or
standards.

If you have a mailing list set up for your module, mention it here.

If you have a web site set up for your module, mention it here.

=head1 AUTHOR

root, E<lt>root@(none)E<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2012 by root

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.10.1 or,
at your option, any later version of Perl 5 you may have available.


=cut
