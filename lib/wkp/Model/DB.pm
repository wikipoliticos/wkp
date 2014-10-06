package wkp::Model::DB;

use strict;
use base 'Catalyst::Model::DBIC::Schema';

__PACKAGE__->config(
    schema_class => 'wkp::Schema',

    connect_info => {
        pg_enable_utf8 => 1,
        quote_char => '"'
    }
);

1;
