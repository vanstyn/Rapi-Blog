use utf8;
package Rapi::Blog::DB::Result::Content;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

use strict;
use warnings;

use Moose;
use MooseX::NonMoose;
use MooseX::MarkAsMethods autoclean => 1;
extends 'DBIx::Class::Core';
__PACKAGE__->load_components("InflateColumn::DateTime");
__PACKAGE__->table("content");
__PACKAGE__->add_columns(
  "id",
  { data_type => "integer", is_auto_increment => 1, is_nullable => 0 },
  "name",
  { data_type => "varchar", is_nullable => 0, size => 255 },
  "create_ts",
  {
    data_type     => "datetime",
    default_value => \"current_timestamp",
    is_nullable   => 0,
  },
  "update_ts",
  {
    data_type     => "datetime",
    default_value => \"current_timestamp",
    is_nullable   => 0,
  },
  "create_user_id",
  { data_type => "integer", is_foreign_key => 1, is_nullable => 0 },
  "update_user_id",
  { data_type => "integer", is_foreign_key => 1, is_nullable => 0 },
  "pp_code",
  {
    data_type => "varchar",
    default_value => \"null",
    is_foreign_key => 1,
    is_nullable => 1,
    size => 8,
  },
  "format_code",
  {
    data_type => "varchar",
    default_value => \"null",
    is_foreign_key => 1,
    is_nullable => 1,
    size => 8,
  },
  "published",
  { data_type => "boolean", default_value => 0, is_nullable => 0 },
  "body",
  { data_type => "text", default_value => "", is_nullable => 1 },
);
__PACKAGE__->set_primary_key("id");
__PACKAGE__->add_unique_constraint("name_unique", ["name"]);
__PACKAGE__->has_many(
  "content_keywords",
  "Rapi::Blog::DB::Result::ContentKeyword",
  { "foreign.content_id" => "self.id" },
  { cascade_copy => 0, cascade_delete => 0 },
);
__PACKAGE__->belongs_to(
  "create_user",
  "Rapi::Blog::DB::Result::User",
  { id => "create_user_id" },
  { is_deferrable => 0, on_delete => "RESTRICT", on_update => "CASCADE" },
);
__PACKAGE__->belongs_to(
  "format_code",
  "Rapi::Blog::DB::Result::Format",
  { code => "format_code" },
  {
    is_deferrable => 0,
    join_type     => "LEFT",
    on_delete     => "RESTRICT",
    on_update     => "CASCADE",
  },
);
__PACKAGE__->belongs_to(
  "pp_code",
  "Rapi::Blog::DB::Result::Preprocessor",
  { code => "pp_code" },
  {
    is_deferrable => 0,
    join_type     => "LEFT",
    on_delete     => "RESTRICT",
    on_update     => "CASCADE",
  },
);
__PACKAGE__->belongs_to(
  "update_user",
  "Rapi::Blog::DB::Result::User",
  { id => "update_user_id" },
  { is_deferrable => 0, on_delete => "RESTRICT", on_update => "CASCADE" },
);


# Created by DBIx::Class::Schema::Loader v0.07045 @ 2016-12-28 16:50:15
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:+5hkQpzNZMFwAX+yviWW3g


# You can replace this text with custom code or comments, and it will be preserved on regeneration
__PACKAGE__->meta->make_immutable;
1;
