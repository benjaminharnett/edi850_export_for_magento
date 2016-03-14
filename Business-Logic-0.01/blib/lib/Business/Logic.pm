package Business::Logic;

use 5.010001;
use strict;
use warnings;

use Carp;


require Exporter;

our @ISA = qw(Exporter);

# Items to export into callers namespace by default. Note: do not export
# names by default without a very good reason. Use EXPORT_OK instead.
# Do not simply export all your public functions/methods/constants.

# This allows declaration	use Business::Logic ':all';
# If you do not need this, moving things directly into @EXPORT or @EXPORT_OK
# will save memory.
#our %EXPORT_TAGS = ( 'all' => [ qw( ) ] );

our @EXPORT_OK = qw (

);

our @EXPORT = qw(
	
);

our $VERSION = '0.01';


# Preloaded methods go here.

sub new {

    my($class) = @_;
    my $self = {};
    bless($self, $class);
    return $self;

}

sub create_items {
    my ($self, $array_of_item_hashes, $map, $return_hash) = @_;
    
    $return_hash = defined $return_hash ? $return_hash : 0;
    
    my @items = map {Business::Logic::Item->new($_,$map)} @$array_of_item_hashes;
    
    if(!$return_hash)
    {
	return \@items;
    }
    else
    {
	my $hash = {};
	my $counter = 0;
	map {$hash->{(defined $_->{$return_hash} ? $_->{$return_hash} : ++$counter)} = $_} @items;
	return $hash;
    }
}

sub item_from_sizes {
    
    my ($self, $item_hash, $map, $sizes) = @_;
    
    my @items;
    
    my (@sizes) = split(/\s*\,\s*/,$sizes);
    
    my %factor;
    my %units;
    
    my $total = 0;
    foreach my $size (@sizes)
    {
	my ($s,$q) = split(/\-/,$size,2);
	$factor{$s} = $q;
	$total += $q;
    }
    
    if($total == 0){$total = 1;}
    
    my $item = Business::Logic::Item->new($item_hash,$map);
    
    foreach my $s (keys %factor)
    {
	$factor{$s} = $factor{$s} / $total;
	$units{$s} = int(($item->{'qty'} * $factor{$s}) + .5);

	my $item = Business::Logic::Item->new($item_hash,$map);
	$item->{'qty'} = $units{$s};
	$item->{'size'} = $s;
	push @items,$item;
    }
    
    return \@items;
}

sub items_from_sizes {
    
    my ($self, $item_array, $map, $sizes) = @_;
    
    my @items;
    
    foreach my $item (@{$item_array})
    {
	push @items,@{$self->item_from_sizes($item,$map,$sizes)};
    }
    
    return \@items;
}


sub create_item {
    my ($self, $item_hash, $map) = @_;
    
    return Business::Logic::Item->new($item_hash,$map);
}

sub create_discounts {
    my ($self, $array_of_discount_hashes, $map) = @_;
    
    my @items = map {Business::Logic::Discount->new($_,$map)} @$array_of_discount_hashes;
    return \@items;
}

sub create_shipments {
    my ($self, $array_of_shipment_hashes, $map) = @_;
    
    my @items = map {Business::Logic::Shipment->new($_,$map)} @$array_of_shipment_hashes;
    return \@items;
}

sub create_purchase_orders {
    my ($self, $array_of_po_hashes, $map) = @_;
    
    my @items = map {Business::Logic::PurchaseOrder->new($_,$map)} @$array_of_po_hashes;
    return \@items;
}

