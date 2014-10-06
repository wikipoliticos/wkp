package wkp::Model::Service;

use Moose;
extends 'Catalyst::Model';

sub ACCEPT_CONTEXT {
    my ( $self, $c, @args ) = @_;

    my $package = 'wkp::Service::' . shift @args ;
    eval "require $package" or die $!;

    return $package->new({ schema => $c->model('DB') });
}

1;
