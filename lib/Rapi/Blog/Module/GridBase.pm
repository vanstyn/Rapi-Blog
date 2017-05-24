package Rapi::Blog::Module::GridBase;

use strict;
use warnings;

use Moose;
extends 'Catalyst::Plugin::RapidApp::RapidDbic::TableBase';

use RapidApp::Util ':all';

sub BUILD {
  my $self = shift;
  
  if($self->ResultSource->source_name eq 'Post') {

    $self->apply_extconfig(
      reload_on_show => \1,
      store_button_cnf => {
        add => {
          text     => 'New Post',
          iconCls  => 'icon-post-add',
          showtext => 1
        }
      },
    );
  }
}

has '+use_edit_form', default => 0;

around 'get_add_edit_form_items' => sub {
  my ($orig, $self, @args) = @_;
  
  my @items = $self->$orig(@args);

  if($self->ResultSource->source_name eq 'Post') {
    my $eF = $items[$#items] || {}; # last element
    if($eF->{xtype} eq 'ra-md-editor') {
      $eF->{_noAutoHeight} = 1;
      $eF->{plugins} = 'ra-parent-gluebottom';
    }
  }

  return @items;
};


before 'load_saved_search' => sub { (shift)->apply_permissions };

sub apply_permissions {
  my $self = shift;
  my $c = RapidApp->active_request_context or return;
  
  # System 'admin' role trumps everything:
  return if ($c->check_user_roles('admin'));
  
  # Only admins can edit grids:
  $self->apply_extconfig( store_exclude_api => [qw(update destroy)] );
  
  
  my $User = $c->user->linkedRow;
  
  my $source_name = $self->ResultSource->source_name;
  
  if($source_name eq 'Post') {
    if($User->author) {
      # authors can only post as themselves
      $self->apply_columns({ author => { allow_add => 0 } });
    
    }
    else {
      # Deny all changes to Post if the user is not an author
      $self->apply_extconfig( store_exclude_api => [qw(create update destroy)] );
    }
  }
  elsif($source_name eq 'User') {
  
  
  
  }
  else {
  
  
  
  }
  

}



1;

