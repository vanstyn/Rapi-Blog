package Rapi::Blog::Controller::Remote;
use Moose;
use namespace::autoclean;

BEGIN { extends 'Catalyst::Controller'; }

use strict;
use warnings;

use RapidApp::Util ':all';
use Rapi::Blog::Util;
use URI;
use Email::Valid;

# This is the general-purpse controller for handing domain-specific 
# custom-code endpoint requests outside/separate of RapidApp


sub comment :Local :Args(1) {
  my ($self, $c, $arg) = @_;
  
  return $self->add_comment($c) if ($arg eq 'add');
  
  
  $self->error_response($c,"bad comment argument '$arg'");
}

sub add_comment {
  my ($self, $c) = @_;
  
  # Ignore via generic redirect if its not a POST
  $c->req->method eq 'POST' or return $c->res->redirect( $c->mount_url.'/', 307 );
  
  my $User = Rapi::Blog::Util->get_User or return $self->error_response($c,
    "Not logged in or unable to find current user"
  );
  
  $User->can_comment or return $self->error_response($c,
    "Add comment: permission denied"
  );
  
  my $body = $c->req->params->{body} or return $self->error_response($c,"missing param 'body'");
  
  my %data;
  my $Post;
  
  if(my $parent_id = $c->req->params->{parent_id}) {
    my $pComment = $c->model('DB::Comment')->search_rs({ 'me.id' => $parent_id })->first
      or return $self->error_response($c,"Comment '$parent_id' does not exist or permission denied");
    
    $Post = $pComment->post;
    $data{parent_id} = $pComment->id;
  }
  elsif(my $post_id = $c->req->params->{post_id}) {
    $Post = $c->model('DB::Post')->search_rs({ 'me.id' => $post_id })->first
      or return $self->error_response($c,"Post '$post_id' does not exist or permission denied");
  }
  else {
    return $self->error_response($c,"Must supply either 'post_id' or 'parent_id'");
  }
  
  %data = ( %data,
    post_id => $Post->id,
    user_id => $User->id,
    body    => $body
  );
  
  my $Comment = $Post->comments->create(\%data)
    or return $self->error_response($c,"Unable to add comment - unknown error");
  
  my $url = join('#',$Post->public_url,$Comment->html_id);
  
  return $c->res->redirect( $url, 303 );
}



sub email_login :Local :Args(0) {
  my ($self, $c) = @_;
  
  ####### comment this out to test
  #die "email_login is experimental and this die line must be commented out in order to try it.";
  ################################
  
  
  # Non-posts silently redirect to the home page:
  $c->req->method eq 'POST' or return $c->res->redirect( $c->mount_url );
  
  $c->ra_builder->enable_email_login or return $self->error_response($c,
    "Permission denied - email login is not enabled."
  );
  
  Rapi::Blog::Util->get_User and return $self->error_response($c,
    "Not allowing E-Mail login for already logged in user"
  );
  
  # Only continue if we're properly using the 'local_info' API:
  $self->_using_local_info or return $self->error_response($c,
    "Invalid or malformed request - failed one or more 'local_info' API requirements"
  );
  
  my $email = $c->req->params->{email} or return $self->error_response($c,
    "Must supply an E-Mail address associated with an account"
  );
  
  ($email =~ /\@/) or return $self->error_response($c,
    "Supplied E-Mail '$email' is invalid"
  );
  
  my $Rs = $c->model('DB::User')->enabled;
  
  my $User = $Rs->search_rs({ -or => [{'me.email' => $email},{'me.email' => lc($email)}]})
    ->first or return $self->error_response($c,
      "No valid account with E-Mail address '$email'"
    );
  my $uid = $User->get_column('id');
  

  my $paRs = $c->model('DB::PreauthAction');
  
  my $key = $paRs->create_auth_key('login', $uid, {
      ttl => 5*60, # 5 minutes
    }) or return $self->error_response($c,join ' ',
      "Failed to create Pre-Authorization",'&ndash;',
      "an unknown error occured.",
      "Please contact your system administrator"
    );
    
  my $Preauth = $paRs->lookup_key($key) or return $self->error_response($c,join ' ',
    "Unknown error occured while creating Pre-Authorization",'&ndash;',
    "please contact your system administrator"
  );

  
  my $uri  = $c->req->uri->clone;
  my $link_url = do {
    $uri->path( join('/',$c->mount_url,'remote', 'preauth_action', $key) );
    $uri->query(undef);
    $uri->fragment( undef );
    $uri->as_string;
  };
  
  
  $c->model('Mailer')->send_mail({
    to      => $User,
    from    => '"Rapi::Blog ('.$uri->host_port.')" <no-reply@'.$uri->host.'>',
    subject => 'One-time login link',
    body    => join("",
      "Here is your one-time login link. This can only be used one time and will expire in ",
      $Preauth->ttl_minutes," minutes.\n\n$link_url\n\n"
    )
  });

  

  return $self->redirect_local_info_success($c, join ' ',

    "One-time direct login link has been sent to the e-mail address on file for your account. Please check your e-mail.",
    "<br><br>", "For security, the reset link will only work one time and will only be valid for the next", 
    $Preauth->ttl_minutes,"minutes",

  )
  
 

}





