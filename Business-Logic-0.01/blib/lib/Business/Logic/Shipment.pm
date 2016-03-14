package Business::Logic::Shipment;

use 5.010001;
use strict;
use warnings;

use Carp;

require Exporter;

our @ISA = qw(Exporter);

# Items to export into callers namespace by default. Note: do not export
# names by default without a very good reason. Use EXPORT_OK instead.
# Do not simply export all your public functions/methods/constants.

# This allows declaration	use Business::Logic::Shipment ':all';
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
	items=>{},
	ex_factory=>time,
	at_port=>time+86400*7,
	available_to_ship=>time+86400*14,
	invoice=>undef,
	shipping_invoice=>undef,
	shipping_cost=>0,
	shipped_via=>"unspecified",
	status=>"", # pending, shipped, received
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

sub received
{
    my ($self) = @_;
    
    my $status = $self->{"status"};
    
    if($status eq "R")
    {
	return (1);
    }
    else
    {
	return (0);
    }
}    

sub qty
{
    my ($self,$item_number) = @_;
    
    if(defined $self->{"items"})
    {
	my $item = $self->{"items"}->{$item_number};
	
	return ($item->{"qty"});
    }
    else
    {
	return (0);
    }
}

sub pending
{
    my ($self) = @_;
    
    my $status = $self->{"status"};
    
    if($status eq "S" || $status eq "P" || $status eq "")
    {
	return (1);
    }
    else
    {
	return (0);
    }
}

sub date
{
    my ($self) = @_;
    
    return ($self->{"available_to_ship"});
}

1;
__END__
# Below is stub documentation for your module. You'd better edit it!

=head1 NAME

Business::Logic::Shipment - Perl extension for blah blah blah

=head1 SYNOPSIS

  use Business::Logic::Shipment;
  blah blah blah

=head1 DESCRIPTION

Stub documentation for Business::Logic::Shipment, created by h2xs. It looks like the
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
