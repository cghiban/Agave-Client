#!/usr/bin/perl

use strict;

use FindBin qw($Bin);
use lib "$Bin/../lib";
use Try::Tiny;

use Agave::Client ();
use Data::Dumper; 

sub list_dir {
	my ($dir_contents) = @_;
	for (@$dir_contents) {
		print sprintf(" %6s\t%-40s\t%-40s", $_->type, $_->name, $_),  $/;
	}
	print "\n";
}

# this will read the configs from the ~/.agave file:
#	conf file content: 
#		{   "user":"iplant_username", 
#		    "password":"iplant_password", 
#           "apikey":"", 
#           "apisecret":""
#		}
#		# set either the password or the token

# see examples/test-io.pl for another way to do auth
#
my $api_instance = Agave::Client->new(debug => 0);
#$api_instance->debug(1);

unless ($api_instance->token) {
	print STDERR "Can't authenticate!" , $/;
	exit 1;
}

my $job_id = shift;

my $base_dir = '/' . $api_instance->user;
#print "Working in [", $base_dir, "]", $/;

#-----------------------------
# APPS
#

$api_instance->debug(0);
my $apps = $api_instance->apps;

#--------------------------
# JOB
#

my $io = $api_instance->io;

my $job_ep = $api_instance->job;
$job_ep->debug(0);

if ($job_id) {
    my $tries = 0;
    while ($tries++ < 100) {
        my $j = $job_ep->job_details($job_id);
        #print STDERR Dumper( $j ), $/;
        my $job_status = $j->status;
        print STDERR 'status: ', $job_status, $/;
        if ($job_status =~ /^(ARCHIVING_)?FINISHED$/) {
            #print STDERR Dumper( $j ), $/;
            my $out_files;
            if ($j->{archive}) {
                print STDERR  "Files stored in: ", $j->archivePath, $/;
                my $out_files = $io->readdir('/' . $j->archivePath);
                list_dir($out_files);
            }
            last;
        }
        #else {
        #    print STDERR Dumper( $j ), $/;
        #}

        if ($job_status =~ /(?:FAILED|KILLED|PAUSED)$/) {
            print STDERR  'message: ', $j->{message}, $/;
            last;
        }

        sleep 30 + $tries;
    }

    exit 0;
}

my $job_list = $job_ep->jobs;
for (@$job_list) {
	print $_->{id}, "\t", $_->{endTime},"\t", $_->status, "\t", $_->{name}, $/;
}

# # delete oldest job..
# $job_id = @$job_list ? $job_list->[scalar @$job_list - 1] : undef;
# if ($job_id) {
# 	$st = $job_ep->delete_job($job_id);
# 	print STDERR  Dumper($st), $/;
# }



