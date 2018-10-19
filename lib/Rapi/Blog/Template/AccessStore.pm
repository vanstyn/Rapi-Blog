package Rapi::Blog::Template::AccessStore;
use strict;
use warnings;

use RapidApp::Util qw(:all);
use Rapi::Blog::Util;
use List::Util;

use Moo;
extends 'RapidApp::Template::AccessStore';
use Types::Standard ':all';

use Rapi::Blog::Scaffold;
use Rapi::Blog::Template::AccessStore::DispatchRule;

use Plack::App::File;
use Plack::Builder;
use Plack::Middleware::ConditionalGET;

sub _cache_slots { (shift)->local_cache->{template_row_slot} //= {} }

has 'underlay_scaffold_dirs',  is => 'ro', isa => ArrayRef, default => sub {[]};

has 'Scaffolds', is => 'ro', isa => ArrayRef[InstanceOf['Rapi::Blog::Scaffold']], lazy => 1, default => sub {
  my $self = shift;
  [
    Rapi::Blog::Scaffold->new(
      dir    => $self->scaffold_dir,
      config => $self->scaffold_cnf,
      Post_exists_fn => $self->Post_exists_fn
    ), 
    map { Rapi::Blog::Scaffold->new( 
      dir => $_,
      Post_exists_fn => $self->Post_exists_fn
    ) } @{ $self->underlay_scaffold_dirs }
  ]
};


has 'Post_exists_fn', is => 'ro', init_arg => undef, lazy => 1, default => sub {
  my $self = shift;
  my $Rs = $self->Model->resultset('Post');
  sub {
    my $name = shift;
    $Rs->permission_filtered->search_rs({ 'me.name' => $name })->count ? 1 : 0
  };
};

has 'Post_mtime_fn', is => 'ro', init_arg => undef, lazy => 1, default => sub {
  my $self = shift;
  my $Rs = $self->Model->resultset('Post');
  sub {
    my $name = shift;
    
    my $Row = $Rs->permission_filtered
      ->search_rs(undef,{
        columns => ['update_ts']
      })
      ->search_rs({ 'me.name' => $name })
      ->first or return undef;
  
    return Date::Parse::str2time( $Row->get_column('update_ts') )
  };
};

has 'Post_content_fn', is => 'ro', init_arg => undef, lazy => 1, default => sub {
  my $self = shift;
  my $Rs = $self->Model->resultset('Post');
  sub {
    my $name = shift;
    
    my $Row = $Rs->permission_filtered
      ->search_rs(undef,{
        columns => ['body']
      })
      ->search_rs({ 'me.name' => $name })
      ->first or return undef;
  
    return $Row->get_column('body')
  };
};


sub DispatchRule_for {
  my ($self,@args) = @_;
  my $path = join('/',@args);  
  $self->_cache_slots->{$path}{DispatchRule} ||= Rapi::Blog::Template::AccessStore::DispatchRule->new(
    path => $path, AccessStore => $self, ctx => RapidApp->active_request_context
  )
}


has 'scaffold_dir',  is => 'ro', isa => InstanceOf['Path::Class::Dir'], required => 1;
has 'scaffold_cnf',  is => 'ro', isa => HashRef, required => 1;
has 'static_paths',  is => 'ro', isa => ArrayRef[Str], default => sub {[]};
has 'private_paths', is => 'ro', isa => ArrayRef[Str], default => sub {[]};
has 'default_ext',   is => 'ro', isa => Maybe[Str],    default => sub {undef};

around 'template_external_tpl' => sub {
  my ($orig,$self,@args) = @_;
  my $template = join('/',@args);
  
  $self->DispatchRule_for($template)->claimed ? 1 : $self->$orig(@args)
};


# Deny post templates access to to privileged attributes such as the catalyst context object). 
# This could be expanded later on to allow only certain posts to be able to access these attributes.
around 'template_admin_tpl' => sub {
  my ($orig,$self,@args) = @_;
  my $template = join('/',@args);
  $self->DispatchRule_for($template)->post_name ? 0 : $self->$orig(@args)
};






sub _is_static_path {
  my ($self, $template) = @_;
  $self->_cache_slots->{$template}{_is_static_path} //= do {
    $self->DispatchRule_for($template)->Scaffold->_is_static_path($template)
  }
}

