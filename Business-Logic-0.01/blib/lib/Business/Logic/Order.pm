package Business::Logic::Order;

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
	cart=>undef,
	customer=>undef,
	shipping_address=>undef,
	billing_address=>undef,
	order_status=>undef,
	gift_flag=>'',
	gift_message=>'',
	order_number=>undef,
	payment_method=>undef,
	company=>undef,
	order_date=>undef,
    };

    my $self = {};
    foreach my $parameter (keys %$parameters)
    {
	$self->{$parameter} = q_map($params,q_map($map,$parameter),$parameters->{$parameter});
	
	# refactor this
	if($self->{$parameter} eq $parameter)
	{
	    $self->{$parameter} = undef;
	}
    }
    
    $self->{'data'} = $params;

    bless($self, $class);
    return $self;
}

sub set_shipping_address
{
    my ($self,$address) = @_;
    
    $self->{'shipping_address'} = $address;
}

sub is_gift
{
    my ($self) = @_;
    
    if(defined $self->{'gift_flag'} && $self->{'gift_flag'} eq 'Y' || $self->{'gift_flag'} eq '1')
    {
	return (1);
    }
    else
    {
	return (0);
    }
}

sub set_order_number
{
    my ($self,$order_number) = @_;
    
    $self->{'order_number'} = $order_number;
    
    return (1);
}

sub set_company
{
    my ($self,$company) = @_;

    $self->{'company'} = $company;
    
}

sub get_order_number
{
    my ($self) = @_;
    
    if(defined $self->{'order_number'})
    {
	return $self->{'order_number'};
    }
    else
    {
	if(defined $self->{'company'})
	{
	    my $order_number = $self->{'company'}->get_next_order_number();
	    $self->{'order_number'} = $order_number;
	    return ($order_number);
	}
	else
	{
	    # generate a random order number
	    my $order_number = time . int(rand(time)) . int(rand(100));
	    $self->{'order_number'} = $order_number;
	    return ($order_number);
	}
    }
}

sub add_customer
{
    my ($self,$customer) = @_;
    $self->{'customer'} = $customer;
    return (1);
}

sub get_customer
{
    my ($self) = @_;
    my $customer = $self->{'customer'};
    return ($customer);
}

sub customer_name
{
    my ($self) = @_;
    
    my $customer = $self->get_customer();
    
    my ($customer_name,$first_name,$last_name) = $customer->customer_name();    
    return ($customer_name);
}

sub set_cart
{
    my ($self,$cart) = @_;
    
    $self->{'cart'} = $cart;
    
    return (1);
}

sub get_cart
{
    my ($self) = @_;
    my $cart = $self->{'cart'};
    return ($cart);
}

sub get_order_subtotal
{
    my ($self) = @_;
    
    my $order_subtotal = 0;
    my $cart = $self->get_cart();
    
    if(defined $cart)
    {
	$order_subtotal = $cart->total();
    }
    
    return ($order_subtotal);
}

sub get_order_taxable_total
{
    my ($self) = @_;
    
    my $taxable_total = 0;
    my $cart = $self->get_cart();
    
    if(defined $cart)
    {
	$taxable_total = $cart->taxable_total(); 
    
	if($self->get_shipping_taxable())
	{
	    $taxable_total += $self->get_shipping_total();
	}
    }
    
    return ($taxable_total);
}

sub taxable
{
    my ($self,$taxable) = @_;
    

    if(defined $taxable)
    {
	$self->{'taxable'} = $taxable;
	return (1);
    }

    
    my $tax_rate = $self->{'tax_rate'};
    if(!defined $self->{'tax_rate'} && defined $self->{'company'})
    {
	$tax_rate = $self->{'company'}->get_tax_rate();
    }
    
    if(defined $tax_rate) # use tax rate hash for calculation / is better way!
    {
	return (1);
    }
    else
    {
	# fall back on other methods
	if(defined $self->{'taxable'})
	{
	    return ($self->{'taxable'});
	}
	elsif (defined $self->{'company'})
	{
	    return $self->{'company'}->is_order_taxable($self);
	}
	else
	{
	    return 0; # not taxable or error
	}
    }
}

sub order_date
{
    my ($self, $order_date) = @_;
    

    if(defined $order_date)
    {
	$self->{'order_date'} = $order_date;
    }
    
    if(!defined $self->{'order_date'})
    {
	$self->{'order_date'} = time;
    }
    
    return $self->{'order_date'};
}

