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
  "sealed",
  { data_type => "boolean", default_value => 0, is_nullable => 0 },
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


# Created by DBIx::Class::Schema::Loader v0.07049 @ 2019-01-27 12:50:16
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:43iysyBK1Y/m5ydH2fLefQ


__PACKAGE__->load_components('+Rapi::Blog::DB::Component::SafeResult');

use RapidApp::Util ':all';
use Rapi::Blog::Util;

sub active_request_Hit {
  my ($self, $new) = @_;
  $self->{_active_request_Hit} = $new if ($new);
  $self->{_active_request_Hit}
}


sub create_event {
  my ($self, $pkt) = @_;
  
  $pkt->{action_id} = $self->get_column('id');
  
  my $Hit = $self->active_request_Hit;
  
  $Hit 
    ? $self->evRsCmeth( create_with_hit => $Hit, $pkt ) 
    : $self->evRsCmeth( create => $pkt )
}

sub evRsCmeth {
  my ($self, $meth, @args) = @_;
  
  my $evRow = $self->preauth_action_events->$meth(@args);
  
  my $trk = $self->{_track_created_Events}; # <-- This is not currently being set and may be removed
  push @$trk, $evRow if (ref($trk)||'' eq 'ARRAY');

  $evRow
}

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


sub deactivate {
  my ($self, $info) = @_;
  
  $self->active or die "Already inactive!";
  
  $self->create_event({ 
    type_id => 3,     # Deactivate
    info    => $info
  });
  
  $self->active(0);
  $self->update;
  
  $self
}



sub not_expired {
  my ($self, $test_dt) = shift;
  $test_dt ||= Rapi::Blog::Util->now_dt;
  
  return 1 if (
        Rapi::Blog::Util->dt_to_ts($self->expire_ts)
     gt Rapi::Blog::Util->dt_to_ts($test_dt)
  );
  
  $self->deactivate('Expired') if ($self->active);

  return 0
}


sub enforce_valid {
  my $self = shift;
  $self->active && $self->not_expired
}


sub request_validate {
  my ($self, $Hit) = @_;
  
  $self->active_request_Hit($Hit);
  
  if($self->enforce_valid) {
    $self->create_event({ type_id => 1 }); # Valid
    return 1;
  }
  else {
    $self->create_event({ type_id => 2 }); # Invalid
    return 0;
  }
}


sub actor_execute {
  my ($self, $c, @args) = @_;
  
  $self->active or die "Action not active! cannot execute";
  
  my ($Actor, $info);
  my $not_final = 0;
  
  $self->{_actor_execute_exception} = undef;

  try {
    $Actor = $self->type
      ->actor_class
      ->new( ctx => $c, PreauthAction => $self );
      
    $Actor->execute(@args) or die "Actor ->execute did not return true";

    $info      = $Actor->info;
    $not_final = $Actor->not_final;
    
  } catch {
    my $err = shift;
    $self->{_actor_execute_exception} = $err;
    $info = "Exception: $err";
  };
  
  $self->create_event({ 
    type_id => 4,     # Executed
    info    => $info
  });
  
  $self->deactivate('Executed') unless ($not_final);
  
  # Return the post-executed Actor object:
  $Actor
}





# You can replace this text with custom code or comments, and it will be preserved on regeneration
__PACKAGE__->meta->make_immutable;
1;
