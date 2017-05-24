use utf8;
package Rapi::Blog::DB::Result::User;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

use strict;
use warnings;

use Moose;
use MooseX::NonMoose;
use MooseX::MarkAsMethods autoclean => 1;
extends 'DBIx::Class::Core';
__PACKAGE__->load_components("InflateColumn::DateTime");
__PACKAGE__->table("user");
__PACKAGE__->add_columns(
  "id",
  { data_type => "integer", is_auto_increment => 1, is_nullable => 0 },
  "username",
  { data_type => "varchar", is_nullable => 0, size => 32 },
  "full_name",
  {
    data_type => "varchar",
    default_value => \"null",
    is_nullable => 1,
    size => 64,
  },
  "admin",
  { data_type => "boolean", default_value => 0, is_nullable => 0 },
  "author",
  { data_type => "boolean", default_value => 0, is_nullable => 0 },
  "comment",
  { data_type => "boolean", default_value => 1, is_nullable => 0 },
);
__PACKAGE__->set_primary_key("id");
__PACKAGE__->add_unique_constraint("full_name_unique", ["full_name"]);
__PACKAGE__->add_unique_constraint("username_unique", ["username"]);
__PACKAGE__->has_many(
  "comments",
  "Rapi::Blog::DB::Result::Comment",
  { "foreign.user_id" => "self.id" },
  { cascade_copy => 0, cascade_delete => 0 },
);
__PACKAGE__->has_many(
  "post_authors",
  "Rapi::Blog::DB::Result::Post",
  { "foreign.author_id" => "self.id" },
  { cascade_copy => 0, cascade_delete => 0 },
);
__PACKAGE__->has_many(
  "post_creators",
  "Rapi::Blog::DB::Result::Post",
  { "foreign.creator_id" => "self.id" },
  { cascade_copy => 0, cascade_delete => 0 },
);
__PACKAGE__->has_many(
  "post_updaters",
  "Rapi::Blog::DB::Result::Post",
  { "foreign.updater_id" => "self.id" },
  { cascade_copy => 0, cascade_delete => 0 },
);


# Created by DBIx::Class::Schema::Loader v0.07045 @ 2017-05-24 12:06:23
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:d8XOlxc3ysqy5CPSA0/2UQ

use RapidApp::Util ':all';

__PACKAGE__->load_components('+RapidApp::DBIC::Component::TableSpec');

__PACKAGE__->add_virtual_columns( set_pw => {
  data_type => "varchar", 
  is_nullable => 1, 
  sql => "SELECT NULL",
  set_function => sub {} # This is a dummy designed to hook via AuthCore/linked_user_model
});

__PACKAGE__->apply_TableSpec;


sub insert {
  my $self = shift;
  $self->next::method(@_);
  
  $self->_role_perm_sync;

  $self
}

sub update {
  my $self = shift;
  $self->next::method(@_);
  
  $self->_role_perm_sync;

  $self
}



sub _role_perm_sync {
  my $self = shift;
  
  if($self->{_pulling_linkedRow}) {
    $self->_apply_from_CoreUser($self->{_pulling_linkedRow});
  }
  else {
    if($self->can('_find_linkedRow')) {
      # This is ugly but needed to hook both sides correctly across all CRUD ops
      my $Row = $self->_find_linkedRow || $self->_create_linkedRow;
      $self->_apply_to_CoreUser( $Row );
    }
  }
}



# change originated from CoreSchema::User:
sub _apply_from_CoreUser {
  my ($self, $CoreUser) = @_;
  
  my $cur_admin = $self->admin;
  
  $CoreUser = $CoreUser->get_from_storage if ($CoreUser->in_storage); # needed in case the username has changed

  my $LinkRs = $CoreUser->user_to_roles;
  my $admin_cond = { username => $CoreUser->username, role => 'administrator' };
  if($LinkRs->search_rs($admin_cond)->first) {
    $self->admin(1);
  }
  else {
    $self->admin(0);
  }
  
  $self->update unless ($cur_admin == $self->admin);# {
}



# change originated locally:
sub _apply_to_CoreUser {
  my ($self, $CoreUser) = @_;
  
  my $LinkRs = $CoreUser->user_to_roles;
  my $admin_cond = { username => $CoreUser->username, role => 'administrator' };
  if($self->admin) {
    $LinkRs->find_or_create($admin_cond);
  }
  else {
    if(my $Link = $LinkRs->search_rs($admin_cond)->first) {
      $Link->delete;
    }
  }

}



# You can replace this text with custom code or comments, and it will be preserved on regeneration
__PACKAGE__->meta->make_immutable;
1;
