#!/usr/bin/perl

use DBI;
use Getopt::Long;

## Magento configuration ##
my $username;
my $host;
my $database;
my $password;

## EDI configuration ##
my $source_folder;
my $upc_attribute_id;

GetOptions ("username=s" => \$username,    
	    "host=s"   => \$host,      
	    "database=s"  => \$database,
	    "password=s" => \$password,
	    "source=s" => \$soruce_folder,
	    "upcattribute=i" => \$upc_attribute_id
    )
    or die("Error in command line arguments\n");

if !defined $password
{
    print "Password: ";
    $password = <STDIN>;
    chomp $password;
}

if !defined $username || !defined $host || !defined $database || !defined $password || !defined $source_folder || !defined $upc_attribute_id
{
    die("You must specify required options\n");
    exit;
}

open FILE,$source_folder . 'EDOBIW';

my $inventory_list = '';

while(<FILE>)
{
	$inventory_list .= $_;
}

close FILE;

my $dbh = DBI->connect("DBI:mysql:database=$database:host=$host",$username,$password);


while($inventory_list =~ /LIN\~\~UP\~(\d+)\*QTY\~33\~(\d+)\~EA/igs)
{
	print $1 . " = " . $2 . "\n";
	update_inventory("0" . $1, $2);
}

$dbh->disconnect;

exit;

sub update_inventory
{
	my ($upc, $qty) = @_;

	my $statement = 'select entity_id FROM catalog_product_entity_varchar where attribute_id = ' . $upc_attribute_id . ' and value like ?';
	my $sth = $dbh->prepare($statement);
	$sth->execute($upc . '%');
	
	my $result = $sth->fetchall_arrayref;
	
	if($#$result > -1)
	{
		print $upc . " ==> " . $result->[0]->[0] . "\n";	
		my $product_id = $result->[0]->[0];
	
		my $statement = 'select qty from cataloginventory_stock_item where product_id = ?';
		my $sth = $dbh->prepare($statement);
		$sth->execute($product_id);
		my $results = $sth->fetchall_arrayref;
	
		if($#$results > -1)
		{
			my $old_qty = $results->[0]->[0];
			my $new_qty = $qty;

			if($old_qty != $new_qty)
			{
				print "$old_qty --> $new_qty\n";
				my $statement = 'update cataloginventory_stock_item SET qty = ? WHERE product_id = ?';
				my $sth = $dbh->prepare($statement);
				$sth->execute($new_qty, $product_id);
			}
		}


	}	

}


