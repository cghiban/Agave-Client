package Agave::Client::Job;

use warnings;
use strict;

use base qw/Agave::Client::Base/;

use Agave::Client::Object::Job ();
use Try::Tiny;

use Data::Dumper;

=head1 NAME

Agave::Client::Job - The great new Agave::Client::Job!

=head1 VERSION

Version 0.03

=cut

our $VERSION = '0.03';


=head1 SYNOPSIS

Quick summary of what the module does.

Perhaps a little code snippet.

    use Agave::Client::Job;

    my $foo = Agave::Client::Job->new();
    ...

=head1 METHODS

=head2 submit_job

    Submits a request to run a job.
    Returns a hashref: {status => [success|fail], message => '..', data => $job}
    where $job is a Job object.

	$apps = $api_instance->apps;
	$job = $api_instance->job;
	($ap) = $apps->find_by_name("name"); #Agave::Client::Object::Application
	$job->submit_job($ap, %arguments)

=cut

sub submit_job {
	my ($self, $application, %params) = @_;

	#print STDERR  '$application: ', $application, $/;
	#print STDERR  'ref $application: ', ref $application, $/;
	unless ($application && ref($application) =~ /::Application/) {
		print STDERR  "::submit_job: Invalid argument. Expecting Application object", $/;
		return $self->_error("Invalid argument. Expecting Application object.");
	}


	my %required_options = ();
	my %available_options = ();

	# fix jobName
	if (defined $params{jobName} && $params{jobName} ne "") {
		$params{jobName} =~ s|/+||g;
		$params{jobName} =~ s|^\d|N|;
	}

	my %post_content = (
			appId => $application->id,
			jobName => delete $params{name} || delete $params{jobName} || 'Job for ' . $application->id,
			maxRunTime => delete $params{maxRunTime} || delete $params{requestedTime} || '01:00:00',
			nodeCount => delete $params{nodeCount} || delete $params{processors} || 1,
			#processorsPerNode => delete $params{processorsPerNode} || delete $params{processorsPerNode} || 1,
			#memory => delete $params{memory} || '',
		);

    for my $option (qw(notifications archive archivePath archiveSystem memoryPerNode)) {
        $post_content{ $option } = delete $params{ $option } 
            if (defined $params{ $option });
    }

	for my $opt_group (qw/inputs outputs parameters/) {
		for my $opt ($application->$opt_group) {
			#print STDERR  "  ** ", $opt->{id}, 
			#	"\tr:", defined $opt->{required} ? $opt->{required} : '',
			#	"\tv:", defined $opt->{validator} ? $opt->{validator} : '',
			#	$/;
			#$available_options{$opt->{id}} = $opt;
			if (defined $params{$opt->{id}} && $params{$opt->{id}} ne "") {
				$post_content{ $opt->{id} } = $params{$opt->{id}};
			}
			elsif (defined $opt->{required} && $opt->{required}) {
				$required_options{$opt->{id}} = $opt_group;
			}
		}
	}

	if (%required_options) {
		return $self->_error("Missing required argument(s)", \%required_options);
	}

	my $resp = try {
            $self->do_post('/', %post_content);
        }
        catch {
	        return $self->_error("JobEP: Unable to submit job.");
        };
	if (ref $resp) {
		if ($resp->{id}) {
			return { status => 'success', data => Agave::Client::Object::Job->new($resp) };
		}
		return $resp;
	}
}

=head2 job_details

=cut

sub job_details {
	my ($self, $job_id) = @_;

	my $data = $self->do_get('/' . $job_id);
	if ('HASH' eq ref $data) {
		return Agave::Client::Object::Job->new($data);
	}

	return $data;
}

sub job_output_files {
	my ($self, $job_id) = @_;

	$self->do_get('/' . $job_id . '/output/list');
}

=head2 jobs

=cut

sub jobs {
	my ($self) = @_;

	my $list = $self->do_get('/');
	return @$list ? [map {Agave::Client::Object::Job->new($_)} @$list] : [];
}


=head2 delete_job

    Kills a running job identified by <id> and removes it from history

=cut

sub delete_job {
	my ($self, $job_id) = @_;

	my $st = $self->do_delete('/' . $job_id);

	return 1 if ($st != 1);
	return;
}

=head2 input

=cut

sub input {
	my ($self, $job_id) = @_;

	$self->do_get('/' . $job_id . '/input');
}


=head2 share_job

=cut

sub share_job {
	my ($self, $job_id, $username, $perm) = @_;

    $perm ||= "read";
    return unless ($job_id && $username);

    my $path = join("/", "", $job_id, "share", $username);

    return unless $perm =~ /^(?:read|write)$/;

    $self->do_post($path, permission => $perm);
}

=head2 stop_job

=cut

sub stop_job {
	my ($self, $job_id) = @_;

    return unless ($job_id);

    my $path = "/$job_id";

    my $rc = $self->do_post($path, "action" => "stop");
}


sub stdout {
    my ($self, $job_id) = @_;

    return unless ($job_id);

    my $path = '/' . $job_id . '/output/ipc.stdout';
    $self->do_get($path);
}

sub stderr {
    my ($self, $job_id) = @_;

    return unless ($job_id);

    my $path = '/' . $job_id . '/output/ipc.stderr';
    $self->do_get($path);
}

=head1 AUTHOR

Cornel Ghiban, C<< <ghiban at cshl.edu> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-iplant-foundationalapi at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=iPlant-FoundationalAPI>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.




=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Agave::Client

=head1 ACKNOWLEDGEMENTS


=head1 COPYRIGHT & LICENSE

Copyright 2014 Cornel Ghiban.

=cut

1; # End of Agave::Client::Job
