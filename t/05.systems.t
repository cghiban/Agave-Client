#!/usr/bin/perl -w

use strict;
use Test::More;

my $TNUM = 13;
plan tests => $TNUM;

use FindBin;
use Data::Dumper;
use Agave::Client ();

my $conf_file = "$FindBin::Bin/agave-auth.json";

diag <<EOF


********************* WARNING ********************************
The t/agave-auth.json is missing. Here's the structure:
    {
        "username"  :"", 
        "password"  :"",
        "apisecret" :"",
        "apikey"    :""
    }

For more details go to http://agaveapi.co/authentication-token-management/


EOF
unless (-f $conf_file);

SKIP: {
    skip "Create the t/agave-auth.json file for tests to run", $TNUM
        unless (-f $conf_file);

    my $api = Agave::Client->new( config_file => $conf_file, debug => 0);

    ok( defined $api, "API object created");
    ok( defined $api->token, "Authentication succeeded" );

    unless ($api && $api->token) {
        skip "Auth failed. No reason to continue..", $TNUM - 2;
    }

    my $S = $api->system;
    ok(defined $S, 'System endpoint succeeded defined');

    # let's start with a public system
    my $dataIPC = $S->list('data.iplantcollaborative.org');
    #diag(Dumper($dataIPC));
    ok($dataIPC && 'HASH' eq ref $dataIPC, 'Retrieved system');
    is(lc $dataIPC->{type}, 'storage', 'Confirmed system type');

    # let's search by public status
    my $public_systems = $S->list({ public => 'true' });
    #diag(Dumper($public_systems));
    ok($public_systems && 'ARRAY' eq ref $public_systems, 'Got search results');

    my ($public_dataIPC) = grep {$_->{id} eq $dataIPC->{id}} @$public_systems;
    ok($public_dataIPC && 'HASH' eq ref $public_dataIPC, 'Public system found as expected');

    # let's get an execution system
    my $stampede2 = $S->list('stampede2.tacc.utexas.edu');
    #diag(Dumper($stampede2));
    ok($stampede2 && 'HASH' eq ref $stampede2, 'Retrieved system');
    is(lc $stampede2->{type}, 'execution', 'Confirmed system type');

    my $queues = $S->queues($stampede2->{id});
    ok($queues && 'ARRAY' eq ref $queues, 'Got system queues');
    ok(scalar @$queues > 0, 'Execution system has at least one queue');
    #diag(Dumper($queues));

    # let's retrieve one queue
    my ($queue) = $S->queue($stampede2->{id}, $queues->[0]->{name});
    #diag(Dumper($queue));
    ok($queue && 'HASH' eq ref $queue, 'Got system queue');
    is($queue->{id}, $queues->[0]->{id}, 'Get the same queue');

    done_testing();
}

