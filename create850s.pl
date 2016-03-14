#!/usr/bin/perl

use DBI;
use Time::Local;
use Getopt::Long;

use Business::Logic::Order;
use Business::Logic::Address;
use Business::Logic::Customer;
use Business::Logic::Item;
use Business::Logic::Cart;
use Business::Logic::EDI;

my $bl = Business::Logic->new;

## Magento configuration ##
my $username;
my $host;
my $database;
my $password;

## EDI configuration ##
my $edi_sender;
my $edi_recipient;
my $destination_folder;

GetOptions ("username=s" => \$username,    
	    "host=s"   => \$host,      
	    "database=s"  => \$database,
	    "password=s" => \$password,
	    "sender=s" => \$edi_sender,
	    "recipient=s" => \$edi_recipient,
	    "destination=s" => \$destination_folder
    )
    or die("Error in command line arguments\n");

if !defined $password
{
    print "Password: ";
    $password = <STDIN>;
    chomp $password;
}

if !defined $username || !defined $host || !defined $database || !defined $password || !defined $sender || !defined $recipient || !defined $destination
{
    die("You must specify required options\n");
    exit;
}

my $dbh = DBI->connect("DBI:mysql:database=$database:host=$host",$username,$password);

my $statement = 'select * from sales_flat_order WHERE status in (\'pending\',\'processing\') AND (entity_id NOT IN (select order_id from edi_table))';
my $sth = $dbh->prepare($statement);
$sth->execute();

my $orders = [];
while(my $result = $sth->fetchrow_hashref)
{

	my $order = {};

	print "======= ORDER =======\n";

	$order->{'id'} = $result->{'entity_id'};
	$order->{'order_date'} = $result->{'created_at'};
	
	if($result->{'shipping_description'} =~ /ground/i)
	{
		$result->{'shipping_description'} = 'UPS Ground';
	}
        elsif($result->{'shipping_description'} =~ /free/i)
	{
		$result->{'shipping_description'} = 'UPS Ground';
	}

        $result->{'shipping_description'} =~ s/United Parcel Service/UPS/igs;
	$result->{'shipping_description'} =~ s/ \- //igs;
	
	$order->{'shipping'} = $result->{'shipping_description'} . ' $' . sprintf "%.2f", $result->{'shipping_amount'};
	
	$order->{'increment'} = $result->{'increment_id'};

	$order->{'shipping_address'} = get_address($result->{'shipping_address_id'});
	$order->{'billing_address'} = get_address($result->{'billing_address_id'});
	
	$order->{'customer_name'} = $result->{'customer_firstname'} . ' ' . $result->{'customer_lastname'};
	$order->{'customer_name'} =~ s/\s\s/\s/igs;

	print $order->{'customer_name'} . "\n";
	
	$order->{'order_items'} = get_order_items($order->{'id'});


	my $has_upcs = 1;
	foreach my $order_item (@{$order->{'order_items'}})
	{
		print $order_item->{'UPC'} . " - " . $order_item->{'sku'} . " - " . $order_item->{'id'} . " - " . $order_item->{'price'} . " - " . $order_item->{'name'} . "\n";

		if ($order_item->{'UPC'} eq '')
		{
			$has_upcs = 0;
		}
	}
	
	if ($has_upcs)
	{
		push @$orders, $order;
	}
	else
	{
		print "===== ORDER HAS NO UPCS =====\n";
	}

} 	

print "\n\n";

foreach my $order (@$orders)
{
	generate_edi_file($order);	
}


$dbh->disconnect;
exit;