sub password_reset :Local :Args(0) {
  my ($self, $c) = @_;
  
  ###########
  # phase 2:
  # handle the preauthed reset after the user clicked the link from phase 1
  #
  $c->req->params->{key} and return $self->_password_reset_by_key($c);
  
  
  ###########
  # phase 1:
  # fresh request to start an preauth to reset a password
  #
  
  # Non-posts silently redirect to the home page:
  $c->req->method eq 'POST' or return $c->res->redirect( $c->mount_url );
  
  $c->ra_builder->enable_password_reset or return $self->error_response($c,
    "Permission denied - password reset is not enabled."
  );
  
  Rapi::Blog::Util->get_User and return $self->error_response($c,
    "Not allowing password reset for already logged in user"
  );
  
  # Only continue if we're properly using the 'local_info' API:
  $self->_using_local_info or return $self->error_response($c,
    "Invalid or malformed request - failed one or more 'local_info' API requirements"
  );
  
  
  my $supplied = $c->req->params->{username} or return $self->error_response($c,
    "Must supply a username or E-Mail address"
  );
  
  my $Rs = $c->model('DB::User')->enabled;
  
  my $uid;
  if($supplied =~ /\@/) {
    my $User = $Rs->search_rs({ -or => [{'me.email' => $supplied},{'me.email' => lc($supplied)}]})
      ->first or return $self->error_response($c,
        "No valid account with E-Mail address '$supplied'"
      );
    $uid = $User->get_column('id')
  }
  else {
    my $User = $Rs->search_rs({ -or => [{'me.username' => $supplied},{'me.username' => lc($supplied)}]})
      ->first or return $self->error_response($c,
        "No valid account with username '$supplied'"
      );
    $uid = $User->get_column('id')
  }

  my $paRs = $c->model('DB::PreauthAction');
  
  my $key = $paRs->create_auth_key('password_reset', $uid, {
      ttl => 15*60, # 15 minutes
      action_data => { 
        origin_referer => $c->req->referer # come back to us
      }
    }) or return $self->error_response($c,join ' ',
      "Failed to create Pre-Authorization",'&ndash;',
      "an unknown error occured.",
      "Please contact your system administrator"
    );
    
  my $Preauth = $paRs->lookup_key($key) or return $self->error_response($c,join ' ',
    "Unknown error occured while creating Pre-Authorization",'&ndash;',
    "please contact your system administrator"
  );
  
  
  # Real logic (send actual e-mail) goes here
  # ...
  

  my $link_url = do {
    my $uri  = $c->req->uri->clone;
    $uri->query_form( $uri->query_form, key => $key );
    $uri->as_string;
  };
  
  
  

  return $self->redirect_local_info_success($c, join ' ',
  

    "Password reset initiated",'&ndash;',
    "a password reset link has been E-Mailed to you.",
    "For security, the reset link will only be valid for the next", $Preauth->ttl_minutes,"minutes",
    
    "<br><br><br>\n","<a href='$link_url'>$link_url</a>",
    
    "<br><br><br>","TEMP DEBUG DATA:","<br><br>",
    "<pre>",join("\n   ",'',
     "key: $key",
     "ttl: " . $Preauth->ttl, '',
     "now_ts: ".Rapi::Blog::Util->dt_to_ts(Rapi::Blog::Util->now_dt),
     
     
     "columns: ". Dumper({ $Preauth->get_columns }),'','',
     "action_data: ". Dumper($Preauth->action_data),'','',
    
    ),"</pre>"
  )
  
 

}



