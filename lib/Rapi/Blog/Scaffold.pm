package Rapi::Blog::Scaffold;
use strict;
use warnings;

use RapidApp::Util qw(:all);
use Rapi::Blog::Util;
use Scalar::Util 'blessed';

use Moo;
use Types::Standard ':all';

use Rapi::Blog::Scaffold::Config;

require Path::Class;
use YAML::XS 0.64 'LoadFile';

has 'dir', 
  is       => 'ro', 
  required => 1, 
  isa      => InstanceOf['Path::Class::Dir'],
  coerce   => sub { Path::Class::dir($_[0]) };


has 'config', 
  is      => 'ro',
  isa     => InstanceOf['Rapi::Blog::Scaffold::Config'],
  default => sub {{}},
  coerce  => sub { blessed $_[0] ? $_[0] : Rapi::Blog::Scaffold::Config->new($_[0]) };
  


sub BUILD {
  my $self = shift;
  
  $self->_load_from_yaml;
}


sub _load_from_yaml {
  my $self = shift;
  
  my $yaml_file = $self->dir->file('scaffold.yml');
  $self->config->_load_from_yaml($yaml_file) if (-f $yaml_file);

 
}

1;