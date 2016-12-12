use utf8;
package Rapi::Blog::DB::Result::ContentKeyword;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

use strict;
use warnings;

use Moose;
use MooseX::NonMoose;
use MooseX::MarkAsMethods autoclean => 1;
extends 'DBIx::Class::Core';
__PACKAGE__->load_components("InflateColumn::DateTime");
__PACKAGE__->table("content_keyword");
__PACKAGE__->add_columns(
  "id",
  { data_type => "integer", is_auto_increment => 1, is_nullable => 0 },
  "content_id",
  { data_type => "integer", is_foreign_key => 1, is_nullable => 0 },
  "keyword_name",
  { data_type => "varchar", is_foreign_key => 1, is_nullable => 0, size => 64 },
);
__PACKAGE__->set_primary_key("id");
__PACKAGE__->add_unique_constraint("keyword_name_unique", ["keyword_name"]);
__PACKAGE__->belongs_to(
  "content",
  "Rapi::Blog::DB::Result::Content",
  { id => "content_id" },
  { is_deferrable => 0, on_delete => "CASCADE", on_update => "CASCADE" },
);
__PACKAGE__->belongs_to(
  "keyword_name",
  "Rapi::Blog::DB::Result::Keyword",
  { name => "keyword_name" },
  { is_deferrable => 0, on_delete => "CASCADE", on_update => "CASCADE" },
);


# Created by DBIx::Class::Schema::Loader v0.07045 @ 2016-12-11 19:00:13
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:fzSN9hJME1MPKltfzE8oDw


# You can replace this text with custom code or comments, and it will be preserved on regeneration
__PACKAGE__->meta->make_immutable;
1;