sub pos_from_array {
    my ($self, $array, $map) = @_;
    
    my %purchase_orders;
    
    foreach my $result (@{$array})
    {
	if(ref($result) eq 'ARRAY')
	{
	    my %hash;
	    
	    for(my $i = 0;$i <= $#$result;$i++)
	    {
		$hash{$map->[$i]} = $result->[$i];
	    
	    }

	    $result = \%hash;
	}
	
	
	my ($Shipment) = $result->{'shipment_number'};
	my ($PO_Number) = $result->{'po_number'};
	next if !defined $PO_Number;

	my ($ETD) = $result->{'ex_factory'};
	my ($ETAW) = $result->{'at_warehouse'};
	my ($ATS) = $result->{'available_to_ship'};
	my ($Real_Style) = $result->{'style'};
	my ($Qty_Ordered) = (defined $result->{'ordered'} ? $result->{'ordered'} : 0);
	my ($Qty_Shipped) = (defined $result->{'shipped'} ? $result->{'shipped'} : 0);
	my ($PO_Status) = $result->{'po_status'};
	my ($Size_Breakdown)= (defined $result->{'sizes'} ? $result->{'sizes'} : '');
	my ($Status) = $result->{'shipment_status'};
	my ($Position) = $result->{'item_no'};
    
	if(!defined $purchase_orders{$PO_Number})
	{
	    my $ordered = {};
	    my $shipments = {};
	    my $estimated_date = $ATS;
	    
	    my $po = {};
	    $po->{'ordered'} = $ordered;
	    $po->{'estimated_date'} = $estimated_date;
	    $po->{'shipments'} = $shipments;
	    $purchase_orders{$PO_Number} = $po;
	}
    
	my $po = $purchase_orders{$PO_Number};
	
	my $ordered = $po->{'ordered'};
	
	my $shipments = $po->{'shipments'};
    
	if(!defined $ordered->{$Position})
	{
	    $ordered->{$Position}->{'ordered'} = $Qty_Ordered;
	    $ordered->{$Position}->{'style'} = $Real_Style;
	    $ordered->{$Position}->{'date'} = $ATS;
	    $ordered->{$Position}->{'position'} = $Position;
	    $ordered->{$Position}->{'sizes'} = $Size_Breakdown;
	    
	}
	elsif(!defined $ordered->{$Position}->{'ordered'} || ($Qty_Ordered > 0 && $ordered->{$Position}->{'ordered'} < $Qty_Ordered))
	{
	    $ordered->{$Position}->{'ordered'} = $Qty_Ordered;
	}
	
	if($Qty_Shipped > 0)
	{
	    
	    my $ShipNum = $ATS . '_' . $Shipment;
	    
	    if(defined $shipments->{$ShipNum})
	    {
		my $shipment = $shipments->{$ShipNum};
		
		my $item = {};
		$item->{'sizes'} = $Size_Breakdown;
		$item->{'qty'} = $Qty_Shipped;
		$item->{'ats'} = $ATS;
		
		$shipment->{'items'}->{$Position} = $item;
	    }
	    else
	    {
		my $shipment = {};
		
		$shipment->{'at_port'} = (defined $ETAW ? $ETAW : $ATS - 86400*1);
		$shipment->{'ex_factory'} = (defined $ETD ? $ETD : $shipment->{'at_port'} - 86400*7);
		$shipment->{'ats'} = $ATS;
		
		my $ST = '';
		
		if($Status eq 'Received'){ $ST = 'R'; }
		elsif($Status eq 'Pending'){ $ST = 'P'; }
		elsif($Status eq 'Shipped'){ $ST = 'S'; }
		else{$ST = $Status;}
		
		$shipment->{'status'} = $ST;
		
		my $item = {};
		$item->{'sizes'} = $Size_Breakdown;
		$item->{'qty'} = $Qty_Shipped;
		$item->{'ats'} = $ATS;
		$item->{'style'} = $Real_Style;
		
		$shipment->{'items'}->{$Position} = $item;
		
		$shipments->{$ShipNum} = $shipment;
	    }
	}
	
    }
    
    my @pos;
    
    foreach my $PO (keys %purchase_orders)
    {
	
	my %items;
	
	my $od = $purchase_orders{$PO}->{'ordered'};
	my $ships = $purchase_orders{$PO}->{'shipments'};
	
	foreach my $position (keys %{$od})
	{
	    my $item_no = $position;
	    
	    my $qty = $od->{$position}->{'ordered'};
	    my $style = $od->{$position}->{'style'};
	    my $date = $od->{$position}->{'date'};
	    
	    my $sizes = $od->{$position}->{'sizes'};
	    
	    if($sizes ne '')
	    {
		my $items = $self->item_from_sizes({'style'=>$style,'qty'=>$qty,'item_no'=>$item_no,'availability_date'=>$date},{'SKU'=>'style','qty'=>'qty','item_no'=>'item_no','availability_date'=>'availability_date'},$sizes);
		
		foreach my $item (@{$items})
		{
		    $items{$position . '_' . $item->{'size'}} = $item;
		}
	    }
	    else
	    {
		my $item = $self->create_item({'style'=>$style,'qty'=>$qty,'item_no'=>$item_no,'availability_date'=>$date},{'SKU'=>'style','qty'=>'qty','item_no'=>'item_no','availability_date'=>'availability_date'});
		$items{$position} = $item;
	    }
	}
	
	my $shipments = [];
	
	foreach my $ShipNum (keys %{$ships})
	{
	    my $shipment = $ships->{$ShipNum};
	    
	    my $STATUS = $shipment->{'status'};
	    
	    my $ETAW = $shipment->{'at_port'};
	    my $ETD = $shipment->{'ex_factory'};
	    my $ATS = $shipment->{'ats'};
	    
	    my $items = {};
	    
	    foreach my $position (keys %{$shipment->{'items'}})
	    {
		
		my $item = $shipment->{'items'}->{$position};
		
		my $item_no = $position;
		
		my $style = $item->{'style'};
		my $sizes = $item->{'sizes'};
		my $qty = $item->{'qty'};
		my $date = $item->{'ats'};
		
		if($sizes ne '')
		{
		    my $bitems = $self->item_from_sizes({'style'=>$style,'qty'=>$qty,'item_no'=>$item_no,'availability_date'=>$date},{'SKU'=>'style','qty'=>'qty','item_no'=>'item_no','availability_date'=>'availability_date'},$sizes);
		    
		    foreach my $item (@{$bitems})
		    {
			$items->{$position . '_' . $item->{'size'}} = $item;
		    }
		}
		else
		{
		    my $item = $self->create_item({'style'=>$style,'qty'=>$qty,'item_no'=>$item_no,'availability_date'=>$date},{'SKU'=>'style','qty'=>'qty','item_no'=>'item_no','availability_date'=>'availability_date'});
		    $items->{$position} = $item;
		}
		
	    }
	    
	    my $nshipment = $self->create_shipments (
		[{
		    ex_factory=>$ETD,
		    at_port=>$ETAW,
		    available_to_ship=>$ATS,
		    status=>$STATUS,
		    items=> $items,	
		 }
		]
		);
	    push @{$shipments},@{$nshipment};
	    
	}
	
	my $purchase_order = 
	{
	    number=>$PO,
	    completion_date=>$purchase_orders{$PO}->{'estimated_date'},
	    ordered=> \%items,
	    shipments=> $shipments,
	};
	
	push @pos,@{$self->create_purchase_orders([$purchase_order])};
    }
    
    return \@pos;
}

sub create_discount {
    my ($self, $discount_hash, $map) = @_;    
    return Business::Logic::Discount->new($discount_hash,$map);
}

sub get_cart {
    my ($self, $cart_hash, $map) = @_;
    return Business::Logic::Cart->new($cart_hash,$map);
}

sub get_received_qty {

    my ($self, $search, $purchase_orders) = @_;

    my ($from) = (defined $search->{'from'} ? $search->{'from'} : 0);
    my ($to) = (defined $search->{'to'} ? $search->{'to'} : 0);
    my ($SKU) = (defined $search->{'SKU'} ? $search->{'SKU'} : '');
    my ($size) = (defined $search->{'size'} ? $search->{'size'} : '');
    
    my ($qty_on_order) = (defined $search->{'on_order'} ? $search->{'on_order'} : 0);
    
    $search->{'return'} = 'array';
    
    my @qtys;
    
    foreach my $po (@{$purchase_orders})
    {
	push @qtys,@{$po->qty_received($search)};
    }
    
    my $total_received_qty = 0;

    foreach my $qty (sort {$a->{'date'} <=> $b->{'date'}} @qtys)
    {
	if($qty->{'date'} >= $from)
	{
	    if($to == 0 || $qty->{'date'} < $to)
	    {
		$qty_on_order -= $qty->{'qty'};
		
		if($qty_on_order < 0)
		{
		    $qty_on_order = 0;
		}
		
		$total_received_qty += $qty->{'qty'};
	    }
	}
    }
    
    return ( $total_received_qty, $qty_on_order );
}

sub get_pending_qty {

    my ($self, $search, $purchase_orders) = @_;

    my ($from) = (defined $search->{'from'} ? $search->{'from'} : 0);
    my ($to) = (defined $search->{'to'} ? $search->{'to'} : 0);
    my ($SKU) = (defined $search->{'SKU'} ? $search->{'SKU'} : '');
    my ($size) = (defined $search->{'size'} ? $search->{'size'} : '');
    
    my ($qty_on_order) = (defined $search->{'on_order'} ? $search->{'on_order'} : 0);
    
    $search->{'return'} = 'array';
    
    my @qtys;
    
    foreach my $po (@{$purchase_orders})
    {
	push @qtys,@{$po->qty_pending($search)};
    }
    
    my $total_pending_qty = 0;
    my $operative_date = 0;
    
    foreach my $qty (sort {$a->{'date'} <=> $b->{'date'}} @qtys)
    {
	if($qty->{'date'} >= $from)
	{
	
	    if($to == 0 || $qty->{'date'} < $to)
	    {
		$qty_on_order -= $qty->{'qty'};
		
		if($qty_on_order < 0 && $operative_date == 0)
		{
		    $operative_date = $qty->{'date'};
		}
		
		$total_pending_qty += $qty->{'qty'};
	    }
	}
    }
    
    return ( $total_pending_qty, $operative_date );
}

sub sort_items {
    my ($self, $items, $sort_mode) = @_;
    
    my $sorted_items = [];
    my $excess_items = [];
    
    my $instock_only = (defined $sort_mode->{'in-stock'} ? $sort_mode->{'in-stock'} : 1);
    my $items_per_style = (defined $sort_mode->{'items-per-style'} ? $sort_mode->{'items-per-style'} : 2);
    my $secondary_sort = (defined $sort_mode->{'secondary-sort'} ? $sort_mode->{'secondary-sort'} : 'popularity');
    my $primary_sort = (defined $sort_mode->{'sort'} ? $sort_mode->{'sort'} : 'age');
    my $sort_direction = (defined $sort_mode->{'direction'} ? $sort_mode->{'direction'} : 'up');
    
    if($primary_sort eq 'age' || $primary_sort eq 'featured'){
	if($sort_direction eq 'up'){$sort_direction = 'down';}
	else {$sort_direction = 'up';}
    }
    
    my $secondary_direction = (defined $sort_mode->{'secondary-direction'} ? $sort_mode->{'secondary-direction'} : 'up');
    
    my $show_all = (defined $sort_mode->{'show-all'} ? $sort_mode->{'show-all'} : 1);
    
    my $do_not_repeat_colors = (defined $sort_mode->{'avoid-color-repeat'} ? $sort_mode->{'avoid-color-repeat'} : 1);
    
    my $sort = {};
    my $sort2 = {};
    
    my $color_seen = {};
    
    my $max_sort2 = 0;
    
    my $nitems = {};
    my $items_count = {};

    
    my $max_sort;

    foreach my $item ( @{$items})
    {
	if(!$instock_only || $item->{'in_stock'} >= $instock_only || ($item->{'made_to_order'} && $instock_only == 1))
	{
	    if(!defined $item->{'parentSKU'}){$item->{'parentSKU'} = $item->SKU;}
	    push @{$nitems->{$item->{'parentSKU'}}},$item;
	    
	    if($primary_sort eq 'featured')
	    {
		$sort->{$item->SKU} = $item->{'age'};
	    }
	    elsif($primary_sort eq 'price')
	    {
		$sort->{$item->SKU} = $item->current_price;	    
	    }
	    elsif($primary_sort eq 'size')
	    {
		$sort->{$item->SKU} = $item->{'size'};	    	    
	    }
	    elsif($primary_sort eq 'color')
	    {
		my $color = $item->{'color'};
		if($color =~ /rgb\((\d?)\,(\d?)\,(\d?)\)/i)
		{
		    my $R = $1;
		    my $G = $2;
		    my $B = $3;
		    
		    if($R == $B && $B == $G)
		    {
			$color = 0;
		    }
		    elsif ($B > $G && $G > $R)
		    {
			$color = 60*(4-($G-$R)/($B-$R));
		    }
		    elsif($G > $R && $R > $B)
		    {
			$color = 60*(2-($R-$B)/($G-$B));
		    }
		    elsif($R > $B && $B > $G)
		    {
			$color = 60*(0-($B-$G)/($R-$G));
		    }
		}
		$sort->{$item->SKU} = $color;
	    }
	    elsif($primary_sort eq 'age')
	    {
		$sort->{$item->SKU} = $item->{'age'};	    	    
	    }
	    elsif($primary_sort eq 'availability')
	    {
		$sort->{$item->SKU} = $item->{'in_stock'};	     	    
	    }
	    elsif($primary_sort eq 'random')
	    {
		$sort->{$item->SKU} = int(rand(1000));
	    }
	    elsif($primary_sort eq 'popularity')
	    {
		$sort->{$item->SKU} = $item->{'popularity'};	     	    
	    }
	    else
	    {
		$sort->{$item->SKU} = 0;
	    }
	    
	    my $amt = 0;
	    
	    if($secondary_sort eq 'popularity')
	    {
		$amt = $item->{'popularity'};
	    }
	    elsif($secondary_sort eq 'age')
	    {
		$amt = $item->{'age'};
	    }
	    elsif($secondary_sort eq 'price')
	    {
		$amt = $item->current_price;
	    }
	    elsif($secondary_sort eq 'size')
	    {
		$amt = $item->{'size'};
	    }
	    else
	    {
		$amt = 0;
	    }
	    
	    if(!defined $max_sort2 || $amt > $max_sort2)
	    {
		$max_sort2 = $amt;
	    }
	    
	    $sort2->{$item->SKU} = $amt;
	}
	else
	{
	    $sort2->{$item->SKU} = -1;
	    $sort->{$item->SKU} = -1;
	    
	}
    }
    
    if($max_sort2 < 1){$max_sort2 = 1;}

    foreach my $SKU (keys %{$sort2})
    {
	my $amt = $sort2->{$SKU};
	
	if($amt > 0)
	{
	
	    if($secondary_direction eq 'down')
	    {
		$amt = 1 - ($amt / $max_sort2);
	    }
	    else
	    {
		$amt = $amt / $max_sort2;
	    }
	}

	$sort2->{$SKU} = $amt;
    }

    foreach my $parentSKU (keys %{$nitems})
    {
	my $item_count = (scalar @{$nitems->{$parentSKU}});
	
	my $more_colors = 0;
	if($item_count > 1){$more_colors = 1;}

	$items_count->{$parentSKU} = $item_count;
	
	foreach my $item (@{$nitems->{$parentSKU}})
	{
	    $item->{'data'}->{'has_more_colors'} = $more_colors;
	    $item->{'more_colors'} = $more_colors;
	}
	
    }

    my $seen = {};
    my $used = {};
    
    foreach my $item (sort { if($sort_direction eq 'up'){ return ($sort->{$a->SKU} + $sort2->{$a->SKU} <=> $sort->{$b->SKU} + $sort2->{$b->SKU}); } else { return ($sort->{$b->SKU} + $sort2->{$b->SKU} <=> $sort->{$a->SKU} + $sort2->{$a->SKU}); }} @{$items})
    {

	if(defined $sort->{$item->SKU} && $sort->{$item->SKU} > -1 && !$used->{$item->SKU})
	{
	    if(($items_per_style == 0 || !defined $seen->{$item->{'parentSKU'}} || $seen->{$item->{'parentSKU'}} < $items_per_style) )
	    {
		
		if($items_per_style == 0 || $items_count->{$item->{'parentSKU'}} <= $items_per_style || !defined $color_seen->{$item->{'color'}})
		{
		    $used->{$item->SKU} = 1;
		    push @{$sorted_items},$item;
		    $seen->{$item->{'parentSKU'}} = (defined $seen->{$item->{'parentSKU'}} ? $seen->{$item->{'parentSKU'}}+1 : 1);
		    $color_seen->{$item->{'color'}} = (defined $color_seen->{$item->{'color'}} ? $color_seen->{$item->{'color'}}+1 : 1);
		}
		
		my $ok = 1;

		my @items;
		
		if($items_per_style > 0)
		{
		    @items = sort { if($sort_direction eq 'up'){ return ($sort2->{$a->SKU} + $sort2->{$a->SKU} <=> $sort2->{$b->SKU} + $sort2->{$b->SKU}); } else { return ($sort2->{$b->SKU} + $sort2->{$b->SKU} <=> $sort2->{$a->SKU} + $sort2->{$a->SKU}); }} @{ $nitems->{$item->{'parentSKU'}} };
		}
		
		my @tossed_for_color;

		while ( (defined $seen->{$item->{'parentSKU'}} ? $seen->{$item->{'parentSKU'}} : 0) < $items_per_style && $ok)
		{
		    
		    my $it = pop @items;
		    
		    if($do_not_repeat_colors && defined $it)
		    {
			while(defined $it && ($color_seen->{$it->{'color'}} || $used->{$it->SKU}))
			{
			    push @tossed_for_color,$it;
			    $it = pop @items;
			}
		    }
		    
		    if(!defined $it && $do_not_repeat_colors)
		    {
			$it = pop @tossed_for_color;
		    }
		    
		    while(defined $it && ($used->{$it->SKU} || ($do_not_repeat_colors && $color_seen->{$it->{'color'}})))
		    {
			push @tossed_for_color,$it;
			$it = pop @items;
			
			if($do_not_repeat_colors && defined $it)
			{
			    while(defined $it && ($color_seen->{$it->{'color'}} || $used->{$it->SKU}))
			    {
				push @tossed_for_color,$it;
				$it = pop @items;
			    }
			}
		    }
		    
		    if(!defined $it && $do_not_repeat_colors)
		    {
			$it = pop @tossed_for_color;
			while(defined $it && $used->{$it->SKU})
			{
			    $it = pop @tossed_for_color;
			}
		    }
		    		    
		    if(defined $it && !$used->{$it->SKU})
		    {
			$used->{$it->SKU} = 1;
			push @{$sorted_items},$it;
			$seen->{$item->{'parentSKU'}} = (defined $seen->{$item->{'parentSKU'}} ? $seen->{$item->{'parentSKU'}}+1 : 1);
			$color_seen->{$it->{'color'}} = (defined $color_seen->{$it->{'color'}} ? $color_seen->{$it->{'color'}}+1 : 1);
			
	
		    }
		    else
		    {
			
			$ok = 0;
		    }
		}
		
		while (my $tossed = pop @tossed_for_color)
		{
		    if (! $used->{$tossed->SKU})
		    {
			$used->{$tossed->SKU} = 1;
			push @{$excess_items},$tossed;
		    }
		}

	    }
	    elsif($show_all)
	    {
		push @{$excess_items},$item;
	    }
	}
    }
	    
    push @{$sorted_items},@{$excess_items};
    return ($sorted_items);
}


sub match {
    
    my ($self,$discount,$item) = @_;
    
    if($discount->SKU eq 'ALL')
    {
	return (1);
    }

    if($discount->SKU eq 'ALL-ITEMS')
    {
	return (1);
    }
    
    if($discount->SKU eq $item->SKU)
    {
	return (1);
    }
    
    if(grep(/\*$/,$discount->SKU))
    {
	if($item->SKU =~ $discount->SKU)
	{
	    return (1);
	}
    }
    
    if($discount->SKU =~ /^NAME=(.*?)$/)
    {
	if($1)
	{
	    if(defined $item->{'name'} && grep(/$1/i,$item->{'name'}))
	    {
		return (1);
	    }
	    elsif(defined $item->{'data'}->{'name'} && grep(/$1/i,$item->{'data'}->{'name'}))
	    {
		return (1);
	    }
	}
    }

    return (0);
}

sub get_discounted_item_price {

    my ($self) = shift @_; 
    my ($t) = shift @_;
    
    if($t ne 'F' && $t ne '')
    {
	unshift @_,$t;
	$t = '';
    }

    my ($item, $discounts, $cart) = @_;
    
    my ($full_price) = 0;
    my ($current_price) = 0;
    
    $full_price = $item->price;
    $current_price = $full_price;
    
    my @discounts_applied;

    if($item->on_sale)
    {
	$current_price = $item->sale_price;
    }
    
    my $combines_discount = 0;
    my $fullprice_discount = 0;
    my $override = 0;

    if(!$item->no_discounts)
    {
	foreach my $discount (sort {$b->combines <=> $a->combines} @$discounts) # applied discounts
	{
	    if(!$discount->ignore)
	    {
		$discount->ignore('Y');
		
		if((!$discount->expires || $discount->expires > time) && $self->match($discount,$item))
		{
		    if(($discount->instock_only && $item->in_stock) || !$discount->instock_only)
		    {
			if(($discount->cart_only && $item->in_cart) || !$discount->cart_only)
			{
			
			# discount requires a minimum amount in the cart (inclusive of item)
			if($discount->floor == 0 || ($discount->floor > 0 && $cart->total('F') >= $discount->floor))
			{
			    # discount requires another item in the cart
			    
			    if(!$discount->needs || ($discount->needs && defined $cart && $discount->slurp($cart->has($discount->needs('SKU'))))) # slurp uses up an item
			    {
				# does discount apply to sale items only
				
				if(!$discount->onsale_only || ($discount->onsale_only && $item->on_sale))
				{
				    # does discount apply to full price only?
				    if(!$discount->fullprice_only || ($discount->fullprice_only && !$item->on_sale))
				    {
					if(!$discount->bogo || (!$discount->bneeded($item) && defined $cart && $discount->bslurp($cart->has($discount->bogo_needs($item)))))
					{
					    my $discount_done = 0;
					    if($discount->apply($t))
					    {
						
						if($discount->combines)
						{
						    if($discount->fullprice)
						    {
							if($fullprice_discount == 0)
							{
							    $fullprice_discount = $discount->pct;
							    $discount_done = 1;
							}
							else
							{
							    $fullprice_discount = $discount->pct + $fullprice_discount * ((100-$discount->pct)/100);
							    $discount_done = 1;
							}
						    }
						    else
						    {
							
							if($combines_discount == 0)
							{
							    $combines_discount = $discount->pct;
							    $discount_done = 1;
							}
							else
							{
							    $combines_discount = $discount->pct + $combines_discount * ((100-$discount->pct)/100);
							    $discount_done = 1;
							}
							
						    }
						    
						}
						else
						{
						    if($discount->fullprice && !$override)
						    {
							
							if($fullprice_discount <= $discount->pct || $discount->override)
							{
							    $override = $discount->override;
							    
							    $fullprice_discount = $discount->pct;
							    $discount_done = 1;
							}
						    }
						    elsif(!$override)
						    {
							
							if($combines_discount <= $discount->pct || $discount->override)
							{
							    
							    $override = $discount->override;
							    $combines_discount = $discount->pct;
							    $discount_done = 1;
							}
						    }
						}
						
					    }
					    
					    if($discount_done)
					    {
						if($discount->bogo)
						{
						    $discount->bslurp($item);
						}

						push @discounts_applied,$discount; #use this later
					    }
					}
				    }
				}
				
			    }
			    
			}
			
			}
		    }
		    
		}
		
		$discount->ignore('N');
		
	    }
	}
    }
    
    my $test_price = $full_price;

    if($combines_discount != 0)
    {
	
	$current_price = int($current_price * (100-$combines_discount))/100;
    }

    if($fullprice_discount != 0)
    {
	$test_price = int($full_price * (100-$fullprice_discount))/100;
    }

    if($test_price > 0 && $test_price < $current_price)
    {
	$current_price = $test_price;
    }
    
    if($item->max_discount)
    {
	$item->max_discount('clear');

	my $effective_pct = int(100-($current_price/$full_price)*100);
	my $max_pct = $item->max_discount('pct');
	if($effective_pct > $max_pct)
	{
	    $current_price = int($full_price * (100-$max_pct))/100;
	    $item->max_discount('override');
	}
	
    }

    $item->discounts_applied(@discounts_applied);
    $item->set_price($current_price);
    
    return ($current_price,$full_price);
}


1;
__END__
# Below is stub documentation for your module. You'd better edit it!

=head1 NAME

Business::Logic - Perl extension for blah blah blah

=head1 SYNOPSIS

  use Business::Logic;
  blah blah blah

=head1 DESCRIPTION

Stub documentation for Business::Logic, created by h2xs. It looks like the
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
