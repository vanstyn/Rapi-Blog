package Rapi::Blog::Util::Mailer;
use strict;
use warnings;

# ABSTRACT: General mailer object with defaults

use Moo;
use Types::Standard qw(:all);

use RapidApp::Util qw(:all);

require Module::Runtime;
use Email::Sender::Transport;
use Email::Sender::Transport::Sendmail;
use Email::Sender::Transport::SMTP;
use Email::Sender::Simple;
use Email::Simple;
use Email::Abstract;


sub send {
  my $self = shift;
  
  my %args = (scalar(@_) == 1) && (blessed($_[0]) || !ref($_[0]))
    ? ( message => $_[0] )
    : (ref($_[0]) eq 'HASH') ? %{ $_[0] } : @_; # <-- arg as hash or hashref
  
  
  # If we're called as a class method:
  return $self->new(\%args)->send unless (blessed $self);
  
  # We're an already created object, we shouldn't see any arguments:
  die "->send() only accepts arguments when called as a class method" if (scalar(keys %args) > 0);

  Email::Sender::Simple->send($self->email, { 
    to        => $self->full_envelope_to,
    from      => $self->envelope_from,
    transport => $self->transport
  });

}



sub BUILD {
  my $self = shift;
  
  # Perform initializations:
  $self->transport;
  $self->email;
}


has 'transport', 
  is      => 'ro', 
  isa     => ConsumerOf['Email::Sender::Transport'],
  lazy    => 1,
  default => sub { Email::Sender::Transport::Sendmail->new };


has 'message', is => 'ro', default => sub {undef};
has 'body', is => 'ro', isa => Str, lazy => 1, default => sub {
  my $self = shift;
  $self->initialized ? $self->email->body : $self->default_body
};


#has 'default_to',      is => 'ro', isa => Str, default => sub { 'unspecified-address@unspecified-domain.com' };
#has 'default_from',    is => 'ro', isa => Str, default => sub { 'unspecified-address@unspecified-domain.com' };

has 'default_to', is => 'ro', lazy => 1, default => sub { 
  'hvs@hvs.io' 
}, isa => ArrayRef[InstanceOf['Email::Address']], coerce => \&_coerce_addresses;


has 'default_from',    is => 'ro', default => sub { 
  'henry@vanstyn.com' 
}, isa => InstanceOf['Email::Address'], coerce => \&_coerce_first_addresses;



has 'default_subject', is => 'ro', isa => Str, default => sub { '(no subject)' }; 
has 'default_body',    is => 'ro', isa => Str, default => sub { '' }; 


has 'default_headers', is => 'ro', default => sub {[
  'X-Mailer-Class' => __PACKAGE__
]}, isa => ArrayRef;


has 'from', is => 'ro', lazy => 1, default => sub {
  my $self = shift;
  $self->initialized ? $self->email->get_header('From') : $self->envelope_from
}, isa => InstanceOf['Email::Address'], coerce => \&_coerce_first_addresses;

has 'envelope_from', is => 'ro', lazy => 1, default => sub {
  my $self = shift;
  $self->initialized ? $self->email->get_header('From') : $self->default_from
}, isa => InstanceOf['Email::Address'], coerce => \&_coerce_first_addresses;


has 'to', is => 'ro', lazy => 1, default => sub {
  my $self = shift;
  $self->initialized ? $self->email->get_header('To') : $self->envelope_to
}, isa => ArrayRef[InstanceOf['Email::Address']], coerce => \&_coerce_addresses;


has 'cc', is => 'ro', lazy => 1, default => sub {
  my $self = shift;
  $self->initialized ? $self->email->get_header('CC') : $self->envelope_to
}, isa => ArrayRef[InstanceOf['Email::Address']], coerce => \&_coerce_addresses;


has 'bcc', is => 'ro', lazy => 1, 
  default => sub { undef },
  isa => Maybe[ArrayRef[InstanceOf['Email::Address']]], 
  coerce => \&_coerce_addresses;


has 'envelope_to', is => 'ro', lazy => 1, default => sub {
  my $self = shift;
  $self->initialized ? $self->email->get_header('To') : $self->default_to
}, isa => ArrayRef[InstanceOf['Email::Address']], coerce => \&_coerce_addresses;


has 'full_envelope_to', is => 'ro', init_arg => undef, lazy => 1, default => sub {
  my $self = shift;
  my %seen = ();
  [ grep { !$seen{lc($_->address)}++ } (@{$self->envelope_to},@{$self->to},@{$self->cc},@{$self->bcc}) ]
}, isa => ArrayRef[InstanceOf['Email::Address']];


sub _coerce_first_addresses { &_coerce_addresses(@_)->[0] };

sub _coerce_addresses {
  #shift(@_) if (($_[0] eq __PACKAGE__) || (blessed($_[0]) && $_[0]->isa(__PACKAGE__)));
  my @list = (ref($_[0])||'' eq 'ARRAY') ? @{$_[0]} : @_;
  return [ map { Email::Address->parse($_) } @list ];
}


has 'subject', is => 'ro', isa => Str, lazy => 1, default => sub {
  my $self = shift;
  $self->initialized ? $self->email->get_header('Subject') : $self->defult_subject
};

has 'initialized', is => 'rw', isa => Bool, default => sub {0};


has 'email', is => 'ro', init_arg => undef, lazy => 1, default => sub {
  my $self = shift;
  $self->initialized(0);
  
  my $email = Email::Abstract->new( $self->message
    ? $self->message
    : Email::Simple->create( header => $self->default_headers )
  ) or die "unknown error occured parsing message";
  

  # If these attributes have been expressly set, those values take priority, override
  # any which are already set via being parsed out the the supplied message:
  my @header_attrs = qw/to from cc subject/;
  for my $header (@header_attrs) {
    next unless $self->meta->get_attribute($header)->has_value($self);
    $email->set_header( ucfirst($header) => $self->_format_header_multival($self->$header) );
  }
  
  # These are getting set again, however, the difference is that these apply to the 
  # default values vs user-defined values. User-defined values take priority, while 
  # parsed values take priory over the defaults
  $email->get_header($_) or $email->set_header( ucfirst($_) => $self->$_ ) for (@header_attrs);
  
  # Finally set additional default headers which haven't already been set:
  my %headers = @{$self->default_headers};
  $email->get_header($_) or $email->set_header( $headers{$_} ) for (keys %headers);
  
  # Do the same for body: user-supplied value first, then auto parsed value, then default as last resort
  $self->meta->get_attribute('body')->has_value($self) and $email->set_body( $self->body );
  $email->get_body or $email->set_body( $self->body );
  
  $self->initialized(1);
  
  return $email
  
}, isa => InstanceOf['Email::Abstract'];


sub _format_header_multival {
  my ($self, $vals) = @_;
  $vals = [$vals] unless (ref($vals)||'' eq 'ARRAY');
  join(', ',map { blessed($_) && $_->can('format') ? $_->format : "$_" } @$vals)
}





1;


__END__

=head1 NAME

Rapi::Blog::Util::Mailer - General mailer object with defaults


=head1 DESCRIPTION

Sends E-Mails

=head1 SEE ALSO

=over

=item * 

L<rabl.pl>

=back

=head1 AUTHOR

Henry Van Styn <vanstyn@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2019 by IntelliTree Solutions llc.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
