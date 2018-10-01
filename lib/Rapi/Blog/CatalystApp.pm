package Rapi::Blog::CatalystApp;
use Moose::Role;
use namespace::autoclean;

# ABSTRACT: Common Catalyst plugin loaded on all Rapi::Blog apps

use strict;
use warnings;

use RapidApp::Util qw(:all);


around 'authenticate' => sub {
  my ($orig, $self, @args) = @_;
  
  #scream(\@args);
  
  # TODO ...
  
  $self->$orig(@args);

};



1;