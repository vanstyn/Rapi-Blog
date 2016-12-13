package Rapi::Blog::Template::Store;
use strict;
use warnings;

use RapidApp::Util qw(:all);

use Moo;
extends 'RapidApp::Template::Store';
use Types::Standard ':all';

use DateTime;
use Date::Parse;

has 'get_Model', is => 'ro', isa => Maybe[CodeRef], default => sub {undef};

has 'Model', is => 'ro', lazy => 1, default => sub {
  my $self = shift;
  die "Must supply 'Model' or 'get_Model'" unless $self->get_Model;
  $self->get_Model->()
}, isa => Object;

has 'tpl_prefix', is => 'ro', isa => Str, required => 1;

sub get_uid {
  my $self = shift;
  
  if(my $c = RapidApp->active_request_context) {
    return $c->user->id if ($c->can('user'));
  }
  
  return 0;
}

sub cur_ts {
  my $self = shift;
  my $dt = DateTime->now( time_zone => 'local' );
  join(' ',$dt->ymd('-'),$dt->hms(':'));
}

sub local_name {
  my ($self, $template) = @_;
  (split($self->tpl_prefix,$template,2))[1]
}

sub owns_tpl {
  my ($self, $template) = @_;
  $self->local_name($template) ? 1 : 0
}


sub template_exists {
  my ($self, $template) = @_;
  my $name = $self->local_name($template) or return undef;
  
  $self->Model->resultset('ContentName')
    ->search_rs({ 'me.name' => $name })
    ->count
}

sub template_mtime {
  my ($self, $template) = @_;
  my $name = $self->local_name($template) or return undef;
  
  my $Row = $self->Model->resultset('Content')
    ->search_rs(undef,{
      join    => 'content_names',
      columns => ['update_ts']
    })
    ->search_rs({ 'content_names.name' => $name })
    ->first or return undef;
  
  return Date::Parse::str2time( $Row->get_column('update_ts') )
}

sub template_content {
  my ($self, $template) = @_;
  my $name = $self->local_name($template) or return undef;
  
  my $Row = $self->Model->resultset('Content')
    ->search_rs(undef,{
      join    => 'content_names',
      columns => ['body']
    })
    ->search_rs({ 'content_names.name' => $name })
    ->first or return undef;
    
  return $Row->get_column('body');
}


sub create_template {
  my ($self, $template, $content) = @_;
  my $name = $self->local_name($template) or return undef;
  
  my $uid = $self->get_uid;
  my $ts  = $self->cur_ts;

  my $create = {
    name => $name,
    prio => 0,
    content => {
      create_user_id => $uid,
      update_user_id => $uid,
      create_ts => $ts,
      update_ts => $ts,
      body => $content
    }
  };
  
  $self->Model->resultset('ContentName')->create($create) ? 1 : 0;
  
}


sub update_template {
  my ($self, $template, $content) = @_;
  my $name = $self->local_name($template) or return undef;
  
  my $uid = $self->get_uid;
  my $ts  = $self->cur_ts;
  
  my $Row = $self->Model->resultset('Content')
    ->search_rs(undef,{
      join    => 'content_names',
    })
    ->search_rs({ 'content_names.name' => $name })
    ->first or die 'Not found!';
  
  $Row->update({
    update_user_id => $uid,
    update_ts => $ts,
    body => $content
  }) ? 1 : 0;
}


sub delete_template {
  my ($self, $template) = @_;
  my $name = $self->local_name($template) or return undef;
  
  my $Row = $self->Model->resultset('Content')
    ->search_rs(undef,{
      join    => 'content_names',
    })
    ->search_rs({ 'content_names.name' => $name })
    ->first or die 'Not found!';
  
  $Row->delete ? 1 : 0;
}


sub list_templates {
  my $self = shift;
  [ map { join('',$self->tpl_prefix,$_) } $self->Model->resultset('ContentName')->get_column('name')->all ]
}


1;