package wkp::View::Email;

use strict;
use base 'Catalyst::View::Email';

__PACKAGE__->config(
    stash_key => 'email'
);

1;
