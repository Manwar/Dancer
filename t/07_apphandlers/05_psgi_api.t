use Test::More import => ['!pass'];
use strict;
use warnings;

BEGIN {
    use Dancer::ModuleLoader;
    plan skip_all => "Plack is needed to run this test"
      unless Dancer::ModuleLoader->load('Plack::Request');
    use Dancer ':syntax';
}

plan tests => 9;

Dancer::ModuleLoader->require('Dancer::Handler::PSGI');

my $handler = Dancer::Handler::PSGI->new();

my %ENV = (
    REQUEST_METHOD  => 'GET',
    PATH_INFO       => '/',
    HTTP_ACCEPT     => 'text/html',
    HTTP_USER_AGENT => 'test::more',
);

$handler->init_request_headers( \%ENV );
ok my $headers = Dancer::SharedData->headers;
isa_ok $headers->{_headers}, 'HTTP::Headers';

my $app = sub {
    my $env     = shift;
    my $request = Dancer::Request->new( \%ENV );
    $handler->handle_request($request);
};

setting 'plack_middlewares' => { 'Runtime' => [], };
setting 'public' => '.';

ok $app = $handler->apply_plack_middlewares($app);
my $res = $app->( \%ENV );
is $res->[0], 404;
ok grep { /X-Runtime/ } @{ $res->[1] };

ok $handler = Dancer::Handler::PSGI->new();
ok $app = $handler->dance;
$res = $app->(\%ENV);
is $res->[0], 404;

is ref $app, 'CODE';
