# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl Business-Logic.t'

#########################

# change 'tests => 1' to 'tests => last_test_to_print';

use Test::More tests => 106;
BEGIN { use_ok('Business::Logic'); use_ok('Business::Logic::Cart'); use_ok('Business::Logic::Item'); use_ok('Business::Logic::Discount'); use_ok('Business::Logic::PurchaseOrder'); use_ok('Business::Logic::Shipment'); use_ok('Business::Logic::Shipping'); use_ok('Business::Logic::Company'); use_ok('Business::Logic::Address'); use_ok('Business::Logic::Order'); use_ok('Business::Logic::Credit'); use_ok('Business::Logic::Option'); use_ok('Business::Logic::Options'); use_ok('Business::Logic::PaymentMethod'); use_ok('Business::Logic::EDI'); use_ok('Business::Logic::Customer'); use_ok('Business::Logic::Address')};

#########################

# Insert your test code below, the Test::More module is use()ed here so read
# its man page ( perldoc Test::More ) for help writing this test script.

my $bl = Business::Logic->new;

my $items = $bl->create_items([{"style"=>"HAVANABLK","retail"=>398},{"style"=>"RAMONECBLK","retail"=>78}],{"SKU"=>"style","price"=>"retail"});

my $cart = $bl->get_cart({"items"=>$items});

my $total = $cart->total();

ok( $total == 398+78 , "cart total adds correctly");

my $discount = $bl->create_discount({"code"=>"HHTHANKSYOU","pct"=>"25"});

my $code = $discount->code;

ok($code eq "HHTHANKSYOU", "retrieving discount code");

my $pct = $discount->pct;

ok($pct == 25, "correct discount");

$cart->{'cart_offers'} = [
       { 'value' => 100, 'text' => 'save 5', 'amount' => 50},
       { 'value' => 300, 'text' => 'save 10', 'amount' => 100},
       { 'value' => 600, 'text' => 'save 20', 'amount' => 200},
];

my $offer_total = $cart->total();

ok( $offer_total == (398+78-100), 'cart offer amount');

ok( defined $cart->{'applied_offer'}, 'offer saved');

ok( $cart->{'applied_offer'}->{'text'} eq 'save 10');

ok( $cart->applied_offer_text eq 'save 10');

ok( $cart->applied_offer_amount == 100, ' amount');

$cart->{'cart_offers'} = undef;

$cart->add_discount($discount);

$total = $cart->total();

ok( $total == (398+78)*.75 , "cart discounted total adds correctly");

$discount->pct(50);

$total = $cart->total();

ok( $total == (398+78)*.50 , "discount changed and total adds correctly");

my $discount2 = $bl->create_discount({"code"=>"BZR532XK1","pct"=>10});

$cart->add_discount($discount2);

$total = $cart->total();

my $sum = (398+78)*.50*.90;

ok( int($total*100)/100 == int($sum*100)/100 , "2 discounts and total adds correctly");

my $discount3 = $bl->create_discount({"code"=>"TOTALDISCOUNT","pct"=>50,"combines"=>"N"});

$cart->add_discount($discount3);

$total = $cart->total();

$sum = (398+78)*.50*.90;

ok( int($total*100)/100 == int($sum*100)/100 , "3 discounts and total adds correctly");

$cart->remove_discount($discount2->code,$discount->code);

$total = $cart->total();

$sum = (398+78)*.50;

ok( int($total*100)/100 == int($sum*100)/100 , "removing discounts total adds correctly");

$cart->clear_discounts();
$total = $cart->total();

$sum = (398+78);

ok( int($total*100)/100 == int($sum*100)/100 , "clearing all discounts");

# save 50% on havana when you buy Ramone in black - greedy

my $discount4 = $bl->create_discount({"code"=>"HAVANASV","pct"=>50,"SKU"=>"HAVANABLK","combines"=>"Y","needs"=>{"SKU"=>"RAMONECBLK","greedy"=>"Y"}});

$cart->add_discount($discount4);

$cart->add_item( $bl->create_item ( {"style"=>"HAVANABLK","retail"=>398},{"SKU"=>"style","price"=>"retail"} ) );

$cart->add_item( $bl->create_item ( {"style"=>"HAVANABLK","retail"=>398},{"SKU"=>"style","price"=>"retail"} ) );

$total = $cart->total();
$sum = (398*.50+78+398+398);

ok( int($total*100)/100 == int($sum*100)/100 , "discount on item - $total - $sum");




# get a ramone in black free for every havana in black, and save 30% on everything

my $discount_fml = $bl->create_discount({"code"=>"FMLDISCOUNT","pct"=>100,"SKU"=>"RAMONECBLK","combines"=>"N","needs"=>{"SKU"=>"HAVANABLK,HAVANARED","greedy"=>"Y"}});
my $discount_fml2 = $bl->create_discount({"code"=>"FMLDISCOUNT","pct"=>30,"combines"=>"N","needs"=>{"SKU"=>"HAVANARED","greedy"=>"N"}});

my $fml_cart = $bl->get_cart();

$fml_cart->add_discount($discount_fml);
$fml_cart->add_discount($discount_fml2);


$fml_cart->add_item( $bl->create_item ( {"style"=>"HAVANARED","retail"=>398},{"SKU"=>"style","price"=>"retail"} ) );

$fml_cart->add_item( $bl->create_item ( {"style"=>"RAMONECBLK","retail"=>78},{"SKU"=>"style","price"=>"retail"} ) );
$fml_cart->add_item( $bl->create_item ( {"style"=>"RAMONECBLK","retail"=>78},{"SKU"=>"style","price"=>"retail"} ) );

my $fml_total = $fml_cart->total();
my $fml_sum = (398*.70+78*0+78*.70);#+398*.70+78*.70);

ok( int($fml_total*100+.5)/100 == int($fml_sum*100+.5)/100 , "fml discount - $fml_total - $fml_sum");

$fml_cart->add_item( $bl->create_item ( {"style"=>"HAVANABLK","retail"=>398},{"SKU"=>"style","price"=>"retail"} ) );
$fml_cart->add_item( $bl->create_item ( {"style"=>"RAMONECBLK","retail"=>78},{"SKU"=>"style","price"=>"retail"} ) );

$fml_total = $fml_cart->total();
$fml_sum = (398*.70+78*0+78*0+398*.70+78*.70);

ok( int($fml_total*100+.5)/100 == int($fml_sum*100+.5)/100 , "fml discount2 - $fml_total - $fml_sum");


$cart->add_item( $bl->create_item ( {"style"=>"RAMONECBLK","retail"=>78},{"SKU"=>"style","price"=>"retail"} ) );

$total = $cart->total();
$sum = (398*.50+78+398*.50+398+78);

ok( int($total*100)/100 == int($sum*100)/100 , "discount on item greedy works? - $total - $sum");

$cart->clear_discounts();

my $discount5 = $bl->create_discount({"code"=>"HAVANASV","pct"=>50,"SKU"=>"HAVANABLK","combines"=>"Y","needs"=>{"SKU"=>"RAMONECBLK"}});

$cart->add_discount($discount5);

$total = $cart->total();
$sum = (398*.50+78+398*.50+398*.50+78);

ok( int($total*100)/100 == int($sum*100)/100 , "discount on item - noslurp");

$cart->clear_discounts();

my $discount6 = $bl->create_discount({"code"=>"SAVE20ON1000","pct"=>20,"SKU"=>"ALL","combines"=>"Y","floor"=>1000});

$cart->add_discount($discount6);

$total = $cart->total();

$sum = (398+78+398+398+78) * .80;

ok( int($total*100)/100 == int($sum*100)/100 , "floor - \$1000");

$cart->remove_item("","HAVANABLK");