# password reset phase 2:
sub _password_reset_by_key {
  my $self = shift;
  my $c = shift || RapidApp->active_request_context or return 0;
  
  my $key = $c->req->params->{key} or die "no key param supplied";
  
  my $Actor = $c
    ->model('DB::PreauthAction')
    ->request_Actor($c,$key);
  
  if($Actor->is_error) {
    die $Actor;
    #my $referer = '/forgot_password';
    #return $self->_local_info_dispatch($c,$referer,{ error_only => $Actor->info });
  }
  
  
  # phase 3
  if($c->req->params->{new_password}) {
    $Actor->call_execute and return $self->_redirect_local_info($c, { finished => 1 });
    
    # TODO:
    return $self->_redirect_local_info($c, { finished => 1, failed => 1 });
  }
  else {
    # phase 2:
    my $referer = $Actor->PreauthAction->action_data_get('origin_referer') or die "Missing origin_referer";
    return $self->_local_info_dispatch($c,$referer,{ key => $key });
  }
  
}


sub _using_local_info {
  my $self = shift;
  my $c = shift || RapidApp->active_request_context or return 0;
  
  $c->stash->{_using_local_info} //=  
    $c->req->params->{using}||'' eq 'local_info' && do {
    
      my $uri  = $c->req->uri;
      my $ruri = $c->req->referer ? URI->new( $c->req->referer ) : undef;
      
      # Require referer to be one of our local pages - not really hard security, 
      # but since we do not expect to ever be accessed via direct browse or 
      # linked to from an external site, don't allow it:
      $uri && $ruri && $uri->host_port eq $ruri->host_port
    }
}








sub signup :Local :Args(0) {
  my $self = shift;
  my $c = shift || RapidApp->active_request_context or return 0;
  
  $c->session->{local_info} and delete $c->session->{local_info};
  
  # Non-posts silently redirect to the home page:
  $c->req->method eq 'POST' or return $c->res->redirect( $c->mount_url );
  
  my @errs = ();
  
  my $uRs = $c->model('DB::User');
  my $p = $c->req->params;
  my $field_errs = {};
  
  if (my $username = $p->{username}) {
    if ($username =~ /^[a-zA-Z0-9\.\-\_]+$/) {
      if ($uRs->search_rs({ 'me.username' => $p->{username} })->count > 0) {
        $field_errs->{username}++; 
        push @errs, "Username already taken";
      }
    }
    else {
       push @errs, "usernames may only contain alpha characters and (-_.)";
       $field_errs->{username}++; 
    }
  }
  else {
    push @errs, "Must supply a username";
    $field_errs->{username}++;
  }
  
  if (my $email = $p->{email}) {
    if (Email::Valid->address($email)) {
      if ($uRs->search_rs({ 'me.email' => $p->{email} })->count > 0) {
        push @errs, "E-Mail already in use";
        $field_errs->{email}++;
      }
    }
    else {
      push @errs, "Supplied E-Mail address is not valid";
      $field_errs->{email}++;
    }
  }
  else {
    push @errs, "Must supply an E-Mail address";
    $field_errs->{email}++;
  }
  
  unless ($p->{full_name} && ($p->{full_name} =~ /\S/)) {
    $field_errs->{full_name}++; 
    push @errs, "Full Name cannot be blank";
  }
  if (($p->{full_name} =~ /^\s+/) || ($p->{full_name} =~ /\s+$/)) {
    $field_errs->{full_name}++;
    push @errs, "Full Name cannot start or end with whitespace";
  }
  
  my ($p1,$p2) = ($p->{password},$p->{confirm_password});
  if(length($p1) < 6) {
    $field_errs->{password}++;
    push @errs, "Passwords must be at least 6 characters long";
  }
  unless("$p1" eq "$p2") { 
    $field_errs->{confirm_password}++; 
    push @errs, "Passworrds do not match";
  }
  
  my $extra = { field_vals => $p, field_errs => $field_errs };
  
  if(scalar(@errs) > 0) {
    my $error_msg = join("\n",
      '<ul style="list-style-type:disc;padding-left:20px;font-size:.9em;">',
      (map { join('','<li>',$_,'</li>') } @errs),
      '</ul>'
    );
    
    $self->error_response($c,(join ' ',
      '<div style="padding-left:75px;margin-top:-25px;margin-bottom:-20px;text-align:left;">',
      '<div style="font-size:1.8em;padding-bottom:10px;">Errors:</div>',"\n",$error_msg,
      '</div>'),$extra
    );
  
  }
  else {
    $self->error_response($c,join( ' ',
      "No errors!! but no further code yet!")
    );
  }
  
  
  
  


}














