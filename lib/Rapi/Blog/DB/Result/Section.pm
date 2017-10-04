use utf8;
package Rapi::Blog::DB::Result::Section;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

use strict;
use warnings;

use Moose;
use MooseX::NonMoose;
use MooseX::MarkAsMethods autoclean => 1;
extends 'DBIx::Class::Core';
__PACKAGE__->load_components("InflateColumn::DateTime");
__PACKAGE__->table("section");
__PACKAGE__->add_columns(
  "id",
  { data_type => "integer", is_auto_increment => 1, is_nullable => 0 },
  "name",
  { data_type => "varchar", is_nullable => 0, size => 64 },
  "description",
  {
    data_type => "varchar",
    default_value => \"null",
    is_nullable => 1,
    size => 1024,
  },
  "parent_id",
  {
    data_type      => "integer",
    default_value  => \"null",
    is_foreign_key => 1,
    is_nullable    => 1,
  },
);
__PACKAGE__->set_primary_key("id");
__PACKAGE__->add_unique_constraint("parent_id_name_unique", ["parent_id", "name"]);
__PACKAGE__->belongs_to(
  "parent",
  "Rapi::Blog::DB::Result::Section",
  { id => "parent_id" },
  {
    is_deferrable => 0,
    join_type     => "LEFT",
    on_delete     => "CASCADE",
    on_update     => "CASCADE",
  },
);
__PACKAGE__->has_many(
  "posts",
  "Rapi::Blog::DB::Result::Post",
  { "foreign.section_id" => "self.id" },
  { cascade_copy => 0, cascade_delete => 0 },
);
__PACKAGE__->has_many(
  "sections",
  "Rapi::Blog::DB::Result::Section",
  { "foreign.parent_id" => "self.id" },
  { cascade_copy => 0, cascade_delete => 0 },
);


# Created by DBIx::Class::Schema::Loader v0.07045 @ 2017-10-04 14:52:49
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:V0GvpLRp6WXqAyPQ0DKGaw

use RapidApp::Util ':all';
use Rapi::Blog::Util;

__PACKAGE__->load_components('+Rapi::Blog::DB::Component::SafeResult');

sub insert {
  my $self = shift;
  my $columns = shift;
  
  if(my $User = Rapi::Blog::Util->get_User) {
    die usererr "Create Section: PERMISSION DENIED" if ($User->id && !$User->admin);
  }
  
  $self->set_inflated_columns($columns) if $columns;
  
  $self->_validate_depth;
  
  $self->next::method
}

sub update {
  my $self = shift;
  my $columns = shift;
  
  if(my $User = Rapi::Blog::Util->get_User) {
    die usererr "Update Section: PERMISSION DENIED" if ($User->id && !$User->admin);
  }
  
  $self->set_inflated_columns($columns) if $columns;
  
  $self->_validate_depth;
  
  $self->next::method
}


sub delete {
  my $self = shift;
  
  if(my $User = Rapi::Blog::Util->get_User) {
    die usererr "Delete Section: PERMISSION DENIED" if ($User->id && !$User->admin);
  }
  
  $self->next::method(@_)
}

sub _validate_depth {
  my $self = shift;
  my $level = shift || 1;
  my $seen = shift || {};
  
  my $max_depth = 10;
  
  if (my $id = $self->get_column('id')) { # may not have an id yet
    die usererr "Circular references not allowed (cannot make a Section a child of itself)" if ($seen->{$id}++);
  }
  
  die usererr "Too many levels of Sections -- max allowed is $max_depth" if ($level > $max_depth);
  
  $self->get_column('parent_id')
    ? $self->parent->_validate_depth($level+1,$seen)
    : 1
}



# You can replace this text with custom code or comments, and it will be preserved on regeneration
__PACKAGE__->meta->make_immutable;
1;
