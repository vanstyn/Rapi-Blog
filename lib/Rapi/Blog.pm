package Rapi::Blog;

use strict;
use warnings;

# ABSTRACT: RapidApp-powered blog

use RapidApp 1.2111_53;

use Moose;
extends 'RapidApp::Builder';

use Types::Standard qw(:all);

use RapidApp::Util ':all';
use Path::Class qw/file dir/;
use YAML::XS 0.64 'LoadFile';

our $VERSION = '0.02';
our $TITLE = "Rapi::Blog v" . $VERSION;

has 'site_path',        is => 'ro', required => 1;
has 'scaffold_path',    is => 'ro', isa => Maybe[Str], default => sub { undef };
has 'scaffold_config',  is => 'ro', isa => HashRef, default => sub {{}};

has '+base_appname', default => sub { 'Rapi::Blog::App' };
has '+debug',        default => sub {1};

has '+inject_components', default => sub {
  my $self = shift;
  my $model = 'Rapi::Blog::Model::DB';
  
  my $db = $self->site_dir->file('rapi_blog.db');
  
  Module::Runtime::require_module($model);
  $model->config->{connect_info}{dsn} = "dbi:SQLite:$db";

  return [
    [ $model => 'Model::DB' ]
  ]
};

has 'site_dir', is => 'ro', init_arg => undef, lazy => 1, default => sub {
  my $self = shift;
  
  my $Dir = dir( $self->site_path );
  -d $Dir or die "Scaffold directory '$Dir' not found.\n";
  
  return $Dir
}, isa => InstanceOf['Path::Class::Dir'];

has 'scaffold_dir', is => 'ro', init_arg => undef, lazy => 1, default => sub {
  my $self = shift;
  
  my $path = $self->scaffold_path || $self->site_dir->subdir('scaffold');
  
  my $Dir = dir( $path );
  -d $Dir or die "Scaffold directory '$Dir' not found.\n";
  
  return $Dir
}, isa => InstanceOf['Path::Class::Dir'];

has 'scaffold_cnf', is => 'ro', init_arg => undef, lazy => 1, default => sub {
  my $self = shift;
  
  my $defaults = {
    favicon            => 'favicon.ico',
    landing_page       => 'index.html',
    internal_post_path => 'private/post/',
  
  };
  
  my $cnf = clone( $self->scaffold_config );
  
  my $yaml_file = $self->scaffold_dir->file('scaffold.yml');
  if (-f $yaml_file) {
    my $data = LoadFile( $yaml_file );
    %$cnf = ( %$data, %$cnf );
  }
  
  %$cnf = ( %$defaults, %$cnf );
  
  return $cnf

}, isa => HashRef;


sub _build_version { $VERSION }
sub _build_plugins { ['RapidApp::RapidDbic'] }

sub _build_config {
  my $self = shift;
  
  my $tpl_regex = '^site\/';

  my $config = {
  
    'RapidApp' => {
      module_root_namespace => 'adm',
    },
    
    'Model::RapidApp::CoreSchema' => {
      sqlite_file => $self->site_dir->file('rapidapp_coreschema.db')->stringify
    },
    
    'Controller::SimpleCAS' => {
      store_path => $self->site_dir->subdir('cas_store')->stringify
    },
    
    'Plugin::RapidApp::TabGui' => {
      title => $TITLE,
      nav_title => 'Administration',
      dashboard_url => '/tple/site/dashboard.md',
      template_navtree_regex => $tpl_regex
    },
    
    'Controller::RapidApp::Template' => {
      root_template_prefix  => '/',
      root_template         => $self->scaffold_cnf->{landing_page},
      read_alias_path => '/tpl',  #<-- already the default
      edit_alias_path => '/tple', #<-- already the default
      default_template_extension => 'html',
      access_class => 'Rapi::Blog::Template::AccessStore',
      access_params => {
        writable_regex      => $tpl_regex,
        creatable_regex     => $tpl_regex,
        deletable_regex     => $tpl_regex,
        
        scaffold_dir  => $self->scaffold_dir,
        scaffold_cnf  => $self->scaffold_cnf,
        static_paths  => $self->scaffold_cnf->{static_paths},
        private_paths => $self->scaffold_cnf->{private_paths},
        
        internal_post_path => $self->scaffold_cnf->{internal_post_path},
        
        view_wrappers => $self->scaffold_cnf->{view_wrappers}, 

        get_Model => sub { $self->base_appname->model('DB') } 
      } 
    }
  };
  
  if(my $favname = $self->scaffold_cnf->{favicon}) {
    my $Fav = $self->scaffold_dir->file($favname);
    $config->{RapidApp}{default_favicon_url} = $Fav->stringify if (-f $Fav);
  }
  
  
  return $config
}

1;
