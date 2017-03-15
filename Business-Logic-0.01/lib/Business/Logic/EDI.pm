package Business::Logic::EDI;

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
	terminator=>'*',
	separator=>'~',
	delimiter=>'>',
	sender=>'',
	recipient=>'',
	send_type=>'12',
	recipient_type=>'12',
	edi_version=>'00401',
	gs_version=>'004010VICS',
	items=>[],
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

sub format_column
{
    my ($self,$value,$format) = @_;
    
    if(!defined $value){$value = '';}

    my $size = $format->{'size'};
    my $pad = $format->{'pad'};
    my $left_pad = $format->{'padleft'};
    
    if($size)
    {
	if(defined $left_pad)
	{
	    $value = sprintf('%*s',$size,$value);

	    if($left_pad eq '0')
	    {
		while($value =~ s/\s/0/) {}
	    }
	}
	else
	{
	    if(!defined $pad){$pad = ' '}
	    $value = sprintf('%-*s',$size,$value);

	    if($pad eq '0')
	    {
		while($value =~ s/\s/0/) {}
	    }
	}
    }

    return $value;
}

sub row
{
    my ($self, $values, $columns) = @_;
    
    my $row;
    for (my $i = 0;$i <= $#$values;$i++)
    {
	my $value = $values->[$i];

	if(defined $columns && $columns->[$i])
	{
	    my $format = $columns->[$i];
	    $value = $self->format_column($value,$format);
	}
	
	$row .= $value . $self->{'separator'};
    }
    chop $row;
    
    $row .= $self->{'terminator'} . "\n";
    
    return $row;
}

sub add_item
{
    my ($self,$item) = @_;
    
    my $items = $self->{'items'};
    
    if(!defined $items)
    {
	$items = [];
    }
    
    my $found = 0;
    foreach my $test_item (@$items)
    {
	if($test_item->{'id'} eq $item->{'id'})
	{
	    $found = 1;
	    last;
	}
    }

    if(!$found)
    {
	push @$items,$item;
	$self->{'items'} = $items;
    }
    
    return !$found;
}

sub edi_850
{
    my ($self,$id) = @_;
    
    return $self->generate($id,850);
}

sub edi_855
{
    my ($self,$id) = @_;
    
    return $self->generate($id,855);
}

sub generate
{
    my ($self, $id, $type) = @_;
    
    my $result;
    
    my $date = time;
    
    $result .= $self->isa($id,$date);

    if($#{$self->{'items'}} > -1)
    {
	$result .= $self->gs($date);
	
	foreach my $item (@{$self->{'items'}})
	{
	    $result .= $self->st($type,$item);
	}
	
	$result .= $self->ge();
    }
    
    $result .= $self->iea($id);
    
    return $result;
}

sub shipping_address
{
    my ($self,$address) = @_;

    my $row;
    my $row_data = ['N1','ST',$address->get_name,92,9999];
    my $row_format = [];
    
    $row .= $self->row($row_data,$row_format);
    
    $row_data = ['N3',$address->{'address'},$address->{'address2'}];
    
    $row .= $self->row($row_data,$row_format);
    
    $row_data = ['N4',$address->{'city'},$address->get_state(),$address->{'zip'},$address->get_country()];
    $row .= $self->row($row_data,$row_format);
    
    if(defined $address->{'phone'} && $address->{'phone'} ne '')
    {
	$row_data = ['PER','IC','','TE',$address->{'phone'}];
	$row .= $self->row($row_data,$row_format);
    }
    
    return $row;
}

sub items
{
    my ($self,$cart,$order) = @_;

    if(!defined $cart)
    {
	my $row_data = ['CTT','0','0'];
	my $row_format = [{size=>3}];
	return $self->row($row_data,$row_format);
    }
    else
    {
	my $rows;

	my $items = $cart->hash_items;
	my $item_no = 0;
	
	foreach my $item (@{$items})
	{
	    $item_no++;
	    my $row_data;
	    if (defined $item->{'UPC'} && $item->{'UPC'} ne "")
	    {
		$row_data = ['PO1',$item_no,$item->{'qty'},'EA',$item->{'price'},'','UP',$item->{'UPC'}];
	    }
	    else
	    {
		$row_data = ['PO1',$item_no,$item->{'qty'},'EA',$item->{'price'},'','SKU',$item->{'SKU'}];
	    }

	    my $row_format = [{size=>3},{size=>4,padleft=>'0'}];
	    
	    $rows .= $self->row($row_data,$row_format);

	    $row_data = ['PID','F','08','','',$item->{'name'} . ' (' . $item->{'SKU'} . ') - ' . $item->{'qty'}];
	    $row_format = [];

	    $rows .= $self->row($row_data,$row_format);
	}
	
	$rows .= $self->shipping_method($cart,$order);

	my $row_data = ['CTT',$cart->item_count,$cart->total];
	my $row_format = [{size=>3}];
	$rows .= $self->row($row_data,$row_format);
	
	return $rows;
    }
}

sub billing_address
{
    my ($self,$billing_address) = @_;
    
    if (!defined $billing_address)
    {
	return '';
    }

    my $row_data = ['MSG','BT: ' . $billing_address->get_name . ' ' . $billing_address->{'address'} . (defined $billing_address->{'address2'} ? ' ' . $billing_address->{'address2'} : '') . ' ' . $billing_address->{'city'} . ' ' . $billing_address->get_state() . ' ' . $billing_address->{'zip'} . ' ' . $billing_address->get_country()];

    my $row_format = [];

    return $self->row($row_data,$row_format);
}

sub get_service_level_code
{
    my ($self, $service_level,$order) = @_;
    
    if($service_level eq 'UPS Ground')
    {
	return 'SI';
    }
    elsif($service_level eq 'UPS 3-Day Select')
    {
	return 'D3';
    }
    elsif($service_level =~ /3 Day Select/i)
    {
        return 'D3';
    }
    elsif($service_level =~ /3DAY/i)
    {
        return 'D3';
    }	 
    elsif($service_level =~ /2nd Day Air/i)
    {
	return 'D2';
    }
    elsif($service_level =~ /Next Day Air/i)
    {
	return 'D1';
    }
    elsif($service_level =~ /1DAY/i)
    {
        return 'D1';
    }
    else
    {
	return 'SI';
    }
}

sub shipping_message
{
    my ($self,$cart,$order) = @_;
    
    my $row = '';
    
    if(defined $cart)
    {
	my $shipping_method = $cart->get_shipping_method();
	
	if(defined $shipping_method)
	{
	    my $cost;
	    
	    if(defined $cart->{'shipping_total'})
	    {
		$cost = $cart->{'shipping_total'};
	    }
	    else
	    {
		$cost = $cart->shipping_total();
	    }


	    my $msg = "S: " . $shipping_method . ' ' . (sprintf "%.2f", $cost);
	    if(grep(/\$/,$shipping_method))
	    {
		$msg = "S: " . $shipping_method;
	    }
	    my $row_data = ['MSG',$msg];
	    my $row_format = [];
	    $row .= $self->row($row_data,$row_format);
	}
    }

    return $row;
}

sub shipping_method
{
    my ($self,$cart,$order) = @_;
    
    my $row = '';

    if(!defined $cart)
    {
	return $row;
    }

    my $shipping_method = $cart->get_shipping_method();
    
    if(defined $shipping_method)
    {
	my $service_level_code = $self->get_service_level_code($shipping_method,$order);
	
	if(defined $service_level_code)
	{
	    my $row_data = ['TD5','','','','','','','','','','','',$service_level_code];
	    my $row_format = [];
	    
	    $row .= $self->row($row_data,$row_format);
	}
    }
    
    return $row;
}

sub st
{
    my ($self,$type,$item) = @_;
    
    if ($type == '855')
    {
	my $row_data = ['ST','855',$item->{'id'}];
	my $row_format = [{size=>2},{size=>3},{size=>9,padleft=>0}];

	my $header_row = $self->row($row_data,$row_format);
	
	my $rows = '';

	$row_data = ['BAK','0','AD',$item->{'order number'},$self->get_gs_date($item->{'order date'})];
	$row_format = [{size=>3},{size=>2,padleft=>'0'}];
	$rows .= $self->row($row_data,$row_format);

	$row_data = ['REF','IA','3310912'];
	$row_format = [{size=>3},{size=>2}];
	$rows .= $self->row($row_data,$row_format);

	$row_data = ['DTM','002',$self->get_gs_date($item->{'order date'})];
	$row_format = [{size=>3},{size=>2}];
	$rows .= $self->row($row_data,$row_format);

	$row_data = ['N1','OB',$item->{'ship address'}->{'firstname'} . ' ' . $item->{'ship address'}->{'lastname'}];
	$row_format = [{size=>2},{size=>2}];
	$rows .= $self->row($row_data,$row_format);

	$row_data = ['N3',$item->{'ship address'}->{'address1'}, $item->{'ship address'}->{'address2'}];
	$row_format = [{size=>2}];
	$rows .= $self->row($row_data,$row_format);

	$row_data = ['N4',$item->{'ship address'}->{'city'}, $item->{'ship address'}->{'state'}, $item->{'ship address'}->{'zip'}, $item->{'ship address'}->{'country'}];
	$row_format = [{size=>2}];
	$rows .= $self->row($row_data,$row_format);
	
	my $po_lines = 0;
	foreach my $line (@{$item->{'items'}})
	{
	    $po_lines++;

	    my $line_item = $po_lines;
	    my $qty = $line->{'qty'};
	    my $unit = 'EA';
	    my $price = sprintf("%010.2f",$line->{'cost'});
	    my $po106 = 'IT';
	    my $po107 = $line->{'model number'};

	    $row_data = ['PO1',$line_item,$qty,$unit,$price,'',$po106,$po107];
	    $row_format = [{size=>3}];
	    $rows .= $self->row($row_data,$row_format);

	    $row_data = ['PID','F','08','','',$line->{'model number'} . ' ' . $line->{'manufacturer'} . ' ' . $line->{'title'}];
	    $row_format = [{size=>3}];
	    $rows .= $self->row($row_data,$row_format);

	    $row_data = ['ACK','IA',$qty,'EA','068',$self->get_gs_date($item->{'order date'})];
	    $row_format = [{size=>3}];
	    $rows .= $self->row($row_data,$row_format);
	}

	$row_data = ['CTT',$po_lines,''];
	$row_format = [{size=>3}];
	$rows .= $self->row($row_data,$row_format);

	my @rows = split(/\n/,$rows);
    
	$row_data = ['SE',(scalar @rows) + 2,$item->{'id'}];
	$row_format = [{size=>2},{},{size=>9,padleft=>0}];
	
	my $footer_row = $self->row($row_data,$row_format);
	
	return $header_row . $rows . $footer_row;
    
    }
    elsif ($type == '850')
    {
	my $row_data = ['ST','850',$item->{'id'}];
	my $row_format = [{size=>2},{size=>3},{size=>9,padleft=>0}];

	my $header_row = $self->row($row_data,$row_format);
	
	my $rows = '';

	$row_data = ['BEG','0','SA',$item->{'order_number'},'',$self->get_gs_date($item->order_date),'','','','','','','DP'];
	$row_format = [{size=>3},{size=>2,padleft=>'0'}];
	$rows .= $self->row($row_data,$row_format);

	$row_data = ['REF','DP','WEBSITE'];
	$row_format = [];
	$rows .= $self->row($row_data,$row_format);
	
	$row_data = ['PER','DC',$item->customer_name()];
	$row_format = [];
	$rows .= $self->row($row_data,$row_format);
    
	$rows .= $self->shipping_address($item->{'shipping_address'});
	$rows .= $self->billing_address($item->{'billing_address'});
	$rows .= $self->shipping_message($item->{'cart'},$item);
    
	$rows .= $self->items($item->{'cart'},$item);
	
	my @rows = split(/\n/,$rows);
    
	$row_data = ['SE',(scalar @rows) + 2,$item->{'id'}];
	$row_format = [{size=>2},{},{size=>9,padleft=>0}];
	
	my $footer_row = $self->row($row_data,$row_format);
	
	return $header_row . $rows . $footer_row;
    }
}

sub gs
{
    my ($self,$date) = @_;

    $date = $self->get_gs_date($date);
    
    my $row_data = ['GS','PO',$self->{'sender'},$self->{'recipient'},$date,'0900','0001','X','004010VICS'];
    my $row_format = [{size=>2},{size=>2}];

    return $self->row($row_data,$row_format);
}

sub ge
{
    my ($self) = @_;

    my $row_data = ['GE','1','1'];
    my $row_format = [{size=>2},{},{size=>4,padleft=>'0'}];

    return $self->row($row_data,$row_format);
}

sub get_isa_date
{
    my ($self,$date) = @_;
    
    my ($sec,$min,$hour,$mday,$mon,$year,$wday,$yday,$isdst) = localtime($date);

    $mon++;
    if($mon < 10){$mon = '0' . $mon;}
    if($mday < 10){$mday = '0' . $mday;}
    
    $year += 1900;
    
    my $two_digit_year = sprintf("%02d", $year % 100);
    
    my $isa_date = $two_digit_year . $mon . $mday;		    
    
    return($isa_date);
}

sub get_gs_date
{
    my ($self,$date) = @_;
    
    my ($sec,$min,$hour,$mday,$mon,$year,$wday,$yday,$isdst) = localtime($date);

    $mon++;
    if($mon < 10){$mon = '0' . $mon;}
    if($mday < 10){$mday = '0' . $mday;}
    
    $year += 1900;
    
    my $gs_date = $year . $mon . $mday;		    
    
    return($gs_date);
}


sub isa
{
    my ($self,$id,$date) = @_;
    
    my $row;
 
    my $row_data = ['ISA','0','','0','','12',$self->{'sender'},'12',$self->{'recipient'},$self->get_isa_date($date),'0900','U','00401',$id,'1','P','>'];

    my $row_format = [{size=>3},{size=>2,pad=>'0'},{size=>10},{size=>2,pad=>'0'},{size=>10},{size=>2,padleft=>'0'},{size=>15,pad=>' '},{size=>2,pad=>'0'},{size=>15,pad=>' '},{},{},{},{},{size=>9,padleft=>'0'}];

    $row .= $self->row($row_data,$row_format);
    
    return $row;
}

sub iea
{
    my ($self,$id) = @_;
    
    my $row;

    my $row_data = ['IEA','1',$id];

    my $row_format = [{size=>3},{size=>1,pad=>'0'},{size=>9,padleft=>'0'}];

    $row .= $self->row($row_data,$row_format);

    return $row;
}

1;
__END__
# Below is stub documentation for your module. You'd better edit it!

=head1 NAME

Business::Logic::Cart - Perl extension for blah blah blah

=head1 SYNOPSIS

  use Business::Logic::EDI;
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