$total = $cart->total();

$sum = (78+78);

ok( int($total*100)/100 == int($sum*100)/100 , "remove items & floor - \$1000");

# expires in the future

my $discount7 = $bl->create_discount({"code"=>"SAVE15","pct"=>15,"SKU"=>"ALL","expires"=>time+86400,"combines"=>"Y"});

$cart->add_discount($discount7);

$total = $cart->total();

$sum = (78+78)*.85;

ok( int($total*100)/100 == int($sum*100)/100 , "future expiration date");

# expires in the past

my $discount8 = $bl->create_discount({"code"=>"OLDSAVE15","pct"=>25,"SKU"=>"ALL","expires"=>time-86400,"combines"=>"Y"});

$cart->add_discount($discount8);

$total = $cart->total();

$sum = (78+78)*.85;

ok( int($total*100)/100 == int($sum*100)/100 , "past expiration date");

$cart->clear_discounts();

my $discount9 = $bl->create_discount({"code"=>"ONEITEM","pct"=>10,"SKU"=>"ALL","uses"=>1,"combines"=>"Y"});

my $discount10 = $bl->create_discount({"code"=>"SAVE15ALL","pct"=>15,"SKU"=>"ALL","combines"=>"Y"});

$cart->add_discount($discount9);
$cart->add_discount($discount10);

$total = $cart->total();

$sum = (78*.85*.90+78*.85);

ok( int($total*100)/100 == int($sum*100)/100 , "one use - $total - $sum");


my $discount11 = $bl->create_discount({"code"=>"SAVE15100","pct"=>15,"SKU"=>"ALL","floor"=>100,"combines"=>"Y"});


$cart->add_discount($discount11);

$total = $cart->total();

$sum = (int(78*.85*.90*.85*100)/100+int(78*.85*.85*100)/100);

ok( int($total*100)/100 == int($sum*100)/100 , "one use+floor & combines - $total - $sum");

$cart->clear_discounts();

my $discount12 = $bl->create_discount({"code"=>"SAVE15100","pct"=>15,"SKU"=>"ALL","floor"=>100,"combines"=>"Y"});

$cart->add_item( $bl->create_item ( {"style"=>"HAVANARED","retail"=>398,"on_sale"=>"Y","sale_price"=>150,"sale_expires"=>time+86400},{"SKU"=>"style","price"=>"retail"} ) );


$cart->add_discount($discount12);

$total = $cart->total();

$sum = (int(78*.85*100)/100+int(78*.85*100)/100+int(150*.85*100)/100);

ok( int($total*100)/100 == int($sum*100)/100 , "one use+floor & combines - $total - $sum");

$cart->remove_discount($discount12->code);

my $discount13 = $bl->create_discount({"code"=>"SAVE15SALE","pct"=>20,"SKU"=>"ALL","onsale_only"=>"Y","combines"=>"Y"});

$cart->add_discount($discount13);

$total = $cart->total();

$sum = (int(78*100)/100+int(78*100)/100+int(150*.80*100)/100);

ok( int($total*100)/100 == int($sum*100)/100 , "on sale only - $total - $sum");

my $sort_items = $bl->create_items([{"style"=>"HAVANABLK","retail"=>398,"parentSKU"=>"HAVANA","age"=>1000,"color"=>100},{"style"=>"HAVANARBY","retail"=>398,"parentSKU"=>"HAVANA","age"=>2000,"color"=>200},{"style"=>"HAVANAYEL","retail"=>398,"parentSKU"=>"HAVANA","age"=>3000,"color"=>300},{"style"=>"HAVANAGRN","retail"=>398,"parentSKU"=>"HAVANA","age"=>4000,"color"=>400},{"style"=>"LORCAYEL","retail"=>298,"parentSKU"=>"LORCA","age"=>2000,"color"=>300},{"style"=>"LORCARED","retail"=>298,"parentSKU"=>"LORCA","age"=>3000,"color"=>200},{"style"=>"LORCACHC","retail"=>298,"parentSKU"=>"LORCA","age"=>4000,"color"=>100},{"style"=>"LORCAMUL","retail"=>298,"parentSKU"=>"LORCA","age"=>5000,"color"=>150},{"style"=>"RAMONECBLK","retail"=>78,"color"=>100}],{"SKU"=>"style","price"=>"retail","parentSKU"=>"parentSKU","age"=>"age","color"=>"color"});

$sort_items = $bl->sort_items($sort_items,{"in-stock"=>0,"items-per-style"=>1,"secondary-sort"=>"age","primary-sort"=>"featured"});

my $sorted = "";

foreach my $item (@{$sort_items})
{
	$sorted .= $item->SKU . ",";
}

chop $sorted;

my $asort = "LORCAMUL,HAVANAGRN,RAMONECBLK,LORCACHC,HAVANAYEL,LORCARED,HAVANARBY,LORCAYEL,HAVANABLK";

ok ($sorted eq $asort,"sorted items - $sorted");

$items = $bl->create_items([{"style"=>"HAVANABLK","retail"=>398,"in_stock"=>15},{"style"=>"RAMONECBLK","retail"=>78}],{"SKU"=>"style","price"=>"retail","in_stock"=>"in_stock"});

$cart = $bl->get_cart({"items"=>$items});

my $discount37 = $bl->create_discount({"code"=>"SAVE20","pct"=>20,"SKU"=>"ALL","instock_only"=>"Y"});

$cart->add_discount($discount37);


$total = $cart->total();

ok($total == 396.40,"IN stock only test - $total");


# save 30% when you have 3 items

my $save30_items = $bl->create_items([{"style"=>"HAVANABLK","retail"=>398,"in_stock"=>15},{"style"=>"RAMONECBLK","retail"=>78}],{"SKU"=>"style","price"=>"retail","in_stock"=>"in_stock"});

my $save30_cart = $bl->get_cart({"items"=>$save30_items});

my $save30_discount = $bl->create_discount({"code"=>"SAVE303","pct"=>30,'SKU'=>'ALL','needs'=>{'SKU'=>'ALL','counts'=>{'SKU'=>3}}});

$save30_cart->add_discount($save30_discount);

my $save30_total = $save30_cart->total();

ok($save30_total == 398 + 78,"Don't Save 30 on 2 items - $save30_total != " . (398 + 78));

$save30_cart->clear_discounts();

$save30_discount = $bl->create_discount({"code"=>"SAVE303","pct"=>30,'SKU'=>'ALL','needs'=>{'SKU'=>'ALL','counts'=>{'SKU'=>3}}});

$save30_cart->add_discount($save30_discount);

$save30_cart->add_item( $bl->create_item ( {"style"=>"HAVANABLK","retail"=>398},{"SKU"=>"style","price"=>"retail"} ) );

$save30_total = $save30_cart->total();

ok(int($save30_total+.5) == int((398 + 398 + 78)*.70 +.5),"Save 30 on 3 items - $save30_total " . (398 + 398 + 78)*.70 . ' ' . $save30_cart->item_count());

# save 20/30

my $save2030_items = $bl->create_items([{"style"=>"HAVANABLK","retail"=>398,"in_stock"=>15},{"style"=>"RAMONECBLK","retail"=>78}],{"SKU"=>"style","price"=>"retail","in_stock"=>"in_stock"});

my $save2030_cart = $bl->get_cart({"items"=>$save2030_items});

my $save130_discount = $bl->create_discount({"code"=>"SAVE3020","pct"=>20,'SKU'=>'ALL','needs'=>{'SKU'=>'ALL','counts'=>{'SKU'=>2}}});
my $save230_discount = $bl->create_discount({"code"=>"SAVE3030","pct"=>30,'SKU'=>'ALL','needs'=>{'SKU'=>'ALL','counts'=>{'SKU'=>3}}});

