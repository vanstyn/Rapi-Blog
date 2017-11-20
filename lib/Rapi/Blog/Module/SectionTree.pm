package Rapi::Blog::Module::SectionTree;
use strict;
use warnings;
use Moose;
extends 'RapidApp::Module::Tree';

use RapidApp::Util qw(:all);


#has '+module_scope', default => sub { return (shift)->parent_module };
has '+instance_id', default => 'main-nav-tree';

has '+fetch_nodes_deep', default => 1;

sub BUILD {
  my $self = shift;
  
  $self->apply_extconfig(
    tabTitle   => 'Sections',
    tabIconCls => 'icon-sitemap-color',
    border     => \1,
    autoScroll => \1
  );

}


sub Sections_of {
  my ($self, $id) = @_;
  
  $id = (reverse split(/\//,$id))[0];
  
  $id = undef if ($id eq $self->root_node_name);
  $self->c->model('DB::Section')
    ->search_rs({ 'me.parent_id' => $id })
    ->all
}


sub fetch_nodes {
  my ($self, $id) = @_;
  
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



1;
