package Business::Logic::Discount;

use 5.010001;
use strict;
use warnings;

use Carp;

require Exporter;

our @ISA = qw(Exporter);

# Items to export into callers namespace by default. Note: do not export
# names by default without a very good reason. Use EXPORT_OK instead.
# Do not simply export all your public functions/methods/constants.

# This allows declaration	use Business::Logic::Discount ':all';
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
	expires=>time+86400,
	cart_only=>'N',
	SKU=>'ALL',
	ignore=>'N',
	floor=>0,
	needs=>'',
	onsale_only=>'N',
	fullprice_only=>'N',
	instock_only=>'N',
	combines=>'Y',
	fullprice=>'N',
	pct=>0,
	code=>'DISCOUNTCODE',
	uses=>0,
	use_counter=>[0,0],
	override=>'N',
	bogo=>'N',
	bogo_needs=>'',
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


sub reset
{
    my ($self,@p) = @_;
    
    my $level = 0;
    if(ifdef($p[0],'') eq 'F'){$level = 1;}

    if($self->{'needs'} ne '' && defined $self->{'needs'}->{'exclude'})
    {
	$self->{'needs'}->{'exclude'} = {};
    }

    if($self->{'bogo_needs'} ne '' && defined $self->{'bogo_needs'}->{'exclude'})
    {
	$self->{'bogo_needs'}->{'exclude'} = {};
    }
    
    unless($level == 1)
    {
	$self->{'use_counter'} = [0,0];
    }
}

sub needs
{
    my ($self,@p) = @_;
    
    if(defined $p[0] && $p[0] ne 'SKU') { $self->{'needs'} = $p[0]; }
    
    if(!defined $p[0] || $p[0] ne 'SKU')
    {
	return ($self->{'needs'} ne '' ? 1 : 0);
    }
    else
    {
	return ($self->{'needs'});
    }
}

sub slurp
{
    my ($self,@p) = @_;
    
    if(defined $p[0])
    {
	# go-round
	if((defined $self->{'needs'}->{'greedy'} && $self->{'needs'}->{'greedy'} eq 'Y'))
	{
	    my $exclude = $self->{'needs'}->{'exclude'};
	    if(!$exclude){$exclude = {}; $self->{'needs'}->{'exclude'} = $exclude;}
	    $self->{'needs'}->{'exclude'}->{$p[0]->{'item_no'}} = 1;
	}
	return(1);
    }
    
    return (0);
}

sub bneeded
{
    my ($self,@p) = @_;
    
    if(defined $p[0])
    {
	
	if($self->{bogo_needs} eq '')
	{
	    $self->{bogo_needs} = {};
	}
	if(!defined $self->{bogo_needs}->{exclude})
	{
	    $self->{bogo_needs}->{exclude} = {};
	}

	if($self->{'bogo_needs'}->{'exclude'}->{$p[0]->{'item_no'}})
	{
	    return(1);
	}
    }
    return (0);
}

sub bslurp
{
    my ($self,@p) = @_;
    
    if(defined $p[0])
    {
	# go-round
	$self->{'bogo_needs'}->{'exclude'}->{$p[0]->{'item_no'}} = 1;	
	return(1);
    }
    
    return (0);
}

sub code
{
    my ($self,@p) = @_;
    
    if(defined $p[0]) { $self->{code} = $p[0]; }
   
    return ($self->{code});

}

sub override
{
    my ($self,@p) = @_;
    
    if(defined $p[0]) { $self->{override} = $p[0]; }
   
    return ($self->{override} eq 'Y' ? 1 : 0);
}

sub floor
{
    my ($self,@p) = @_;
    
    if(defined $p[0]) { $self->{floor} = $p[0]; }
   
    return ($self->{floor});
}

sub pct
{
    my ($self,@p) = @_;
    
    if(defined $p[0]) { $self->{pct} = $p[0]; }
   
    return ($self->{pct});
}

sub SKU
{
    my ($self,@p) = @_;

    if(defined $p[0]) { $self->{SKU} = $p[0]; }
    
    return ($self->{SKU});
}

sub expires
{
    my ($self,@p) = @_;
    
    return ($self->{expires});
}

sub cart_only
{
    my ($self,@p) = @_;
    
    if(defined $p[0]) { $self->{cart_only} = $p[0]; }

    return ($self->{cart_only} eq 'Y' ? 1 : 0);
}

sub ignore
{
    my ($self,@p) = @_;
    
    if(defined $p[0]) { $self->{ignore} = $p[0]; }
    
    return ($self->{ignore} eq 'Y' ? 1 : 0);
}

sub apply
{
    my ($self,@p) = @_;
    
    my $t = shift @p;
    
    my $level = 0;
    if(ifdef($t,'') eq 'F'){$level = 1;}
    
    my $applied = 0;
    
    if($self->{'uses'} == 0 || ifdef($self->{'use_counter'}->[$level],0) < $self->{'uses'})
    {
	$applied = 1;
	$self->{'use_counter'}->[$level]++;
    }

    return ($applied);
}

sub instock_only
{
    my ($self,@p) = @_;
    
    if(defined $p[0]) { $self->{instock_only} = $p[0]; }
    
    return ($self->{instock_only} eq 'Y' ? 1 : 0);
}

sub onsale_only
{
    my ($self,@p) = @_;
    
    if(defined $p[0]) { $self->{onsale_only} = $p[0]; }
    
    return ($self->{onsale_only} eq 'Y' ? 1 : 0);
}


sub fullprice_only
{
    my ($self,@p) = @_;
    
    if(defined $p[0]) { $self->{fullprice_only} = $p[0]; }
    
    return ($self->{fullprice_only} eq 'Y' ? 1 : 0);
}

sub combines
{
    my ($self,@p) = @_;
    
    if(defined $p[0]) { $self->{combines} = $p[0]; }
    
    return ($self->{combines} eq 'Y' ? 1 : 0);
}

sub fullprice
{
    my ($self,@p) = @_;
    
    if(defined $p[0]) { $self->{fullprice} = $p[0]; }
    
    return ($self->{fullprice} eq 'Y' ? 1 : 0);
}

sub bogo
{
    my ($self,@p) = @_;
    
    if(defined $p[0]) { $self->{bogo} = $p[0]; }
    
    return ($self->{bogo} eq 'Y' ? 1 : 0);
}

sub bogo_needs
{
    my ($self,@p) = @_;
    
    if($self->{bogo_needs} eq '')
    {
	$self->{bogo_needs} = {};
    }

    if(!defined $self->{bogo_needs}->{exclude})
    {
	$self->{bogo_needs}->{exclude} = {};
    }

    if(defined $p[0]) { 
	$self->{bogo_needs}->{current_item} = $p[0];
	if($self->{bogo_needs}->{'matchers'})
	{
	    my $matchers = $self->{bogo_needs}->{'matchers'};
	    
	    foreach my $matcher (keys %{$matchers})
	    {
		if($matcher eq 'price')
		{
		    $matchers->{$matcher}->{'value'} = $p[0]->current_price;
		}
	    }
	}
	else
	{
	    $self->{bogo_needs}->{'SKU'} = $p[0]->{'SKU'}; 
	}
    }

    return ($self->{bogo_needs});
}



1;
__END__
# Below is stub documentation for your module. You'd better edit it!

=head1 NAME

Business::Logic::Discount - Perl extension for blah blah blah

=head1 SYNOPSIS

  use Business::Logic::Discount;
  blah blah blah

=head1 DESCRIPTION

Stub documentation for Business::Logic::Discount, created by h2xs. It looks like the
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