$save2030_cart->add_discount($save130_discount);
$save2030_cart->add_discount($save230_discount);

my $save2030_total = $save2030_cart->total();

ok(int($save2030_total+.5) == int((398 + 78)*.80+.5),"Save 20, not 30 on 2 items");

$save130_discount = $bl->create_discount({"code"=>"SAVE3020","pct"=>20,'SKU'=>'ALL','needs'=>{'SKU'=>'ALL','counts'=>{'SKU'=>2}},'combines'=>'N'});
$save230_discount = $bl->create_discount({"code"=>"SAVE3030","pct"=>30,'SKU'=>'ALL','needs'=>{'SKU'=>'ALL','counts'=>{'SKU'=>3}},'combines'=>'N'});

$save2030_cart->clear_discounts();

$save2030_cart->add_discount($save230_discount);
$save2030_cart->add_discount($save130_discount);

$save2030_cart->add_item( $bl->create_item ( {"style"=>"HAVANABLK","retail"=>398},{"SKU"=>"style","price"=>"retail"} ) );

my $save20302_total = $save2030_cart->total();
ok(int($save20302_total+.5) == int((398 +398 + 78)*.70+.5),"Save 30, not 20 on 3 items - " . $save20302_total . " vs " . int((398 +398 + 78)*.70+.5));

#save 20% on all items when you have 1 sale item in your cart

my $discount38 = $bl->create_discount({"code"=>"SAVE20","pct"=>20,"SKU"=>"ALL","instock_only"=>"N","needs"=>{"on_sale"=>"Y","greedy"=>"N"}});

$cart->clear_discounts();

$cart->add_discount($discount38);

$total = $cart->total();

ok($total == 476,"needs test - in stock - $total");

$cart->add_item( $bl->create_item ( {"style"=>"HAVANABLK","retail"=>200,"on_sale"=>"Y","sale_expires"=>(time+86400),"sale_price"=>50},{"SKU"=>"style","price"=>"retail","on_sale"=>"on_sale","sale_expires"=>"sale_expires","sale_price"=>"sale_price"} ) );

$total = $cart->total();

my $test_total = int((398 * .80 + 78 * .80 + 50*.80)/100)*100;

$total = int($total/100)*100;

ok($total == $test_total,"needs test2 - in stock - $total - $test_total");

$cart->clear_discounts();

my $discount39 = $bl->create_discount({"code"=>"SAVE202","pct"=>20,"SKU"=>"ALL","instock_only"=>"N","needs"=>{"on_sale"=>"Y","counts"=>{"on_sale"=>1},"match_type"=>"AND","greedy"=>"N"}});
$cart->add_discount($discount39);

$total = $cart->total();

$test_total = int((398 * .80 + 78 * .80 + 50*.80)/100)*100;

$total = int($total/100)*100;

ok($total == $test_total,"needs test3 - in stock - $total - $test_total");


$cart->clear_discounts();

my $discount40 = $bl->create_discount({"code"=>"SAVE202","pct"=>20,"SKU"=>"ALL","instock_only"=>"N","needs"=>{"on_sale"=>"Y","counts"=>{"on_sale"=>2},"match_type"=>"AND","greedy"=>"N"}});
$cart->add_discount($discount40);

$total = $cart->total();

$test_total = int((398 + 78 + 50)/100)*100;

$total = int($total/100)*100;

ok($total == $test_total,"needs test4 - in stock - $total - $test_total");

$cart->add_item( $bl->create_item ( {"style"=>"HAVANABLK","retail"=>200,"on_sale"=>"Y","sale_expires"=>(time+86400),"sale_price"=>50},{"SKU"=>"style","price"=>"retail","on_sale"=>"on_sale","sale_expires"=>"sale_expires","sale_price"=>"sale_price"} ) );


$cart->clear_discounts();

my $discount41 = $bl->create_discount({"code"=>"SAVE202","pct"=>20,"SKU"=>"ALL","instock_only"=>"N","needs"=>{"on_sale"=>"Y","counts"=>{"on_sale"=>2},"match_type"=>"AND","greedy"=>"N"}});
$cart->add_discount($discount41);

$total = $cart->total();

$test_total = int((398*.80 + 78*.80 + 50*.80+50*.80)/100)*100;

$total = int($total/100)*100;

ok($total == $test_total,"needs test4 - in stock - $total - $test_total");

$cart->clear_discounts();

my $discount42 = $bl->create_discount({"code"=>"SAVE203","pct"=>20,"SKU"=>"ALL","instock_only"=>"N","needs"=>{"on_sale"=>"Y","counts"=>{"on_sale"=>3},"match_type"=>"AND","greedy"=>"N"}});
$cart->add_discount($discount42);

$total = $cart->total();

$test_total = int((398 + 78 + 50+50)/100)*100;

$total = int($total/100)*100;

ok($total == $test_total,"needs test5 - in stock - $total - $test_total");

$cart->clear_discounts();

my $discount43 = $bl->create_discount({"code"=>"SAVE204","pct"=>20,"SKU"=>"ALL","instock_only"=>"N","needs"=>{"on_sale"=>"Y","counts"=>{"on_sale"=>3},"match_type"=>"AND","greedy"=>"N"}});
$cart->add_discount($discount43);

$cart->add_item( $bl->create_item ( {"style"=>"HAVANABLK","retail"=>200,"on_sale"=>"Y","sale_expires"=>(time+86400),"sale_price"=>50},{"SKU"=>"style","price"=>"retail","on_sale"=>"on_sale","sale_expires"=>"sale_expires","sale_price"=>"sale_price"} ) );


$total = $cart->total();

$test_total = int((398*.80 + 78*.80 + 50*.80+50*.80+50*.80)/100)*100;

$total = int($total/100)*100;

ok($total == $test_total,"needs test6 - in stock - $total - $test_total");

$cart->clear_discounts();

my $discount44 = $bl->create_discount({"code"=>"SAVE204","pct"=>20,"SKU"=>"ALL","instock_only"=>"N","needs"=>{"on_sale"=>"Y","counts"=>{"on_sale"=>7},"match_type"=>"AND","greedy"=>"N"}});
$cart->add_discount($discount44);

$cart->add_item( $bl->create_item ( {"style"=>"HAVANABLK","retail"=>200,"on_sale"=>"Y","sale_expires"=>(time+86400),"sale_price"=>50,"qty"=>4},{"SKU"=>"style","price"=>"retail","on_sale"=>"on_sale","sale_expires"=>"sale_expires","sale_price"=>"sale_price"} ) );


$total = $cart->total();

$test_total = int((398*.80 + 78*.80 + 50*.80+50*.80+50*.80 + 4*50*.80)/100)*100;

$total = int($total/100)*100;

ok($total == $test_total,"needs test7 - in stock - $total - $test_total");

$cart->clear_discounts();

my $discount45 = $bl->create_discount({"code"=>"SAVE205","pct"=>20,"SKU"=>"ALL","instock_only"=>"N","needs"=>{"on_sale"=>"Y","counts"=>{"on_sale"=>8},"match_type"=>"AND","greedy"=>"N"}});
$cart->add_discount($discount45);

$total = $cart->total();

$test_total = int((398 + 78 + 50+50 + 4*50+100)/100)*100;

$total = int($total/100)*100;

ok($total == $test_total,"needs test8 - in stock - $total - $test_total");

###############################

