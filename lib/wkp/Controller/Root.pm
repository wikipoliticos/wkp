package wkp::Controller::Root;
use Moose;
use namespace::autoclean;
use Text::Unidecode;
use JSON;
use utf8;
use DateTime;
use Digest::SHA1 qw/sha1_base64/;

BEGIN { extends 'Catalyst::Controller' }

#
# Sets the actions in this controller to be registered with no prefix
# so they function identically to actions created in MyApp.pm
#
__PACKAGE__->config(namespace => '');


sub index :Path :Args(0) {
    my ( $self, $c ) = @_;

    my $post_srv = $c->model('Service', 'Post');
    my ($posts_rs, $pager) = $post_srv->posts_without_comments(undef, 1, 5);

    $c->stash(posts => [$posts_rs->all], pager => $pager,
              page_title_full => 'WikiPolíticos - Registro Colaborativo da História Política');
}

sub about :Path('/sobre') {
    my ($self, $c) = @_;
    $c->stash(page_title => 'Sobre');
}

sub default :Path {
    my ( $self, $c ) = @_;
    #$c->response->body( 'Page not found' );
    $c->response->status(404);
    $c->stash(template => '404.tt');
}

sub busca :Local {
    my ( $self, $c ) = @_;

    my $p = lc unidecode $c->req->param('p');
    $p =~ s/\s{1,}/%/g;

    my $politicians_rs = $c->model('DB::Politician');
    my @politicians = $politicians_rs->search_rs(
                                                 { token => { like => '%' . $p . '%' } },
                                                 { prefetch => 'candidatures',
                                                   order_by => { '-asc' => 'me.name'},
                                                   rows => 30 }
                                                )->all;

    my $financiers_rs = $c->model('DB::Financier');
    my @financiers = $financiers_rs->search_rs(
                                               { token => { like => '%' . $p . '%' } },
                                               { order_by => 'name', rows => 30 }
                                              )->all;

    $c->stash(politicians => \@politicians, financiers => \@financiers,
              page_title => 'Busca de Perfis');
}

=for everyone

Recebe uma string e procura por ela em cada contexto.
Retorna um JSON

Será ainda usado na tela de postagens na qual será possível escolher
diversos contextos para um post. Ou seja, o usuário não terá que ir
para a tela de um contexto para postar nele, mas poderia ir para uma
tela de postagem integrada.

=cut

sub search_contexts :Chained('/') PathPart('search-contexts') Args(1) {
    my ($self, $c, $term) = @_;

    my $result = [];
    my $politicians_rs = $c->model('DB::Politician');
    my $financiers_rs  = $c->model('DB::Financier');
    my $actions_rs     = $c->model('DB::Action');

    $term = lc unidecode $term;
    $term =~ s/-/ /g;
    $term =~ s/\s{1,}/%/g;

    my @politicians = $politicians_rs->search({ token => { like => '%' . $term . '%' } },
                                              { prefetch => 'candidatures',
                                                order_by => { '-asc' => 'token' },
                                                rows => 10 });

    for my $politician (@politicians) {
        push @$result, { name => $politician->name,
                         token => $politician->token,
                         type => 'politician',
                         recent_candidature => $politician->candidatures->first->print_ok };
    }
    $c->res->content_type('application/json');
    $c->res->body(encode_json $result);
}

sub login : Path('/entrar') GET {
    my ($self, $c) = @_;
    $c->stash(page_title => 'Entrar');
}

sub login_post : Path('/entrar') POST {
    my ( $self, $c ) = @_;

    if ( my $username = $c->req->params->{username} and
         my $password = $c->req->params->{password} ) {
        if ( $c->authenticate({ token => $username,
                                password => $password }) ) {
            $c->res->redirect('/');
        }
        else {
            $c->flash->{alert_error} = 'Usuário e/ou senha incorretos.';
            $c->res->redirect($c->uri_for_action('login'));
        }
    }
    else {
        $c->flash->{alert_error} = 'Usuário e/ou senha incorretos.';
        $c->res->redirect($c->uri_for_action('login'))
    }

}

sub sign_up : Path('/cadastrar-se') GET {
    my ($self, $c) = @_;

    $c->stash(page_title => 'Cadastro de Usuário');
}

sub sign_up_post : Path('/cadastrar-se') POST {
    my ($self, $c) = @_;

    unless ($c->validate_captcha($c->req->param('captcha'))) {
        $c->flash->{alert_error} = 'Código de validação incorreto.';
        $c->go('/sign_up');
    }

    my $username = $c->req->param('username');
    $username = lc unidecode $username;
    $username =~ s/\s*//g;

    unless ($username =~ /^\w{5,}+$/) {
        $c->flash->{alert_error} =
          'Login deve ter no mínimo 5 caracteres e conter apenas letras, números e/ou _ (sublinhado).';
        $c->go('sign_up');
    }

    my $password = $c->req->param('password');
    my $password_confirmation = $c->req->param('password_confirmation');

    unless ($username and $password and $password_confirmation) {
        $c->flash->{alert_error} =
          'Cadastro deve ter no mínimo nome de usuário, senha e confirmação de senha.';
        $c->go('sign_up');
    }

    if ($password ne $password_confirmation) {
        $c->flash->{alert_error} = 'Confirmação de senha incorreta.';
        $c->go('sign_up');
    }

    my $users_rs = $c->model('DB::User');

    my $user_token_check = $users_rs->find({ token => $username });
    if ($user_token_check) {
        $c->flash->{alert_error} = 'Nome de usuário já em uso. Por favor, escolha outro.';
        $c->go('sign_up');
    }

    if ($c->req->param('email')) {
        my $user_email_check = $users_rs->find({ email => $c->req->param('email') });
        if ($user_email_check) {
            $c->flash->{alert_error} = 'Email já em uso. Por favor, escolha outro.';
            $c->go('sign_up');
        }
    }

    my $user_data = { name => $c->req->param('name'),
                      token => $username,
                      password => sha1_base64 $password };

    $user_data->{email} = $c->req->param('email') if $c->req->param('email');

    eval {
        $users_rs->create( $user_data );
    } or do {
        $c->flash->{alert_error} = 'Erro.';
        $c->go('sign_up');
    };

    $c->authenticate({ token => $username, password => $password });
    $c->res->redirect( $c->uri_for_action('/index') );
}

