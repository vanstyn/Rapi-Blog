package Rapi::Blog::DB::ResultSet::PreauthAction;

use strict;
use warnings;

use Moo;
extends 'DBIx::Class::ResultSet';

use RapidApp::Util ':all';
use Rapi::Blog::Util;

use String::Random;
use Digest::SHA1;

sub unsealed {
  (shift)
    ->search_rs({ 'me.sealed' => 0 })
}

sub _hash_auth_key {
  my ($self, $key) = @_;
  die "missing required key argument" unless $key;
  Digest::SHA1->new->add($key)->hexdigest
}

sub create_auth_key {
  my ($self, $type, $user_id, $columns) = @_;
  
  my $key = String::Random->new->randregex('[a-z0-9A-Z]{15}');
  my $key_hash = $self->_hash_auth_key($key);
  
  my $create = {
    type       => $type,
    user_id    => $user_id,
    auth_key   => $key_hash
  };
  
  if($columns) {
    die "Optional 'columns' 3rd argument must be a hashref" 
      unless ((ref($columns)||'') eq 'HASH');
    
    my @ban_cols = ((keys %$create), 'user', 'type_id');
    exists $columns->{$_} and die "Custom/override of '$_' is not allowed" for (@ban_cols);
    %$create = (%$columns,%$create);
  }

  $self->create( $create ) and return $key
}


sub _matches_key {
  my ($self, $key) = @_;
  $self->search_rs({ 'me.auth_key' => $self->_hash_auth_key($key) })
}


sub lookup_key {
  my ($self, $key) = @_;
  $self->_matches_key($key)
    ->unsealed
    ->first
}

sub lookup_key_include_sealed {
  my ($self, $key) = @_;
  $self->_matches_key($key)
    ->first
}


1;