my $pos = $bl->create_purchase_orders([ 
   
   {
	number=>"PO-1",
	completion_date=>time+86400*30,
	ordered=>$bl->create_items([{"style"=>"ITEM1","qty"=>40,"item_no"=>1},
				    {"style"=>"ITEM2","qty"=>30,"item_no"=>2},
				    ],{"SKU"=>"style","qty"=>"qty"},"item_no"
				   ),
	shipments=>$bl->create_shipments( [{
		ex_factory=>time+86400,
		at_port=>time+86400*7,
		available_to_ship=>time+86400*8,
		items=> $bl->create_items([{"style"=>"ITEM1","qty"=>20,"item_no"=>1},
				    {"style"=>"ITEM2","qty"=>20,"item_no"=>2},
				    ],{"SKU"=>"style","qty"=>"qty"},"item_no"
				   ),	
		}]		   
	),
   }
   ] );

my ($pending_qty,$pending_date) = $bl->get_pending_qty({"SKU"=>"ITEM2"},$pos);

ok($pending_qty == 30,"Pending qty test $pending_qty");

###############################

$pos->[0]->add_shipment(

$bl->create_shipments( [{
		ex_factory=>time-86400*8,
		at_port=>time-86400*2,
		available_to_ship=>time-86400*1,
		status=> "R",
		items=> $bl->create_items([{"style"=>"ITEM1","qty"=>20,"item_no"=>1},
				    {"style"=>"ITEM2","qty"=>10,"item_no"=>2},
				    ],{"SKU"=>"style","qty"=>"qty"},"item_no"
				   ),	
		}] )

);

my ($npending_qty,$npending_date) = $bl->get_pending_qty({"SKU"=>"ITEM2"},$pos);

ok($npending_qty == 20,"Pending qty test2 -  $npending_qty");



my ($recd_qty,$remg) = $bl->get_received_qty({"SKU"=>"ITEM2"},$pos);

ok($recd_qty == 10,"Received qty -  $recd_qty");

ok(int($npending_date/60) == int((time+86400*8)/60),"proper pending date test - $npending_date - " . (time+86400*8) . "");

my $on_order_already = 11;

my $available_date = time;

my ($nrecd_qty,$nremg) = $bl->get_received_qty({"SKU"=>"ITEM2","on_order"=>$on_order_already},$pos);

if($nremg > 0)
{
	my ($npending_qty,$npending_date) = $bl->get_pending_qty({"SKU"=>"ITEM2","on_order"=>$nremg},$pos);
	
	if($npending_qty > 0)
	{
		$available_date = $npending_date;
	}	
	$nrecd_qty = $npending_qty - $nremg;
}

ok($nrecd_qty == 19 && $available_date > time,"Received qty w/ on order test -  $nrecd_qty - $nremg");

$pos = $bl->create_purchase_orders([ 
   
   {
	number=>"PO-1",
	completion_date=>time+86400*30,
	ordered=>$bl->create_items([{"style"=>"ITEM1","qty"=>100,"item_no"=>1},
				    {"style"=>"ITEM2","qty"=>100,"item_no"=>2},
				    ],{"SKU"=>"style","qty"=>"qty"},"item_no"
				   ),
	shipments=>$bl->create_shipments( [
		{
		ex_factory=>time-86400*8,
		at_port=>time-86400*7,
		available_to_ship=>time-86400*1,
		status=>"R",
		items=> $bl->create_items([{"style"=>"ITEM1","qty"=>5,"item_no"=>1},
				    {"style"=>"ITEM2","qty"=>5,"item_no"=>2},
				    ],{"SKU"=>"style","qty"=>"qty"},"item_no"
				   ),	
		},
		{
		ex_factory=>time+86400,
		at_port=>time+86400*7,
		available_to_ship=>time+86400*8,
		items=> $bl->create_items([{"style"=>"ITEM1","qty"=>20,"item_no"=>1},
				    {"style"=>"ITEM2","qty"=>20,"item_no"=>2},
				    ],{"SKU"=>"style","qty"=>"qty"},"item_no"
				   ),	
		},
		{
		ex_factory=>time+86400*10,
		at_port=>time+86400*15,
		available_to_ship=>time+86400*16,
		items=> $bl->create_items([{"style"=>"ITEM1","qty"=>20,"item_no"=>1},
				    {"style"=>"ITEM2","qty"=>20,"item_no"=>2},
				    ],{"SKU"=>"style","qty"=>"qty"},"item_no"
				   ),	
		},
		{
		ex_factory=>time+86400*20,
		at_port=>time+86400*31,
		available_to_ship=>time+86400*32,
		items=> $bl->create_items([{"style"=>"ITEM1","qty"=>20,"item_no"=>1},
				    {"style"=>"ITEM2","qty"=>20,"item_no"=>2},
				    ],{"SKU"=>"style","qty"=>"qty"},"item_no"
				   ),	
		},
		
		
		
		
		]		   
	),
   }
   ] );


$on_order_already = 11;

$available_date = time;

($nrecd_qty,$nremg) = $bl->get_received_qty({"SKU"=>"ITEM2","on_order"=>$on_order_already},$pos);

if($nremg > 0)
{
	my ($npending_qty,$npending_date) = $bl->get_pending_qty({"SKU"=>"ITEM2","on_order"=>$nremg},$pos);
	
	if($npending_qty > 0)
	{
		$available_date = $npending_date;
	}	
	$nrecd_qty = $npending_qty - $nremg;
}

ok($available_date == time + 86400*8,"Available date test -  $nrecd_qty - $nremg");

$on_order_already = 27;

$available_date = time;

($nrecd_qty,$nremg) = $bl->get_received_qty({"SKU"=>"ITEM2","on_order"=>$on_order_already},$pos);

if($nremg > 0)
{
	my ($npending_qty,$npending_date) = $bl->get_pending_qty({"SKU"=>"ITEM2","on_order"=>$nremg},$pos);
	
	if($npending_qty > 0)
	{
		$available_date = $npending_date;
	}	
	$nrecd_qty = $npending_qty - $nremg;
}

ok($available_date == time + 86400*16,"Available date test -  $nrecd_qty - $nremg");

$pos = $bl->create_purchase_orders([ 
   
   {
	number=>"PO-1",
	completion_date=>time+86400*30,
	ordered=>$bl->create_items([
				    {"style"=>"ITEM1","qty"=>100,"item_no"=>"1_S"},
				    {"style"=>"ITEM1","qty"=>100,"item_no"=>"1_M"},
				    {"style"=>"ITEM1","qty"=>100,"item_no"=>"1_L"},
				    {"style"=>"ITEM2","qty"=>100,"item_no"=>"2"},
				    ],{"SKU"=>"style","qty"=>"qty"},"item_no"
				   ),
	shipments=>$bl->create_shipments( [
		{
		ex_factory=>time-86400*8,
		at_port=>time-86400*7,
		available_to_ship=>time-86400*1,
		status=>"R",
		items=> $bl->create_items([
		
				    {"style"=>"ITEM1","qty"=>2,"item_no"=>"1_S"},
				    {"style"=>"ITEM1","qty"=>3,"item_no"=>"1_M"},
				    {"style"=>"ITEM1","qty"=>4,"item_no"=>"1_L"},
				    {"style"=>"ITEM2","qty"=>5,"item_no"=>2},
				    ],{"SKU"=>"style","qty"=>"qty"},"item_no"
				   ),	
		},
		{
		ex_factory=>time+86400,
		at_port=>time+86400*7,
		available_to_ship=>time+86400*8,
		items=> $bl->create_items([
				    {"style"=>"ITEM1","qty"=>20,"item_no"=>"1_S"},
				    {"style"=>"ITEM1","qty"=>20,"item_no"=>"1_M"},
				    {"style"=>"ITEM1","qty"=>20,"item_no"=>"1_L"},
				    {"style"=>"ITEM2","qty"=>20,"item_no"=>2},
				    ],{"SKU"=>"style","qty"=>"qty"},"item_no"
				   ),	
		},
		{
		ex_factory=>time+86400*10,
		at_port=>time+86400*15,
		available_to_ship=>time+86400*16,
		items=> $bl->create_items([

				    {"style"=>"ITEM1","qty"=>20,"item_no"=>"1_S"},
				    {"style"=>"ITEM1","qty"=>20,"item_no"=>"1_M"},
				    {"style"=>"ITEM1","qty"=>20,"item_no"=>"1_L"},

				    {"style"=>"ITEM2","qty"=>20,"item_no"=>2},
				    ],{"SKU"=>"style","qty"=>"qty"},"item_no"
				   ),	
		},
		{
		ex_factory=>time+86400*20,
		at_port=>time+86400*31,
		available_to_ship=>time+86400*32,
		items=> $bl->create_items([

				    {"style"=>"ITEM1","qty"=>20,"item_no"=>"1_S"},
				    {"style"=>"ITEM1","qty"=>20,"item_no"=>"1_M"},
				    {"style"=>"ITEM1","qty"=>20,"item_no"=>"1_L"},

				    {"style"=>"ITEM2","qty"=>20,"item_no"=>2},
				    ],{"SKU"=>"style","qty"=>"qty"},"item_no"
				   ),	
		},
		
		
		
		
		]		   
	),
   }
   ] );


