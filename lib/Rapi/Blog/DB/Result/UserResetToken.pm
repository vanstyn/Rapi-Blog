use utf8;
package Rapi::Blog::DB::Result::UserResetToken;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

use strict;
use warnings;

use Moose;
use MooseX::NonMoose;
use MooseX::MarkAsMethods autoclean => 1;
extends 'DBIx::Class::Core';
__PACKAGE__->load_components("InflateColumn::DateTime");
__PACKAGE__->table("user_reset_token");
__PACKAGE__->add_columns(
  "id",
  { data_type => "integer", is_auto_increment => 1, is_nullable => 0 },
  "type",
  { data_type => "varchar", is_foreign_key => 1, is_nullable => 0, size => 16 },
  "user_id",
  { data_type => "integer", is_foreign_key => 1, is_nullable => 0 },
  "create_ts",
  { data_type => "datetime", is_nullable => 0 },
  "expire_ts",
  { data_type => "datetime", is_nullable => 0 },
  "token_hash",
  { data_type => "varchar", is_nullable => 0, size => 128 },
);
__PACKAGE__->set_primary_key("id");
__PACKAGE__->add_unique_constraint("token_hash_unique", ["token_hash"]);
__PACKAGE__->belongs_to(
  "type",
  "Rapi::Blog::DB::Result::UserResetTokenType",
  { name => "type" },
  { is_deferrable => 0, on_delete => "CASCADE", on_update => "CASCADE" },
);
__PACKAGE__->belongs_to(
  "user",
  "Rapi::Blog::DB::Result::User",
  { id => "user_id" },
  { is_deferrable => 0, on_delete => "CASCADE", on_update => "CASCADE" },
);


# Created by DBIx::Class::Schema::Loader v0.07049 @ 2018-10-01 22:28:38
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:Jfp5TEXxB4Ptqu5mp5tPQQ


# You can replace this text with custom code or comments, and it will be preserved on regeneration
__PACKAGE__->meta->make_immutable;
1;
