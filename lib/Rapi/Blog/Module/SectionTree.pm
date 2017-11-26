package Rapi::Blog::Module::SectionTree;
use strict;
use warnings;
use Moose;
extends 'RapidApp::Module::Tree';

use RapidApp::Util qw(:all);
use Rapi::Blog::Util;

has '+root_node_text',      default => 'Sections';
has '+show_root_node',      default => 1;
has '+fetch_nodes_deep',    default => 1;
has '+use_contextmenu',     default => 1;
has '+no_dragdrop_menu',    default => 1;
has '+setup_tbar',          default => 1;
has '+no_recursive_delete', default => 0;


sub BUILD {
  my $self = shift;
  
  $self->apply_extconfig(
    tabTitle   => 'Manage Sections',
    tabIconCls => 'icon-sitemap-color',
    border     => \1,
    autoScroll => \1
  );

}

sub is_admin {
  my $self = shift;
  my $User = Rapi::Blog::Util->get_User;
  $User && $User->admin ? 1 : 0
}

around 'content' => sub {
  my ($orig, $self, @args) = @_;
  my $cfg = $self->$orig(@args);
  
  unless ($self->is_admin) {
    my @ops = qw/add delete rename copy move/;
    $cfg->{$_.'_node_url'} = undef for (@ops);
  }

  return $cfg
};


sub get_node_id {
  my ($self, $node) = @_;
  
  my $id = (reverse split(/\//,$node))[0];
  $id = undef if ($id eq $self->root_node_name);

  $id
}

sub Rs {
  my $self = shift;
  $self->c->model('DB::Section')
}

sub Sections_of {
  my ($self, $id) = @_;
  $self->Rs
    ->search_rs({ 'me.parent_id' => $id })
    ->all
}

sub get_Section {
  my ($self, $id) = @_;
  $self->Rs->find($id)
}


sub fetch_nodes {
  my ($self, $node) = @_;
  
  my $id = $self->get_node_id($node);
  
  my @nodes = ();
  
  foreach my $Section ($self->Sections_of($id)) {
    my $cfg = {
      id   => $Section->id,
      text => $Section->name
    };
    
    push @nodes, $cfg;
  }
  
  \@nodes
}



sub add_node {
  my ($self,$name,$node,$params) = @_;
  
  die usererr "Create Section: PERMISSION DENIED" unless ($self->is_admin);

  my $id = $self->get_node_id($node);
  
  my $Section = $self->Rs->create({
    parent_id => $id,
    name      => $name
  });
  
  return {
    msg    => 'Created',
    success  => \1,
    child => {
      id   => $Section->id,
      text => $Section->name
    }
  };
}


sub rename_node {
  my ($self,$node,$name,$params) = @_;
  
  die usererr "Rename Section: PERMISSION DENIED" unless ($self->is_admin);
  
  my $id = $self->get_node_id($node);
  die "Cannot rename the root node" unless ($id);
  
  my $Section = $self->get_Section($id) or die "Section id '$id' not found";
  
  # strip whitespace
  $name =~ s/^\s+//;
  $name =~ s/\s+$//;
  
  $Section->update({ name => $name });
  
  return {
    msg    => 'Renamed',
    success  => \1,
    new_text => $Section->name,
  };
}

sub delete_node {
  my $self = shift;
  my $node = shift;
  
  die usererr "Delete Section: PERMISSION DENIED" unless ($self->is_admin);
  
  my $id = $self->get_node_id($node);
  die "Cannot rename the root node" unless ($id);
  
  my $Section = $self->get_Section($id) or die "Section id '$id' not found";
  
  $Section->delete;
  
  return {
    msg    => "Deleted",
    success  => \1
  };
}


sub move_node {
  my $self = shift;
  my $node = shift;
  my $target = shift;
  my $point = shift;
  
  die usererr "Move Section: PERMISSION DENIED" unless ($self->is_admin);
  
  my $id  = $self->get_node_id($node);
  my $tid = $self->get_node_id($target);
  
  my $Section = $self->get_Section($id) or die "Section id '$id' not found";
  
  $Section->parent_id($tid);
  $Section->update
}




1;
