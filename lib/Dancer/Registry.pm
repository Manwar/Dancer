package Dancer::Registry;

use strict;
use warnings;

# singleton for stroing the routes defined
my $REG = {};

# accessor for setting up a new route
sub add_route {
    my ($class, $method, $route, $code) = @_;
    $REG->{routes}{$method} ||= [];
    push @{ $REG->{routes}{$method} }, {route => $route, code => $code};
}

# return the first route that matches the path
sub find_route {
    my ($class, $path, $method) = @_;
    $method ||= 'get';
    $method = lc($method);
    
    foreach my $r (@{$REG->{routes}{$method}}) {
        my $params = route_match($path, $r->{route});
        if ($params) {
            $r->{params} = $params;
            return $r;
        }
    }
    return undef;
}

sub call_route {
    my ($class, $handler, $params) = @_;
    $params ||= $handler->{params};
    $handler->{code}->($params); 
}

sub route_match {
    my ($path, $route) = @_;
    my ($regexp, @variables) = make_regexp_from_route($route);
    
    # first, try the match, and save potential values
    my @values = $path =~ $regexp;
    
    # if no values found, do not match!
    return 0 unless @values;
    
    # Hmm, I can has a match?
    my %params;

    # if named variables where found, return params accordingly
    if (@variables) {
        for (my $i=0; $i< ~~@variables; $i++) {
            $params{$variables[$i]} = $values[$i];
        }
        return \%params;
    }
    
    # else, we have a unnamed matches, store them in params->{splat}
    return { splat => \@values };
}

# replace any ':foo' by '(.+)' and stores all the named 
# matches defined in $REG->{route_params}{$route}
sub make_regexp_from_route {
    my ($route) = @_;
    my $pattern = $route;

    # look for route with params (/hello/:foo)
    my @params = $pattern =~ /:([^\/]+)/g;
    if (@params) {
        $REG->{route_params}{$route} = \@params;
        $pattern =~ s/(:[^\/]+)/\(\[\^\/\]\+\)/g;
    }

    # parse wildcards
    $pattern =~ s/\*/\(\[\^\/\]\+\)/g;

    # escape slashes
    $pattern =~ s/\//\\\//g;

    # return the final regexp
    return '^'.$pattern.'$', @params;
}

'Dancer::Registry';
