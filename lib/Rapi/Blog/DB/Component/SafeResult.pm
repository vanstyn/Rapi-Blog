package Rapi::Blog::DB::Component::SafeResult;

use strict;
use warnings;
 
use parent 'DBIx::Class::Core';
use RapidApp::Util ':all';

sub _caller_is_template {
	if(my $c = RapidApp->active_request_context) {
		return 1 if($c->controller('RapidApp::Template')->Access->currently_viewing_template);
	}
	return 0;
}

sub insert {
	my $self = shift;
	$self->_caller_is_template and die "INSERT denied";
	$self->next::method(@_)
}

sub update {
	my $self = shift;
	$self->_caller_is_template and die "UPDATE denied";
	$self->next::method(@_)
}

sub delete {
	my $self = shift;
	$self->_caller_is_template and die "DELETE denied";
	$self->next::method(@_)
}


1;