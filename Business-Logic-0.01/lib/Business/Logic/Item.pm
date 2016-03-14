package Business::Logic::Item;

use 5.010001;
use strict;
use warnings;

use Carp;

use Business::Logic::Options;
use Business::Logic::Option;

require Exporter;

our @ISA = qw(Exporter);

# Items to export into callers namespace by default. Note: do not export
# names by default without a very good reason. Use EXPORT_OK instead.
# Do not simply export all your public functions/methods/constants.

# This allows declaration	use Business::Logic::Item ':all';
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
	price=>0,
	sale_price=>0,
	sale_expires=>0,
	current_price=>0,
	on_sale=>'N',
	no_discounts=>'N',
	SKU=>'',
	in_cart=>'N',
	discounts_applied=>[],
	discount_truncated=>'N',
	max_discount=>100,
	item_no=>0, #in cart only
	qty=>1, #qty in cart
	color=>0, #for sorting
	size=>0,
	age=>0, #when was it created
	parentSKU=>'', #for sorting
	more_colors=>undef, # 0 or 1 or undef
	in_stock=>0, #qty in stock
	made_to_order=>0, #0 for not made to order, time for when it arrives
	popularity=>0, # how popular is the item
	availability_date=>undef, # expected availability date when in PO
	taxable=>1, # default to taxable
	
	type=>undef, # type of item
	category=>undef, #category of item
	subtype=>undef, #subtype of item
	customer=>undef, #customer type of item
	
	per_item_shipping=>undef, #override for item shipping
	first_item_shipping=>undef, #override for total shipping
	
	variations=>undef, # variations
	options=>undef, # options
	
	giftcard=>undef, # is a giftcard
	upc=>undef,
	name=>undef,
    };

    my $self = {};
    foreach my $parameter (keys %$parameters)
    {
	$self->{$parameter} = q_map($params,q_map($map,$parameter),$parameters->{$parameter});
	
	# there must be an easier way
	if($self->{$parameter} eq $parameter && $parameter ne 'in_cart')
	{
	    $self->{$parameter} = undef;
	}
	
    }

    $self->{'data'} = $params;
    bless($self, $class);
    
    if(defined $self->{'options'})
    {
	if(ref $self->{'options'} eq 'ARRAY')
	{
	    my $options = $self->{'options'};
	    
	    $self->{'options'} = undef;
	    
	    foreach my $option (@{$options})
	    {
		$self->add_option($option);
	    }
	}
    }
    

    return $self;
}

sub is_giftcard
{
    my ($self) = @_;
    
    if(!defined $self->{'is_giftcard'})
    {
	if(grep(/giftcard/i,$self->SKU))
	{
	    $self->{'is_giftcard'} = 1;
	    return 1;
	}
	elsif(grep(/gift certificate/i,(defined $self->{'name'} ? $self->{'name'} : '')))
	{
	    $self->{'is_giftcard'} = 1;
	    return 1;
	}
	else
	{
	    $self->{'is_giftcard'} = 0;
	    return 0;
	}
    }
    else
    {
	return $self->{'is_giftcard'};
    }
}

sub hash_options
{
    my ($self) = @_;

    if(defined $self->{'options'})
    {
	return ($self->{'options'}->hash_options());
    }
    else
    {
	return (undef);
    }
    
}

sub options_ok
{
    my ($self) = @_;

    if(defined $self->{'options'})
    {
	return ($self->{'options'}->options_ok());
    }
    else
    {
	return (1);
    }
}

sub has_options
{
    my ($self) = @_;
    
    if(defined $self->{'options'})
    {
	return $self->{'options'}->has_options();
    }
    
    return (0);
}

sub add_option
{
    my ($self,$option) = @_;
    
    my $options = $self->{'options'};
    
    if(!defined $options)
    {
	$options = new Business::Logic::Options();
	$self->{'options'} = $options;
    }
    
    if(defined $option)
    {
	if(ref($option) eq 'Business::Logic::Option')
	{
	    $options->add_option($option);
	    return (1);
	}
	elsif(ref($option) eq 'HASH')
	{

	    $option = new Business::Logic::Option($option);
	    $options->add_option($option);
	    return (1);
	}
    }
    return (0); # failure
}

sub assign_options_values
{
    my ($self, $values) = @_;
    
    if(defined $self->{'options'})
    {
	return($self->{'options'}->assign_values($values,$self));
    }
    else
    {
	return 0;
    }
}

sub error_code
{
    my ($self, $code) = @_;
    
    my $error_codes = $self->{'error_codes'};
    
    if(defined $code)
    {
	
    }
    
    return undef;
    
}

# set size value
sub set_size
{
    my ($self, $size) = @_;
    
    $self->{'size'} = $size;
    
    if($self->is_giftcard())
    {
	$self->{'price'} = $size;
    }
    
    return (1); # success

}

sub size_exists
{
    my ($self, $size) = @_;

    my $variations = $self->{'variations'};
    
    if($self->is_giftcard())
    {
	if($size =~ /^\d+$/)
	{
	    if($size > 0)
	    {
		return (1);
	    }
	}
	return 0;
    }
    
    if(defined $variations)
    {
	if(defined $variations->{'size'})
	{
	    foreach my $s (@{$variations->{'size'}->{'variations'}})
	    {
		# hash here?
		if ($s->{'variation'} eq $size)
		{
		    return (1); # ?
		}
	    }
	}
    }
    
    return (0);
}