sub set_shipping_taxable
{
    my ($self,$shipping_taxable) = @_;

    $self->{'shipping_taxable'} = $shipping_taxable;

    return (1);
}

sub set_tax_rate
{
    my ($self,$tax_rate) = @_;
    
    $self->{'tax_rate'} = $tax_rate;

    return (1);
}

sub recurse_tax_rate
{
    my ($self,$tax_rate) = @_;
    
    if(defined $tax_rate)
    {
	if(ref ($tax_rate) eq '')
	{
	    return ($tax_rate);
	}
	elsif(ref ($tax_rate) eq 'HASH')
	{
	    my $country = $self->get_order_country();
	    if(!defined $country){$country = 'US';}

	    if(defined $tax_rate->{$country})
	    {
		return $self->recurse_tax_rate($tax_rate->{$country});
	    }
	    else
	    {
		my $state = $self->get_order_state();
		if(!defined $state){$state = '';}
		
		if(defined $tax_rate->{$state})
		{
		    return $self->recurse_tax_rate($tax_rate->{$state});
		}
		
		# add tax rates for zip codes
	    }
	}
    }
    else
    {
	return 0; #not found
    }
}

sub recurse_shipping_taxable
{
    my ($self,$tax_rate) = @_;
    
    if(defined $tax_rate)
    {
	if(ref ($tax_rate) eq '')
	{
	    return ($tax_rate);
	}
	elsif(ref ($tax_rate) eq 'HASH')
	{
	    my $country = $self->get_order_country();
	    if(!defined $country){$country = 'US';}

	    if(defined $tax_rate->{$country})
	    {
		return $self->recurse_tax_rate($tax_rate->{$country});
	    }
	    else
	    {
		my $state = $self->get_order_state();
		if(!defined $state){$state = '';}
		
		if(defined $tax_rate->{$state})
		{
		    return $self->recurse_shipping_taxable($tax_rate->{$state});
		}
		
		# add tax rates for zip codes
	    }
	}
    }
    else
    {
	return 0; #not found # assume deer dead
    }
}


sub get_tax_rate
{
    my ($self) = @_;
    
    my $tax_rates;
    
    if(defined $self->{'tax_rate'})
    {
	$tax_rates = $self->{'tax_rate'};
    }
    elsif(defined $self->{'company'})
    {
	$self->{'tax_rate'} = $self->{'company'}->get_tax_rate();
	$tax_rates = $self->{'tax_rate'};
    }
    else
    {
	return 0;
    }
    
    my $tax_rate = $self->recurse_tax_rate($tax_rates);
    
    if($tax_rate > 1) # passing tax rate as int not pct
    {
	$tax_rate = $tax_rate / 100; 
    }
    
    return $tax_rate;
}

sub get_shipping_taxable
{
    my ($self) = @_;
    
    my $tax_rates;
    
    if(defined $self->{'shipping_taxable'})
    {
	$tax_rates = $self->{'shipping_taxable'};
    }
    elsif(defined $self->{'company'})
    {
	$self->{'shipping_taxable'} = $self->{'company'}->get_shipping_taxable();
	$tax_rates = $self->{'shipping_taxable'};
    }
    else
    {
	return 0;
    }
    
    my $tax_rate = $self->recurse_shipping_taxable($tax_rates);
    
    if(defined $tax_rate)
    {
	if($tax_rate == 1 || $tax_rate eq 'Y' || $tax_rate eq 'Yes' || $tax_rate eq 'yes')
	{
	    return 1;
	}
	else
	{
	    return 0;
	}
    }
    else
    {
	return 0; # not taxable
    }
}


sub get_order_tax
{
    my ($self,$tax_rate) = @_;
    
    my $order_tax_total = 0;
    
    if($self->taxable)
    {
	$order_tax_total = $self->get_order_taxable_total() * (defined $tax_rate ? $tax_rate : $self->get_tax_rate());
    }

    $order_tax_total = int(($order_tax_total*100) + .5)/100; # round to the penny
    return ($order_tax_total);
}

sub get_order_country
{
    my ($self) = @_;
    
    my $shipping_address = $self->{'shipping_address'};
    
    if(!defined $shipping_address)
    {
	return undef;
    }
    else
    {
	return $shipping_address->get_country();
    }
    
}

