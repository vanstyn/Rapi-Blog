package Rapi::Blog::Template::Postprocessor::MarkedWrapper;
use strict;
use warnings;

use RapidApp::Util qw(:all);
use String::Random;

sub process {
  shift if ($_[0] eq __PACKAGE__);
  my ($output_ref, $context) = @_;
  
  # If we're being processed (i.e. included within) from another Markdown template,
  # return the output as-is, since we only want to process at the top-level
  return $$output_ref if ($context->next_template_post_processor||'' eq __PACKAGE__);
  
  my $markedId = 'markdown-el-'. String::Random->new->randregex('[a-z0-9]{6}');
  
  return join("\n",
    '<xmp style="display:none;" id="'.$markedId.'">',
      $$output_ref,
    '</xmp>',
    '<script>',
    '  processMarkdownElementById("'.$markedId.'")',
    '</script>'
  );
}


1;