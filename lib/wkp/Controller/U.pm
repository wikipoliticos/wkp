package wkp::Controller::U;
use Moose;
use namespace::autoclean;
use Text::Unidecode;
use utf8;
use Digest::SHA1 qw/sha1_base64/;

BEGIN { extends 'Catalyst::Controller'; }

sub base :Chained('/') PathPart('u') :CaptureArgs(0) {
    my ( $self, $c ) = @_;
    $c->stash(users_rs => $c->model('DB::User'),
             page_title => 'Usuários');
}

sub object :Chained('base') PathPart('') CaptureArgs(1) {
    my ( $self, $c, $token ) = @_;
    my $user = $c->stash->{users_rs}->find({ token => $token });

    $c->stash(user => $user,
              page_title => $user->token . ' - Usuários');
}

sub index :Chained('base') PathPart('') Args(0) {
    my ( $self, $c ) = @_;

    my $p = lc unidecode $c->req->param('p');
    $p =~ s/\s{1,}/%/g;

    my $rs = $c->stash->{users_rs}
      ->search_rs({ 'me.token' => { like => '%' . $p . '%' } },
                  { order_by   => 'token', rows => 100        })
        ->page($c->req->params->{'pagina'} || 1);

    $c->stash(users => [$rs->all],
              pager => $rs->pager);

}

sub edit :Chained('object') PathPart('editar') Args(0) {
    my ( $self, $c ) = @_;

    $c->res->redirect('/u')
      unless $c->user->token eq $c->stash->{user}->token;

    if ($c->req->method eq 'POST') {
        $c->stash->{user}->update({ name => $c->req->param('name') });
        $c->flash->{alert_success} = 'Dados atualizados.';
        $c->res->redirect(
            $c->uri_for_action( '/u/posts', [$c->stash->{user}->token] ));
    }
}

sub edit_password :Chained('object') PathPart('editar-senha') Args(0) {
    my ( $self, $c ) = @_;

    $c->res->redirect('/u')
      unless $c->user->token eq $c->stash->{user}->token;

    if ($c->req->method eq 'POST') {
        my $user = $c->stash->{user};

        if ($c->req->param('password') && $c->req->param('password2')
              && $c->req->param('password') eq $c->req->param('password2')) {

            $user->password(sha1_base64 $c->req->param('password'));
            $user->update;

            $c->flash->{alert_success} = 'Senha alterada.';
            $c->res->redirect(
                $c->uri_for_action( '/u/posts', [$c->stash->{user}->token] ));
        }
        else {
            $c->flash->{alert_error} =
              'Você deve digitar duas vezes sua nova senha.';
            $c->res->redirect(
                $c->uri_for_action( '/u/edit_password',
                                    [$c->stash->{user}->token] ));
        }
    }
}

sub delete_account :Chained('object') PathPart('deletar-conta') Args(0) {
    my ($self, $c) = @_;

    unless ($c->user_exists and $c->user->id == $c->stash->{user}->id) {
        $c->flash->{alert_error} = 'Não autorizado.';
        $c->res->redirect('/');
        return;
    }

    if ($c->req->method eq 'POST') {
        my @posts =
          $c->model('DB::Post')->search({ user_id => $c->stash->{user}->id });

        # TODO otimizar
        for my $post (@posts) {
            $post->user_id(undef);
            $post->update;
        }

        $c->logout;
        $c->stash->{user}->delete;

        $c->flash->{alert_success} = 'Sua conta foi deletada.';
        $c->res->redirect('/');
    }
}

sub posts :Chained('object') PathPart('') Args(0) {
    my ( $self, $c ) = @_;

    my @posts = $c->stash->{user}->posts(undef,
                                         { order_by => { -desc => 'me.id' } });

    $c->stash(posts => \@posts);
}

__PACKAGE__->meta->make_immutable;
1;
