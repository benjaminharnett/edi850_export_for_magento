package Business::Logic::Cart;

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
sub ifdef
{
    my ($p,$d) = @_;
    
    if(!defined $d){$d = '';}
    return (defined $p ? $p : $d);
}

sub q_map
{
    my ($map,$p,$d) = @_;
    unless(defined $d){$d = $p;}
    return defined $map->{$p} ? $map->{$p} : $d;
}

sub get_cart
{
    my ($self) = @_;
    # not cool
    return $self;
}

sub new
{
    my($class, $params,$map) = @_;
    
    $map = (defined $map ? $map : {});
    
    my $parameters = {
	items=>[],
	customer=>'',
	created=>time,
	last_updated=>time,
	expires=>time+120,
	discounts=>{},
	store_credits=>[],
	company=>undef,
	order_id=>undef,
	cart_country=>undef,
	cart_region=>undef,
	cart_state=>undef,
	cart_offers=>undef,
    };

    my $self = {};
    foreach my $parameter (keys %$parameters)
    {
	$self->{$parameter} = q_map($params,q_map($map,$parameter),$parameters->{$parameter});
    }

    # add item numbers
    my $last_item_number = 0;
    foreach my $item (sort {$b->{'item_no'} <=> $a->{'item_no'}} @{$self->{'items'}})
    {
	if($last_item_number == 0){$last_item_number = $item->{'item_no'};}
	if($item->{'item_no'} == 0){
	    $item->{'item_no'} = $last_item_number + 1;
	    $last_item_number = $item->{'item_no'};
	}
    }
    
    $self->{'data'} = $params;

    bless($self, $class);
    return $self;
}

sub add_order_id
{
    my ($self,$order_id) = @_;
    
    $self->{'last_updated'} = time;
    
    $self->{'order_id'} = $order_id;
    
    return (1);
}

sub cart_id
{
    my ($self) = @_;
    
    if(!defined $self->{'cart_id'})
    {
	$self->{'cart_id'} = time . '_' . int(rand(time)) . '_' . int(rand(100));
    }
    
    return ($self->{'cart_id'});
}


sub order_id
{
    my ($self) = @_;
    
    return ($self->{'order_id'});
}


sub discounts_applied
{
    my ($self) = @_;
    
    my $discounts = $self->{'discounts'};
    
    my %seen;
    my @discount_array = grep { ! $seen{$_}++ } keys %{$discounts};
    
    return \@discount_array;
}

sub hash_items
{
    my ($self) = @_;
    
    my $item_return = [];
    
    foreach my $item (@{$self->{'items'}})
    {
	push @{$item_return},$item->get_hash();
    }
    
    return $item_return;
}

