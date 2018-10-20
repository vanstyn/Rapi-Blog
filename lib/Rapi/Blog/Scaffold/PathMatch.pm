package Rapi::Blog::Scaffold::PathMatch;
use strict;
use warnings;

use RapidApp::Util qw(:all);
use Rapi::Blog::Util;
use List::Util;

use Moo;
use Types::Standard ':all';

has 'Scaffold',         is => 'ro', required => 1, isa => InstanceOf['Rapi::Blog::Scaffold'];
has 'path',             is => 'ro', required => 1, isa => Str;
has 'origin_PathMatch', is => 'ro', isa => Maybe[InstanceOf[__PACKAGE__]], default => sub { undef };

# This allows *relative* paths to static resources to work when loaded via a view/url prefix
has 'resolved_PathMatch', is => 'ro', init_arg => undef, lazy => 1, default => sub {
  my $self = shift;
  return undef;
  my $subpath = $self->view_subpath or return undef;
  my $PM = __PACKAGE__->new( 
    path             => $subpath, 
    Scaffold         => $self->Scaffold, 
    origin_PathMatch => $self
  );
  $PM->scaffold_file ? $PM : undef
}, isa => Maybe[InstanceOf[__PACKAGE__]];

sub BUILD {
  my $self = shift;

  # init
  $self->resolved_PathMatch;
}


sub us_or_better {
  my ($this,$that) = @_;
  $that && $that->match_rank < $this->match_rank ? $that : $this
}


has 'matches', is => 'ro', init_arg => undef, lazy => 1, default => sub {
  my $self = shift;
  $self->match_rank && $self->match_rank < 100 ? 1 : 0
}, isa => Bool;

has 'match_rank', is => 'ro', init_arg => undef, lazy => 1, default => sub {
  my $self = shift;
  
  return 1 if $self->scaffold_file || $self->resolved_PathMatch;
  
  if($self->post_name_exists) {
    return 2 if ($self->direct_post_name);
    return 3 if ($self->ViewWrapper);
  }
  
  if ($self->handles_not_found) {
    return 4 if $self->ViewWrapper;
    return 5 if ($self->is_static || $self->is_private);
  }
  
  100
  
}, isa => Maybe[Int];


has 'type', is => 'ro', init_arg => undef, lazy => 1, default => sub {
  my $self = shift;
  return 'file' if ($self->scaffold_file);
  return 'post' if ($self->direct_post_name);
  return 'view' if ($self->ViewWrapper);
  
  return 'oops';

}, isa => Enum[qw/file post view oops/];


has 'is_static', is => 'ro', init_arg => undef, lazy => 1, default => sub {
  my $self = shift;
  $self->Scaffold->_is_static_path($self->path)
}, isa => Bool;

has 'is_private', is => 'ro', init_arg => undef, lazy => 1, default => sub {
  my $self = shift;
  $self->Scaffold->_is_private_path($self->path)
}, isa => Bool;


has 'view_subpath', is => 'ro', init_arg => undef, lazy => 1, default => sub {
  my $self = shift;
  ! $self->origin_PathMatch && $self->ViewWrapper 
    ? $self->ViewWrapper->resolve_subpath($self->path) 
    : undef
}, isa => Maybe[Str];


has 'scaffold_file', is => 'ro', init_arg => undef, lazy => 1, default => sub {
  my $self = shift;
  $self->Scaffold->_resolve_scaffold_file($self->path)
}, isa => Maybe[InstanceOf['Path::Class::File']];


has 'direct_post_name', is => 'ro', init_arg => undef, lazy => 1, default => sub {
  my $self = shift;
  return undef if ($self->scaffold_file);
  my ($pfx,$name) = split($self->Scaffold->unique_int_post_path,$self->path,2);
  ($name && $pfx eq '') ? $name : undef
}, isa => Maybe[Str];


has 'ViewWrapper', is => 'ro', init_arg => undef, lazy => 1, default => sub {
  my $self = shift;
  my $info = $self->ViewWrapper_info || {};
  $info->{ViewWrapper}
}, isa => Maybe[InstanceOf['Rapi::Blog::Scaffold::ViewWrapper']];


has 'post_name', is => 'ro', init_arg => undef, lazy => 1, default => sub {
  my $self = shift;
  return $self->direct_post_name if $self->direct_post_name;
  my $info = $self->ViewWrapper_info || {};
  return $info->{post_name};
}, isa => Maybe[Str];


has 'post_name_exists', is => 'ro', init_arg => undef, lazy => 1, default => sub {
  my $self = shift;
  $self->post_name ? $self->_post_name_exists($self->post_name) : undef
}, isa => Maybe[Bool];


has 'handles_not_found', is => 'ro', init_arg => undef, lazy => 1, default => sub {
  my $self = shift;
  return (
    $self->Scaffold->handles_not_found ||
    ($self->ViewWrapper_info and $self->ViewWrapper_info->{handles_not_found})
  ) ? 1 : 0
}, isa => Bool;


has 'ViewWrapper_info', is => 'ro', init_arg => undef, lazy => 1, default => sub {
  my $self = shift;
  return undef if ($self->scaffold_file || $self->direct_post_name);
  my $info;
  for my $VW (@{ $self->Scaffold->ViewWrappers }) {
    my $post_name = $VW->resolve_subpath($self->path) or next;
    $info = { ViewWrapper => $VW, post_name => $post_name, exists => $self->_post_name_exists($post_name) };
    last if ($info->{exists});
    if($VW->valid_not_found_template) {
      $info->{handles_not_found} = 1;
      last;
    }
  }
  $info
}, isa => Maybe[HashRef];



has '_post_name_exist_trk', is => 'ro', isa => HashRef, default => sub {{}};
sub _post_name_exists {
  my ($self, $name) = @_;
  $self->_post_name_exist_trk->{$name} //= $self->Scaffold->Post_exists_fn->($name)
}



1;