package Business::Logic::Address;

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
	firstname=>'',
	lastname=>'',
	address=>'',
	address2=>'',
	city=>'',
	state=>'',
	zip=>'',
	country=>'US',
	phone=>'',
	email=>'',
	type=>'shipping',
    };

    my $self = {};
    foreach my $parameter (keys %$parameters)
    {
	$self->{$parameter} = q_map($params,q_map($map,$parameter),$parameters->{$parameter});
    }

    my $us_states = {
	alabama=>'AL',
	al=>'AL',
	alaska=>'AK',
	ak=>'AK',
	arizona=>'AZ',
	az=>'AZ',
	arkansas=>'AR',
	ar=>'AR',
	california=>'CA',
	ca=>'CA',
	calif=>'CA',
	cali=>'CA',
	cal=>'CA',
	colorado=>'CO',
	co=>'CO',
	connecticut=>'CT',
	ct=>'CT',
	delaware=>'DE',
	de=>'DE',
	'district of columbia'=>'DC',
	dc=>'DC',
	florida=>'FL',
	fl=>'FL',
	georgia=>'GA',
	ga=>'GA',
	hawaii=>'HI',
	hi=>'HI',
	'hawai\'i'=>'HI',
	idaho=>'ID',
	id=>'ID',
	illinois=>'IL',
	il=>'IL',
	indiana=>'IN',
	in=>'IN',
	iowa=>'IA',
	ia=>'IA',
	kansas=>'KS',
	ks=>'KS',
	kentucky=>'KY',
	ky=>'KY',
	louisiana=>'LA',
	la=>'LA',
	maine=>'ME',
	me=>'ME',
	maryland=>'MD',
	md=>'MD',
	massachusetts=>'MA',
	ma=>'MA',
	michigan=>'MI',
	mi=>'MI',
	minnesota=>'MN',
	mn=>'MN',
	mississippi=>'MS',
	ms=>'MS',
	missouri=>'MO',
	mo=>'MO',
	montana=>'MT',
	mt=>'MT',
	nebraska=>'NE',
	ne=>'NE',
	nevada=>'NV',
	nv=>'NV',
	'new hampshire'=>'NH',
	nh=>'NH',
	'new jersey'=>'NJ',
	nj=>'NJ',
	'new mexico'=>'NM',
	nm=>'NM',
	'new york'=>'NY',
	'n york'=>'NY',
	'newyork'=>'NY',
	ny=>'NY',
	'north carolina'=>'NC',
	'n car'=>'NC',
	nc=>'NC',
	'north dakota'=>'ND',
	nd=>'ND',
	'n dak'=>'ND',
	ohio=>'OH',
	oh=>'OH',
	oklahoma=>'OK',
	ok=>'OK',
	okla=>'OK',
	oregon=>'OR',
	oreg=>'OR',
	ore=>'OR',
	or=>'OR',
	pennsylvania=>'PA',
	pensylvania=>'PA',
	penn=>'PA',
	pa=>'PA',
	penna=>'PA',
	'rhode island'=>'RI',
	ri=>'RI',
	'south carolina'=>'SC',
	sc=>'SC',
	's car'=>'SC',
	'south dakota'=>'SD',
	's dak'=>'SD',
	'sodak'=>'SD',
	sd=>'SD',
	tennessee=>'TN',
	tenessee=>'TN',
	tenesee=>'TN',
	tn=>'TN',
	tenn=>'TN',
	texas=>'TX',
	tex=>'TX',
	tx=>'TX',
	utah=>'UT',
	ut=>'UT',
	vermont=>'VT',
	vt=>'VT',
	virginia=>'VA',
	virg=>'VA',
	va=>'VA',
	washington=>'WA',
	wash=>'WA',
	wa=>'WA',
	'west virginia'=>'WV',
	'w va'=>'WV',
	'w virg'=>'WV',
	wv=>'WV',
	wisconsin=>'WI',
	wis=>'WI',
	wi=>'WI',
	wisc=>'WI',
	wyoming=>'WY',
	wyo=>'WY',
	wy=>'WY',
	'american samoa'=>'AS',
	as=>'AS',
	'samoa'=>'AS',
	guam=>'GU',
	gu=>'GU',
	'northern mariana islands'=>'MP',
	mp=>'MP',
	'puerto rico'=>'PR',
	pr=>'PR',
	'virgin islands'=>'VI',
	vi=>'VI',
	'us virgin islands'=>'VI',
	
    };
    
    my $states = {
	'US'=>$us_states,
    };
    
    $self->{'state_abbrevs'} = $states;
    
    $self->{'data'} = $params;

    bless($self, $class);
    
    $self->fix_address(); # fix up address upon completion

    return $self;
}