$on_order_already = 11;

$available_date = time;

my ($Srecd_qty,$nSremg) = $bl->get_received_qty({"SKU"=>"ITEM1","size"=>"S","on_order"=>$on_order_already},$pos);
my ($Mrecd_qty,$nMremg) = $bl->get_received_qty({"SKU"=>"ITEM1","size"=>"M","on_order"=>$on_order_already},$pos);
my ($Lrecd_qty,$nLremg) = $bl->get_received_qty({"SKU"=>"ITEM1","size"=>"L","on_order"=>$on_order_already},$pos);


ok($Srecd_qty + $Mrecd_qty + $Lrecd_qty == 9,"Sizes test - $Srecd_qty $Mrecd_qty $Lrecd_qty ");


my $credit = new Business::Logic::Credit({code=>'BC123435',amount=>1000});

my $new_credit_items = $bl->create_items([{"style"=>"HAVANABLK","retail"=>398},{"style"=>"RAMONECBLK","retail"=>78}],{"SKU"=>"style","price"=>"retail"});

my $new_credit_cart = $bl->get_cart({"items"=>$new_credit_items});

my $order = new Business::Logic::Order({cart=>$new_credit_cart});

my ($subtotal,$tax,$shipping,$store_credit) = $order->get_order_totals();

$order->apply_store_credit($credit);

my $store_credit_total = $order->store_credit_total();

ok($store_credit_total == 487,"Store Credit Test: " . $store_credit_total . " " . $subtotal);

my $state = 'New. York';

my $address = new Business::Logic::Address({state=>$state});
$order->set_shipping_address($address);

$order->set_tax_rate({'US'=>{'NY'=>0.08875}});

my $ostate = $order->get_order_state();
my $ocountry = $order->get_order_country();

my $otaxrate = $order->get_tax_rate();
my $otaxamount = $order->get_order_tax();

my $tax_total = $order->get_order_taxable_total();

ok($ostate . ' ' . $ocountry . ' ' . $otaxrate . ' ' . $otaxamount . ' ' . $tax_total eq 'NY US 0.08875 42.25 476','testing tax rate amount etc. ' . $ostate . ' ' . $ocountry . ' ' . $otaxrate . ' ' . $otaxamount . ' ' . $tax_total);

# test it handles tax rate as > 1 properly


$order->set_tax_rate({'US'=>{'NY'=>8.875}});

$otaxamount = $order->get_order_tax();
$tax_total = $order->get_order_taxable_total();

ok($ostate . ' ' . $ocountry . ' ' . $otaxrate . ' ' . $otaxamount . ' ' . $tax_total eq 'NY US 0.08875 42.25 476','testing tax rate amount etc. ' . $ostate . ' ' . $ocountry . ' ' . $otaxrate . ' ' . $otaxamount . ' ' . $tax_total);

my $address2 = new Business::Logic::Address({state=>'CaLi.'});
$order->set_shipping_address($address2);

my $ostate2 = $order->get_order_state();
my $otaxamount2 = $order->get_order_tax();

# no tax! and found CA

ok($ostate2 . $otaxamount2 eq 'CA0','Testing that orderstate is CA: ' . $ostate2 . ' and tax amount is 0:' . $otaxamount2);

# california tax rate = 10% add this
  
$order->set_tax_rate({'US'=>{'NY'=>8.875,'CA'=>.10}});

my $otaxamount3 = $order->get_order_tax();

ok($otaxamount3 == 47.60,'Testing that tax amount is 10%:' . $otaxamount3);

my $company = new Business::Logic::Company({tax_rates=>{'US'=>{'CA'=>10}}});

$order->{'taxable'} = undef;

$order->set_company($company);

$order->set_tax_rate(undef);

my $otaxamount4 = $order->get_order_tax();

ok($otaxamount3 == 47.60,'Get order tax is ' . $otaxamount4);

my $new_items = $bl->create_items([{"style"=>"HAVANABLK","retail"=>398},{"style"=>"RAMONECBLK","retail"=>78}],{"SKU"=>"style","price"=>"retail"});

my $havanablk = $new_items->[0];

my $return_value = $havanablk->add_option({
option_name=>'Recipient Email',
option_text=>'Recipient E-Mail:',
option_type=>'text',
option_required=>'Y',
option_values=>'^[A-Za-z0-9\.\_\%\-]+\@[A-Za-z0-9\.\-]+\.[A-Za-z]{2,4}$You must enter a valid e-mail address.',
option_help=>'Enter the e-mail address to which you would like the e-gift card sent. You will also receive a copy in your inbox. You may enter your own e-mail address here and print out the gift card to give. If you do not receive your e-mail confirmation after you complete checkout, please contact customer service at 866 921-2247.',
option_order=>1,
});

my $options = $havanablk->{'options'}->hash_options();

my $option_id = $options->[0]->{'id'};

ok($option_id eq 'recipient_email','option id check ' . $option_id . ' ' . $return_value . '<');

my $options_ok = $havanablk->options_ok();

ok($options_ok == 0,'check default option processing');

my $option_values_input = {'query_recipient_email'=>'benatinvalidemail'};

$havanablk->assign_options_values($option_values_input);

my $rerror_message = $option_values_input->{'recipient_email_error'};

my $options_ok2 = $havanablk->options_ok();

ok($options_ok2 == 0,'check options value type');

$option_values_input = {'recipient_email'=>'ben@validemail.com'};

$havanablk->assign_options_values($option_values_input);

my $options_ok3 = $havanablk->options_ok();

ok($options_ok3 == 1,'check options value type, valid info');

ok($rerror_message eq 'You must enter a valid e-mail address.','error message test ' . $rerror_message);


my $option_values_input2 = {'HAVANABLK_recipient_email'=>'ben@validemail.com'};

$havanablk->assign_options_values($option_values_input2);

my $options_ok4 = $havanablk->options_ok();

ok($options_ok4 == 1,'sku + option_id testing ' . $options_ok4);


my $discount_staff1 = $bl->create_discount({"code"=>"STAFFDISCOUNT","SKU"=>"ALL","pct"=>"75","combines"=>"N","override"=>"N"});
my $discount_staff2 = $bl->create_discount({"code"=>"STAFFDISCOUNT","SKU"=>"HAVANABLK","pct"=>"50","combines"=>"N","override"=>"Y"});

my $test_items = $bl->create_items([{"style"=>"HAVANABLK","retail"=>398},{"style"=>"RAMONECBLK","retail"=>78}],{"SKU"=>"style","price"=>"retail"});

