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
  

sub static_paths       { (shift)->config->static_paths       }
sub private_paths      { (shift)->config->private_paths      }
sub default_ext        { (shift)->config->default_ext        }
sub view_wrappers      { (shift)->config->view_wrappers      }
sub internal_post_path { (shift)->config->internal_post_path }


sub BUILD {
  my $self = shift;
  $self->_load_yaml_config;
}


sub _load_yaml_config {
  my $self = shift;
  
  my $yaml_file = $self->dir->file('scaffold.yml');
  $self->config->_load_from_yaml($yaml_file) if (-f $yaml_file);
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
  $self->__resolve_scaffold_file($template)
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



sub _match_path {
  my ($self, $path, $template) = @_;
  
  my ($pfx,$name) = split($path,$template,2);
  return ($name && $pfx eq '') ? $name : undef;
}


sub split_name_wrapper {
  my ($self, $template) = @_;
  
  my ($name, $wrapper);
  
  for my $def (@{ $self->view_wrappers }) {
    my $path = $def->{path} or die "Bad view_wrapper definition -- 'path' is required";
    if ($name = $self->_match_path($path, $template)) {
      $wrapper = $def;
      last;
    }
  }
  
  $name ||= $self->_match_path($self->internal_post_path, $template);

  ($name, $wrapper);
}


sub local_name {
  my ($self, $template) = @_;
  my ($name, $wrapper) = $self->split_name_wrapper($template);
  $name 
}

sub wrapper_def {
  my ($self, $template) = @_;
  my ($name, $wrapper) = $self->split_name_wrapper($template);
  return $wrapper;
}


sub owns_tpl {
  my ($self, $template) = @_;
  $self->local_name($template) 
    || $self->_is_static_path($template) 
    || $self->_resolve_scaffold_file($template) 
  ? 1 : 0
}




1;