package Rapi::Blog::Controller::Remote::PreauthAction;
use Moose;
use namespace::autoclean;

BEGIN { extends 'Catalyst::Controller'; }

__PACKAGE__->config( namespace => 'remote/preauth_action' );

use strict;
use warnings;

use RapidApp::Util ':all';
use Rapi::Blog::Util;

use Rapi::Blog::Util::ActionSession;

sub index :Path :Args(1) {
  my ($self, $c, $key) = @_;
  
  my $PreauthAction = $c
    ->model('DB::PreauthAction')
    ->lookup_key($key) 
  or return $self->_handle_not_found_key($c, $key);
  
  my $paSes = Rapi::Blog::Util::ActionSession->new(
    PreauthAction => $PreauthAction,
    request       => $c->request
  );
  
  $paSes->start;
  
  my $evs = $paSes->Events;
  
  my $dinfo = {
    _started  => $paSes->started,
    _finished => $paSes->finished,
    _invalid  => $paSes->invalid,
    _open     => $paSes->open,
    
    count_events => scalar(@$evs),
    
    dump_events => [ map { { $_->get_columns } } @$evs ]
    
  };
  
  scream($dinfo);
  
  
  return $self->_response_plain($c, "Key: '$key' \n\n\n" . Dumper($dinfo));
  
}


sub _handle_not_found_key {
  my ($self, $c, $key) = @_;

  # TBD
  # ...

  return $self->_response_plain($c, "bad key '$key' -- Not found");
}

sub _response_plain {
  my ($self, $c, $text) = @_;
  
  $c->res->body($text);
  $c->res->content_type('text/plain');
  $c->detach;
}



__PACKAGE__->meta->make_immutable;

1;

__END__

=head1 NAME

Rapi::Blog::Controller::Remote::PreauthAction - Pre-Authorized Actions Controller

=head1 DESCRIPTION

This controller handles valid Pre-Authorized Actions, such as password_reset, and other
specific, single-use actions which can be triggered by any remote user who knows the
secret C<auth_key> for the action

=head1 SEE ALSO

=over

=item * 

L<Rapi::Blog>

=item * 

L<Catalyst::Controller>

=back


=head1 AUTHOR

Henry Van Styn <vanstyn@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2018 by IntelliTree Solutions llc.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

