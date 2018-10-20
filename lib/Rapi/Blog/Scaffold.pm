package Rapi::Blog::Scaffold;
use strict;
use warnings;

use RapidApp::Util qw(:all);
use Rapi::Blog::Util;
use Scalar::Util 'blessed';
use List::Util;
use String::Random;

use Moo;
use Types::Standard ':all';

use Rapi::Blog::Scaffold::Config;
use Rapi::Blog::Scaffold::ViewWrapper;

use Plack::App::File;
use Plack::Builder;
use Plack::Middleware::ConditionalGET;

require Path::Class;
use YAML::XS 0.64 'LoadFile';

has 'uuid', is => 'ro', init_arg => undef, 
  default => sub { join('-','scfld',String::Random->new->randregex('[a-z0-9A-Z]{20}')) };

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

# The Scaffold needs to be able to check if a given Post exists in the database  
has 'Post_exists_fn', is => 'ro', required => 1, isa => CodeRef;


sub static_paths       { (shift)->config->static_paths       }
sub private_paths      { (shift)->config->private_paths      }
sub default_ext        { (shift)->config->default_ext        }
sub view_wrappers      { (shift)->config->view_wrappers      }
sub internal_post_path { (shift)->config->internal_post_path }

# This is a unique, private path which is automatically generated that allows this
# scaffold to own a path which it can use fetch a post, and be sure another scaffold
# wont claim the path
has 'unique_int_post_path', is => 'ro', init_arg => undef, lazy => 1, default => sub {
  my $self = shift;
  join('','_',$self->uuid,'/private/post/')
};


# If this Scaffold can handle a path which it owns but doesn't exist:
sub handles_not_found {
  my $self = shift;
  my $template = $self->config->not_found or return 0;
  $self->_resolve_scaffold_file($template) ? 1 : 0
}


has 'ViewWrappers', is => 'ro', init_arg => undef, lazy => 1, default => sub {
  my $self = shift;
  return [ map {
    Rapi::Blog::Scaffold::ViewWrapper->new( 
      Scaffold => $self, %$_ 
    ) 
  } @{$self->config->view_wrappers} ]
}, isa => ArrayRef[InstanceOf['Rapi::Blog::Scaffold::ViewWrapper']];




sub BUILD {
  my $self = shift;
  $self->_load_yaml_config;
}


sub _load_yaml_config {
  my $self = shift;
  
  my $yaml_file = $self->dir->file('scaffold.yml');
  $self->config->_load_from_yaml($yaml_file) if (-f $yaml_file);
}


sub owns_path {
  my ($self, $path) = @_;
  $self->owns_path_as($path) ? 1 : 0
}

sub _resolve_path_to_post {
  my ($self, $path) = @_;
  
  my ($pfx,$name) = split($self->unique_int_post_path,$path,2);
  ($name && $pfx eq '') ? $name : undef
}



sub owns_path_as_view {
  my ($self, $path) = @_;

  for my $VW (@{ $self->ViewWrappers }) {
    my $name = $VW->resolve_subpath($path) or next;
    return 1 if ($self->handles_not_found || $VW->handles_not_found);
    # If we don't hadle not found, only claim the template if the resolved post exists:
    return 1 if ($self->Post_exists_fn->($name));
  }

  return 0
}



has '_static_path_regexp', is => 'ro', lazy => 1, default => sub {
  my $self = shift;
  return $self->_compile_path_list_regex(@{$self->static_paths});
};

has '_private_path_regexp', is => 'ro', lazy => 1, default => sub {
  my $self = shift;
  return $self->_compile_path_list_regex(@{$self->private_paths});
};

sub _compile_path_list_regex {
  my ($self, @paths) = @_;
  return undef unless (scalar(@paths) > 0);
  
  my @list = ();
  for my $path (@paths) {
    next if ($path eq ''); # empty string match nothing
    push @list, '^.*$' and next if($path eq '/') ; # special handling for '/' -- match everything

    $path =~ s/^\///; # strip and ignore leading /
    if ($path =~ /\/$/) {
      # ends in slash, matches begining of the path
      push @list, join('','^',$path);
    }
    else {
      # does not end in slash, match as if it did AND the whole path
      push @list, join('','^',$path,'/');
      push @list, join('','^',$path,'$');
    }
  }
  
  return undef unless (scalar(@list) > 0);
  
  my $reStr = join('','(',join('|', @list ),')');
  
  return qr/$reStr/
}


has 'static_path_app', is => 'ro', lazy => 1, default => sub {
  my $self = shift;
  my $app = builder {
    enable "ConditionalGET";
    Plack::App::File->new(root => $self->dir)->to_app;
  };
  
  sub {
    my $env = shift;
    my $res = $app->($env);
    # limit caching to 10 minutes now that we return 304s
    push @{$res->[1]}, 'Cache-Control', 'public, max-age=600';
    
    $res
  }
};



sub _is_static_path {
  my ($self, $template) = @_;
  my $Regexp = $self->_static_path_regexp;
  $Regexp ? $template =~ $Regexp : 0
}

sub _is_private_path {
  my ($self, $template) = @_;
  my $Regexp = $self->_private_path_regexp;
  $Regexp ? $template =~ $Regexp : 0
}


sub _resolve_scaffold_file {
  my ($self, $template) = @_;
  
  
  
  
  my $ret = $self->__resolve_scaffold_file($template);
  
  #scream_color(RED,$template,"$ret");
  
  $ret
  
}

sub __resolve_scaffold_file {
  my ($self, $template,$recur) = @_;
  my $File = $self->dir->file($template);
  # If not found, try once more by appending the default file extenson:
  return $self->__resolve_scaffold_file(join('.',$template,$self->default_ext),1) unless (
    $recur || -f $File || ! $self->default_ext
  );
  -f $File ? $File : undef
}

sub _resolve_static_path {
  my ($self, $template) = @_;
  return $template if ($self->_is_static_path($template));
  
  for my $def (@{ $self->view_wrappers }) {
    my $path = $def->{path} or die "Bad view_wrapper definition -- 'path' is required";
    $path =~ s/\/?/\//; $path =~ s/^\///;
    my ($pre, $loc_tpl) = split(/$path/,$template,2);
    return $loc_tpl if ($pre eq '' && $loc_tpl && $self->_is_static_path($loc_tpl));
  }
  
  return undef
}



1;