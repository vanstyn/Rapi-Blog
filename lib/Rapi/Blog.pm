package Rapi::Blog;
use Moose;
use namespace::autoclean;

use RapidApp 1.2101_50;

use Catalyst qw/
    -Debug
    RapidApp::RapidDbic
/;

extends 'Catalyst';

our $VERSION = '0.01';
our $TITLE = "Rapi::Blog v" . $VERSION;

my $tpl_regex = '^site\/';

__PACKAGE__->config(
    name => 'Rapi::Blog',

    # The general 'RapidApp' config controls aspects of the special components that
    # are globally injected/mounted into the Catalyst application dispatcher:
    'RapidApp' => {
      ## To change the root RapidApp module to be mounted someplace other than
      ## at the root (/) of the Catalyst app (default is '' which is the root)
      module_root_namespace => 'adm',

      ## To load additional, custom RapidApp modules (under the root module):
      #load_modules => { somemodule => 'Some::RapidApp::Module::Class' },

      ## To set a custom favicon for all pages generated by RapidApp
      #default_favicon_url => '/assets/rapidapp/misc/static/images/rapidapp_icon_small.ico',
    },
    
    'Plugin::RapidApp::TabGui' => {
      title => $TITLE,
      nav_title => 'Administration',
      dashboard_url => '/tple/site/dashboard.md',
      template_navtree_regex => $tpl_regex
    },
    
    'Controller::RapidApp::Template' => {
      root_template_prefix  => 'site/public/page/',
      root_template         => 'site/public/page/home',
      read_alias_path => '/tpl',  #<-- already the default
      edit_alias_path => '/tple', #<-- already the default
      default_template_extension => 'html',
      access_params => {
        writable_regex      => $tpl_regex,
        creatable_regex     => $tpl_regex,
        deletable_regex     => $tpl_regex,
        external_tpl_regex  => $tpl_regex.'public\/',
      },
      access_class => 'Rapi::Blog::Template::Access',
      store_class  => 'Rapi::Blog::Template::Store',
      store_params => {
        content_path => 'site/content/',
        view_wrappers => {
          'content/' => 'site/content/standard_wrapper.html'
        
        },
        resource_dir => 'root/bootstrap-3.3.7-dist',
        resource_paths => [qw/css js fonts/],

        get_Model => sub { Rapi::Blog->model('DB') } 
      }

      
    }

);

# Start the application
__PACKAGE__->setup();

1;


# ---
# This app was initially generated/bootrapped with:
#  rapidapp.pl --helpers RapidDbic Rapi::Blog -- --blank-ddl
# ---


__END__

=head1 NAME

Rapi::Blog - Catalyst/RapidApp based application

=head1 SYNOPSIS

    script/rapi_blog_server.pl

=head1 DESCRIPTION

[enter your description here]

=head1 SEE ALSO

L<RapidApp>, L<Catalyst>

=head1 AUTHOR

root

=head1 LICENSE

This library is free software. You can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