sub has
{
    my ($self,@p) = @_;

    if(defined $p[0])
    {
	# has search string is a hashref
	
	my $match_type = defined $p[0]->{'match_type'} ? $p[0]->{'match_type'} : 'OR';
	my $exclude = defined $p[0]->{'exclude'} ? $p[0]->{'exclude'} : {};
	my $counts = defined $p[0]->{'counts'} ? $p[0]->{'counts'} : {};
	
	my $test_counts = {};

	my $matchers = defined $p[0]->{'matchers'} ? $p[0]->{'matchers'} : {};
	my $current_item = defined $p[0]->{'current_item'} ? $p[0]->{'current_item'} : undef;

	foreach my $item (sort {$b->current_price <=> $a->current_price} @{$self->{'items'}})
	{
	    if(!$exclude->{$item->{'item_no'}} && (!defined $current_item || $current_item->{'item_no'} ne $item->{'item_no'}))
	    {
		my $found = 0;
		
		foreach my $test (keys %{$p[0]})
		{

		    unless($test eq 'exclude' || $test eq 'match_type' || $test eq 'greedy' || $test eq 'counts' || $test eq 'matchers' || $test eq 'current_item')
		    {
			if($test eq 'SKU' && grep(/\,/,$p[0]->{$test}))
			{
			    if($item->qty > 0)
			    {
				foreach my $sku (split(/\,/,$p[0]->{$test}))
				{
				    if($sku =~ /^(\w)\*$/)
				    {
					if($item->SKU =~ /^$1/)
					{
					    $found = 1;
					    return ($item);
					}
				    }
				    else
				    {

					if($item->SKU eq uc($sku))
					{
					    $found = 1;
					    return ($item);
					}
				    }
				}
			    }
			}
			elsif (($test eq 'SKU' && $p[0]->{$test} eq 'ALL') || (defined $item->{$test} && $item->{$test} eq $p[0]->{$test}) || (defined $item->{'data'}->{$test} && $item->{'data'}->{$test} eq $p[0]->{$test}))
			{
			    $found = 1;
				
			    if(defined $counts->{$test})
			    {
				if(!defined $test_counts->{$test})
				{
				    $test_counts->{$test} = $counts->{$test};
				}
				
				$test_counts->{$test} -= $item->qty;
				foreach my $test (keys %{$counts})
				{
				    if($test_counts->{$test} > 0)
				    {
					$found = 0;
				    }
				}
			    }
			    
			}
			elsif($match_type eq 'AND')
			{
			    $found = 0;
			    last;
			}
		    }
			
		}
		
		my $test_find = undef;
		foreach my $matcher (keys %{$matchers})
		{
		    my $match = $matchers->{$matcher};
		    
		    my $match_type = $matcher;
		    my $match_cmp = $match->{'type'};
		    my $match_value = $match->{'value'};

		    $test_find = 0;

		    if($match_cmp eq '<=')
		    {
			if($match_type eq 'price')
			{
			    if($item->current_price >= $match_value)
			    {
				$test_find = 1;
			    }
			}
			elsif(defined $item->{$match_type} && $item->{$match_type} >= $match_value)
			{
			    $test_find = 1;
			}
		    }
		    elsif($match_cmp eq 'has')
		    {
			if(defined $item->{$match_type} && grep(/$match_value/i,$item->{$match_type}))
			{
			    $test_find = 1;
			}
			elsif(defined $item->{data}->{$match_type} && grep(/$match_value/i,$item->{data}->{$match_type}))
			{
			    $test_find = 1;
			}
		    }
		    
		    last if !defined $test_find || $test_find == 0;
		}
		
		if($test_find)
		{
		    $found = $test_find;
		}

		if($found == 1)
		{
		    return ($item);
		}
	    }
	}
    }
    
    return ();
}