my $test_cart = $bl->get_cart({"items"=>$test_items});

$test_cart->add_discount($discount_staff1);
$test_cart->add_discount($discount_staff2);

my $the_test_total = $test_cart->total();

ok( $the_test_total == int((398*.50+78*.25)*100+.5)/100 , "cart total adds correctly for employee discount override " . $the_test_total);

# now reverse it
my $discount_staff3 = $bl->create_discount({"code"=>"STAFFDISCOUNT","SKU"=>"ALL","pct"=>"75","combines"=>"N","override"=>"N"});
my $discount_staff4 = $bl->create_discount({"code"=>"STAFFDISCOUNT","SKU"=>"HAVANABLK","pct"=>"50","combines"=>"N","override"=>"Y"});

my $test_items2 = $bl->create_items([{"style"=>"HAVANABLK","retail"=>398},{"style"=>"RAMONECBLK","retail"=>78}],{"SKU"=>"style","price"=>"retail"});

my $test_cart2 = $bl->get_cart({"items"=>$test_items2});

$test_cart2->add_discount($discount_staff4);
$test_cart2->add_discount($discount_staff3);

my $the_test_total2 = $test_cart2->total();

ok( $the_test_total2 == int((398*.50+78*.25)*100+.5)/100 , "reverse cart total adds correctly for employee discount override " . $the_test_total2);


my $items22 = $bl->create_items([{"style"=>"HAVANABLK","retail"=>398,"on_sale"=>'Y',"sale_price"=>100},{"style"=>"RAMONECBLK","retail"=>78}],{"SKU"=>"style","price"=>"retail","on_sale"=>"on_sale","sale_price"=>"sale_price"});

my $cart22 = $bl->get_cart({"items"=>$items22});

my $total22 = $cart22->total();

ok( $total22 == 100+78 , "on sale cart total adds correctly " . $total22);

my $discount22 = $bl->create_discount({"code"=>"HHTHANKSYOU","pct"=>"25","onsale_only"=>"Y"});

$cart22->add_discount($discount22);

$total22 = $cart22->total();

ok( $total22 == (100*.75+78) , "cart discounted total on sale only adds correctly " . $total22);

my $discount23 = $bl->create_discount({"code"=>"HHTHANKSYOU","pct"=>"25","fullprice_only"=>"Y","SKU"=>'ALL-ITEMS'});

$cart22->add_discount($discount23);

$total23 = $cart22->total();

ok( $total23 == (100*.75+78*.75) , "cart discounted total on sale and not on sale only adds correctly " . $total23 . " Should BE " . (100*.75+78*.75));

# BOGO

my $bogo_discount = $bl->create_discount({"code"=>"BOGO","pct"=>"100","bogo"=>"Y"});

my $bogo_items = $bl->create_items([{"style"=>"HAVANABLK","retail"=>398},{"style"=>"RAMONECBLK","retail"=>78},{"style"=>"HAVANABLK","retail"=>398}],{"SKU"=>"style","price"=>"retail"});

my $bogo_cart = $bl->get_cart({"items"=>$bogo_items});

$bogo_cart->add_discount($bogo_discount);

my $bogo_total = $bogo_cart->total();

ok( $bogo_total == (398 + 78) , "Buy One, Get One Total Should Add Up but adds to $bogo_total not " . (398 + 78) . "");

# BOGO should work on multiple items

$bogo_cart->add_item( $bl->create_item ( {"style"=>"RAMONECBLK","retail"=>78},{"SKU"=>"style","price"=>"retail"} ) );

$bogo_cart->remove_discount($bogo_discount->code);

my $bogo_discount2 = $bl->create_discount({"code"=>"BOGO2","pct"=>"100","bogo"=>"Y"});
$bogo_cart->add_discount($bogo_discount2);

$bogo_total = $bogo_cart->total();

ok( $bogo_total == (398 + 78) , "Buy One, Get One Total Should Add Up with second item, but adds to $bogo_total not " . (398 + 78) . "");

# BOGO same or lesser price

my $bogo_same_lesser_discount = $bl->create_discount({"code"=>"BOGO","pct"=>"100","bogo"=>"Y","bogo_needs"=>{"greedy"=>"Y","matchers"=>{"price" => { "type" => "<="}}}}) ;

my $bogo_test_items = $bl->create_items([{"style"=>"HAVANABLK","retail"=>398},{"style"=>"RAMONECBLK","retail"=>78},{"style"=>"ROCKYRED","retail"=>398}],{"SKU"=>"style","price"=>"retail"});

my $bogo_same_lesser_cart = $bl->get_cart({"items"=>$bogo_test_items});

$bogo_same_lesser_cart->add_discount($bogo_same_lesser_discount);

my $bogo_same_lesser_total = $bogo_same_lesser_cart->total();

ok( $bogo_same_lesser_total == (398 + 78) , "Buy One, Get One Same or Lesser Price Total Should Add Up but adds to $bogo_same_lesser_total not " . (398 + 78) . "");

# BOGO same or lesser price different order

my $bogo_same_lesser_discount_do = $bl->create_discount({"code"=>"BOGO","pct"=>"100","bogo"=>"Y","bogo_needs"=>{"greedy"=>"Y","matchers"=>{"price" => { "type" => "<="}}}}) ;

my $bogo_test_items_do = $bl->create_items([{"style"=>"HAVANABLK","retail"=>398},{"style"=>"ROCKYRED","retail"=>398},{"style"=>"RAMONECBLK","retail"=>78}],{"SKU"=>"style","price"=>"retail"});

my $bogo_same_lesser_cart_do = $bl->get_cart({"items"=>$bogo_test_items_do});

$bogo_same_lesser_cart_do->add_discount($bogo_same_lesser_discount_do);

my $bogo_same_lesser_total_do = $bogo_same_lesser_cart_do->total();

ok( $bogo_same_lesser_total_do == (398 + 78) , "Buy One, Get One Same or Lesser Price Total in different order Should Add Up but adds to $bogo_same_lesser_total_do not " . (398 + 78) . "");

# BOGO same or lesser price different order 2

my $bogo_same_lesser_discount_do2 = $bl->create_discount({"code"=>"BOGO","pct"=>"100","bogo"=>"Y","bogo_needs"=>{"greedy"=>"Y","matchers"=>{"price" => { "type" => "<="}}}}) ;

my $bogo_test_items_do2 = $bl->create_items([{"style"=>"HAVANABLK","retail"=>398},{"style"=>"HAVANAXLK","retail"=>498},{"style"=>"ROCKYRED","retail"=>398},{"style"=>"RAMONECBLK","retail"=>78}],{"SKU"=>"style","price"=>"retail"});

my $bogo_same_lesser_cart_do2 = $bl->get_cart({"items"=>$bogo_test_items_do2});

$bogo_same_lesser_cart_do2->add_discount($bogo_same_lesser_discount_do2);

my $bogo_same_lesser_total_do2 = $bogo_same_lesser_cart_do2->total();

ok( $bogo_same_lesser_total_do2 == (498 + 398) , "Buy One, Get One Same or Lesser Price Total in different order 2 Should Add Up but adds to $bogo_same_lesser_total_do2 not " . (498 + 398) . "");

# BOGO but only when you buy a style named handbag

my $bogo_handbag = $bl->create_discount({"code"=>"BOGO","pct"=>"100","bogo"=>"Y","bogo_needs"=>{"greedy"=>"Y","matchers"=>{"price" => { "type" => "<="}, "name" => { "type" => "has", "value" => "handBag"}}},"SKU" => "NAME=HaNdbag"}) ;

