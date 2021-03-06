package Agave::Client::Object::Job;


=head1 NAME

Agave::Client::Object::Job - The great new Agave::Client::Object::Job!

=head1 VERSION

Version 0.03

=cut

use overload '""' => sub { $_[0]->id; };

our $VERSION = '0.03';

=head1 SYNOPSIS

Quick summary of what the module does.

Perhaps a little code snippet.

    use Agave::Client;

    my $apif = Agave::Client->new;
    my $job_endpoint = $apif->job;
    my $my_jobs = $job_endpoint->list;
    print $applications[0]->status;
    ...

=head1 METHODS

=head2 new

=cut


sub new {
	my ($proto, $args) = @_;
	my $class = ref($proto) || $proto;
	
	my $self  = { map {$_ => $args->{$_}} keys %$args};
	
	
	bless($self, $class);
	
	
	return $self;
}

sub name {
	my ($self) = @_;
	return $self->{name};
}


sub owner {
	my ($self) = @_;
	return $self->{owner};
}

sub id {
	my ($self) = @_;
	return $self->{id};
}

# returns a list of output files
#
sub outputs {
	my ($self) = @_;
	return $self->{outputs};
}

#
#
sub inputs {
	my ($self) = @_;
	return $self->{inputs};
}


sub helpURI {
	my ($self) = @_;
	return $self->{helpURI};
}

sub shortDescription {
	my ($self) = @_;
	return $self->{shortDescription};	
}


sub parameters {
	my ($self) = @_;
	my $p = $self->{parameters};
	wantarray ? %$p : $p;
}


sub status {
	my ($self) = @_;
	$self->{status};
}

sub archivePath {
	my ($self) = @_;
	$self->{archivePath};
}

sub archive {
	my ($self) = @_;
	$self->{archive};
}

sub fullOutputPath {
	my ($self) = @_;
	return if $self->{archive};
	
	sprintf("agave://%s/%s", $self->executionSystem, $self->outputPath);
}

sub outputPath {
	my ($self) = @_;
	!$self->{archive} ? $self->{outputPath} : undef;
}

sub executionSystem {
	my ($self) = @_;

	$self->{executionSystem};
}

sub is_finished {
	$_[0]->status =~ /^(?:FINISHED|KILLED|FAILED|STOPPED|ARCHIVING_FAILED)$/;
}

sub is_successful {
	$_[0]->status eq 'FINISHED'
}

sub TO_JSON {
	my $self = shift;
	return { map {$_ => $self->{$_}} keys %$self};
}


1; # End of Agave::Client::Object::Application
