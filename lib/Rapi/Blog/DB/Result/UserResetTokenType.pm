use utf8;
package Rapi::Blog::DB::Result::UserResetTokenType;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

use strict;
use warnings;

use Moose;
use MooseX::NonMoose;
use MooseX::MarkAsMethods autoclean => 1;
extends 'DBIx::Class::Core';
__PACKAGE__->load_components("InflateColumn::DateTime");
__PACKAGE__->table("user_reset_token_type");
__PACKAGE__->add_columns(
  "name",
  { data_type => "varchar", is_nullable => 0, size => 16 },
  "description",
  {
    data_type => "varchar",
    default_value => \"null",
    is_nullable => 1,
    size => 1024,
  },
);
__PACKAGE__->set_primary_key("name");
__PACKAGE__->has_many(
  "user_reset_tokens",
  "Rapi::Blog::DB::Result::UserResetToken",
  { "foreign.type" => "self.name" },
  { cascade_copy => 0, cascade_delete => 0 },
);


# Created by DBIx::Class::Schema::Loader v0.07049 @ 2018-10-01 22:28:38
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:RYI47gQGi7uIxnePRw1w7Q


# You can replace this text with custom code or comments, and it will be preserved on regeneration
__PACKAGE__->meta->make_immutable;
1;
