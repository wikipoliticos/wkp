package wkp::Controller::U::Contexts;
use Moose;
use namespace::autoclean;

BEGIN { extends 'Catalyst::Controller'; }

sub auto :Private {
    my ( $self, $c ) = @_;

}

sub base :Chained('/u/object') PathPart('contextos') CaptureArgs(0) {
    my ( $self, $c ) = @_;

    unless ($c->user_exists && $c->user->id eq $c->stash->{user}->id) {

        $c->res->redirect('/');
    }
}

sub index :Chained('base') PathPart('') Args(0) {
    my ( $self, $c ) = @_;

}
sub p :Chained('base') PathPart('p') Args(0) {
    my ( $self, $c ) = @_;

}

__PACKAGE__->meta->make_immutable;

1;