sub generate_edi_file
{
	my ($order) = @_;

	my $order_number = $order->{'id'};

	my $statement = 'insert into edi_table (order_id) values (?)';
	my $sth = $dbh->prepare($statement);
	$sth->execute($order_number);
	my $counter = $sth->{ mysql_insertid };

	my $order_date = $order->{'order_date'};
			
        my $billing_address = $order->{'billing_address'};
	my $shipping_address = $order->{'shipping_address'};
	$shipping_address = $shipping_address ? $shipping_address : $billing_address;
	
	my $bill_name = $billing_address->{'firstname'} . ' ' . $billing_address->{'lastname'};
	my $ship_name = $shipping_address->{'firstname'} . ' ' . $shipping_address->{'lastname'};
	
	my $ship_first = $shipping_address->{'firstname'};
	my $ship_last = $shipping_address->{'lastname'};
	my $bill_first = $billing_address->{'firstname'};
	my $bill_last = $billing_address->{'lastname'};

	my $bill_address1 = $billing_address->{'address'};
	my $ship_address1 = $shipping_address->{'address'};

	my $bill_address2 = '';
	my $ship_address2 = '';	

	($bill_address1, $bill_address2) = split(/\n/,$bill_address1,2);
	($ship_address1, $ship_address2) = split(/\n/,$ship_address1,2);
	
	if($bill_address1 eq $bill_address2) { $bill_address2 = ''; }
	if($ship_address1 eq $ship_address2) { $ship_address2 = ''; }

	my $bill_city = $billing_address->{'city'};
	my $ship_city = $shipping_address->{'city'};
	my $bill_state = $billing_address->{'state'};
	my $ship_state = $shipping_address->{'state'};
	my $bill_zip = $billing_address->{'zip'};
	my $ship_zip = $shipping_address->{'zip'};
	my $bill_country = $billing_address->{'country'};
	my $ship_country = $shipping_address->{'country'};
	my $shipping_line = $order->{'shipping'};

	$bill_address1 =~ s/\*//igs;
	$bill_address2 =~ s/\*//igs;
	$ship_address1 =~ s/\*//igs;
	$ship_address2 =~ s/\*//igs;
	
	my $shipment_address = new Business::Logic::Address({firstname=>$ship_first,lastname=>$ship_last,address=>$ship_address1,address2=>$ship_address2, city=>$ship_city, state=>$ship_state, zip=>$ship_zip, country=>$shipping_country, phone=>$ship_phone });	
	my $billment_address = new Business::Logic::Address({firstname=>$bill_first,lastname=>$bill_last,address=>$bill_address1,address2=>$bill_address2, city=>$bill_city, state=>$bill_state, zip=>$bill_zip, country=>$bill_country, phone=>$bill_phone });
	
	my $order_customer = new Business::Logic::Customer({customer_name=>$order->{'customer_name'} } );

	my $items = $order->{'order_items'};
	
	my $edi_items = [];
	my $item_count = 0;	

	foreach my $item (@$items)
	{	
		$item_count++;
		my $new_edi_items = $bl->create_items([$item],{"SKU"=>"sku","price"=>"price","qty"=>"qty"});
		my $new_edi_item = $new_edi_items->[0];

        	$new_edi_item->{'UPC'} = $item->{'UPC'};	
        	$new_edi_item->{'name'} = $item->{'name'};
		$new_edi_item->{'price'} = $item->{'price'};

		push @$edi_items,$new_edi_item;
	}

	my $edi_cart = $bl->get_cart({"items"=>$edi_items});		
	$edi_cart->set_shipping_method( $shipping_line );
	my $edi_id = $order_number;
    	my $edi_order = new Business::Logic::Order({shipping_address=>$shipment_address, billing_address=>$billment_address, order_number=>$edi_id,customer=> $order_customer});

    	$edi_order->{'id'} = $edi_order->get_order_number();
    	$edi_order->{'cart'} = $edi_cart;	

	my $EDI = new Business::Logic::EDI;

    	$EDI->{'sender'} = $edi_sender;
    	$EDI->{'recipient'} = $edi_recipient;

    	$EDI->add_item($edi_order);


	my $second = 0;
	my $minute = 0;
	my $hour = 12;

	my $month = 12;
	my $day = 30;
	my $year = 2015;

	if($order_date =~ /^(\d\d\d\d)\-(\d\d)\-(\d\d)/)
	{
		$year = $1;
		$month = $2;
		$day = $3;
	} 
	
	my $order_time = timelocal($second,$minute,$hour,$day,$month-1,$year); 

	$edi_order->{'order_date'} = $order_time;
	
    	my $edi850 = $EDI->edi_850($counter);

	if($item_count > 0)
	{

		my $filename = $destination_folder . 'edi850.' . $counter;

		open my $fh,'>',$filename;
    		print $fh $edi850;
    		close $fh;

		print $edi850;
		print "\n";
	}
}

sub get_order_items
{
	my ($id) = @_;

	my $order_items = [];
	
	my $statement = 'select * from sales_flat_order_item where order_id = ? AND parent_item_id IS NULL'; 
	my $sth = $dbh->prepare($statement) || print $dbh->errstr;
	$sth->execute($id) || print $sth->errstr;
	
	my $get_child_item_product_id = 'select product_id FROM sales_flat_order_item WHERE parent_item_id = ? and order_id = ?';
	$get_child_item_product_id = $dbh->prepare($get_child_item_product_id);

	while (my $result = $sth->fetchrow_hashref)
	{
		my $order_item = {};
		$order_item->{'name'} = $result->{'name'};
		$order_item->{'sku'} = $result->{'sku'};
		$order_item->{'qty'} = $result->{'qty_ordered'};
		$order_item->{'price'} = $result->{'price'};
		$order_item->{'description'} = $result->{'description'};
		$order_item->{'id'} = $result->{'product_id'};
		$order_item->{'item_id'} = $result->{'item_id'};
		
		$get_child_item_product_id->execute($order_item->{'item_id'}, $id);
		my $child_item_product_id = $get_child_item_product_id->fetchall_arrayref;		

		if($#$child_item_product_id > -1)
		{
			$order_item->{'UPC'} = get_upc($child_item_product_id->[0]->[0]);
			if ($order_item->{'UPC'})
			{		
				push @$order_items, $order_item;	
			}
		}
	}		
	return $order_items;
}

sub get_upc
{
	my ($id) = @_;
	
	my $upc = '';

	my $statement = 'select value from catalog_product_entity_varchar where attribute_id = 175 and entity_id=?';
	my $sth = $dbh->prepare($statement);
	$sth->execute($id);	

	my $results = $sth->fetchall_arrayref;
	if ($results)
	{
		if($results->[0])
		{
			$upc = $results->[0]->[0];
		}
	}

	$upc =~ s/^0//;
	$upc =~ s/\D$//igs;
	$upc =~ s/\s//igs;
	
	return $upc;
}

sub get_address
{
	my ($id) = @_;
	my $address = {};

	my $statement = 'select * from sales_flat_order_address where entity_id = ?';
	my $sth = $dbh->prepare($statement);
	$sth->execute($id);
	my $result = $sth->fetchrow_hashref;
	$sth->finish;
	
	if($result == undef)
	{
		print "Address Not Found ERROR\n";
	}
        else
        {	
	        $address->{'firstname'} = $result->{'firstname'};
		$address->{'lastname'} = $result->{'lastname'};
		$address->{'address'} = $result->{'street'};
		$address->{'city'} = $result->{'city'};
		$address->{'state'} = $result->{'region'};
		$address->{'zip'} = $result->{'postcode'};
		$address->{'country'} = $result->{'country_id'};
		$address->{'telephone'} = $result->{'telephone'};

        }

	return $address;	
}
