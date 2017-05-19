package Rapi::Blog::Module::GridBase;

use strict;
use warnings;

use Moose;
extends 'Catalyst::Plugin::RapidApp::RapidDbic::TableBase';

use RapidApp::Util ':all';


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


1;

