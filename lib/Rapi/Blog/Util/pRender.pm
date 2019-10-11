package Rapi::Blog::Util::pRender;
use strict;
use warnings;

# ABSTRACT: Render method dispatch to template process class

use Moo;
use Types::Standard qw(:all);
use RapidApp::Util qw(:all);
require Module::Runtime;


sub AUTOLOAD {
  my $self = shift;
  my $meth = (reverse(split('::',our $AUTOLOAD)))[0];
  my $class = join('::','Rapi::Blog::Template::Postprocessor',$meth);
	
	Module::Runtime::require_module($class);
	
	$class->can('process') or die "$class is not a Template Processor class without a ->process method";
	
	my $content = shift;
	my $content_ref = ref $content ? $content : \$content;
	
	$class->process($content_ref)
}



1;


__END__

=head1 NAME

Rapi::Blog::Util::pRender - Render method dispatch to template process class


=head1 DESCRIPTION

Caller to Template Postprocessor class

=head1 SEE ALSO

=over

=item * 

L<Rapi::Blog>

=back

=head1 AUTHOR

Henry Van Styn <vanstyn@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2019 by IntelliTree Solutions llc.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