sub get_order_state
{
    my ($self) = @_;
    
    my $shipping_address = $self->{'shipping_address'};
    
    if(!defined $shipping_address)
    {
	return undef;
    }
    else
    {
	return $shipping_address->get_state();
    }
}

sub get_shipping_total
{
    my ($self) = @_;
    
    my $shipping_total = 0;
    
    my $cart = $self->get_cart();
    
    if(defined $cart)
    {
	$shipping_total = $cart->shipping_total();
    }
    
    return ($shipping_total);
}

sub remove_store_credit
{
    my ($self,$store_credit) = @_;
    
    my $cart = $self->get_cart();
    
    return($cart->remove_store_credit($store_credit));    
}

sub apply_store_credit
{
    my ($self,$store_credit) = @_;
    
    my $cart = $self->get_cart();
    
    return($cart->apply_store_credit($store_credit));    
}

sub hash_credits
{
    my ($self) = @_;
    
    my $scs = $self->store_credits();
    
    my $store_credits = [];
    
    foreach my $sc (@{$scs})
    {
	my $cr = {};
	$cr->{'id'} = $sc->id();
	$cr->{'code'} = $sc->code();
	$cr->{'amount'} = $sc->credit_applied($self);
	push @{$store_credits},$cr;
    }
    
    return $store_credits;
}

sub store_credits
{
    my ($self,$no_calculate) = @_;

    if((defined $no_calculate && !$no_calculate) && (time - (defined $self->{'store_credits_calculated'} ? $self->{'store_credits_calculated'} : 0) > 30))
    {
	$self->store_credit_total();
    }

    my $cart = $self->get_cart();
    
    if(!defined $cart)
    {
	return ([]);
    }
    else
    {
	return ($cart->store_credits());
    }
}

sub store_credit_total
{
    my ($self) = @_;
    
    my $store_credits = $self->store_credits(1);
    
    my $total_cart = $self->get_order_subtotal() + $self->get_order_tax() + $self->get_shipping_total();
    
    my $total = 0;
    
    foreach my $credit (@{$store_credits})
    {
	my $credit_amount = $credit->calculate_amount($self,$total_cart);
	$total += $credit->credit_applied($self);
	$total_cart -= $credit_amount;
    }

    $self->{'store_credits_calculated'} = time;
    
    return ($total);
}


sub get_order_totals
{
    my ($self) = @_;
    
    return ($self->get_order_subtotal(),$self->get_order_tax(),$self->get_shipping_total(),$self->store_credit_total());
}

sub get_order_email
{
    my ($self) = @_;
    
    my $email = undef;
    
    if(defined $self->{'customer'})
    {
	$email = $self->{'customer'}->get_email();
    }
    
    if(!defined $email)
    {
	if(defined $self->{'shipping_address'})
	{
	    $email = $self->{'shipping_address'}->get_email();
	}
	elsif(defined $self->{'billing_address'})
	{
	    $email = $self->{'billing_address'}->get_email(); # this should be wasted
	}
    }
    
    return ($email);
}

sub order_complete
{
    my ($self) = @_;
    
    if(defined $self->{'billing_address'} && $self->{'billing_address'}->is_ok())
    {
	if(defined $self->{'shipping_address'} && $self->{'shipping_address'}->is_ok())
	{
	    if(defined $self->get_order_email())
	    {
		return (1);
	    }
	}
    
    }
    return (0); # order incomplete
}

sub get_order_status
{
    my ($self) = @_;
    
    # 0 -> no customer
    
    if(!defined $self->{'customer'} || !$self->{'customer'}->is_complete())
    {
	return (0);
    }
    
    # 1 -> no shipping info
    if(!defined $self->{'shipping_address'} || !$self->{'shipping_address'}->is_ok())
    {
	return (1);
    }
    
    # 2 -> if gift flag, no gift message?
    
    # 3 -> no shipping method selected

    # 4 -> if not same as, no billing info
    if(!defined $self->{'billing_address'} || !$self->{'billing_address'}->is_ok())
    {
	return (4);
    }

    # 5 -> no payment info
    if(!defined $self->{'payment_method'} || !$self->{'payment_method'}->is_ok())
    {
	return (5);
    }
    
    
    # 6 -> ?
    
    return (6);
}


1;
__END__
# Below is stub documentation for your module. You'd better edit it!

=head1 NAME

Business::Logic::Cart - Perl extension for blah blah blah

=head1 SYNOPSIS

  use Business::Logic::Order;
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
