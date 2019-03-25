package Rapi::Blog::Model::Mailer;

use Moose;
extends 'Catalyst::Model';

use strict;
use warnings;

# ABSTRACT: Common interface for sending E-Mails

use RapidApp::Util qw(:all);

require Module::Runtime;
use Email::Sender::Transport;
use Email::Sender::Transport::Sendmail;
use Email::Sender::Simple;
use Email::Simple;


use Email::MIME::CreateHTML;
use Email::Sender;


has transport => (
  does => 'Email::Sender::Transport',
  is => 'ro',
  lazy_build => 1,
);

sub _build_transport { 
  Email::Sender::Transport::Sendmail->new 
}


# Perform some coersions, because these parameters come from the config file.
around 'BUILDARGS' => sub {
  my ($orig, $class, @args) = @_;
  my $params = $class->$orig(@args);

  # We allow the mail transport to be specified in the config file.
  # This means we need to convert it from either a string or hash into the appropriate object.
  $params->{transport} = $class->_resolve_transport($params->{transport});
  delete $params->{transport} unless ($params->{transport});

  return $params;
};

sub _resolve_transport {
  my $self = shift;
  my $cfg  = shift or return undef;
  
  return $cfg unless ((ref($cfg)||'') eq 'HASH');
  my $class = $cfg->{class} ? delete $cfg->{class} : undef;
  
  if($class) {
    Module::Runtime::require_module($class);
    return $class->new($cfg)
  }
  
  return undef
}


sub send_email {
  my $self = shift;
  my $email = shift or die "send_email: no e-mail supplied to send!";
  my %opts = (ref($_[0]) eq 'HASH') ? %{ $_[0] } : @_; # <-- arg as hash or hashref
  
  %opts = ( transport => $self->transport, %opts );
  
  if(my $reftype = ref($email)) {
    $email = Email::Simple->create(%$email) if (!blessed($email) && $reftype eq 'HASH')
  }
  else {
    $email = Email::Simple->new($email)
  }

  die "send_email: Bad email argument - unable to use or parse into an Email::Simple object"
    unless(blessed($email) && $email->isa('Email::Simple'));

  Email::Sender::Simple->try_to_send($email,\%opts);
}







__PACKAGE__->meta->make_immutable;
1;

__END__

=head1 NAME

Rapi::Blog::Model::Mailer - Common interface for sending E-Mails

=head1 SYNOPSIS

See L<Rapi::Blog>

=head1 DESCRIPTION

This model provides the interface used to generate all E-Mails from the system


=head1 CONFIGURATION

TBD

=head1 METHODS

TBD

=head1 AUTHOR

Henry Van Styn <vanstyn@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2019 by IntelliTree Solutions llc.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut



