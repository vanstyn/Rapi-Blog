package Rapi::Blog::Template::AccessStore;
use strict;
use warnings;

use RapidApp::Util qw(:all);

use Moo;
extends 'RapidApp::Template::AccessStore';
use Types::Standard ':all';

use Plack::App::File;

has 'scaffold_dir',  is => 'ro', isa => InstanceOf['Path::Class::Dir'], required => 1;
has 'scaffold_cnf',  is => 'ro', isa => HashRef, required => 1;
has 'static_paths',  is => 'ro', isa => ArrayRef[Str], default => sub {[]};
has 'private_paths', is => 'ro', isa => ArrayRef[Str], default => sub {[]};

around 'template_external_tpl' => sub {
  my ($orig,$self,@args) = @_;
  my $template = join('/',@args);

  return 1 if (
    $self->_is_static_path($template) || 
    $self->_resolve_scaffold_file($template) ||
    $self->wrapper_def($template)
  );

  return $self->$orig(@args)
};


has 'static_path_app', is => 'ro', lazy => 1, default => sub {
  my $self = shift;
  Plack::App::File->new(root => $self->scaffold_dir)->to_app
};


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
  
  my $reStr = join('','(',join('|', @list ),')');
  
  return qr/$reStr/
}



sub _is_static_path {
  my ($self, $template) = @_;
  my $Regexp = $self->_static_path_regexp or return 0;
  $template =~ $Regexp
}

sub _is_private_path {
  my ($self, $template) = @_;
  my $Regexp = $self->_private_path_regexp or return 0;
  $template =~ $Regexp
}

sub _resolve_scaffold_file {
  my ($self, $template) = @_;
  my $File = $self->scaffold_dir->file($template);
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
  $self->local_cache->{template_row_slot}{$template} //= do {
    my $data = {};
    if(my $name = $self->local_name($template)) {
      $data->{Row} = $self->Model->resultset('Post')
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
    
    scaffold     => $self->scaffold_cnf,
    list_posts   => sub { $self->Model->resultset('Post')->list_posts(@_) },
    
    # TODO: consider mount_url
    request_path => sub { $c ? join('','/',$c->req->path) : undef }
    
  };
  
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
has 'default_view_path',  is => 'ro', isa => Str, required => 1;


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

  return ($name, $wrapper);
}


sub local_name {
  my ($self, $template) = @_;
  my ($name, $wrapper) = $self->split_name_wrapper($template);
  return $name;
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

sub template_exists {
  my ($self, $template) = @_;
  
  return 1 if ($self->_resolve_scaffold_file($template));
  
  my $name = $self->local_name($template) or return undef;

  $self->Model->resultset('Post')
    ->search_rs({ 'me.name' => $name })
    ->count
}

sub template_mtime {
  my ($self, $template) = @_;
  
  if (my $File = $self->_resolve_scaffold_file($template)) {
    return $self->_File_mtime($File);
  }
  
  my $name = $self->local_name($template) or return undef;
  
  my $Row = $self->Model->resultset('Post')
    ->search_rs(undef,{
      columns => ['update_ts']
    })
    ->search_rs({ 'me.name' => $name })
    ->first or return undef;
  
  return Date::Parse::str2time( $Row->get_column('update_ts') )
}

sub template_content {
  my ($self, $template) = @_;
  
  if (my $File = $self->_resolve_scaffold_file($template)) {
    return $self->_File_content($File);
  }
  
  my ($name, $wrapper) = $self->split_name_wrapper($template);
  return undef unless ($name);
  
  if($wrapper) {
    my $wrap_name = $wrapper->{wrapper} or die "Bad view_wrapper definition -- 'wrapper' is required";
    my $type      = $wrapper->{type} or die "Bad view_wrapper definition -- 'type' is required";
    my $directive = 
      $type eq 'include' ? 'INCLUDE' :
      $type eq 'insert'  ? 'INSERT'  :
      die "Bad view_wrapper definition -- 'type' must be 'include' or 'insert'";
    
    return join("\n",
      join('','[% META local_name = "',$name,'" %]'),
      join('','[% WRAPPER "',$wrap_name,'" %]'),
      join('','[% ', $directive, ' "',$self->internal_post_path,$name,'" %]'),
      '[% END %]'
    )
  }
  
  my $Row = $self->templateData($template)->{Row} or return undef;
  
  #my $Row = $self->Model->resultset('Post')
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
  
  my $create = {
    name => $name,
    body => $content,
    published => 1
  };
  
  $self->Model->resultset('Post')->create($create) ? 1 : 0;
}


sub update_template {
  my ($self, $template, $content) = @_;
  my $name = $self->local_name($template) or return undef;
  
  my $Row = $self->Model->resultset('Post')
    ->search_rs({ 'me.name' => $name })
    ->first or die 'Not found!';
  
  $Row->update({ body => $content }) ? 1 : 0;
}


sub delete_template {
  my ($self, $template) = @_;
  my $name = $self->local_name($template) or return undef;
  
  my $Row = $self->Model->resultset('Post')
    ->search_rs({ 'me.name' => $name })
    ->first or die 'Not found!';
  
  $Row->delete ? 1 : 0;
}


sub list_templates {
  my $self = shift;
  [ map { join('',$self->internal_post_path,$_) } $self->Model->resultset('Post')->get_column('name')->all ]
}

around 'template_post_processor_class' => sub {
  my ($orig,$self,@args) = @_;
  my $template = join('/',@args);
  
  # By rule, never use a post processor with a wrapper view:
  return undef if ($self->wrapper_def($template));
  
  # Render markdown with our MarkdownElement post-processor if the next template
  # (i.e. which is including us) is one of our wrapper/views. This will defer
  # rendering of markdown to the client-side with the marked.js library
  if($self->process_Context && $self->get_template_format($template) eq 'markdown') {
    if(my $next_template = $self->process_Context->next_template) {
      if($self->wrapper_def($next_template)) {
        return 'Rapi::Blog::Template::Postprocessor::MarkdownElement'
      }
    }
  }

  return $self->$orig(@args)
};


sub template_psgi_response {
  my ($self, $template, $c) = @_;
  
  # Return 404 for private paths:
  if ($self->_is_private_path($template)) {
    return [ 404, [ 'Post-Type' => 'text/plain' ], [ '404 not found' ] ] unless (
      $c->req->action =~ /^\/rapidapp\/template\// # does not apply to internal tpl reqs
    );
  }
  
  my $tpl = $self->_resolve_static_path($template) or return undef;
  
  my $env = {
    %{ $c->req->env },
    PATH_INFO   => "/$tpl",
    SCRIPT_NAME => ''
  };
  
  return $self->static_path_app->($env)
}

1;