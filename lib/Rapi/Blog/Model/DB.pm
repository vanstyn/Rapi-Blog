package Rapi::Blog::Model::DB;
use Moo;
extends 'Catalyst::Model::DBIC::Schema';
with 'RapidApp::Util::Role::ModelDBIC';

use strict;
use warnings;

use Path::Class qw(file);
use RapidApp::Util ':all';
my $db_path = file( RapidApp::Util::find_app_home('Rapi::Blog'), 'rapi_blog.db' );
sub _sqlt_db_path { "$db_path" };    # exposed for use by the regen devel script

__PACKAGE__->config(
  schema_class => 'Rapi::Blog::DB',

  connect_info => {
    dsn             => "dbi:SQLite:$db_path",
    user            => '',
    password        => '',
    quote_names     => q{1},
    sqlite_unicode  => q{1},
    on_connect_call => q{use_foreign_keys},
  },

  # Configs for the RapidApp::RapidDbic Catalyst Plugin:
  RapidDbic => {

    # use only the relationship column of a foreign-key and hide the
    # redundant literal column when the names are different:
    hide_fk_columns => 1,

    # The grid_class is used to automatically setup a module for each source in the
    # navtree with the grid_params for each source supplied as its options.
    grid_class  => 'Rapi::Blog::Module::GridBase',
    grid_params => {
      # The special '*defaults' key applies to all sources at once
      '*defaults' => {
        include_colspec => ['*'],    #<-- default already ['*']
        ## uncomment these lines to turn on editing in all grids
        #updatable_colspec   => ['*'],
        #creatable_colspec   => ['*'],
        #destroyable_relspec => ['*'],
        extra_extconfig => {
          store_button_cnf => {
            save => { showtext => 1 },
            undo => { showtext => 1 }
          }
        }
      }
    },

    # TableSpecs define extra RapidApp-specific metadata for each source
    # and is used/available to all modules which interact with them
    TableSpecs => {
      Content => {
        display_column => 'id',
        title          => 'Content',
        title_multi    => 'Content Rows',
        iconCls        => 'ra-icon-pg',
        multiIconCls   => 'ra-icon-pg-multi',
        columns        => {
          id => {
            allow_add => 0,
            header    => 'id',
            #width => 100,
            #renderer => 'RA.ux.App.someJsFunc',
            #profiles => [],
          },
          create_ts => {
            header => 'create_ts',
            #width => 100,
            #renderer => 'RA.ux.App.someJsFunc',
            #profiles => [],
          },
          update_ts => {
            header => 'update_ts',
            #width => 100,
            #renderer => 'RA.ux.App.someJsFunc',
            #profiles => [],
          },
          create_user_id => {
            header => 'create_user_id',
            #width => 100,
            #renderer => 'RA.ux.App.someJsFunc',
            profiles => ['hidden'],
          },
          update_user_id => {
            header => 'update_user_id',
            #width => 100,
            #renderer => 'RA.ux.App.someJsFunc',
            profiles => ['hidden'],
          },
          pp_code => {
            header => 'pp_code',
            #width => 100,
            #renderer => 'RA.ux.App.someJsFunc',
            #profiles => [],
          },
          format_code => {
            header => 'format_code',
            #width => 100,
            #renderer => 'RA.ux.App.someJsFunc',
            #profiles => [],
          },
          content_keywords => {
            header => 'content_keywords',
            #width => 100,
            #sortable => 1,
            #renderer => 'RA.ux.App.someJsFunc',
            #profiles => [],
          },
          content_names => {
            header => 'content_names',
            #width => 100,
            #sortable => 1,
            #renderer => 'RA.ux.App.someJsFunc',
            #profiles => [],
          },
          create_user => {
            header => 'create_user',
            #width => 100,
            #renderer => 'RA.ux.App.someJsFunc',
            #profiles => [],
          },
          update_user => {
            header => 'update_user',
            #width => 100,
            #renderer => 'RA.ux.App.someJsFunc',
            #profiles => [],
          },
          body => {
            header => 'body',
            #width => 100,
            #renderer => 'RA.ux.App.someJsFunc',
            #profiles => [],
          },
          name => {
            header => 'name',
            #width => 100,
            #renderer => 'RA.ux.App.someJsFunc',
            #profiles => [],
          },
          published => {
            header => 'published',
            #width => 100,
            #renderer => 'RA.ux.App.someJsFunc',
            #profiles => [],
          },
          title => {
            header => 'title',
            #width => 100,
            #renderer => 'RA.ux.App.someJsFunc',
            #profiles => [],
          },
          publish_ts => {
            header => 'publish_ts',
            #width => 100,
            #renderer => 'RA.ux.App.someJsFunc',
            #profiles => [],
          },
        },
      },
      ContentKeyword => {
        display_column => 'id',
        title          => 'ContentKeyword',
        title_multi    => 'ContentKeyword Rows',
        iconCls        => 'ra-icon-pg',
        multiIconCls   => 'ra-icon-pg-multi',
        columns        => {
          id => {
            allow_add => 0,
            header    => 'id',
            #width => 100,
            #renderer => 'RA.ux.App.someJsFunc',
            #profiles => [],
          },
          content_id => {
            header => 'content_id',
            #width => 100,
            #renderer => 'RA.ux.App.someJsFunc',
            profiles => ['hidden'],
          },
          keyword_name => {
            header => 'keyword_name',
            #width => 100,
            #renderer => 'RA.ux.App.someJsFunc',
            #profiles => [],
          },
          content => {
            header => 'content',
            #width => 100,
            #renderer => 'RA.ux.App.someJsFunc',
            #profiles => [],
          },
        },
      },
      ContentName => {
        display_column => 'name',
        title          => 'ContentName',
        title_multi    => 'ContentName Rows',
        iconCls        => 'ra-icon-pg',
        multiIconCls   => 'ra-icon-pg-multi',
        columns        => {
          id => {
            allow_add => 0,
            header    => 'id',
            #width => 100,
            #renderer => 'RA.ux.App.someJsFunc',
            #profiles => [],
          },
          content_id => {
            header => 'content_id',
            #width => 100,
            #renderer => 'RA.ux.App.someJsFunc',
            profiles => ['hidden'],
          },
          name => {
            header => 'name',
            #width => 100,
            #renderer => 'RA.ux.App.someJsFunc',
            #profiles => [],
          },
          prio => {
            header => 'prio',
            #width => 100,
            #renderer => 'RA.ux.App.someJsFunc',
            #profiles => [],
          },
          content => {
            header => 'content',
            #width => 100,
            #renderer => 'RA.ux.App.someJsFunc',
            #profiles => [],
          },
          published => {
            header => 'published',
            #width => 100,
            #renderer => 'RA.ux.App.someJsFunc',
            #profiles => [],
          },
        },
      },
      Format => {
        display_column => 'name',
        title          => 'Format',
        title_multi    => 'Format Rows',
        iconCls        => 'ra-icon-pg',
        multiIconCls   => 'ra-icon-pg-multi',
        columns        => {
          code => {
            header => 'code',
            #width => 100,
            #renderer => 'RA.ux.App.someJsFunc',
            #profiles => [],
          },
          name => {
            header => 'name',
            #width => 100,
            #renderer => 'RA.ux.App.someJsFunc',
            #profiles => [],
          },
          contents => {
            header => 'contents',
            #width => 100,
            #sortable => 1,
            #renderer => 'RA.ux.App.someJsFunc',
            #profiles => [],
          },
        },
      },
      Keyword => {
        display_column => 'name',
        title          => 'Keyword',
        title_multi    => 'Keyword Rows',
        iconCls        => 'ra-icon-pg',
        multiIconCls   => 'ra-icon-pg-multi',
        columns        => {
          name => {
            header => 'name',
            #width => 100,
            #renderer => 'RA.ux.App.someJsFunc',
            #profiles => [],
          },
          content_keyword => {
            header => 'content_keyword',
            #width => 100,
            #renderer => 'RA.ux.App.someJsFunc',
            #profiles => [],
          },
        },
      },
      Preprocessor => {
        display_column => 'name',
        title          => 'Preprocessor',
        title_multi    => 'Preprocessor Rows',
        iconCls        => 'ra-icon-pg',
        multiIconCls   => 'ra-icon-pg-multi',
        columns        => {
          code => {
            header => 'code',
            #width => 100,
            #renderer => 'RA.ux.App.someJsFunc',
            #profiles => [],
          },
          name => {
            header => 'name',
            #width => 100,
            #renderer => 'RA.ux.App.someJsFunc',
            #profiles => [],
          },
          contents => {
            header => 'contents',
            #width => 100,
            #sortable => 1,
            #renderer => 'RA.ux.App.someJsFunc',
            #profiles => [],
          },
        },
      },
      User => {
        display_column => 'id',
        title          => 'User',
        title_multi    => 'User Rows',
        iconCls        => 'ra-icon-pg',
        multiIconCls   => 'ra-icon-pg-multi',
        columns        => {
          id => {
            allow_add => 0,
            header    => 'id',
            #width => 100,
            #renderer => 'RA.ux.App.someJsFunc',
            #profiles => [],
          },
          username => {
            header => 'username',
            #width => 100,
            #renderer => 'RA.ux.App.someJsFunc',
            #profiles => [],
          },
          full_name => {
            header => 'full_name',
            #width => 100,
            #renderer => 'RA.ux.App.someJsFunc',
            #profiles => [],
          },
          content_create_users => {
            header => 'content_create_users',
            #width => 100,
            #sortable => 1,
            #renderer => 'RA.ux.App.someJsFunc',
            #profiles => [],
          },
          content_update_users => {
            header => 'content_update_users',
            #width => 100,
            #sortable => 1,
            #renderer => 'RA.ux.App.someJsFunc',
            #profiles => [],
          },
        },
      },
    },
  },

);

## ------
## Uncomment these lines to have the schema auto-deployed during
## application startup when the sqlite db file is missing:
#before 'setup' => sub {
#  my $self = shift;
#  return if (-f $db_path);
#  $self->schema_class->connect($self->connect_info->{dsn})->deploy;
#};
## ------

=head1 NAME

Rapi::Blog::Model::DB - Catalyst/RapidApp DBIC Schema Model

=head1 SYNOPSIS

See L<Rapi::Blog>

=head1 DESCRIPTION

L<Catalyst::Model::DBIC::Schema> Model using schema L<Rapi::Blog::DB>

=head1 GENERATED BY

Catalyst::Helper::Model::DBIC::Schema::ForRapidDbic - 0.65

=head1 AUTHOR

root

=head1 LICENSE

This library is free software, you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

1;