my $bogo_handbags = $bl->create_items([{"style"=>"HAVANABLK","name"=>"handbag","retail"=>398},{"style"=>"HAVANAXLK","name"=>"handbag","retail"=>498},{"style"=>"ROCKYRED","name"=>"handbag","retail"=>398},{"style"=>"RAMONECBLK","name"=>"cuff","retail"=>78},{"style"=>"RAMONECBLK","name"=>"cuff","retail"=>78}],{"SKU"=>"style","price"=>"retail"});

my $bogo_handbag_cart = $bl->get_cart({"items"=>$bogo_handbags});

$bogo_handbag_cart->add_discount($bogo_handbag);

my $bogo_handbag_total = $bogo_handbag_cart->total();

ok( $bogo_handbag_total == (498 + 398 + 78 + 78) , "Buy One, Get One Named handbag only adds to $bogo_handbag_total not " . (498 + 398 + 78 + 78) . "");

# Handle BOGO properly for qty 2 items

#my $bogo_handbag2 = $bl->create_discount({"code"=>"BOGO","pct"=>"100","bogo"=>"Y","bogo_needs"=>{"greedy"=>"Y","matchers"=>{"price" => { "type" => "<="}, "name" => { "type" => "has", "value" => "Handbag"}}},"SKU" => "NAME=Handbag"}) ;

#my $bogo_handbags2 = $bl->create_items([{"style"=>"HAVANABLK","name"=>"handbag","retail"=>398},{"style"=>"HAVANAXLK","name"=>"handbag","retail"=>498, "qty"=>2},{"style"=>"ROCKYRED","name"=>"handbag","retail"=>398},{"style"=>"RAMONECBLK","name"=>"cuff","retail"=>78},{"style"=>"RAMONECBLK","name"=>"cuff","retail"=>78}],{"SKU"=>"style","price"=>"retail"});

#my $bogo_handbag_cart2 = $bl->get_cart({"items"=>$bogo_handbags2});

#$bogo_handbag_cart2->add_discount($bogo_handbag2);

#my $bogo_handbag_total2 = $bogo_handbag_cart2->total();

#ok( $bogo_handbag_total2 == (498 + 498 + 78 + 78) , "Buy One, Get One Named handbag, qty 2 only adds to $bogo_handbag_total2 not " . (498 + 498 + 78 + 78) . "");

##### Payment Method

my $payment_method = Business::Logic::PaymentMethod->new();

my $number = '12345678910';

$payment_method->{'card_number'} = $number;

my $encrypted_number = $payment_method->encrypted_number('SALT1234SALT');

ok($encrypted_number ne $number);

my $decrypted_number = $payment_method->set_and_decrypt_number($encrypted_number,'SALT1234SALT');

ok($decrypted_number eq $number,'decrypt');

#### Business Logic

my $EDI = Business::Logic::EDI->new();

my $row = $EDI->row(['a','b','c']);

ok($row eq 'a~b~c*' . "\n", 'Row test - ' . $row);


#### Business Logic w/ minimum chars

$row = $EDI->row(['a','b','c'],[{size=>2,pad=>' '},{size=>2,pad=>' '},{size=>2,pad=>' '}]);

ok($row eq 'a ~b ~c *' . "\n", 'Padded row test - ' . $row);

#### Business Logic w/ minimum chars, left padding

$row = $EDI->row(['a','b','c'],[{size=>3,padleft=>' '},{size=>3,padleft=>' '},{size=>2,padleft=>' '}]);

ok($row eq '  a~  b~ c*' . "\n", 'Padded row test - ' . $row);

#### Business Logic w/ minimum chars, left and right padding, 0s

$row = $EDI->row(['a','b','c'],[{size=>3,padleft=>' '},{size=>3,padleft=>'0'},{size=>2,pad=>'0'}]);

ok($row eq '  a~00b~c0*' . "\n", 'Padded row test with 0s - ' . $row);

### Business Logic EDI large row test

my $row_data = ['ISA','0','','0','','12','6468311945','12','2123281560','140124','0900','U','00401','100002810','1','P','>'];

my $row_format = [{size=>3},{size=>2,pad=>'0'},{size=>10},{size=>2,pad=>'0'},{size=>10},{size=>2,padleft=>'0'},{size=>15,pad=>' '},{size=>2,pad=>'0'},{size=>15,pad=>' '}];

$row = $EDI->row($row_data,$row_format);

ok($row eq 'ISA~00~          ~00~          ~12~6468311945     ~12~2123281560     ~140124~0900~U~00401~100002810~1~P~>*' . "\n", 'Full row definition - ' . $row);

#######

my ($sec,$min,$hour,$mday,$mon,$year,$wday,$yday,$isdst) = localtime(time);

$mon++;
if($mon < 10){$mon = '0' . $mon;}
if($mday < 10){$mday = '0' . $mday;}

$year += 1900;

my $two_digit_year = sprintf("%02d", $year % 100);

my $isa_date = $two_digit_year . $mon . $mday;		    


$EDI->{'sender'} = '6468311945';
$EDI->{'recipient'} = '2123281560';

my $edi850 = $EDI->edi_850(27);

my $test_edi850 = qq[ISA~00~          ~00~          ~12~6468311945     ~12~2123281560     ~$isa_date~0900~U~00401~000000027~1~P~>*
IEA~1~000000027*
];

ok($edi850 eq $test_edi850,"EDI 850 Test, No Items " . $edi850);


##########

$EDI->{'sender'} = '6468311946';
$EDI->{'recipient'} = '2123281561';

$edi850 = $EDI->edi_850(27);

$test_edi850 = qq[ISA~00~          ~00~          ~12~6468311946     ~12~2123281561     ~$isa_date~0900~U~00401~000000027~1~P~>*
IEA~1~000000027*
];

ok($edi850 eq $test_edi850,"EDI 850 Test, No Items change receipient" . $edi850);

#### One order, with a customer, no items

my $edi_address = new Business::Logic::Address({firstname=>'Test',lastname=>'Name',address=>'123 anywhere lane',address2=>'apartment #2', city=>'city', state=>'ST', zip=>'12345'});

my $edi_customer = new Business::Logic::Customer({customer_name=>'Test Name'});

my $edi_order = new Business::Logic::Order({shipping_address=>$edi_address, order_number=>54, customer=> $edi_customer});

$edi_order->{'id'} = $edi_order->get_order_number();
$EDI->add_item($edi_order);

$edi850 = $EDI->edi_850(27);

$test_edi850 = qq[ISA~00~          ~00~          ~12~6468311946     ~12~2123281561     ~$isa_date~0900~U~00401~000000027~1~P~>*
GS~PO~6468311946~2123281561~20$isa_date~0900~0001~X~004010VICS*
ST~850~000000054*
BEG~00~SA~54~~20$isa_date~~~~~~~DP*
REF~DP~WEBSITE*
PER~DC~Test Name*
N1~ST~Test Name~92~9999*
N3~123 anywhere lane~apartment #2*
N4~city~ST~12345~US*
CTT~0~0*
SE~9~000000054*
GE~1~0001*
IEA~1~000000027*
];

ok($edi850 eq $test_edi850,"EDI 850 Test, No Items, one order >" . $edi850 . "< != >" . $test_edi850 . "<");

##### one item, no billing, no shipping


my $edi_items = $bl->create_items([{"style"=>"HS14116-18","retail"=>248}],{"SKU"=>"style","price"=>"retail"});

$edi_items->[0]->{'UPC'} = '848673023250';
$edi_items->[0]->{'name'} = 'Juliette Tote, Tan Saffiano';

my $edi_cart = $bl->get_cart({"items"=>$edi_items});

$edi_order->{'cart'} = $edi_cart;

$edi850 = $EDI->edi_850(27);

