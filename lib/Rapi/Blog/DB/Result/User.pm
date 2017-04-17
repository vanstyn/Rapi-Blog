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


# Created by DBIx::Class::Schema::Loader v0.07045 @ 2017-04-17 16:58:50
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:4szSN0KnoTTJE6LhtGK6YQ


# You can replace this text with custom code or comments, and it will be preserved on regeneration
__PACKAGE__->meta->make_immutable;
1;
