package iPlant::FoundationalAPI::IO;

#use warnings;
#use strict;
use Carp;
use HTTP::Request::Common qw(POST);
use URI::Escape;
use Data::Dumper;

use iPlant::FoundationalAPI::Constants ':all';
use iPlant::FoundationalAPI::Object::File;
use base qw/iPlant::FoundationalAPI::Base/;


=head1 NAME

iPlant::FoundationalAPI::IO - The great new iPlant::FoundationalAPI::IO!

=head1 VERSION

Version 0.01

=cut

our $VERSION = '0.01';


=head1 SYNOPSIS

Quick summary of what the module does.

Perhaps a little code snippet.

    use iPlant::FoundationalAPI::IO;

    my $foo = iPlant::FoundationalAPI::IO->new();
    ...

=head1 EXPORT

A list of functions that can be exported.  You can delete this section
if you don't export anything, such as for a purely object-oriented module.

=head1 FUNCTIONS

=head2 readdir

=cut

# List iRODS directory/retrieves directory contents
sub readdir {
	my ($self, $path) = @_;

	# Check for a request path
	unless (defined($path)) {
		print STDERR "Please specify a path for which you want contents retrieved\n";
		return;
	}

	my $list = $self->do_get('/list' . $path);
	return @$list ? [map {iPlant::FoundationalAPI::Object::File->new($_)} @$list] : [];
}

=head2 mkdir

=cut

# creates a new directory in the specified path
sub mkdir {
	my ($self, $path, $new_dir) = @_;

	# Check for a request path
	unless (defined($path)) {
		print STDERR "Please specify a path for which you want contents retrieved\n";
		return;
	}

	return $self->do_put($path, action => 'mkdir', dirName => uri_escape($new_dir));
}

=head2 remove

=cut

# remove the specified directory/file
sub remove {
	my ($self, $path) = @_;

	# Check for a request path
	unless (defined($path)) {
		print STDERR "::IO::remove - Please specify the path you want removed\n";
		return;
	}

	return $self->do_delete($path);
}

=head2 rename

=cut

# rename the specified directory/file
sub rename {
	my ($self, $path, $new_name) = @_;

	# Check for the requested path to be renamed
	unless (defined($path)) {
		print STDERR "::IO::rename Please specify a path which you want renamed\n";
		return;
	}

	# Check for a request path
	unless ($new_name) {
		print STDERR "::IO::rename Please specify a new name\n";
		return;
	}

	my $st = $self->do_put($path, action => 'rename', newName => uri_escape($new_name));
	print STDERR 'rename status: ', Dumper( $st), $/;
	#if ($st == -1) {
	#	return undef;
	#}
	$st;
}

=head2 move

=cut


sub move {
	my ($self, $src, $dest) = @_;

	print STDERR  "::IO::move: Not implemented", $/;
}

=head2 stream_file

	TODO - can it handle large files?
		- should it store data in tmp files and when done, assemble the final product?
		- should we pass it a file/filehadle to write data into?

=cut


sub stream_file {
	my ($self, $path, %params) = @_;

	#print STDERR  "::IO::stream_file: Not implemented", $/;
	# Check for the requested path to be renamed
	unless (defined($path)) {
		print STDERR "::IO::rename Please specify a path which you want renamed\n";
		return;
	}

	# TODO - make limit_size = 1024 by default - why?
	#unless (defined $params)

	my $buffer = $self->do_get($path, %params);

	return $buffer if ($buffer ne kExitError);
}

=head2 upload

=cut


# performs a file upload to the specified directory
# on success, it returns the ::IO::File representing the uploaded file
# 
sub upload {
	my ($self, $path, %params) = @_;

	my $END_POINT = $self->_get_end_point;
	unless ($END_POINT) {
		print STDERR  "Invalid request. ", $/;
		return kExitError;
	}
	
	# Check for a request path
	unless (defined($path)) {
		print STDERR "Please specify a RESTful path using for ", $END_POINT, $/;
		return kExitError;
	}

	print STDERR '::do_post: ', Dumper( \%params), $/ if $self->debug;
	my $content = {};
	while (my ($k, $v) = each %params) {
		next if $k eq 'fileToUpload';
		$content->{$k} = $v;
	}
	$content->{fileToUpload} = [ $params{'fileToUpload'} ];
	

	my $ua = $self->_setup_user_agent;
	print STDERR "\nhttps://" . $self->hostname . "/" . $END_POINT . $path, "\n" if $self->debug;
 	my $res = $ua->request(
			POST "https://" . $self->hostname . "/" . $END_POINT . $path,
			'Content_Type' => 'form-data',
			Content	=> $content,
		);
	
	# Parse response
	my $message;
	my $mref;
	
	#print STDERR Dumper( $res ), $/;
	if ($res->is_success) {
		$message = $res->content;
		if ($self->debug) {
			print STDERR $message, "\n";
		}
		my $json = JSON::XS->new->allow_nonref;
		$mref = eval {$json->decode( $message );};
		if ($mref) {
			if ($mref->{status} eq 'success') {
				return iPlant::FoundationalAPI::Object::File->new($mref->{result});
			}
			else {
				print STDERR "::upload error: ", $mref->{message}, $/;
			}
		}
	}
	else {
		print STDERR $res->status_line, "\n";
	}
	return kExitError;
}

=head1 AUTHOR

Cornel Ghiban, C<< <ghiban at cshl.edu> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-iplant-foundationalapi at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=iPlant-FoundationalAPI>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.




=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc iPlant::FoundationalAPI::IO


You can also look for information at:

=over 4

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=iPlant-FoundationalAPI>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/iPlant-FoundationalAPI>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/iPlant-FoundationalAPI>

=item * Search CPAN

L<http://search.cpan.org/dist/iPlant-FoundationalAPI/>

=back


=head1 ACKNOWLEDGEMENTS


=head1 COPYRIGHT & LICENSE

Copyright 2011 Cornel Ghiban.

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See http://dev.perl.org/licenses/ for more information.


=cut

1; # End of iPlant::FoundationalAPI::IO