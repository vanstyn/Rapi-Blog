package Rapi::Blog::PreAuth::Error;
use strict;
use warnings;

# ABSTRACT: Base error class for preauth Actors

use Moo;
use Types::Standard qw(:all);

use RapidApp::Util ':all';
use Rapi::Blog::Util;
use Scalar::Util 'blessed';

use overload '""' => 'stringify';

sub stringify {
  my $self = shift;
  $self->msg || join(' ','Unspecified',blessed($self),'error')
}

has 'msg', is => 'ro', isa => Str, default => sub {''};

sub type {
  my $self = shift;
  my $class = blessed($self) or die "not a blessed instance";
  (split(/Rapi::Blog::PreAuth::Actor::Error::/,$class,2))[1];
}

sub throw {
  my ($self, $msg) = @_;
  my $p = {};
  $p->{msg} = $msg if $msg;
  die $self->new($p)
}



1;


__END__

=head1 NAME

Rapi::Blog::PreAuth::Error - Base error class


=head1 DESCRIPTION

This is an internal class and is not intended to be used directly. 

=head1 SEE ALSO

=over

=item * 

L<Rapi::Blog>

=back

=head1 AUTHOR

Henry Van Styn <vanstyn@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2019 by IntelliTree Solutions llc.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
