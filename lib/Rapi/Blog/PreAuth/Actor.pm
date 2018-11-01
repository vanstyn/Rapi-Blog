package Rapi::Blog::PreAuth::Actor;
use strict;
use warnings;

# ABSTRACT: Base class for preauth Actors

use Moo;
use Types::Standard qw(:all);

use RapidApp::Util ':all';
use Rapi::Blog::Util;

has 'PreauthAction',
  is       => 'ro',
  required => 1,
  isa => InstanceOf['Rapi::Blog::DB::Result::PreauthAction'];




sub execute { ... }




1;


__END__

=head1 NAME

Rapi::Blog::PreAuth::Actor - Base class for preauth Actors


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

This software is copyright (c) 2018 by IntelliTree Solutions llc.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
