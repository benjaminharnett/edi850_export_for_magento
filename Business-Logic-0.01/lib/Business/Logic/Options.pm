package Business::Logic::Options;

use 5.010001;
use strict;
use warnings;

use Carp;

require Exporter;

our @ISA = qw(Exporter);

# Optionss to export into callers namespace by default. Note: do not export
# names by default without a very good reason. Use EXPORT_OK instead.
# Do not simply export all your public functions/methods/constants.

# This allows declaration	use Business::Logic::Options ':all';
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
	options=>{},
    };

    my $self = {};
    foreach my $parameter (keys %$parameters)
    {
	$self->{$parameter} = q_map($params,q_map($map,$parameter),$parameters->{$parameter});
	
	# there must be an easier way
	if($self->{$parameter} eq $parameter && $parameter ne 'in_cart')
	{
	    $self->{$parameter} = undef;
	}
    }
    
    $self->{'data'} = $params;

    bless($self, $class);
    return $self;
}

sub add_option
{
    my ($self,$option) = @_;
    
    my $option_id = $option->get_id();
    $self->{'options'}->{$option_id} = $option;
    
    return (1); #success
}

sub remove_option
{
    my ($self,$option) = @_;
    
    my $option_id = $option->get_id();
    $self->{'options'}->{$option_id} = undef;
    
    return (1); #success
}

sub has_options
{
    my ($self) = @_;
    
    foreach my $option_id (keys %{$self->{'options'}})
    {
	my $option = $self->{'options'}->{$option_id};
	if(defined $option)
	{
	    return (1);
	}
    }
    return 0;
}

sub options_ok
{
    my ($self) = @_;
    
    foreach my $option_id (keys %{$self->{'options'}})
    {
	my $option = $self->{'options'}->{$option_id};
	
	if(!$option->is_ok())
	{
	    return (0); # not ok
	}
    }

    return (1); # yes options are ok
}

sub assign_values
{
    my ($self,$values,$item) = @_;
    
    my $item_no = undef;
    
    if(defined $item)
    {
	# search for values from style & item_no
	$item_no = $item->{'item_no'};
	
	if(!defined $item_no || $item_no == 0)
	{
	    $item_no = $item->SKU;
	}
	
    }
    
    foreach my $option_id (keys %{$self->{'options'}})
    {
	my $option = $self->{'options'}->{$option_id};
	my $value = undef;
	
	if(defined $item_no && defined $values->{$item_no . '_' . $option_id})
	{
	    $value = $values->{$item_no . '_' . $option_id};
	
	}
	elsif(defined $item_no && defined $values->{'query_' . $item_no . '_' . $option_id})
	{
	    $value = $values->{'query_' . $item_no . '_' . $option_id};
	}
	elsif(defined $values->{$option_id})
	{
	    $value = $values->{$option_id};
	}
	elsif(defined $values->{'query_' . $option_id})
	{
	    $value = $values->{'query_' . $option_id};
	}
	

	my ($res,$err) = $option->set_value($value);
	
	if(defined $err)
	{
	    $values->{$option_id . '_error'} = $err;
	    $values->{'options_set_error'} = 1;
	}
    }
}

sub hash_options
{
    my ($self) = @_;
    
    my $options = [];
    
    foreach my $option_id (keys %{$self->{'options'}})
    {
	my $option = $self->{'options'}->{$option_id};
    
	push @{$options},$option->hash_option();
    }
    
    return $options;
}

1;
__END__
# Below is stub documentation for your module. You'd better edit it!

=head1 NAME

Business::Logic::Options - Perl extension for blah blah blah

=head1 SYNOPSIS

  use Business::Logic::Options;
  blah blah blah

=head1 DESCRIPTION

Stub documentation for Business::Logic::Options, created by h2xs. It looks like the
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
