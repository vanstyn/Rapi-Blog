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



1;