sub default_size
{
    my ($self) = @_;
    
    # is there a default size ?
    
    if($self->is_giftcard())
    {
	return 100;
    }

    my $variations = $self->{'variations'};
    
    if(defined $variations->{'size'})
    {
	if (scalar @{$variations->{'size'}->{'variations'}} > 0)
	{
	    return $variations->{'size'}->{'variations'}->[0]->{'value'};
	}
    }
    
    return undef;
}

sub has_size
{
    my ($self) = @_;
    my $variations = $self->{'variations'};
    
    if($self->is_giftcard())
    {
	return 1;
    }
    
    if(defined $variations)
    {
	if(defined $variations->{'size'})
	{
	    if (scalar @{$variations->{'size'}->{'variations'}} > 0)
	    {
		return 1;
	    }
	    else
	    {
		return 0; #size but not enough options
	    }
	}
	else
	{
	    return 0;
	}
    }
    else
    {
	return 0;
    }
}

# create an array of a particular variation
# suitable for a select, saved as variation_chooser
# or as $name (optional)
sub create_size_chooser
{
    my ($self,$name) = @_;

    if($self->is_giftcard())
    {
	my $choices = [];
	
	my @sizes = (10,15,20,25,50,75,100,125,150,200,250,300,350,400,450,500);
	foreach my $s (@sizes)
	{
	    my $choice = {};
	    $choice->{'name'} = $s;
	    $choice->{'value'} = $s;
	    
	    push @{$choices},$choice;
	}
	
	$name = (defined $name ? $name : 'size_chooser');
	$self->{$name} = $choices;
    }
    else
    {
	$self->create_variation_chooser('size',$name);
    }
}

sub create_variation_chooser
{
    my ($self,$variation,$name) = @_;
    
    my $choices = [];
    
    # sort here?
    my $variations = $self->get_variations($variation);
    
    # sort?
    foreach my $var (@{$variations})
    {
	my $v = {};
	my $value = $var->{'variation'};
	my $name = $var->{'variation'} . (defined $var->{'variation_note'} ? ' ' . $var->{'variation_note'} : '');
	
	# price var here?
	
	my $selected = '';
	
	if($value eq $self->{'variation'})
	{
	    $selected = ' selected';
	}
	
	$v->{'name'} = $name;
	$v->{'value'} = $value;
	$v->{'selected'} = $selected;
	
	push @{$choices},$v;
    }
    
    $name = (defined $name ? $name : $variation . '_chooser');
    $self->{$name} = $choices;
}

#return an array of variations
#return an array of a particular variation
sub get_variations
{
    my ($self,$variation) = @_;
    
    my $variations = $self->{'variations'};
    
    if(!defined $variations)
    {
	return undef;
    }
    else
    {
	if(!defined $variation)
	{
	    return ($variations);
	}
	else
	{
	    return ($variations->{$variation}->{'variations'});
	}
    }
}

sub get_per_item_shipping
{
    my ($self,$per_item_shipping) = @_;
    
    if(defined $per_item_shipping)
    {
	$self->{'per_item_shipping'} = $per_item_shipping;
	return (1);
    }
    else
    {
	if(!defined $self->{'per_item_shipping'} || $self->{'per_item_shipping'} eq 'per_item_shipping')
	{
	    $self->{'per_item_shipping'} = undef;
	    return undef;
	}
	return $self->{'per_item_shipping'};
    }
}

sub get_first_item_shipping
{
    my ($self,$first_item_shipping) = @_;
    
    if(defined $first_item_shipping)
    {
	$self->{'first_item_shipping'} = $first_item_shipping;
	return (1);
    }
    else
    {
	if(!defined $self->{'first_item_shipping'} || $self->{'first_item_shipping'} eq 'first_item_shipping')
	{
	    $self->{'first_item_shipping'} = undef;
	    return undef;
	}
	
	return ($self->{'first_item_shipping'});
    }
}

sub type
{
    my ($self,$type) = @_;
    
    if(defined $type)
    {
	$self->{'type'} = $type;
	return (1);
    }
    else
    {
	return $self->{'type'};
    }
}

sub subtype
{
    my ($self,$subtype) = @_;
    
    if(defined $subtype)
    {
	$self->{'subtype'} = $subtype;
	return (1);
    }
    else
    {
	return $self->{'subtype'};
    }
}


sub customer
{
    my ($self,$customer) = @_;
    
    if(defined $customer)
    {
	$self->{'customer'} = $customer;
	return (1);
    }
    else
    {
	return $self->{'customer'};
    }
}

sub category
{
    my ($self,$category) = @_;
    
    if(defined $category)
    {
	$self->{'category'} = $category;
	return (1);
    }
    else
    {
	return $self->{'category'};
    }
}


