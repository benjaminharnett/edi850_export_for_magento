package Business::Logic::Company;

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

# This allows declaration	use Business::Logic::Company ':all';
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
	company_name=>undef,
	support_email=>undef,
	company_phone=>undef,
	company_website=>undef,
	company_address=>undef,
	company_address2=>undef,
	company_city=>undef,
	company_state=>undef,
	company_zip=>undef,
	company_country=>undef,
	company_contact=>undef,
	company_states=>undef, # for sales tax purposes
	order_number_generator=>undef,
	customer_number_generator=>undef,
	shipping_options=>undef,
	tax_rates=>undef,
	shipping_taxable=>undef,
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


sub get_company_states
{
    my ($self) = @_;
    
    my $company_state = $self->{'company_state'};
    my $company_states = $self->{'company_states'};
    
    if(!defined $company_states)
    {
	$company_states = {};
	$self->{'company_states'} = $company_states;
    }
    
    $company_states->{$company_state} = 1;
    
    return ($company_states);
    
}

sub get_company_country # only built to handle company homed in one country
{
    my ($self) = @_;
    
    return (Business::Logic::Address->uniform_country_code(undef,$self->{'country'}));
}

sub default_per_item_shipping # default to $1
{
    my ($self,$per_item_shipping) = @_;
    
    if(defined $per_item_shipping)
    {
	$self->{'per_item_shipping'} = $per_item_shipping;
	return (1);
    }
    else
    {
	return ($self->{'per_item_shipping'} ? $self->{'per_item_shipping'} : 1);
    }
}

sub default_first_item_shipping # default to $10
{
    my ($self,$first_item_shipping) = @_;
    
    if(defined $first_item_shipping)
    {
	$self->{'first_item_shipping'} = $first_item_shipping;
	return (1);
    }
    else
    {
	return ($self->{'first_item_shipping'} ? $self->{'first_item_shipping'} : 1);
    }
}

sub is_order_taxable
{
    my ($self,$order) = @_;
    
    my $order_state = $order->get_order_state();
    my $company_states = $self->get_company_states();
    
    my $order_country = $order->get_order_country();
    
    if($order_country eq $self->get_company_country())
    {
	if($company_states->{$order_state}) # order w/i nexus
	{
	    return (1); # taxable
	}    
	else
	{
	    return (0);
	}
    }
    else
    {
	return (0);
    }
}

sub add_shipping_method
{
    my ($self,$shipping_method) = @_;
    
    my $shipping_methods = $self->{'shipping_methods'};
    
    my $country = $shipping_method->get_valid_country();
    
    if(!defined $shipping_methods){
	$shipping_methods = {};
	$self->{'shipping_methods'} = $shipping_methods;
    }
    
    my $method_list = $shipping_methods->{$country};
    
    if(!defined $method_list){
	$method_list = [];
	$shipping_methods->{$country} = $method_list;
    }
    
    push @{$method_list},$shipping_method;
}

sub get_shipping_taxable
{
    my ($self) = @_;
    
    if(defined $self->{'shipping_taxable'})
    {
	return ($self->{'shipping_taxable'});
    }
    else
    {
	return undef;
    }
    
}

sub get_tax_rate
{
    my ($self) = @_;
    
    if(defined $self->{'tax_rates'})
    {
	return ($self->{'tax_rates'});
    }
    else
    {
	return undef;
    }
}

sub get_shipping_methods
{
    my ($self,$country) = @_;
    
    my $shipping_methods = $self->{'shipping_methods'};
    
    if(!defined $shipping_methods){$shipping_methods={};} 

    if(!defined $country)
    {
	my $method_list = $shipping_methods->{$self->get_company_country()};
	if(!defined $method_list){$method_list = [];}
	return $method_list;
    }
    else
    {
	my $method_list = $shipping_methods->{$country};
	if(!defined $method_list){$method_list = [];}
	return $method_list;
    }
}

sub get_next_order_number
{
    my ($self) = @_;
    
    if(defined $self->{'order_number_generator'})
    {
	# execute the generator
	return $self->{'order_number_generator'}->();
    }
    else
    {
	# large random number
	return time . int(rand(time)) . int(rand(100));
    }
    
}

sub get_next_customer_number
{
    my ($self) = @_;
    
    if(defined $self->{'customer_number_generator'})
    {
	# execute the generator
	return $self->{'customer_number_generator'}->();
    }
    else
    {
	# large random number
	return time . int(rand(time)) . int(rand(100));
    }
    
}


# default item shipping

sub charge_order
{
    my ($self,$order,$mock) = @_;
    
    my $result = 'APPROVED';
    my $error = '';

    my $details = {};
    
    if(defined $mock)
    {
	$result = $mock->{'result'};
	$error = $mock->{'error'};
	$details = $mock;
    }
    else
    {
	($result,$error,$details) = $self->do_charge_order($order)
	
    }

    return ($result,$error,$details);
}

# generic order charge
sub do_charge_order
{
    my ($self,$order) = @_;
    
    use LWP::UserAgent;
 
    my $url = $order->{'url'};
    
    my $ua = LWP::UserAgent->new;
    my $res = $ua->post($url, [
		     'UMkey' => $order->{'key'},
		     'UMname' => $order->customer_name(),
		     'UMcard' => "4444555566667779",
		     'UMexpir' => "0113",
		     'UMcvv2' => "999",
		     'UMamount' => "5.50",
		     'UMinvoice' => "123456",
		     'UMstreet' => "1234 Main Street",
		     'UMzip' => "12345",
		     'UMcommand' => 'cc:sale'
		 ]);
    
    # unfinished #TO DO!
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
