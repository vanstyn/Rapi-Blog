package Rapi::Blog::Module::SectionTree;
use strict;
use warnings;
use Moose;
extends 'RapidApp::Module::Tree';

use RapidApp::Util qw(:all);

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
    tabTitle   => 'Sections',
    tabIconCls => 'icon-sitemap-color',
    border     => \1,
    autoScroll => \1
  );

}


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
  
  my $id  = $self->get_node_id($node);
  my $tid = $self->get_node_id($target);
  
  my $Section = $self->get_Section($id) or die "Section id '$id' not found";
  
  $Section->parent_id($tid);
  $Section->update
}




1;