$test_edi850 = qq[ISA~00~          ~00~          ~12~6468311946     ~12~2123281561     ~$isa_date~0900~U~00401~000000027~1~P~>*
GS~PO~6468311946~2123281561~20$isa_date~0900~0001~X~004010VICS*
ST~850~000000054*
BEG~00~SA~54~~20$isa_date~~~~~~~DP*
REF~DP~WEBSITE*
PER~DC~Test Name*
N1~ST~Test Name~92~9999*
N3~123 anywhere lane~apartment #2*
N4~city~ST~12345~US*
PO1~0001~1~EA~248~~UP~848673023250*
PID~F~08~~~Juliette Tote, Tan Saffiano (HS14116-18) - 1*
CTT~1~248*
SE~11~000000054*
GE~1~0001*
IEA~1~000000027*
];

ok($edi850 eq $test_edi850,"EDI 850 Test, one item, one order >" . $edi850 . "< != >" . $test_edi850 . "<");

##### handle two items properly

my $new_edi_items = $bl->create_items([{"style"=>"HS14116-19","retail"=>250}],{"SKU"=>"style","price"=>"retail"});
$new_edi_items->[0]->{'UPC'} = '848673023251';
$new_edi_items->[0]->{'name'} = 'Juliette Tote, Red Saffiano';

$edi_cart->add_item($new_edi_items->[0]);


$edi850 = $EDI->edi_850(27);

$test_edi850 = qq[ISA~00~          ~00~          ~12~6468311946     ~12~2123281561     ~$isa_date~0900~U~00401~000000027~1~P~>*
GS~PO~6468311946~2123281561~20$isa_date~0900~0001~X~004010VICS*
ST~850~000000054*
BEG~00~SA~54~~20$isa_date~~~~~~~DP*
REF~DP~WEBSITE*
PER~DC~Test Name*
N1~ST~Test Name~92~9999*
N3~123 anywhere lane~apartment #2*
N4~city~ST~12345~US*
PO1~0001~1~EA~248~~UP~848673023250*
PID~F~08~~~Juliette Tote, Tan Saffiano (HS14116-18) - 1*
PO1~0002~1~EA~250~~UP~848673023251*
PID~F~08~~~Juliette Tote, Red Saffiano (HS14116-19) - 1*
CTT~2~498*
SE~13~000000054*
GE~1~0001*
IEA~1~000000027*
];

ok($edi850 eq $test_edi850,"EDI 850 Test, two items, one order >" . $edi850 . "< != >" . $test_edi850 . "<");

##### handle qty of two


$new_edi_items->[0]->{'qty'} = 2;

$edi850 = $EDI->edi_850(27);

$test_edi850 = qq[ISA~00~          ~00~          ~12~6468311946     ~12~2123281561     ~$isa_date~0900~U~00401~000000027~1~P~>*
GS~PO~6468311946~2123281561~20$isa_date~0900~0001~X~004010VICS*
ST~850~000000054*
BEG~00~SA~54~~20$isa_date~~~~~~~DP*
REF~DP~WEBSITE*
PER~DC~Test Name*
N1~ST~Test Name~92~9999*
N3~123 anywhere lane~apartment #2*
N4~city~ST~12345~US*
PO1~0001~1~EA~248~~UP~848673023250*
PID~F~08~~~Juliette Tote, Tan Saffiano (HS14116-18) - 1*
PO1~0002~2~EA~250~~UP~848673023251*
PID~F~08~~~Juliette Tote, Red Saffiano (HS14116-19) - 2*
CTT~3~748*
SE~13~000000054*
GE~1~0001*
IEA~1~000000027*
];

ok($edi850 eq $test_edi850,"EDI 850 Test, two items, one order >" . $edi850 . "< != >" . $test_edi850 . "<");


$edi_cart->remove_item('',$new_edi_items->[0]->SKU);

##### add billing information

my $edi_billing_address = new Business::Logic::Address({firstname=>'Test',lastname=>'Name',address=>'123 anywhere lane',address2=>'apartment #3', city=>'city', state=>'ST', zip=>'12346'});

$edi_order->{'billing_address'} = $edi_billing_address;
$edi850 = $EDI->edi_850(27);

$test_edi850 = qq[ISA~00~          ~00~          ~12~6468311946     ~12~2123281561     ~$isa_date~0900~U~00401~000000027~1~P~>*
GS~PO~6468311946~2123281561~20$isa_date~0900~0001~X~004010VICS*
ST~850~000000054*
BEG~00~SA~54~~20$isa_date~~~~~~~DP*
REF~DP~WEBSITE*
PER~DC~Test Name*
N1~ST~Test Name~92~9999*
N3~123 anywhere lane~apartment #2*
N4~city~ST~12345~US*
MSG~BT: Test Name 123 anywhere lane apartment #3 city ST 12346 US*
PO1~0001~1~EA~248~~UP~848673023250*
PID~F~08~~~Juliette Tote, Tan Saffiano (HS14116-18) - 1*
CTT~1~248*
SE~12~000000054*
GE~1~0001*
IEA~1~000000027*
];

ok($edi850 eq $test_edi850,"EDI 850 Test, one item, one order, billing info >" . $edi850 . "< != >" . $test_edi850 . "<");

#### shipping method

$edi_order->{'cart'}->set_shipping_method('UPS Ground');

$edi850 = $EDI->edi_850(27);

$test_edi850 = qq[ISA~00~          ~00~          ~12~6468311946     ~12~2123281561     ~$isa_date~0900~U~00401~000000027~1~P~>*
GS~PO~6468311946~2123281561~20$isa_date~0900~0001~X~004010VICS*
ST~850~000000054*
BEG~00~SA~54~~20$isa_date~~~~~~~DP*
REF~DP~WEBSITE*
PER~DC~Test Name*
N1~ST~Test Name~92~9999*
N3~123 anywhere lane~apartment #2*
N4~city~ST~12345~US*
MSG~BT: Test Name 123 anywhere lane apartment #3 city ST 12346 US*
MSG~S: UPS Ground 10.00*
PO1~0001~1~EA~248~~UP~848673023250*
PID~F~08~~~Juliette Tote, Tan Saffiano (HS14116-18) - 1*
TD5~~~~~~~~~~~~SI*
CTT~1~248*
SE~14~000000054*
GE~1~0001*
IEA~1~000000027*
];

ok($edi850 eq $test_edi850,"EDI 850 Test, one item, one order, billing info, shipping method >" . $edi850 . "< != >" . $test_edi850 . "<");

#### Phone #

$edi_address->{'phone'} = '7145551271';

$edi850 = $EDI->edi_850(27);

$test_edi850 = qq[ISA~00~          ~00~          ~12~6468311946     ~12~2123281561     ~$isa_date~0900~U~00401~000000027~1~P~>*
GS~PO~6468311946~2123281561~20$isa_date~0900~0001~X~004010VICS*
ST~850~000000054*
BEG~00~SA~54~~20$isa_date~~~~~~~DP*
REF~DP~WEBSITE*
PER~DC~Test Name*
N1~ST~Test Name~92~9999*
N3~123 anywhere lane~apartment #2*
N4~city~ST~12345~US*
PER~IC~~TE~7145551271*
MSG~BT: Test Name 123 anywhere lane apartment #3 city ST 12346 US*
MSG~S: UPS Ground 10.00*
PO1~0001~1~EA~248~~UP~848673023250*
PID~F~08~~~Juliette Tote, Tan Saffiano (HS14116-18) - 1*
TD5~~~~~~~~~~~~SI*
CTT~1~248*
SE~15~000000054*
GE~1~0001*
IEA~1~000000027*
];

ok($edi850 eq $test_edi850,"EDI 850 Test, one item, one order, billing info, shipping method, phone # >" . $edi850 . "< != >" . $test_edi850 . "<");