sub captcha : Local {
    my ($self, $c) = @_;
    $c->create_captcha();
}

=for
Search for user by email. Not found? Search user by username. No found? Send error msg.
User found? check if it has email. If she has not, send error msg.

Check if user's pw_recover_expiration_date is lesser than
DateTime->now. If it is, user cannot solicitate new recover email
now. The user has to wait the expiration date (1 hour?). If time is
not good, show error msg.

Else, generate hash and send to user.

=cut

sub request_password_recovery : Path('/recuperar-senha') Args(0) {
    my ($self, $c) = @_;

    if ($c->req->method eq 'POST') {
        my $user;
        my $email;

        if (!$c->req->param('username') and !$c->req->param('email')) {
            $c->flash->{alert_error} = 'Você precisa informar seu nome de usuário ou email.';
        }
        else {
            if ($c->req->param('username')) {
                $user = $c->model('DB::User')->find({ token => $c->req->param('username') });
            }

            if (!$user and $c->req->param('email')) {
                $user = $c->model('DB::User')->find({ email => $c->req->param('email')    });
            }

            if (!$user) {
                $c->flash->{alert_error} = 'Usuário não encontrado.';
            }
            else {
                $email = $user->email;

                if (!$email) {
                    $c->flash->{alert_error} = 'Usuário informado não tem email cadastro. '
                      . 'Não será possível recuperar sua senha.';
                }
                else {
                    # Send hash to email if user has not a expiration
                    # date. If she has, send if expiration date is
                    # expired.
                    $c->log->debug( DateTime->now->compare($user->pw_recovery_expiration) );
                    $c->log->debug( DateTime->now );
                    $c->log->debug( $user->pw_recovery_expiration );
                    if (
                      !$user->pw_recovery_expiration ||
                      DateTime->now->compare($user->pw_recovery_expiration) >= 0
                       ) {
                        # Generate hash
                        my @hash_numbers;
                        push @hash_numbers, int(rand(10)) for 0..29;
                        my $hash = join '', @hash_numbers;

                        # Generate new expiration date
                        my $expiration = DateTime->now->add
                          ( DateTime::Duration->new(days => 1) );

                        $user->update({ pw_recovery_hash       => $hash,
                                        pw_recovery_expiration => $expiration });

                        # Send to the user via email
                        $c->stash->{email} =
                          { from    => 'contato@wikipoliticos.com.br',
                            to      => $email,
                            subject => 'WikiPolíticos - Recuperação de senha',
                            body    => _pw_recover_email_body($user->token,
                                                              $hash,
                                                              $expiration) };

                        $c->forward( $c->view('Email') );

                        $c->flash->{alert_success} =
                          'Você receberá por email em alguns minutos'
                            . ' instruções de recuperação de senha.';
                    }
                    else {
                        $c->flash->{alert_error} =
                          'Você requisitou recuperação de senha há menos'
                            . ' de um dia. Pode-se solicitar apenas uma'
                            . ' vez por dia.';
                    }
                }
            }
        }

        $c->res->redirect($c->uri_for_action('/index'));
    }
}

sub _pw_recover_email_body {
    my ($username, $hash, $expiration_date) = @_;

    return

"Olá,

Clique no endereço abaixo. Você irá para uma tela onde poderá reiniciar sua senha.

    http://wikipoliticos.com.br/recuperar-senha/${username}/${hash}

Este enlace é válido até $expiration_date

--
WikiPolíticos";

}

sub process_password_recovery : Path('/recuperar-senha') Args(2) {
    my ($self, $c, $username, $hash) = @_;

    # Get user. Fail? Detach. Check expiration. Fail? Detach.
    # Check hash. Fail? Detach.
    my $user = $c->model('DB::User')->find({ token => $username });

    unless ($user &&
            $user->pw_recovery_hash eq $hash &&
            DateTime->now->compare($user->pw_recovery_expiration) <= 0) {
        $c->flash->{alert_error} = 'Requisição incorreta.';
        $c->res->redirect($c->uri_for_action('/login'));
    }
    else {
        if ($c->req->method eq 'POST') {
            if ($c->req->param('password') && $c->req->param('password2')
                  && $c->req->param('password') eq $c->req->param('password2')) {

                $user->password(sha1_base64 $c->req->param('password'));
                $user->pw_recovery_hash(undef);
                $user->update;

                $c->flash->{alert_success} = 'Senha modificada. Você já está logado(a).';
                $c->authenticate({ token => $username, password => $c->req->param('password') });
                $c->res->redirect( $c->uri_for_action('/index') );
            }
            else {
                $c->stash->{alert_error} =
                  'Você deve digitar duas vezes sua nova senha.';
            }
        }
    }
}

sub logout : Path('/sair') {
    my ($self, $c) = @_;
    $c->logout;
    $c->res->redirect('/');
}

=head2 end

Attempt to render a view, if needed.

=cut

sub end : ActionClass('RenderView') {}

=head1 AUTHOR

sgrs,,,

=head1 LICENSE

This library is free software. You can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

__PACKAGE__->meta->make_immutable;

1;