sub redirect_local_info_error {
  my ($self, $c, $msg, $extra) = @_;
  $self->_redirect_local_info($c, $msg, 0, $extra)
}

sub redirect_local_info_success {
  my ($self, $c, $msg,$extra) = @_;
  $self->_redirect_local_info($c, $msg, 1, $extra)
}

sub _redirect_local_info {
  my ($self, $c, $info, $result, $extra) = @_;
  
  unless((ref($info)||'') eq 'HASH') {
    $info = { message => $info };
    %$info = (%$info,%$extra) if (ref($extra)||'' eq 'HASH');
  }
  my $msg = $info->{message} || '';

  my $uri  = $c->req->uri;
  my $ruri = URI->new( $c->req->referer );
  
  # If this isn't a local referer just throw hard error:
  $ruri && $uri->host_port eq $ruri->host_port or return $self->error_response($c,
    "Error, bad referer - message: '$msg'"
  );
  
  if(defined $result) {
    $result ? $info->{success} = 1 : $info->{error} = 1
  }
  
  # otherwise set the local_info and redirect back to the referer, trusting that
  # it is a properly written template that knows to look for and use the local_info:
  return $self->_local_info_dispatch($c,$ruri,$info)
}



sub _local_info_dispatch {
  my ($self, $c, $target, $info) = @_;
  
  # we don't currently want any local info to hang around at all, even for 
  # other paths. Maybe this will be changed later, but right now I can't envision
  # any use cases besides tight 2-request round trips
  $c->session->{local_info} and delete $c->session->{local_info};
  
  my $uri = blessed($target) && $target->isa('URI') ? $target : do {
    my $u = URI->new($target, $c->req->uri->scheme);
    $u->host_port( $c->req->uri->host_port );
    $u
  };
    
  my $path = $uri->path;
  
  $c->session->{local_info}{$uri->path} = $info;
  return $c->res->redirect( $uri->path_query );
}




# placeholder for later
sub error_response {
  my ($self, $c, $err, $extra) = @_;
  
  local $self->{_error_response_recurse} = $self->{_error_response_recurse} || 0;
  
  return $self->redirect_local_info_error($c,$err,$extra) if (
    $self->{_error_response_recurse}++ < 1 
    && $self->_using_local_info($c)
  );
  
  # hard errors make sure no leftover local_info:
  $c->session->{local_info} and delete $c->session->{local_info};
  
  die $err
}



__PACKAGE__->meta->make_immutable;

1;

__END__

=head1 NAME

Rapi::Blog::Controller::Remote - General-purpose controller actions

=head1 DESCRIPTION

This controller provides general-purpose HTTP end-points for use by scaffolds in Rapi::Blog
applications, such as posts to add comments and other functions (future) that are separate 
from the auto-generated interfaces provided by RapidApp. So far the only action that has 
been implemented is C<comment/add>.

=head1 ACTIONS

=head2 comment

Action for comment operations. Currently the only argument supported argumemnt is C<add>.

This will return with a 303 redirect back to the Post C<public_url> and the label tag C<html_id>
which is automatically generated for the comment. If the scaffold renders the C<html_id> with each
comment as the element id this will result in the page being scrolled to the just added comment.

Expects the following C<POST> params:

=head3 post_id

The id of the Post being commented on. Either C<post_id> or C<parent_id> must be supplied.

=head3 parent_id

The id of another Comment that this comment is a reply to. If C<parent_id> is supplied 
C<post_id> should not.

=head3 body

The body text of the comment

=head2 changepw

Not yet implemented.

=head1 SEE ALSO

=over

=item * 

L<Rapi::Blog>

=item * 

L<Catalyst::Controller>

=back


=head1 AUTHOR

Henry Van Styn <vanstyn@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2017 by IntelliTree Solutions llc.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

