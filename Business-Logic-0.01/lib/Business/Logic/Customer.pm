package Business::Logic::Customer;

use 5.010001;
use strict;
use warnings;

use Carp;

require Exporter;

use Business::Logic;
use Business::Logic::Address;

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
	default_billing_address=>undef,
	default_shipping_address=>undef,
	addresses=>undef,
	default_payment_method=>undef,
	payment_methods=>undef,
	customer_name=>'',
	customer_phone=>'',
	customer_email=>'',
	mailing_list=>'N',
	remember=>'N', # remember the information
	customer_number=>undef,
	company=>undef, # for generating customer #s
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

sub customer_name
{
    my ($self) = @_;
    
    my $customer_name = $self->{'customer_name'};
    
    my ($first_name,$last_name) = split(/\s/,$customer_name,2);
    
    return ($customer_name,$first_name,$last_name);
}

sub customer_number
{
    my ($self,$customer_number) = @_;
    
    if(defined $customer_number)
    {
	$self->{'customer_number'} = $customer_number;
	return (1);
    }
    else
    {
        $customer_number = $self->{'customer_number'};
	
	if(!defined $customer_number)
	{
	    if(defined $self->{'company'})
	    {
		$customer_number = $self->{'company'}->get_next_customer_number();
	    }
	    else
	    {
		# random number
		$customer_number = time . int(rand(time)) . int(rand(100));
	    }
	}
	
	$self->{'customer_number'} = $customer_number;
	return $customer_number;
    }
}

sub get_email
{
    my ($self) = @_;
    
    return ($self->customer_email());
}

sub customer_email
{
    my ($self,$email) = @_;
    
    if(defined $email)
    {
	$self->{'customer_email'} = $email;
    }
    else
    {
	if(defined $self->{'customer_email'})
	{
	    return $self->{'customer_email'};
	}
	else
	{
	    if(defined $self->{'default_billing_address'})
	    {
		$self->{'customer_email'} = $self->{'default_billing_address'}->get_email();
		return $self->{'customer_email'};
	    }
	    else
	    {
		return undef;
	    }
	}
    }
}

sub add_to_email_list
{
    my ($self,$y_or_n) = @_;
    
    if(defined $y_or_n)
    {
	$self->{'mailing_list'} = $y_or_n;
    }
    else
    {
	if(defined $self->{'mailing_list'} && ($self->{'mailing_list'} eq 'Y' || $self->{'mailing_list'}))
	{
	    return 1; # yes!
	}
	else
	{
	    return 0;
	}
    }
    
}

# has all required fields
sub is_complete
{
    my ($self) = @_;
    
    if(defined $self->{'customer_name'} && $self->{'customer_name'} ne '')
    {
	my $email = $self->customer_email();
	
	if(defined $email && grep(/\@/,$email))
	{
	    my $phone = $self->{'customer_phone'};
	    
	    if(defined $phone && grep(/\d/,$phone))
	    {
		# has at least one digit, email w/ @ and name
		return (1);
	    }
	}
    }
    
    return (0);
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