sub update_item # not quite right
{
    my ($self,$updated_item) = @_;

    my $item_no = $updated_item->{'item_no'};
    my $style = $updated_item->SKU;
    
    if(defined $item_no && $item_no ne '')
    {
	for (my $i = 0; $i <= $#{$self->{'items'}};$i++)
	{
	    my $item = $self->{'items'}->[$i];
	    if($item->{'item_no'} eq $item_no)
	    {
		# change this item
		$self->{'items'}->[$i] = $updated_item;
		return;
	    }
	    
	}
    }
    elsif(defined $style && $style ne '')
    {
	for (my $i = 0; $i <= $#{$self->{'items'}};$i++)
	{
	    my $item = $self->{'items'}->[$i];
	    if($item->{'SKU'} eq $style)
	    {
		# change item
		$self->{'items'}->[$i] = $updated_item;
		return;
	    }
	    
	}
    }
}

sub get_item
{
    my ($self,$item_no,$style) = @_;

    my @removed_items;

    if(defined $item_no && $item_no ne '')
    {
	foreach my $item (@{$self->{'items'}})
	{
	    if($item->{'item_no'} eq $item_no)
	    {
		return ($item);
	    }
	    
	}
    }
    elsif(defined $style && $style ne '')
    {
	
	foreach my $item (@{$self->{'items'}})
	{
	    if($item->{'SKU'} eq $style)
	    {
		return ($item);
	    }
	}
    }
    
    return (undef);
}

sub remove_items
{
    my ($self) = @_;
    
    foreach my $item (@{$self->{'items'}})
    {
	$self->remove_item($item->{'item_no'});
    }
    return (1);
}

sub remove_item
{
    my ($self,$item_no,$style,$limit,@p) = @_;
    
    my @removed_items;

    if(defined $item_no && $item_no ne '')
    {
	my @new_items;

	my $removed = 0;	
	$limit = ifdef($limit,0);
	
	foreach my $item (@{$self->{'items'}})
	{
	    if($item->{'item_no'} eq $item_no)
	    {
		if($limit == 0 || $removed <= $limit)
		{
		    push @removed_items,$item;
		}
		else
		{
		    push @new_items,$item;
		}
	    }
	    else
	    {
		push @new_items,$item;
	    }
	    
	}
	
	$self->{'items'} = \@new_items;
    }
    elsif(defined $style && $style ne '')
    {
	my @new_items;
	
	my $removed = 0;	
	$limit = ifdef($limit,0);
	
	foreach my $item (@{$self->{'items'}})
	{
	    if($item->{'SKU'} eq $style)
	    {
		if($limit == 0 || $removed <= $limit)
		{
		    push @removed_items,$item;
		    $removed++;
		}
		else
		{
		    push @new_items,$item;
		}
	    }
	    else
	    {
		push @new_items,$item;
	    }
	    
	}
	$self->{'items'} = \@new_items;
    }

    return (\@removed_items);
}

sub add_item
{
    my ($self,@p) = @_;
    
    foreach my $item (@p)
    {
	push @{$self->{'items'}},$item;
    }
    
    my $last_item_number = 0;
    foreach my $item (sort {$b->{'item_no'} <=> $a->{'item_no'}} @{$self->{'items'}})
    {
	
	if($last_item_number == 0){$last_item_number = $item->{'item_no'};}
	if(!defined $item->{'item_no'} || $item->{'item_no'} == 0){
	    $item->{'item_no'} = $last_item_number + 1;
	    $last_item_number = $item->{'item_no'};
	}

    }
}

sub add_discount
{
    my ($self,@p) = @_;
    
    foreach my $discount (@p)
    {
	push @{$self->{'discounts'}->{$discount->code}->{$discount->SKU}},$discount;
    }
}


sub remove_discount
{
    my ($self,@p) = @_;
    
    foreach my $code (@p)
    {
	delete $self->{'discounts'}->{$code};
    }
}

sub clear_discounts
{
    my ($self,@p) = @_;

    $self->{'discounts'} = undef;
    $self->{'discounts'} = {};
}

sub discounts
{ 
    my ($self,@p) = @_;
    
    my $discounts = [];
    
    foreach my $discount (keys %{$self->{'discounts'}})
    {
	foreach my $sku (keys %{$self->{'discounts'}->{$discount}})
	{
	    push @$discounts,@{$self->{'discounts'}->{$discount}->{$sku}};
	}
    }
    
    return $discounts;
}

sub taxable_total
{
    my ($self,@p) = @_;
    
    if(defined $self->{'cached_taxable_total'}) # this could cause problems if total is not run first
    {
	return $self->{'cached_taxable_total'};
    }
    
    my $total = 0;
    
    my ($t) = ifdef($p[0],'');
    
    foreach my $discount (@{$self->discounts})
    {
	$discount->reset($t);
    }
    
    foreach my $item (sort {$b->current_price <=> $a->current_price} @{$self->{'items'}})
    {
	my $taxable = $item->taxable;
	if($taxable)
	{
	    my ($ip,$fp) = Business::Logic->get_discounted_item_price($t, $item, $self->discounts, $self);
	    $total += int($ip * (defined $item->qty ? $item->qty : 1) * $taxable * 100 + .5)/100; # round to .00
	}
    }
    
    return ($total);
    
}

sub set_per_item_shipping
{
    my ($self,$per_item_shipping) = @_;
    
    $self->{'per_item_shipping'} = $per_item_shipping;
    
    return (1);
}

sub set_first_item_shipping
{
    my ($self,$first_item_shipping) = @_;
    
    $self->{'first_item_shipping'} = $first_item_shipping;
    
    return (1);
}

sub get_default_per_item_shipping
{
    my ($self) = @_;
    
    if(defined $self->{'per_item_shipping'})
    {
	return $self->{'per_item_shipping'};
    }
    elsif(defined $self->{'company'} && $self->{'company'} ne 'company')
    {
	# fix this! where company => company and causes problems
	return $self->{'company'}->default_per_item_shipping();
    }
    else
    {
	return 1; # default to $1
    }
}

sub get_default_first_item_shipping
{

    my ($self) = @_;
    
    if($self->{'first_item_shipping'})
    {
	return $self->{'first_item_shipping'};
    }
    elsif(defined $self->{'company'} && $self->{'company'} ne 'company')
    {
	return $self->{'company'}->default_first_item_shipping();
    }
    else
    {
	return 10; # default to $10
    }
}

sub shipping_costs
{
    my ($self,$f1,$p1) = @_;
    
    my $cart_items = $self->item_count();
    
    my $only_electronic = $self->only_electronic();
    
    if($only_electronic)
    {
	return 0;
    }
    
    my $cart_subtotal = $self->total();
    my $shipping_method = $self->{'shipping_method'};
    
    my $cart_country = $self->{'cart_country'};
    my $cart_region = $self->{'cart_region'};
    my $cart_state = $self->{'cart_state'};
    
    if(defined $self->{'shipping_profile'})
    {
	my $shipping_profile = $self->{'shipping_profile'};
	
	my $shipping = undef;
	
	foreach my $profile (@{$shipping_profile})
	{
	    my $start_qty = $profile->{'from_qty'};
	    my $stop_qty = $profile->{'to_qty'};
	    my $start_cart = $profile->{'from_dol'};
	    my $stop_cart = $profile->{'to_dol'};
	    my $name = $profile->{'name'};
	    my $amt = $profile->{'amt'};
	    
	    my $region = $profile->{'region'};
	    my $country = $profile->{'country'};
	    my $state = $profile->{'state'};
	    my $method = $profile->{'method'};
	    
	    if($name eq 'default' && !defined $shipping)
	    {
		$shipping = $amt;
	    }
	    else
	    {
		if(!defined $start_qty || $start_qty == 0 || $start_qty <= $cart_items)
		{
		    if(!defined $stop_qty || $stop_qty == 0 || $stop_qty >= $cart_items)
		    {
			if(!defined $start_cart || $start_cart == 0 || $start_cart <= $cart_subtotal)
			{
			    if(!defined $stop_cart || $stop_cart == 0 || $stop_cart >= $cart_subtotal)
			    {
				if(!defined $method || (defined $method && defined $shipping_method && $method eq $shipping_method))
				{
				    if(!defined $region || (defined $region && defined $cart_region && $region eq $cart_region))
				    {
					$shipping = $amt;
				    }
				}
			    }
			}
		    }
		}
	    }
	}
	
	if(!defined $shipping)
	{
	    $shipping = 0;
	}
	
	return ($shipping);
    }
    else
    {
	return $self->old_shipping_costs($f1,$p1);
    }
}

sub shipping_profile_to_javascript
{
    # this should be somewhere else
    
}

sub old_shipping_costs
{
    my ($self,$fitem_shipping,$pitem_shipping) = @_;
    
    my $total = 0;
    
    my $first_item_shipping = undef;
    my $first_item_shipping_amount = 0;
    my $per_item_shipping_total = 0;
    
    foreach my $item (sort {$b->current_price <=> $a->current_price} @{$self->{'items'}})
    {
	if(defined $pitem_shipping)
	{
	    if(!defined $first_item_shipping)
	    {
		$first_item_shipping = $item;
		if($item->{'qty'} > 1)
		{
		    $per_item_shipping_total += $pitem_shipping * ($item->{'qty'}-1);
		}
	    }
	    else
	    {
		$per_item_shipping_total += $pitem_shipping * $item->{'qty'};
	    }
	}
	else
	{
	    my $item_first_item_shipping = $item->get_first_item_shipping();
	    $item_first_item_shipping = ($item_first_item_shipping ? $item_first_item_shipping : $self->get_default_first_item_shipping()); 

	    my $item_per_item_shipping = $item->get_per_item_shipping();
	    
	    if(!defined $first_item_shipping)
	    {    
		$first_item_shipping_amount = $item_first_item_shipping;
		$first_item_shipping = $item;
		
		if($item->{'qty'} > 1)
		{
		    $per_item_shipping_total += ($item->{'qty'}-1) * $item_per_item_shipping;
		}
	    }
	    else
	    {
		
		$item_per_item_shipping  = ($item_per_item_shipping ? $item_per_item_shipping : $self->get_default_per_item_shipping());
		
		if($item_first_item_shipping > $first_item_shipping_amount) # swap them
		{
		    
		    my $previous_item = $first_item_shipping;
		    
		    my $prev_item_per_item_shipping = $previous_item->get_per_item_shipping();
		    $prev_item_per_item_shipping  = ($prev_item_per_item_shipping ? $prev_item_per_item_shipping : $self->get_default_per_item_shipping());
		    
		    $per_item_shipping_total += $prev_item_per_item_shipping * $previous_item->{'qty'};
		    
		    $first_item_shipping_amount = $item_first_item_shipping;
		    $first_item_shipping = $item;
		    
		    if($item->{'qty'} > 1)
		    {
			$per_item_shipping_total += $item_per_item_shipping * ($item->{'qty'}-1);
		    }
		}
		else
		{
		    
		    $per_item_shipping_total += $item_per_item_shipping * $item->{'qty'};
		}
	    }
	}
    }
    
    if(defined $fitem_shipping)
    {
	$first_item_shipping_amount = $fitem_shipping;
    }
    
    # add in multiples
    my $total_shipping_cost = $first_item_shipping_amount + $per_item_shipping_total;
    return ($total_shipping_cost);
    
}

sub available_methods
{
    my ($self,$methods) = @_;
    
    if(defined $methods)
    {
	$self->{'available_shipping_methods'} = $methods;
	return (1);
    }
    else
    {
	return ($methods);
    }    
}

sub set_shipping_method
{
    my ($self,$shipping_method) = @_;
    
    $self->{'shipping_method'} = $shipping_method;
    
    return (1);
}

sub get_shipping_method
{
    my ($self) = @_;
    
    my $shipping_method = $self->{'shipping_method'};
    
    # check here to make sure method is allowable,
    # change to default if not allowable
    
    return ($shipping_method);
    
}

sub cart_items_ok
{
    my ($self) = @_;
    
    my $items = $self->{'items'};
    
    foreach my $item (sort {$b->current_price <=> $a->current_price} @{$items})
    {
	if($item->has_size())
	{
	    if(!$item->size_exists($item->{'size'}))
	    {
		return (0);
	    }
	}
	
	if($item->has_options())
	{
	    if(!$item->options_ok())
	    {
		return (0); # you must select your options
	    }
	}
    }

    return (1);
}

sub cart_status
{
    my ($self) = @_;
    
    my $status = 2;
    my $item_to_fix = undef;

    # statuses = 0: items with options not selected
    
    foreach my $item (sort {$b->current_price <=> $a->current_price} @{$self->{'items'}})
    {
	if($item->has_options())
	{
	    if(!$item->options_ok())
	    {
		$status = 0;
                $item_to_fix = $item;
		last;
	    }
	}
    }
    
    # = 1: items with sizes do not have sizes selected
    
    # = 2: everything aok

    return ($status,$item_to_fix);
}

sub shipping_total
{
    my ($self,$shipping_method) = @_;
    
    my $total = 0;
    
    if(!defined $shipping_method)
    {
	$shipping_method = $self->get_shipping_method();
    }
    
    if(defined $shipping_method)
    {
	$total = $self->shipping_costs(); #shipping_method->calculate_price($self);
    }
    else
    {
	$total = $self->shipping_costs(); # defaults
    }
    
    return ($total);
}

sub only_electronic
{
    my ($self) = @_;

    my ($items) = $self->{'items'};
    
    my $count = undef;
    
    foreach my $item (sort {$b->current_price <=> $a->current_price} @{$items})
    {
	if($item->is_giftcard())
	{
	    if(!defined $count || $count)
	    {
		$count = 1;
	    }
	    else
	    {
		$count = 0;
	    }
	}
	else
	{
	    $count = 0;
	}
    }
    
    return ($count);
}

sub item_count
{
    my ($self) = @_;
    
    my ($items) = $self->{'items'};
    
    my $count = 0;
    
    foreach my $item (sort {$b->current_price <=> $a->current_price} @{$items})
    {
	my $qty = $item->qty();
	
	if(!defined $qty || $qty < 1){$qty = 1;}
	$count = $count + $qty;

    }
    
    return ($count);
}

sub store_credits
{
    my ($self) = @_;

    my $store_credits = $self->{'store_credits'};
    
    if(!defined $store_credits)
    {
	$store_credits = [];
	$self->{'store_credits'} = $store_credits;
    }
    
    # return array of store_credits
    
    return ($store_credits);
}

sub remove_store_credit
{
    my ($self,$store_credit) = @_;
    
    my $store_credits = $self->{'store_credits'};
    my $new_store_credits = [];
    
    if(!defined $store_credits)
    {
	$store_credits = [];
	$self->{'store_credits'} = $store_credits;
    }
    
    foreach my $credit (@{$store_credits})
    {
	if($credit->is($store_credit))
	{
	    $credit->remove_credit($self);
	    # do not add it!
	}
	else
	{
	    push @{$new_store_credits},$credit;
	}
    }
    
    $self->{'store_credits'} = $new_store_credits;
    
    return (1); #success

}

sub apply_store_credit
{
    my ($self,$store_credit) = @_;

    my $store_credits = $self->{'store_credits'};
    
    if(!defined $store_credits)
    {
	$store_credits = [];
	$self->{'store_credits'} = $store_credits;
    }
    
    foreach my $credit (@{$store_credits})
    {
	if($credit->is($store_credit))
	{
	    return (0); # already applied
	}
    }

    push @{$store_credits},$store_credit;
    
    return (1); #success
}

sub total
{
    my ($self,@p) = @_;
    
    my $total = 0;
    my $taxable_total = 0;
    
    my ($t) = ifdef($p[0],'');
    
    foreach my $discount (@{$self->discounts})
    {
	$discount->reset($t);
    }
    
    foreach my $item (sort {$b->current_price <=> $a->current_price} @{$self->{'items'}})
    {
	my ($ip,$fp) = Business::Logic->get_discounted_item_price($t, $item, $self->discounts, $self);
	$item->{'discounted_price'} = $ip;
	if($item->{'discounted_price'} != $item->price)
	{
	    $item->{'print_price'} = '<strike>$' . $item->{'price'} . '</strike> $' . $item->{'discounted_price'};
	}
	else
	{
	    $item->{'print_price'} = '$' . $item->{'price'};
	}
	
	$item->{'original_subtotal'} = $item->{'price'} * (defined $item->qty ? $item->qty : 1); 
	
	$item->{'subtotal'} = $item->{'discounted_price'} * (defined $item->qty ? $item->qty : 1);
	
	if($item->{'original_subtotal'} != $item->{'subtotal'})
	{
	    $item->{'print_item_subtotal'} = '<strike>$' . $item->{'original_subtotal'} . '</strike> $' . $item->{'subtotal'};
	}
	else
	{	
	    $item->{'print_item_subtotal'} = '$' . $item->{'subtotal'};
	}

	$taxable_total += int($ip * (defined $item->qty ? $item->qty : 1) * $item->taxable() * 100 + .5)/100; # round to .00
	$total+=$ip * (defined $item->qty ? $item->qty : 1);
    }

    my $cart_offer = $self->calculate_offers($total);

    $taxable_total -= $cart_offer;
    $total -= $cart_offer;
    if($total < 0){ $cart_offer += $total; $total = 0;}

    $self->{'applied_offer_amount'} = $cart_offer;

    if($taxable_total < 0)
    {
	$taxable_total = 0;
    }

    $self->{'cached_taxable_total'} = $taxable_total;
    
    return ($total);
}

sub applied_offer
{
    my ($self,@p) = @_;

    return $self->{'applied_offer'}
}

sub applied_offer_text
{
    my ($self,@p) = @_;

    return (defined $self->{'applied_offer'} ? $self->{'applied_offer'}->{'text'} : '');
}

sub applied_offer_amount
{
    my ($self,@p) = @_;

    return ($self->{'applied_offer_amount'});
}

sub calculate_offers
{
    my ($self,@p) = @_;
    
    my ($total) = ifdef($p[0],0);

    $self->{'applied_offer'} = undef;
    
    my $offer_amount = 0;

    my $offers = $self->{'cart_offers'};
    my $offer_text = undef;

    if(defined $offers && $offers ne 'cart_offers')
    {
	foreach my $offer (sort {$a->{'value'} <=> $b->{'value'}} @$offers)
	{
	    my $offer_value = $offer->{'value'};
	    my $the_offer_text = $offer->{'text'};
	    my $offer_dollar_amount = $offer->{'amount'};
	    
	    if($offer_value <= $total)
	    {
		$offer_amount = $offer_dollar_amount;
		$offer_text = $the_offer_text;
		$self->{'applied_offer'} = $offer;
	    }
	}
    }
    return $offer_amount;
}

1;
__END__
# Below is stub documentation for your module. You'd better edit it!

=head1 NAME

Business::Logic::Cart - Perl extension for blah blah blah

=head1 SYNOPSIS

  use Business::Logic::Cart;
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
