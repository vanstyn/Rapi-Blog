package Rapi::Blog::Module::PostPage;

use strict;
use warnings;

use Moose;
extends 'RapidApp::Module::DbicRowDV';

use RapidApp::Util qw(:all);
use Path::Class qw(file dir);

has '+template', default => 'templates/dv/postview.html';

has '+tt_include_path', default => sub {
  my $self = shift;
  dir( $self->app->ra_builder->share_dir )->stringify;
};

has '+destroyable_relspec', default => sub {['*']};
has '+close_on_destroy'   , default => 1;

before 'content' => sub { (shift)->apply_permissions };

sub apply_permissions {
  my $self = shift;
  my $c = RapidApp->active_request_context or return;
  
  # System 'administrator' role trumps everything:
  return if ($c->check_user_roles('administrator'));

  my $User = $c->user->linkedRow;
  my $reqRow = $self->req_Row or return;
  
  if ($User->id == $reqRow->author_id) {
    # users cannot change the author to someone else:
    $self->apply_columns({ author => { allow_edit => 0 } });
  }
  else {
    # If the user is not the author they can make no changes:
    $self->apply_extconfig( store_exclude_api => [qw(create update destroy)] );
  }
}


1;

