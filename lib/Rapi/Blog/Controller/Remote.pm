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
  
  my $body = $c->req->params->{body} or return $self->error_response($c,"missing param 'body'");
  
  my %data;
  my $Post;
  
  if(my $parent_id = $c->req->params->{parent_id}) {
    my $pComment = $c->model('DB::Comment')->search_rs({ 'me.id' => $parent_id })->first
      or return $self->error_response($c,"Comment '$parent_id' does not exist or permission denied");
    
    $Post = $pComment->post;
    $data{parent_id} = $pComment->id;
  }
  elsif(my $post_id = $c->req->params->{post_id}) {
    $Post = $c->model('DB::Post')->search_rs({ 'me.id' => $post_id })->first
      or return $self->error_response($c,"Post '$post_id' does not exist or permission denied");
  }
  else {
    return $self->error_response($c,"Must supply either 'post_id' or 'parent_id'");
  }
  
  %data = ( %data,
    post_id => $Post->id,
    user_id => $User->id,
    body    => $body
  );
  
  my $Comment = $Post->comments->create(\%data)
    or return $self->error_response($c,"Unable to add comment - unknown error");
  
  my $url = join('#',$Post->public_url,$Comment->html_id);
  
  return $c->res->redirect( $url, 307 );
}

sub changepw :Local :Args(0) {
  my ($self, $c, $arg) = @_;
  
  my $User = $c->user->linkedRow;
  
  # Redirect a non POST to the admin area
  $c->req->method eq 'POST' or return $User
    ? $c->res->redirect( $c->mount_url.'/adm/main/db/db_user/item/'.$User->id, 307 )
    : $c->res->redirect( $c->mount_url.'/adm', 307 );
  
 
  # TDB
  ...

}



# placeholder for later
sub error_response {
  my ($self, $c, $err) = @_;
  
  die $err;
}



__PACKAGE__->meta->make_immutable;

1;
