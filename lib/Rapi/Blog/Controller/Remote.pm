package Rapi::Blog::Controller::Remote;
use Moose;
use namespace::autoclean;

BEGIN { extends 'Catalyst::Controller'; }

use strict;
use warnings;

use RapidApp::Util ':all';
use Rapi::Blog::Util;

# This is the general-purpse controller for handing domain-specific 
# custom-code endpoint requests outside/separate of RapidApp


sub comment :Local :Args(1) {
  my ($self, $c, $arg) = @_;
  
  return $self->add_comment($c) if ($arg eq 'add');
  
  
  $self->error_response($c,"bad comment argument '$arg'");
}

sub add_comment {
  my ($self, $c) = @_;
  
  # Ignore via generic redirect if its not a POST
  $c->req->method eq 'POST' or return $c->res->redirect( $c->mount_url.'/', 307 );
  
  my $User = $c->user->linkedRow or return $self->error_response($c,
    "Not logged in or unable to find current user"
  );
  
  $User->can_comment or return $self->error_response($c,
    "Add comment: permission denied"
  );
  
  $c->req->params->{body} or return $self->error_response($c,"missing param 'body'");
  
  return $self->_add_sub_comment($c) if ($c->req->params->{parent_id});
  
  my $post_id = $c->req->params->{post_id} or return $self->error_response($c,
    "missing param 'post_id' or 'parent_id'"
  );
  
  my $Post = $c->model('DB::Post')->search_rs({ 'me.id' => $post_id })->first
    or return $self->error_response($c,"Post '$post_id' does not exist or permission denied");
  
  my $Comment = $Post->comments->create({
    post_id => $Post->id,
    user_id => $User->id,
    body => $c->req->params->{body},
  }) or return $self->error_response($c,"Unable to add comment - unknown error");
  
  my $url = join('#',$Post->public_url,$Comment->html_id);
  
  scream($url);
  
  return $c->res->redirect( $url, 307 );
}


sub _add_sub_comment {
  my ($self, $c) = @_;
  
  ...
}


# placeholder for later
sub error_response {
  my ($self, $c, $err) = @_;
  
  die $err;
}



__PACKAGE__->meta->make_immutable;

1;
