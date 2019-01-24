package Rapi::Blog::Scaffold::Set;
use strict;
use warnings;

use RapidApp::Util qw(:all);
use Rapi::Blog::Util;

use Moo;
use Types::Standard ':all';

has 'Scaffolds', is => 'ro', required => 1, isa => ArrayRef[InstanceOf['Rapi::Blog::Scaffold']];

sub count { scalar(@{(shift)->Scaffolds}) }
sub all   { @{(shift)->Scaffolds}        }
sub first { (shift)->Scaffolds->[0]      }


sub BUILD {
  my $self = shift;
  
  $self->first or die "At least one Scaffold is required";
}


1;