sub _is_private_path {
  my ($self, $template) = @_;
  $self->_cache_slots->{$template}{_is_private_path} //= do {
    $self->DispatchRule_for($template)->Scaffold->_is_private_path($template)
  }
}


sub _resolve_scaffold_file {
  my ($self, $template) = @_;
  $self->_cache_slots->{$template}{_resolve_scaffold_file} //= do {
    $self->DispatchRule_for($template)->Scaffold->_resolve_scaffold_file($template)
  }
}


sub _resolve_static_path {
  my ($self, $template) = @_;
  $self->DispatchRule_for($template)->Scaffold->_resolve_static_path($template)
}


sub _File_mtime {
  my ($self, $File) = @_;
  my $Stat = $File->stat or return undef;
  $Stat->mtime
}


sub _File_content {
  my ($self, $File) = @_;
  scalar $File->slurp
}

sub templateData {
  my ($self, $template) = @_;
  die 'template name argument missing!' unless ($template);
  
  $self->_cache_slots->{$template}{templateData} //= do {
    my $data = {};
    if(my $name = $self->DispatchRule_for($template)->post_name) {
      $data->{Row} = $data->{Post} = $self->Model->resultset('Post')
        ->permission_filtered
        ->search_rs({ 'me.name' => $name })
        ->first; 
    }
    $data
  }
}

# -----------------
# Access class API:

around 'get_template_vars' => sub {
  my ($orig,$self,@args) = @_;
  my $c = RapidApp->active_request_context;
  
  my $template = join('/',@args);
  
  my $vars = {
    %{ $self->$orig(@args) },
    %{ $self->templateData($template) || {} },
    
    #scaffold        => $self->scaffold_cnf,
    list_posts      => sub { $self->Model->resultset('Post')     ->list_posts(@_)      },
    list_tags       => sub { $self->Model->resultset('Tag')      ->list_tags(@_)       },
    list_categories => sub { $self->Model->resultset('Category') ->list_categories(@_) },
    list_sections   => sub { $self->Model->resultset('Section')  ->list_sections(@_)   },
    list_users      => sub { $self->Model->resultset('User')     ->list_users(@_)      },
    
    # TODO: consider mount_url
    request_path => sub { $c ? join('','/',$c->req->path) : undef },
    
    User => sub { Rapi::Blog::Util->get_User },
    
    # Path to the 'Remote' controller
    remote_action_path => sub { $c ? join('',$c->mount_url,'/remote') : undef },
    
    add_post_path => sub {
      my $ns = $c->module_root_namespace;
      if(my $mode = shift) {
        $mode = lc($mode);
        # Note: 'direct' is not useful un this context since add relies on opening new tab
        die "add_post_path(): bad argument '$mode' -- must be undef or 'navable'"
          unless ($mode eq 'navable');
        return join('',$c->mount_url,'/rapidapp/module/',$mode,'/',$ns,'/main/db/db_post/add')
      }
      else {
        return join('',$c->mount_url,'/',$ns,'/#!/',$ns,'/main/db/db_post/add')
      }
    },
    
    resolve_section_id => sub {
      if(my $id = shift) {
        my $Section = $self->Model->resultset('Section')
          ->search_rs({ 'me.id' => $id })
          ->first;
        return $Section ? $Section->name : $id
      }
    },
    
    # Expose this here so its available to non-priv templates:
    mount_url => sub { $c->mount_url }
    
  };
  
  if (my $Scaffold = $self->DispatchRule_for($template)->Scaffold) {
    $vars->{scaffold} = $Scaffold->config;
  }
  
  return $vars
  
};


# -----------------
# Store class API:


use DateTime;
use Date::Parse;
use Path::Class qw/file dir/;

has 'get_Model', is => 'ro', isa => Maybe[CodeRef], default => sub {undef};

has 'Model', is => 'ro', lazy => 1, default => sub {
  my $self = shift;
  die "Must supply 'Model' or 'get_Model'" unless $self->get_Model;
  $self->get_Model->()
}, isa => Object;


