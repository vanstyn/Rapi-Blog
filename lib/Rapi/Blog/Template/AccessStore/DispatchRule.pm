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
has 'init_path',    is => 'ro', required => 1, isa => Str;
has 'ctx',          is => 'ro', required => 1;

sub BUILD {
  my $self = shift;
  
  # init immediately:
  $self->applies;
  
  #scream({
  #  path => $self->path,
  #  applies => $self->applies,
  #  claimed => $self->claimed,
  #  valid_not_found => $self->valid_not_found_template,
  #  $self->PathMatch->matches ? (
  #    type => $self->PathMatch->type,
  #    rank => $self->PathMatch->match_rank,
  #    
  #    scaf_config => $self->Scaffold->config->all_as_hash
  #    
  #    
  #  ) : ()
  #  
  #})
  
}


# Figure out the *best* PathMatch amoung all our Scaffolds and their various dispatch modes:
has 'PathMatch', is => 'ro', init_arg => undef, lazy => 1, default => sub {
  my $self = shift;
  
  my @scaffolds = @{ $self->AccessStore->Scaffolds };
  scalar(@scaffolds) > 0 or die "Fatal error -- no Scaffolds detected. At least one Scaffold must be loaded.";
  
  if (my $uuid = $self->ctx->stash->{rapi_blog_only_scaffold_uuid}) {
    @scaffolds = grep { $_->uuid eq $uuid } @scaffolds;
    scalar(@scaffolds) > 0 or die join('',
      "Fatal error -- rapi_blog_only_scaffold_uuid is set ('$uuid') but there ",
      "is no Scaffold with that uuid"
    );
  }
  
  my $Best = undef;
  for (@scaffolds) {
    my $Next = Rapi::Blog::Scaffold::PathMatch->new( path => $self->init_path, Scaffold => $_ );
    $Best = $Best ? $Best->us_or_better($Next) : $Next;
  }
 
  $Best->resolved_PathMatch || $Best

}, isa => InstanceOf['Rapi::Blog::Scaffold::PathMatch'];


has 'Scaffold', is => 'ro', init_arg => undef, lazy => 1, default => sub {
  my $self = shift;
  $self->PathMatch->matches ? $self->PathMatch->Scaffold : undef
}, isa => Maybe[InstanceOf['Rapi::Blog::Scaffold']];


# deligations:
sub path             { (shift)->PathMatch->path(@_)             }
sub scaffold_file    { (shift)->PathMatch->scaffold_file(@_)    }
sub post_name_exists { (shift)->PathMatch->post_name_exists(@_) }
sub post_name        { (shift)->PathMatch->post_name(@_)        }
sub direct_post_name { (shift)->PathMatch->direct_post_name(@_) }
sub ViewWrapper      { (shift)->PathMatch->ViewWrapper(@_)      }
sub is_static        { (shift)->PathMatch->is_static(@_)        }
sub is_private       { (shift)->PathMatch->is_private(@_)       }


# true or false if dispatching applies for this path
sub applies {
  my $self = shift;
  $self->Scaffold ? 1 : 0
}


has 'exists', is => 'ro', init_arg => undef, lazy => 1, default => sub {
  my $self = shift;
  $self->scaffold_file || $self->post_name_exists ? 1 : 0
}, isa => Bool;


has 'valid_not_found_template', is => 'ro', init_arg => undef, lazy => 1, default => sub {
  my $self = shift;
  my $tpl = $self->Scaffold->config->not_found or return undef;
  $self->Scaffold->_resolve_scaffold_file($tpl) ? $tpl : undef
}, isa => Maybe[Str];


has 'exist_in_Provider', is => 'ro', init_arg => undef, lazy => 1, default => sub {
  my $self = shift;
  $self->AccessStore->Controller->get_Provider->template_exists_locally($self->PathMatch->path)
}, isa => Bool;

has 'claimed', is => 'ro', init_arg => undef, lazy => 1, default => sub {
  my $self = shift;
  $self->applies or return 0;
  $self->exists and return 1;
  $self->valid_not_found_template or return 0;

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
  
  if ($self->is_static && $self->exists) {
    if(my $tpl = $self->Scaffold->_resolve_static_path($self->PathMatch->path)) {
      my $env = {
        %{ $self->ctx->req->env },
        PATH_INFO   => "/$tpl",
        SCRIPT_NAME => ''
      };
      return $self->Scaffold->static_path_app->($env)
    }
  }
  elsif ($self->is_private || !$self->exists) {
    # Should be redundanr since we already checked this when we claimed the path
    my $tpl = $self->valid_not_found_template or die "unexpected error, we no longer have a valid_not_found_template";
    
    # Make sure the same Scaffold handles the 404 not found:
    $self->ctx->stash->{rapi_blog_only_scaffold_uuid} = $self->Scaffold->uuid;
    
    # Needed to prevent deep recursion when the not found template is private:
    $self->ctx->stash->{rapi_blog_detach_404_template}++ and return undef;
    
    $self->ctx->res->status(404);
    $self->ctx->detach( '/rapidapp/template/view', [$tpl] )
  }
  else {
    return undef
  }
}, isa => Maybe[ArrayRef];



1;