sub get_hash
{
    my ($self) = @_;    
    
    # check
    if(!defined $self->{'data'})
    {
	$self->{'data'} = {};
    }
    
    my $data = $self->{'data'};
    my $new_hash = {};
    
    foreach my $key (keys %{$data})
    {
	$new_hash->{$key} = $data->{$key};
    }
    
    # add current self values to data
    foreach my $key (keys %{$self})
    {
	$new_hash->{$key} = $self->{$key};
    }
    
    return ($new_hash);
}

sub SKU
{
    my ($self,@p) = @_;
    
    if(defined $p[0]) { $self->{SKU} = $p[0]; }
   
    return ($self->{SKU});

}

sub size
{
    my ($self,@p) = @_;
    
    if(defined $p[0]) { $self->{size} = $p[0]; }
   
    return ($self->{size});

}

sub price
{
    my ($self,@p) = @_;
    
    if($self->is_giftcard())
    {
	if(defined $p[0]) { 
	    $self->{size} = $p[0];
	}
	
	$self->{price} = $self->{size}; 
    }
    elsif(defined $p[0]) { 
	$self->{price} = $p[0];
    }
    
    return ($self->{price});
}

sub qty
{
    my ($self,@p) = @_;
    
    if(defined $p[0]) { $self->{qty} = $p[0]; }
   
    return ($self->{qty});
}


sub no_discounts
{
    my ($self,@p) = @_;
    
    if($self->is_giftcard()){return 1;}
    
    if(defined $p[0]) { $self->{no_discounts} = $p[0]; }
    
    return ($self->{no_discounts} eq 'Y' ? 1 : 0);
}

sub in_cart
{

    my ($self,@p) = @_;
    
    if(defined $p[0]) { $self->{in_cart} = $p[0]; }
    
    return ($self->{in_cart} eq 'Y' ? 1 : 0);

}

sub on_sale 
{
    my ($self,@p) = @_;
    
    if(defined $p[0])
    {
	$self->{'on_sale'} = $p[0];
	
	if(defined $p[1])
	{
	    $self->{'sale_expires'} = $p[1];
	}
	
	if(defined $p[2])
	{
	    $self->{'sale_price'} = $p[2];
	}

	if($self->{'sale_expires'} < time)
	{
	    $self->{'sale_expires'} = time + 86400;
	}
    }

    if($self->{'on_sale'} eq 'Y')
    {
	if($self->{'sale_expires'} == 0 || $self->{'sale_expires'} > time)
	{
	    return (1);
	}
    }
    
    return(0);
}

sub sale_price
{
    my ($self,@p) = @_;
    
    if(defined $p[0]) { $self->{sale_price} = $p[0]; }
    
    return ($self->{sale_price});
}

sub sale_expires
{
    my ($self,@p) = @_;
    
    if(defined $p[0]) { $self->{sale_expires} = $p[0]; }
    
    return ($self->{sale_expires});
}

sub max_discount
{
    my ($self,@p) = @_;
    
    if(defined $p[0]){
	if($p[0] eq 'clear')
	{
	    $self->{'discount_truncated'} = 'N';
	}
	elsif($p[0] eq 'override')
	{
	    $self->{'discount_truncated'} = 'Y';	    
	}
	elsif($p[0] eq 'pct')
	{
	    
	    return($self->{'max_discount'});
	}
	else
	{
	    $self->{'max_discount'} = $p[0];
	}
    }
    else
    {
	($self->{'max_discount'} < 100 && $self->{'max_discount'} > 0 ? return(1):return(0));
    }
}

sub in_stock
{
    my ($self,@p) = @_;
    
    if(defined $p[0])
    {
	$self->{'in_stock'} = $p[0];
    }
    
    if(defined $self->{'in_stock'} && $self->{'in_stock'} > 0)
    {
	return 1;
    }
    else
    {
	return 0;
    }
}
sub set_price 
{
    my ($self,@p) = @_;
    
    $self->{'current_price'} = $p[0];
    
    return($self->{'current_price'});
}

sub selling_price
{
    my ($self,@p) = @_;
    
    if(defined $p[0])
    {
	$self->{'current_price'} = $p[0];
    }

    return($self->{'current_price'});
}

sub taxable
{
    my ($self,$taxable) = @_;
    
    if(defined $taxable)
    {
	$self->{'taxable'} = $taxable;
	return 1;
    }
    else
    {
	return $self->{'taxable'};
    }
}

sub current_price
{
    my ($self) = @_;
    
    if(defined $self->{'current_price'} && $self->{'current_price'} > 0)
    {
	return $self->{'current_price'};
    }
    else
    {
	if($self->on_sale)
	{
	    return ($self->sale_price);
	}
	else
	{
	    return ($self->price);
	}
    }
}

sub discounts_applied
{
    my ($self,@p) = @_;
    
    push @{$self->{'discounts_applied'}},@p;
    
    return ($self->{'discounts_applied'});
}

1;
__END__
# Below is stub documentation for your module. You'd better edit it!

=head1 NAME

Business::Logic::Item - Perl extension for blah blah blah

=head1 SYNOPSIS

  use Business::Logic::Item;
  blah blah blah

=head1 DESCRIPTION

Stub documentation for Business::Logic::Item, created by h2xs. It looks like the
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