has 'internal_post_path', is => 'ro', isa => Str, required => 1;
has 'view_wrappers',      is => 'ro', isa => ArrayRef[HashRef], default => sub {[]};
has 'default_view_path',  is => 'ro', isa => Maybe[Str], default => sub {undef};
has 'preview_path',       is => 'ro', isa => Maybe[Str], default => sub {undef};


sub get_uid {
  my $self = shift;
  
  if(my $c = RapidApp->active_request_context) {
    return $c->user->id if ($c->can('user'));
  }
  
  return 0;
}

sub cur_ts {
  my $self = shift;
  my $dt = DateTime->now( time_zone => 'local' );
  join(' ',$dt->ymd('-'),$dt->hms(':'));
}

sub owns_tpl {
  my ($self, $template) = @_;
  $self->DispatchRule_for($template)->claimed
}

sub template_exists {
  my ($self, $template) = @_;
  $self->DispatchRule_for($template)->exists
}


sub template_mtime {
  my ($self, $template) = @_;
  $self->_cache_slots->{$template}{template_mtime} //= $self->_template_mtime($template)
}

sub _template_mtime {
  my ($self, $template) = @_;
  
  $self->DispatchRule_for($template)->mtime
}

sub template_content {
  my ($self, $template) = @_;
  $self->_cache_slots->{$template}{template_content} //= $self->_template_content($template)
}

sub _template_content {
  my ($self, $template) = @_;
  
  $self->DispatchRule_for($template)->content
}


sub create_template {
  my ($self, $template, $content) = @_;
  
  my $name = $self->DispatchRule_for($template)->post_name or return undef;
  
  my $create = {
    name => $name,
    body => $content,
    published => 1
  };
  
  $self->Model->resultset('Post')->create($create) ? 1 : 0;
}


sub update_template {
  my ($self, $template, $content) = @_;
  my $name = $self->DispatchRule_for($template)->post_name or return undef;
  
  my $Row = $self->Model->resultset('Post')
    ->search_rs({ 'me.name' => $name })
    ->first or die 'Not found!';
  
  $Row->update({ body => $content }) ? 1 : 0;
}


sub delete_template {
  my ($self, $template) = @_;
  my $name = $self->DispatchRule_for($template)->post_name or return undef;
  
  my $Row = $self->Model->resultset('Post')
    ->search_rs({ 'me.name' => $name })
    ->first or die 'Not found!';
  
  $Row->delete ? 1 : 0;
}

around 'get_template_format' => sub {
  my ($orig, $self, @args) = @_;
  my $template = join('/',@args);
  
  # By rule all local tempaltes (Post rows) are markdown
  return $self->DispatchRule_for($template)->post_name
    ? 'markdown'
    : $self->$orig(@args)
};

sub list_templates {
  my $self = shift;
  [ map { join('',$self->internal_post_path,$_) } $self->Model->resultset('Post')->get_column('name')->all ]
}

around 'template_post_processor_class' => sub {
  my ($orig,$self,@args) = @_;
  my $template = join('/',@args);
  
  # By rule, never use a post processor with a wrapper view:
  return undef if $self->DispatchRule_for($template)->ViewWrapper;
  
  # Render markdown with our MarkdownElement post-processor if the next template
  # (i.e. which is including us) is one of our wrapper/views. This will defer
  # rendering of markdown to the client-side with the marked.js library
  if($self->process_Context && $self->get_template_format($template) eq 'markdown') {
    if(my $next_template = $self->process_Context->next_template) {
      if($self->DispatchRule_for($next_template)->ViewWrapper) {
        return 'Rapi::Blog::Template::Postprocessor::MarkdownElement'
      }
    }
  }

  return $self->$orig(@args)
};


sub template_psgi_response {
  my ($self, $template, $c) = @_;
  
  $self->DispatchRule_for($template)->maybe_psgi_response
}

sub _forward_to_404_template {
  my $self = shift;
  my $c = shift || RapidApp->active_request_context;
  
  my $tpl = $self->scaffold_cnf->{not_found} || 'rapidapp/public/http-404.html';
  
  # catch deep recursion:
  die "Error dispatching 404 not found template" if ($c->stash->{__forward_to_404_template}++);
  
  $c->res->status(404);
  $c->detach( '/rapidapp/template/view', [$tpl] )
}


1;