package Rapi::Blog::Template::AccessStore;
use strict;
use warnings;

use RapidApp::Util qw(:all);

use Moo;
extends 'RapidApp::Template::AccessStore';
use Types::Standard ':all';

use Plack::App::File;

has 'Resource_app', is => 'ro', lazy => 1, default => sub {
  my $self = shift;
  Plack::App::File->new(root => $self->_resource_Dir)->to_app
};

sub templateData {
  my ($self, $template) = @_;
  die 'template name argument missing!' unless ($template);
  $self->local_cache->{template_row_slot}{$template} //= do {
    my $data = {};
    if(my $name = $self->local_name($template)) {
      $data->{Row} = $self->Model->resultset('Content')
        ->search_rs(undef,{ join => 'content_names' })
        ->search_rs({ 'content_names.name' => $name })
        ->first; 
    }
    $data
  }
}

# -----------------
# Access class API:

around 'get_template_vars' => sub {
  my ($orig,$self,@args) = @_;
  
  my $template = join('/',@args);
  
  return {
    %{ $self->$orig(@args) },
    %{ $self->templateData($template) || {} }
  };
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


has 'content_path',  is => 'ro', isa => Str, required => 1;
has 'view_wrappers', is => 'ro', isa => HashRef, default => sub {{}};

has 'resource_dir',    is => 'ro', isa => Str, required => 1;
has 'resource_paths',  is => 'ro', isa => ArrayRef[Str], required => 1;

has '_resource_paths_ndx', is => 'ro', lazy => 1, 
  default => sub { return { map {$_=>1} @{(shift)->resource_paths} }};

has '_resource_Dir', is => 'ro', lazy => 1, default => sub {
  my $self = shift;
  dir( RapidApp::Util::find_app_home('Rapi::Blog'), $self->resource_dir )->resolve
};


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

# "resources" match the end of the URL, and are keywords like css/, js/, etc, and are
# served from the filesystem instead of the database. The idea is that by matching on
# the end of the URL, all relative requests, which may be generated by a template,
# will work, regardless of the path the template is being dispatched from
sub resource_name {
  my ($self, $template) = @_;
  my @parts = split(/\//,$template);
  
  my $fn  = pop @parts;
  my $dir = pop @parts;
  
  return $self->_resource_paths_ndx->{$dir}
    ? join('/',$dir,$fn)
    : undef
}


sub split_name_wrapper {
  my ($self, $template) = @_;
  
  my ($name, $wrapper);
  
  for my $view (keys %{ $self->view_wrappers }, $self->content_path) {
    my $pfx;
    ($pfx,$name) = split($view,$template,2);
    if($name && $pfx eq '') {
      $wrapper = $self->view_wrappers->{$view};
      last;
    };
  }
  
  return ($name, $wrapper);
}


sub local_name {
  my ($self, $template) = @_;
  my ($name, $wrapper) = $self->split_name_wrapper($template);
  return $name;
}

sub wrapper_name {
  my ($self, $template) = @_;
  my ($name, $wrapper) = $self->split_name_wrapper($template);
  return $wrapper;
}


sub owns_tpl {
  my ($self, $template) = @_;
  $self->local_name($template) ? 1 : 0
}


sub template_exists {
  my ($self, $template) = @_;
  
  if (my $resource = $self->resource_name($template)) {
    return $self->_resource_exists($resource);
  }
  
  my $name = $self->local_name($template) or return undef;
  
  $self->Model->resultset('ContentName')
    ->search_rs({ 'me.name' => $name })
    ->count
}

sub template_mtime {
  my ($self, $template) = @_;
  
  if (my $resource = $self->resource_name($template)) {
    return $self->_resource_mtime($resource);
  }
  
  my $name = $self->local_name($template) or return undef;
  
  my $Row = $self->Model->resultset('Content')
    ->search_rs(undef,{
      join    => 'content_names',
      columns => ['update_ts']
    })
    ->search_rs({ 'content_names.name' => $name })
    ->first or return undef;
  
  return Date::Parse::str2time( $Row->get_column('update_ts') )
}

sub template_content {
  my ($self, $template) = @_;
  
  if (my $resource = $self->resource_name($template)) {
    return $self->_resource_content($resource);
  }
  
  my ($name, $wrapper) = $self->split_name_wrapper($template);
  return undef unless ($name);
  
  return join("\n",
    join('','[% WRAPPER "',$wrapper,'" %]'),
    join('','[% INCLUDE "',$self->content_path,$name,'" %]'),
    '[% END %]'
  ) if ($wrapper);
  
  my $Row = $self->templateData($template)->{Row} or return undef;
  
  #my $Row = $self->Model->resultset('Content')
  #  ->search_rs(undef,{
  #    join    => 'content_names',
  #    columns => ['body']
  #  })
  #  ->search_rs({ 'content_names.name' => $name })
  #  ->first or return undef;
  
  return $Row->get_column('body');
}


sub create_template {
  my ($self, $template, $content) = @_;
  my $name = $self->local_name($template) or return undef;
  
  my $uid = $self->get_uid;
  my $ts  = $self->cur_ts;

  my $create = {
    name => $name,
    prio => 0,
    content => {
      create_user_id => $uid,
      update_user_id => $uid,
      create_ts => $ts,
      update_ts => $ts,
      body => $content
    }
  };
  
  $self->Model->resultset('ContentName')->create($create) ? 1 : 0;
  
}


sub update_template {
  my ($self, $template, $content) = @_;
  my $name = $self->local_name($template) or return undef;
  
  my $uid = $self->get_uid;
  my $ts  = $self->cur_ts;
  
  my $Row = $self->Model->resultset('Content')
    ->search_rs(undef,{
      join    => 'content_names',
    })
    ->search_rs({ 'content_names.name' => $name })
    ->first or die 'Not found!';
  
  $Row->update({
    update_user_id => $uid,
    update_ts => $ts,
    body => $content
  }) ? 1 : 0;
}


sub delete_template {
  my ($self, $template) = @_;
  my $name = $self->local_name($template) or return undef;
  
  my $Row = $self->Model->resultset('Content')
    ->search_rs(undef,{
      join    => 'content_names',
    })
    ->search_rs({ 'content_names.name' => $name })
    ->first or die 'Not found!';
  
  $Row->delete ? 1 : 0;
}


sub list_templates {
  my $self = shift;
  [ map { join('',$self->content_path,$_) } $self->Model->resultset('ContentName')->get_column('name')->all ]
}



sub _resource_exists {
  my ($self, $resource) = @_;
  my $File = file( $self->_resource_Dir, $resource );
  -f $File
}


sub _resource_mtime {
  my ($self, $resource) = @_;
  my $File = file( $self->_resource_Dir, $resource );
  my $Stat = $File->stat or return undef;
  $Stat->mtime
}


sub _resource_content {
  my ($self, $resource) = @_;
  my $File = file( $self->_resource_Dir, $resource )->resolve;
  scalar $File->slurp
}


around 'template_post_processor_class' => sub {
  my ($orig,$self,@args) = @_;
  my $template = join('/',@args);
  
  # By rule, never use a post processor with a wrapper view:
  return undef if ($self->wrapper_name($template));
  
  # Render markdown with our MarkdownElement post-processor if the next template
  # (i.e. which is including us) is one of our wrapper/views. This will defer
  # rendering of markdown to the client-side with the marked.js library
  if($self->process_Context && $self->get_template_format($template) eq 'markdown') {
    if(my $next_template = $self->process_Context->next_template) {
      if($self->wrapper_name($next_template)) {
        return 'Rapi::Blog::Template::Postprocessor::MarkdownElement'
      }
    }
  }

  return $self->$orig(@args)
};


sub template_psgi_response {
  my ($self, $template, $c) = @_;
  
  my $resource = $self->resource_name($template) or return undef;
  
  my $env = {
    %{ $c->req->env },
    PATH_INFO   => "/$resource",
    SCRIPT_NAME => ''
  };
  
  return $self->Resource_app->($env)
}

1;