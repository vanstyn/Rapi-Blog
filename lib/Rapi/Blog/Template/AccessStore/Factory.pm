package Rapi::Blog::Template::AccessStore::Factory;
use strict;
use warnings;

use RapidApp::Util qw(:all);
use Rapi::Blog::Util;

use List::Util;
use Path::Class qw/file dir/;
use YAML::XS 0.64 'LoadFile';

require Rapi::Blog::Template::AccessStore;

sub new {
  my ($class, $params) = @_;
  Rapi::Blog::Template::AccessStore->new( $class->params_factory($params) );
}

sub params_factory {
  my ($class, $p) = @_;
  
  my $params = clone($p);
  
  my $Dir = $params->{scaffold_dir} or die "AccessStore::Factory requires 'scaffold_dir' to be supplied";
  die "scaffold_dir must be a Path::Class::Dir object" unless (ref($Dir)||'' eq 'Path::Class::Dir');
  
  my $cnf = $class->_get_scaffold_cnf($Dir, $params->{scaffold_config} ? delete $params->{scaffold_config} : {} );
  
  my $default_view_path = $class->_get_default_view_path($cnf);
  
  my $default_params = {
  
    scaffold_dir  => $Dir,
    scaffold_cnf  => $cnf,
    static_paths  => $cnf->{static_paths},
    private_paths => $cnf->{private_paths},
    default_ext   => $cnf->{default_ext},
    
    internal_post_path => $cnf->{internal_post_path},
    view_wrappers      => $cnf->{view_wrappers},
    default_view_path  => $default_view_path,
    preview_path       => $cnf->{preview_path} || $default_view_path,

  };
  
  # Prune out undef supplied values when they are available/defined in defaults above:
  (defined $default_params->{$_} && ! defined $params->{$_}) and delete $params->{$_} for (keys %$params);
  
  %$params = ( %$default_params, %$params );

  $params;
}




sub _get_scaffold_cnf {
  my ($class, $Dir, $config) = @_;
  
  my $defaults = {
    favicon            => 'favicon.ico',
    landing_page       => 'index.html',
    internal_post_path => 'private/post/',
    not_found          => 'rapidapp/public/http-404.html',
    view_wrappers      => [],
    static_paths       => ['/'],
    private_paths      => [],
    default_ext        => 'html',
  
  };
  
  my $cnf = clone( $config );
  
  my $yaml_file = $Dir->file('scaffold.yml');
  if (-f $yaml_file) {
    my $data = LoadFile( $yaml_file );
    %$cnf = ( %$data, %$cnf );
  }
  
  %$cnf = ( %$defaults, %$cnf );

  return $cnf
}


sub _get_default_view_path {
  my ($self, $cnf) = @_;
  
  return $cnf->{default_view_path} if ($cnf->{default_view_path});
  
  # first marked 'default' or first type 'include' or first anything
  my @wrappers = grep { $_->{path} } @{$cnf->{view_wrappers} || []};
  my $def = List::Util::first { $_->{default} } @wrappers;
  $def ||= List::Util::first { $_->{type} eq 'include' } @wrappers;
  $def ||= $wrappers[0];
  
  unless($def) {
    warn "\n ** Waring: scaffold has no suitable view_wrappers to use as 'default_view_path'\n\n";
    return undef;
  }

  return $def->{path}
};






1;