sub get_name
{
    my ($self) = @_;
    
    my $name = $self->{'firstname'};
    
    if(!defined $name || $name eq '')
    {
	$name = '';
    }
    else
    {
	$name .= ' ';
    }
    
    my $last_name = $self->{'lastname'};
    if($last_name eq 'lastname'){$last_name = undef;}

    if(defined $last_name && $last_name ne '')
    {
	$name .= $last_name;
    }
    else
    {
	chop $name;
    }
    
    return($name);
}


sub fix_address
{
    my ($self) = @_;
    
    # fix all address errors;
    
    return (1); # success!
}

sub is_ok
{
    my ($self) = @_;

    # check order for errors
    
    if(!defined $self->{'address'} || $self->{'address'} eq '')
    {
	# set an error code
	return (0);
    }
    elsif(!defined $self->{'city'} || $self->{'city'} eq '')
    {
	return (0);
    }
    
    if($self->uniform_country_code() eq 'US')
    {
	if(!defined $self->{'zip'} || $self->{'zip'} eq '')
	{
	    return (0);
	}
	elsif(!defined $self->{'state'} || $self->{'state'} eq '')
	{
	    return (0);
	}
    }
    
    return (1);
}

sub get_state
{
    my ($self) = @_;
    
    my $state = $self->uniform_state_code();
    
    return ($state);
}

sub get_country
{
    my ($self) = @_;
    
    my $country = $self->uniform_country_code();
    
    return ($country);
}


sub uniform_state_code
{
    my ($self,$state,$country) = @_;
    
    if(!defined $state)
    {
	$state = $self->{'state'};
    }
    
    if(!defined $country)
    {
	$country = $self->get_country();
    }
    else
    {
	$country = $self->uniform_country_code();
    }

    my $states = $self->{'state_abbrevs'}->{$country};

    if(!defined $states)
    {
	$states = $self->{'state_abbrevs'}->{'DEFAULT'};
    }
    
    if(defined $states)
    {
    
	my $test_state = $state;
	while($test_state =~ s/^\s//igs){}
	while($test_state =~ s/\s$//igs){}
	while($test_state =~ s/\.//igs){}
	$test_state =~ tr/A-Z/a-z/;
	
	if(defined $states->{$test_state})
	{
	    $state = $states->{$test_state};
	}
	
    }
    
    
    return ($state);
}

sub uniform_country_code
{
    my ($self,$country) = @_;
    
    if(!defined $country)
    {
	$country = $self->{'country'};
    }
    
    if($country eq 'USA' || $country eq 'United States' || $country eq 'U.S.A' || $country eq 'U.S.A.' || $country eq 'US' || $country eq '' || $country eq 'Us' || $country eq 'America' || $country eq 'United States of America' || $country eq 'united states of america' || $country eq 'u s a')
    {
	$country = 'US';
    }
    elsif(grep(/canada/i,$country) || $country eq 'CA' || $country eq 'Canada' || $country eq 'Can')
    {
	$country = 'CA';
    }
    # do some processing
    
    return ($country);
}

sub region_code
{
    my ($self,$country) = @_;
    
    if(!defined $country)
    {
	$country = $self->{'country'};
    }
    
    $country = $self->uniform_country_code($country);
    
    if($country eq 'US')
    {
	return ('US');
    }
    elsif($country eq 'CA')
    {
	return ('CA');
    }
    else
    {
	return ('OT');
    }
}

sub get_email
{
    my ($self) = @_;
    
    my $email = $self->{'email'};
    
    return ($email);
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
