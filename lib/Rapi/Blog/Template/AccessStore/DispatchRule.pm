package Rapi::Blog::Template::AccessStore::DispatchRule;
use strict;
use warnings;

use RapidApp::Util qw(:all);
use Rapi::Blog::Util;
use List::Util;

use Rapi::Blog::Scaffold::PathMatch;

use Moo;
use Types::Standard ':all';

has 'AccessStore',  is => 'ro', required => 1, isa => InstanceOf['Rapi::Blog::Template::AccessStore'];
has 'path',         is => 'ro', required => 1, isa => Str;
has 'ctx',          is => 'ro', required => 1;

sub BUILD {
  my $self = shift;
  
  # init immediately:
  $self->applies;
  
  scream({
    path => $self->path,
    applies => $self->applies,
    $self->PathMatch->matches ? (
      type => $self->PathMatch->type,
      rank => $self->PathMatch->match_rank,
      
      scaf_config => $self->Scaffold->config->all_as_hash
      
      
    ) : ()
    
  })
  
}


# Figure out the *best* PathMatch amoung all our Scaffolds and their various dispatch modes:
has 'PathMatch', is => 'ro', init_arg => undef, lazy => 1, default => sub {
  my $self = shift;
  
  my @scaffolds = @{ $self->AccessStore->Scaffolds };
  scalar(@scaffolds) > 0 or die "Fatal error -- no Scaffolds detected. At least one Scaffold must be loaded.";
  
  my $BestMatch = undef;
  $BestMatch = Rapi::Blog::Scaffold::PathMatch
    ->new( path => $self->path, Scaffold => $_ )
    ->us_or_better($BestMatch) 
  for @scaffolds;
 
  $BestMatch

}, isa => InstanceOf['Rapi::Blog::Scaffold::PathMatch'];


has 'Scaffold', is => 'ro', init_arg => undef, lazy => 1, default => sub {
  my $self = shift;
  $self->PathMatch->matches ? $self->PathMatch->Scaffold : undef
}, isa => Maybe[InstanceOf['Rapi::Blog::Scaffold']];


# deligations:
sub scaffold_file    { (shift)->PathMatch->scaffold_file(@_)    }
sub post_name_exists { (shift)->PathMatch->post_name_exists(@_) }
sub post_name        { (shift)->PathMatch->post_name(@_)        }
sub direct_post_name { (shift)->PathMatch->direct_post_name(@_) }
sub ViewWrapper      { (shift)->PathMatch->ViewWrapper(@_)                 }


# true or false if dispatching applies for this path
sub applies {
  my $self = shift;
  $self->Scaffold ? 1 : 0
}


has 'exists', is => 'ro', init_arg => undef, lazy => 1, default => sub {
  my $self = shift;
  $self->scaffold_file || $self->post_name_exists ? 1 : 0
}, isa => Bool;


has 'exist_in_Provider', is => 'ro', init_arg => undef, lazy => 1, default => sub {
  my $self = shift;
  $self->AccessStore->Controller->get_Provider->template_exists_locally($self->path)
}, isa => Bool;

has 'claimed', is => 'ro', init_arg => undef, lazy => 1, default => sub {
  my $self = shift;
  $self->applies or return 0;
  $self->exists and return 1;
  $self->Scaffold->config->not_found or return 0;
  return 0 unless ($self->PathMatch->is_static || $self->PathMatch->is_private);
  
  # Only claim the path for "not found" if it doesn't exist in the Provider (i.e. RapidApp core templates)
  $self->exist_in_Provider ? 0 : 1
}, isa => Bool;



sub _File_mtime {
  my ($self, $File) = @_;
  my $Stat = $File->stat or return undef;
  $Stat->mtime
}

has 'mtime', is => 'ro', init_arg => undef, lazy => 1, default => sub {
  my $self = shift;
  if (my $File = $self->scaffold_file) {
    my $Stat = $File->stat;
    return $Stat ? $Stat->mtime : undef;
  }
  $self->post_name_exists ? $self->AccessStore->Post_mtime_fn->($self->post_name) : undef
}, isa => Maybe[Num];


has 'content', is => 'ro', init_arg => undef, lazy => 1, default => sub {
  my $self = shift;
  return (scalar $self->scaffold_file->slurp) if $self->scaffold_file;
  
  return $self->AccessStore->Post_content_fn->($self->direct_post_name) if $self->direct_post_name;
  
  if (my $VW = $self->ViewWrapper) {
    my $name = $self->exists ? $self->post_name : $VW->valid_not_found_template;
    return $VW->render_post_wrapper($name) if $name;
  }

  return undef
  
}, isa => Maybe[Str];


has 'maybe_psgi_response', is => 'ro', init_arg => undef, lazy => 1, default => sub {
  my $self = shift;
  $self->claimed or return undef;
  
  my ($c, $template) = ($self->ctx, $self->path);

  # Return 404 for private paths:
  if ($self->Scaffold->_is_private_path($template)) {
    return $self->_forward_to_404_template($c) unless (
      $c->req->action =~ /^\/rapidapp\/template\// # does not apply to internal tpl reqs
      || $c->stash->{__forward_to_404_template} # because the 404 can be a private path
    );
  }

  if(my $tpl = $self->Scaffold->_resolve_static_path($template)) {
    my $env = {
      %{ $c->req->env },
      PATH_INFO   => "/$tpl",
      SCRIPT_NAME => ''
    };
    return $self->Scaffold->static_path_app->($env)
  }
  
  $self->exists ? undef : $self->_forward_to_404_template


}, isa => Maybe[ArrayRef];




sub _forward_to_404_template {
  my $self = shift;
  
  my $c = $self->ctx;
  
  my $tpl = $self->Scaffold->config->not_found || 'rapidapp/public/http-404.html';
  
  # catch deep recursion:
  die "Error dispatching 404 not found template" if ($c->stash->{__forward_to_404_template}++);
  
  $c->res->status(404);
  $c->detach( '/rapidapp/template/view', [$tpl] )
}







1;