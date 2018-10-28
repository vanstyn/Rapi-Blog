package Rapi::Blog::DB::ResultSet::PreauthAction;

use strict;
use warnings;

use Moo;
extends 'DBIx::Class::ResultSet';

use RapidApp::Util ':all';
use Rapi::Blog::Util;

use String::Random;
use Digest::SHA1;

sub _hash_auth_key {
  my ($self, $key) = @_;
  die "missing required key argument" unless $key;
  Digest::SHA1->new->add($key)->hexdigest
}

sub create_auth_key {
  my ($self, $type, $user_id) = @_;
  
  my $key = String::Random->new->randregex('[a-z0-9A-Z]{50}');
  my $key_hash = $self->_hash_auth_key($key);

  $self->create({
    type       => $type,
    user_id    => $user_id,
    auth_key   => $key_hash
  }) and return $key
}


sub lookup_key {
  my ($self, $key) = @_;
  
  $self->search_rs({ 'me.auth_key' => $self->_hash_auth_key($key) })->first

}



1;
