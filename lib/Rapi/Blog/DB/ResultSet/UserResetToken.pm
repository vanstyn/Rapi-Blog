package Rapi::Blog::DB::ResultSet::UserResetToken;

use strict;
use warnings;

use Moo;
extends 'DBIx::Class::ResultSet';

use RapidApp::Util ':all';
use Rapi::Blog::Util;

use String::Random;
use Digest::SHA1;

sub _hash_token {
  my ($self, $token) = @_;
  die "missing required token argument" unless $token;
  Digest::SHA1->new->add($token)->hexdigest
}

sub create_token {
  my ($self, $type, $user_id) = @_;
  
  my $token = String::Random->new->randregex('[a-z0-9A-Z]{50}');
  my $token_hash = $self->_hash_token($token);

  $self->create({
    type       => $type,
    user_id    => $user_id,
    token_hash => $token_hash
  }) and return $token
}


sub lookup_token {
  my ($self, $token) = @_;
  
  $self->search_rs({ 'me.token_hash' => $self->_hash_token($token) })->first

}



1;
