package Rapi::Blog::Template::Access;
use strict;
use warnings;

use RapidApp::Util qw(:all);

use Moo;
extends 'RapidApp::Template::Access';
use Types::Standard ':all';


around 'get_template_vars' => sub {
  my ($orig,$self,@args) = @_;
  
  my $vars = $self->$orig(@args);
  
  
  return $vars;
};


1;