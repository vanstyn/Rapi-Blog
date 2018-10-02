package Rapi::Blog::Scaffold;
use strict;
use warnings;

use RapidApp::Util qw(:all);
use Rapi::Blog::Util;

use Moo;
use Types::Standard ':all';

require Path::Class;
use YAML::XS 0.64 'LoadFile';

has 'dir', is => 'ro', required => 1, coerce => sub { Path::Class::dir($_[0]) }, isa => InstanceOf['Path::Class::Dir'];


has 'favicon',            is => 'rw', isa => Maybe[Str], default => sub { 'favicon.ico' };
has 'landing_page',       is => 'rw', isa => Maybe[Str], default => sub { 'index.html' };
has 'internal_post_path', is => 'rw', isa => Maybe[Str], default => sub { 'private/post/' };
has 'not_found',          is => 'rw', isa => Maybe[Str], default => sub { 'rapidapp/public/http-404.html' };
has 'view_wrappers',      is => 'rw', isa => ArrayRef,   default => sub { [] };
has 'static_paths',       is => 'rw', isa => ArrayRef,   default => sub { ['/'] };
has 'private_paths',      is => 'rw', isa => ArrayRef,   default => sub { [] };
has 'default_ext',        is => 'rw', isa => Maybe[Str], default => sub { 'html' };


has '_supplied_params', is => 'ro', isa => HashRef, required => 1;
around BUILDARGS => sub {
  my $orig   = shift;
  my $class  = shift;
  my %params = (ref($_[0]) eq 'HASH') ? %{ $_[0] } : @_; # <-- arg as hash or hashref

  $params{_supplied_params} = { map {$_=>1} keys %params };
  $class->$orig(%params)
};
 
has '_extra_params', is => 'rw', isa => HashRef, default => sub { {} };
sub AUTOLOAD {
  my $self = shift;
  my $meth = (reverse(split('::',our $AUTOLOAD)))[0];
  $self->_extra_params->{$meth}
}

sub BUILD {
  my $self = shift;
  
  $self->_load_from_yaml;
}



sub _load_from_yaml {
  my $self = shift;
  
  my $yaml_file = $self->dir->file('scaffold.yml');
  if (-f $yaml_file) {
    my $data = LoadFile( $yaml_file );
    
    for (keys %$data) {
      if ($self->_supplied_params->{$_}) { # Don't override any user-supplied params
        delete $data->{$_}
      }
      elsif ($self->can($_)) {
        $self->$_( delete $data->{$_} ) 
      }
    }
    
    # Save leftover params so they can still be accessed via AUTOLOAD
    $self->_extra_params( $data );
  }
}




1;