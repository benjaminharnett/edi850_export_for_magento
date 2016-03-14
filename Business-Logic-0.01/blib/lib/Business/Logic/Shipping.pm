package Business::Logic::Shipping;

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
	method_name=>undef, # long name
	valid_country=>undef, # country code, or foreign, domestic, all, undef
	method_code=>undef, # short code
	estimated_delivery=>undef, # method estimated delivery time
	base_price=>undef, # base price
	unit_price=>undef, # unit price / per additional unit
	unit_type=>undef, # unit, lb, kilo
	vendor=>undef, # UPS,FedEx,USPS, etc.
	note=>undef, # special note
	default=>0, #default to this method or not
	prices=>undef, #hash of prices #more complex!
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


sub get_proper_price
{
    my ($self,$cart) = @_;
    
    my ($cart_amount) = $cart->total();
    
    my $prices = $self->{'prices'};
    
    my $base = 0;
    my $item = 0;
    
    foreach my $price_level (sort {$a <=> $b} keys %{$prices})
    {
	if ($cart_amount < $price_level)
	{
	    ($base,$item) = @{$prices->{$price_level}};
	}
    }
    
    return ($base,$item);
}

sub calculate_price
{
    my ($self,$cart) = @_;
    
    my $prices = $self->{'prices'};
    
    my $base_price = $self->{'base_price'};
    my $item_price = $self->{'item_price'};

    my $total_price = 0;
    
    if(defined $cart)
    {
    
	if(defined $prices)
	{
	    ($base_price,$item_price) = $self->get_proper_price($cart);
	}
	
	
	if($item_price > 0)
	{
	    $total_price = $cart->shipping_costs($base_price,$item_price);
	}
	else
	{
	    $total_price = $base_price;
	}
    }
    else
    {
	$total_price = $base_price;
    }
    
    return ($total_price);
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
