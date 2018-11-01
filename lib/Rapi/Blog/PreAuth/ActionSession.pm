package Rapi::Blog::PreAuth::ActionSession;
use strict;
use warnings;

# ABSTRACT: Object to wrap Pre-Authorized Action "sessions"

use Moo;
use Types::Standard qw(:all);

use RapidApp::Util ':all';
use Rapi::Blog::Util;

has 'PreauthAction',
  is       => 'ro',
  required => 1,
  isa => InstanceOf['Rapi::Blog::DB::Result::PreauthAction'];

has 'request',
  is       => 'ro',
  required => 1,
  isa => InstanceOf['Catalyst::Request'];
  
has 'Events', 
  is      => 'rw', 
  default => sub {[]}, 
  isa     => ArrayRef[InstanceOf['Rapi::Blog::DB::Result::PreauthActionEvent']];
  
has 'started',  is => 'rw', default => sub { 0 }, isa => Bool;
has 'finished', is => 'rw', default => sub { 0 }, isa => Bool;
has 'invalid',  is => 'rw', default => sub { 0 }, isa => Bool;

has 'Hit', is  => 'ro', init_arg => undef, lazy => 1, 
  default => sub {
    my $self = shift;
    $self->PreauthAction
         ->result_source
         ->schema
         ->resultset('Hit')
         ->create_from_request({}, $self->request )
  },
  isa => InstanceOf['Rapi::Blog::DB::Result::Hit'];



sub open {
  my $self = shift;
  $self->started && ! $self->finished && ! $self->invalid
}


sub start {
  my $self = shift;
  
  $self->finished and die "Session already finished -- will not start again";
  $self->started  and return 0;

  $self->started(1);
  
  $self->request_validate
     ? 1 
     : $self->invalid(1) 
       and $self->finished(1) 
       and 0
}


sub request_validate {
  my $self = shift;
  $self->open or die "session not open!";
  $self->_call_pa_meth( request_validate => $self->Hit )
}


sub _call_pa_meth {
  my ($self, $meth, @args) = @_;
  
  my $paRow = $self->PreauthAction;
  
  my $events = [@{ $self->Events }];
  local $paRow->{_track_created_Events} = $events;
  
  my $ret = $paRow->$meth(@args);
  
  $self->Events( $events );

  $ret
}


1;


__END__

=head1 NAME

Rapi::Blog::PreAuth::ActionSession - Object class for preauth action sessions


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
