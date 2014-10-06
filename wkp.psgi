use strict;
use warnings;

use wkp;

my $app = wkp->apply_default_middlewares(wkp->psgi_app);
$app;

