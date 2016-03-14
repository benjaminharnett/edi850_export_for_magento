package Business::Logic::Option;

use 5.010001;
use strict;
use warnings;

use Carp;

require Exporter;

our @ISA = qw(Exporter);

# Options to export into callers namespace by default. Note: do not export
# names by default without a very good reason. Use EXPORT_OK instead.
# Do not simply export all your public functions/methods/constants.

# This allows declaration	use Business::Logic::Option ':all';
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
	option_name=>undef,
	option_text=>undef,
	option_type=>undef,
	option_required=>'N',
	option_values=>undef,
	option_help=>undef,
	option_order=>undef,
	option_value=>undef,
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

sub get_value
{
    my ($self) = @_;
    return ($self->{'option_value'});
}

sub check_value
{
    my ($self,$value) = @_;
    
    my $option_values = $self->{'option_values'};
    
    my $ok = 1;
    my $error = undef;
    
    my @values = split(/\n/,$option_values);
    
    foreach my $val (@values)
    {
	my ($v,$e) = split(/\$/,$val,2);
	
	if(defined $e)
	{
	    my $re = qr/$v/;
	    
	    if ($value !~ $re)
	    {
		return (0,$e);
	    }
	}
    }

    return ($ok,$error);
}

sub set_value
{
    my ($self,$value) = @_;
    
    my $result = 0;
    my $error = 'Unknown error.';
    
    ($result,$error) = $self->check_value($value);
    
    if($result == 1)
    {
	$self->{'option_value'} = $value;
	$self->{'error'} = undef;
    }
    else
    {
	$self->{'error'} = $error;
	$self->{'option_value'} = undef;
	$self->{'error_value'} = $value;
    }
    
    return ($result,$error);
}

sub is_ok
{
    my ($self) = @_;

    if(!defined $self->{'option_required'} || $self->{'option_required'} eq 'N')
    {
	return (1); # everything fine
    }
    else
    {
	if(defined $self->{'option_value'} && $self->{'option_value'} ne '')
	{
	    return (1);
	}
    }
    
    return (0); # not fine!
}

sub hash_option
{
    my ($self) = @_;
    
    my $option_id = $self->get_id();
    
    my $option_text = $self->{'option_text'};
    my $option_value = $self->{'option_value'};
    
    if(!defined $option_value)
    {
	$option_value = $self->{'error_value'};
    }

    my $option_name = $self->{'option_name'};
    my $option_values = $self->{'option_values'};
    my $option_order = $self->{'option_order'};
    my $option_help = $self->{'option_help'};
    my $option_type = $self->{'option_type'};
    my $option_required = $self->{'option_required'};
    my $error = $self->{'error'};
    
    if(defined $option_value && $option_value ne '' && defined $option_values && grep(/\<option\>$option_value/i,$option_values))
    {
	$option_values =~ s/\<option\>$option_value/\<option selected\>$option_value/i;
    }

    my $option = {};
    $option->{'id'} = $option_id;
    $option->{'text'} = $option_text;
    $option->{'value'} = $option_value;
    $option->{'name'} = $option_name;
    $option->{'values'} = $option_values;
    $option->{'order'} = $option_order;
    $option->{'help'} = $option_help;
    $option->{'type'} = $option_type;
    $option->{'required'} = $option_required;
    $option->{'error'} = $error;

    return ($option);
}

sub get_id
{
    my ($self) = @_;
    
    if(!defined $self->{'option_id'})
    {
	my $option_id = $self->{'option_name'};
	$option_id =~ tr/A-Z/a-z/;
	$option_id =~ s/\W/\_/gs;
	$self->{'option_id'} = $option_id;
    }
    
    return ($self->{'option_id'});    
}

1;
__END__
# Below is stub documentation for your module. You'd better edit it!

=head1 NAME

Business::Logic::Option - Perl extension for blah blah blah

=head1 SYNOPSIS

  use Business::Logic::Option;
  blah blah blah

=head1 DESCRIPTION

Stub documentation for Business::Logic::Option, created by h2xs. It looks like the
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
