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
  { data_type => "varchar", is_nullable => 0, size => 64 },
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


# Created by DBIx::Class::Schema::Loader v0.07045 @ 2017-05-23 12:44:33
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:pVeQa5u+6JVWNP2n1aJiPg


# You can replace this text with custom code or comments, and it will be preserved on regeneration
__PACKAGE__->meta->make_immutable;
1;
