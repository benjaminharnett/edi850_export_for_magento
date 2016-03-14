package Business::Logic::PurchaseOrder;

use 5.010001;
use strict;
use warnings;

use Carp;

require Exporter;

our @ISA = qw(Exporter);

# Items to export into callers namespace by default. Note: do not export
# names by default without a very good reason. Use EXPORT_OK instead.
# Do not simply export all your public functions/methods/constants.

# This allows declaration	use Business::Logic::PurchaseOrder ':all';
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
	po_number=>1,
	date_created=>time,
	completion_date=>time,
	vendor=>"unspecified",
	vendor_number=>1,
	shipping_method=>"unspecified",
	payment_terms=>"unspecified",
	memo=>"",
	shipment_invoices=>[],
	factory_invoices=>[],
	ordered=>{},
	shipments=>[],
    };

    my $self = {};
    foreach my $parameter (keys %$parameters)
    {
	$self->{$parameter} = q_map($params,q_map($map,$parameter),$parameters->{$parameter});
    }
    
    $self->{"data"} = $params;

    bless($self, $class);
    return $self;
}

sub get_hash
{
    my ($self) = @_;    
    return ($self->{"data"});
}

    

sub qty_ordered
{

}

sub has_shipment
{
    my ($self,$shipment) = @_;
    
    # add checking here
    
    return (0);
}

sub add_shipment
{
    my ($self,$shipment) = @_;
    
    my $shipments = $self->{"shipments"};
    
    if(ref ($shipment) eq 'ARRAY')
    {
	foreach my $shipment (@{$shipment})
	{
	    if(!$self->has_shipment($shipment))
	    {
		push @{$shipments},$shipment;
	    }
	}
    }
    else
    {
	if(!$self->has_shipment($shipment))
	{
	    push @{$shipments},$shipment;
	}
    }
}

sub qty_received
{
    my ($self,$search) = @_;
    
    my ($from) = (defined $search->{"from"} ? $search->{"from"} : 0);
    my ($to) = (defined $search->{"to"} ? $search->{"to"} : 0);

    my ($SKU) = (defined $search->{"SKU"} ? $search->{"SKU"} : "");
    my ($size) = (defined $search->{"size"} ? $search->{"size"} : "");

    my ($return_type) = (defined $search->{"return"} ? $search->{"return"} : "qty");
    
    my $shipments = $self->{"shipments"};
    
    # qty, qty_date
    
    my $received_qty = 0;
    my $total_pending = 0;
    my $total_ordered = 0;
    my $total_received = 0;
    
    my @qtydate;
    
    foreach my $item_position (keys %{$self->{"ordered"}})
    {
	my $item = $self->{"ordered"}->{$item_position};
	
	my ($position,$item_size) = split(/\_/,$item_position,2);
	
	if(($item->SKU eq $SKU || $SKU eq "")&& ($size eq "" || $item_size eq $size || $item->size eq $size))
	{
	    $total_ordered += $item->{"qty"};

	    foreach my $shipment (@{$shipments})
	    {
		my $qty = $shipment->qty($item_position);
		    
		if($shipment->received)
		{

		    $total_received += $qty;
		    if($shipment->date >= $from || $shipment->pending)
		    {
			if($to == 0 || $shipment->date < $to)
			{
			    $received_qty += $qty;
			    push @qtydate,{"qty"=>$qty,"date"=>$shipment->date,"SKU"=>$item->SKU};
			}
		    }
		    
		}
		else
		{
		    $total_pending += $qty;
		}
	    }
	}
    }
    
    if($return_type eq "qty")
    {
	return ($received_qty);
    }
    else
    {
	return (\@qtydate);
    }
}

sub qty_pending
{
    my ($self,$search) = @_;
    
    my ($from) = (defined $search->{"from"} ? $search->{"from"} : 0);
    my ($to) = (defined $search->{"to"} ? $search->{"to"} : 0);

    my ($SKU) = (defined $search->{"SKU"} ? $search->{"SKU"} : "");
    my ($size) = (defined $search->{"size"} ? $search->{"size"} : "");
    
    my ($return_type) = (defined $search->{"return"} ? $search->{"return"} : "qty");
    
    my ($debug) = (defined $search->{"debug"} ? $search->{"debug"} : 0);
    
    
    my $shipments = $self->{"shipments"};
    
    # qty, qty_date
    
    my $pending_qty = 0;
    my $total_pending = 0;
    my $total_ordered = 0;
    my $total_received = 0;
    
    my @qtydate;
    
    foreach my $item_position (keys %{$self->{"ordered"}})
    {
	my $item = $self->{"ordered"}->{$item_position};
	
	my ($position,$item_size) = split(/\_/,$item_position,2);
	
	if(($item->SKU eq $SKU || $SKU eq "") && ($size eq "" || $item_size eq $size || $item->size eq $size))
	{
	    
	    
	    $total_ordered += $item->{"qty"};

	    foreach my $shipment (@{$shipments})
	    {
		my $qty = (defined $shipment->qty($item_position) ? $shipment->qty($item_position) : 0);

		    
		if(!$shipment->received)
		{

		    $total_pending += $qty;
		    if($shipment->date >= $from || $shipment->pending)
		    {
			if($to == 0 || $shipment->date < $to)
			{

			    $pending_qty += $qty;
			    push @qtydate,{"qty"=>$qty,"date"=>$shipment->date,"SKU"=>$item->SKU};
			}
		    }
		    
		}
		else
		{
		    $total_received += $qty;
		}
	    }
	}
    }
    
    my $estimated_total_pending = $total_ordered - $total_received;
    
    if($estimated_total_pending > $pending_qty)
    {
	if($to == 0 || $self->estimated_date < $to)
	{
	    
	    
	    push @qtydate,{"qty"=>($estimated_total_pending - $pending_qty),"date"=>$self->estimated_date($SKU),"SKU"=>$SKU};

	    $pending_qty = $estimated_total_pending;

	}
    }
    
    if($return_type eq "qty")
    {
	return ($pending_qty);
    }
    else
    {
	return (\@qtydate);
    }
}

sub estimated_date
{
    my ($self,$SKU) = @_;
    
    if(!defined $SKU)
    {
	return ($self->{"completion_date"});
    }
    else
    {
	my $date = $self->{"completion_date"};
	
	foreach my $item_position (keys %{$self->{"ordered"}})
	{
	    my $item = $self->{"ordered"}->{$item_position};
	    
	    if($item->{"SKU"} eq $SKU)
	    {
		if(defined $item->{'availability_date'} && $item->{'availability_date'} ne 'availability_date')
		{
		    $date = $item->{'availability_date'};
		}
	    }
	    
	}
	
	return ($date);
    }
}

sub unit_landed_cost
{

}

sub unit_factory_cost
{

}

sub unit_total_cost
{

}

sub po_factory_cost
{

}

sub po_total_cost
{

}

sub next_delivery
{

}



1;
__END__
# Below is stub documentation for your module. You'd better edit it!

=head1 NAME

Business::Logic::PurchaseOrder - Perl extension for blah blah blah

=head1 SYNOPSIS

  use Business::Logic::PurchaseOrder;
  blah blah blah

=head1 DESCRIPTION

Stub documentation for Business::Logic::PurchaseOrder, created by h2xs. It looks like the
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
