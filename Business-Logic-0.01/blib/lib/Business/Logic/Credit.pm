package Business::Logic::Credit;

use 5.010001;
use strict;
use warnings;

use Carp;

require Exporter;

our @ISA = qw(Exporter);

# Items to export into callers namespace by default. Note: do not export
# names by default without a very good reason. Use EXPORT_OK instead.
# Do not simply export all your public functions/methods/constants.

# This allows declaration	use Business::Logic::Credit ':all';
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

sub new
{
    my($class, $params,$map) = @_;
    
    $map = (defined $map ? $map : {});
    
    my $parameters = {
	expires=>0,
	amount=>0,
	uses=>{},
	code=>'',
	id=>0,
    };

    my $self = {};
    foreach my $parameter (keys %$parameters)
    {
	$self->{$parameter} = q_map($params,q_map($map,$parameter),$parameters->{$parameter});
    }
    $self->{'data'} = $params;
    
    bless($self, $class);
    return $self;
}

sub expires
{
    my ($self) = @_;
    
    my $expires = $self->{'expires'};
    
    return ($expires);
}

sub amount
{
    my ($self) = @_;
    
    my $expires = $self->{'expires'};
    
    if($expires > 0)
    {
	if(time > $expires)
	{
	    return 0; # this code is expired
	}
    }
    
    return ($self->{'amount'});
}

sub code
{
    my ($self) = @_;
    return ($self->{'code'});
}

sub id
{
    my ($self) = @_;
    return ($self->{'id'});
}

sub get_credits_applied
{
    my ($self) = @_;
    
    return ($self->{'used'});
}

sub set_credits_applied
{
    my ($self,$hash) = @_; # hash of credits applied
    
    foreach my $key (keys %{$hash})
    {
	$self->set_credit_applied($hash->{$key},$key);
    }
}

sub set_credit_applied
{
    my ($self,$amount,$order) = @_;
    
    if(!defined($amount)){$amount = 0;}
       
    $self->{'uses'}->{$order} = $amount;
}

sub credit_applied
{
    my ($self,$order) = @_;
    
    my $order_number = $order->get_cart()->cart_id();
    
    # return amount of credit applied to an order
    return ($self->{'uses'}->{$order_number});
}

sub credit_remaining
{
    my ($self) = @_;
    
    my $original_amount = $self->amount();

    my $uses = $self->{'uses'};
    
    foreach my $key (keys %{$uses})
    {
	my $used = $uses->{$key};
	
	if(defined $used)
	{
	    $original_amount -= $used;
	}
    }
    
    return ($original_amount); # remaining amount
}

sub remove_credit
{
    my ($self,$order) = @_;
    
    my $order_number = $order->get_cart()->cart_id();
    
    $self->{'uses'}->{$order_number} = 0;
}

sub calculate_amount
{
    my ($self,$order,$running_total) = @_;
    
    my $order_number = $order->get_cart()->cart_id();
    
    # first is it already applied?
    # remove the amount
    $self->{'uses'}->{$order_number} = 0;
    
    # calculate how much credit to apply to an order
    my $amount_remaining = $self->credit_remaining();
    my $amount_to_apply = 0;
    
    if($amount_remaining >= $running_total)
    {
	$amount_to_apply = $running_total;
    }
    else
    {
	$amount_to_apply = $amount_remaining;
    }
    
    # apply the amount
    $self->{'uses'}->{$order_number} = $amount_to_apply;
    
    # return the amount
    return ($amount_to_apply);
}

sub is
{
    my ($self,$compare) = @_;
    
    if($self->{'code'} eq $compare->code())
    {
	return(1); #yes I is!
    }
    # is I the same credit as the one applied?
    
    return(0); #no I isn't
}

1;
__END__
# Below is stub documentation for your module. You'd better edit it!

=head1 NAME

Business::Logic::Credit - Perl extension for blah blah blah

=head1 SYNOPSIS

  use Business::Logic::Credit;
  blah blah blah

=head1 DESCRIPTION

Stub documentation for Business::Logic::Credit, created by h2xs. It looks like the
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
