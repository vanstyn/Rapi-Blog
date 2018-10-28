use utf8;
package Rapi::Blog::DB::Result::PreauthAction;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

use strict;
use warnings;

use Moose;
use MooseX::NonMoose;
use MooseX::MarkAsMethods autoclean => 1;
extends 'DBIx::Class::Core';
__PACKAGE__->load_components("InflateColumn::DateTime");
__PACKAGE__->table("preauth_action");
__PACKAGE__->add_columns(
  "id",
  { data_type => "integer", is_auto_increment => 1, is_nullable => 0 },
  "type",
  { data_type => "varchar", is_foreign_key => 1, is_nullable => 0, size => 16 },
  "active",
  { data_type => "boolean", default_value => 1, is_nullable => 0 },
  "create_ts",
  { data_type => "datetime", is_nullable => 0 },
  "expire_ts",
  { data_type => "datetime", is_nullable => 0 },
  "user_id",
  { data_type => "integer", is_foreign_key => 1, is_nullable => 1 },
  "auth_key",
  { data_type => "varchar", is_nullable => 0, size => 128 },
  "json_data",
  { data_type => "text", is_nullable => 1 },
);
__PACKAGE__->set_primary_key("id");
__PACKAGE__->add_unique_constraint("auth_key_unique", ["auth_key"]);
__PACKAGE__->has_many(
  "preauth_action_events",
  "Rapi::Blog::DB::Result::PreauthActionEvent",
  { "foreign.action_id" => "self.id" },
  { cascade_copy => 0, cascade_delete => 0 },
);
__PACKAGE__->belongs_to(
  "type",
  "Rapi::Blog::DB::Result::PreauthActionType",
  { name => "type" },
  { is_deferrable => 0, on_delete => "CASCADE", on_update => "CASCADE" },
);
__PACKAGE__->belongs_to(
  "user",
  "Rapi::Blog::DB::Result::User",
  { id => "user_id" },
  {
    is_deferrable => 0,
    join_type     => "LEFT",
    on_delete     => "CASCADE",
    on_update     => "CASCADE",
  },
);


# Created by DBIx::Class::Schema::Loader v0.07049 @ 2018-10-28 02:04:56
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:E2FlZX3VbC1RQIbYEE5pHA


__PACKAGE__->load_components('+Rapi::Blog::DB::Component::SafeResult');

use RapidApp::Util ':all';
use Rapi::Blog::Util;


sub insert {
  my $self = shift;
  my $columns = shift;

  $self->set_inflated_columns($columns) if $columns;
  
  my $now_dt = Rapi::Blog::Util->now_dt;

  $self->create_ts( Rapi::Blog::Util->dt_to_ts($now_dt) );
  
  $self->expire_ts( Rapi::Blog::Util->dt_to_ts(
    $now_dt->clone->add( hours => 1 )
  )) unless $self->expire_ts;
  
  $self->next::method;
  
  return $self;
}


# You can replace this text with custom code or comments, and it will be preserved on regeneration
__PACKAGE__->meta->make_immutable;
1;
