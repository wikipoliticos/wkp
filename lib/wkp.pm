package wkp;
use Moose;
use namespace::autoclean;

use Catalyst::Runtime 5.80;

use Catalyst qw/ConfigLoader
                Static::Simple
                StackTrace
                Authentication
                Session
                Session::Store::File
                Session::State::Cookie
                Captcha
                ErrorCatcher
               /;

extends 'Catalyst';

our $VERSION = '0.01';

__PACKAGE__->config(
    name => 'wkp',
    # Disable deprecated behavior needed by old applications
    disable_component_resolution_regex_fallback => 1,
    enable_catalyst_header => 1, # Send X-Catalyst header

    encoding => "UTF-8",
    'Plugin::Session' => {
        flash_to_stash => 1,
    },
    'Plugin::Authentication' => {
        default => {
            credential => {
                class => 'Password',
                password_field => 'password',
                password_type => 'hashed',
                password_hash_type => 'SHA-1',
            },
            store => {
                class => 'DBIx::Class',
                user_model => 'DB::User',
            },
        },
    },
    default_view => 'TT',
    'View::Email' => {
        default => {
            content_type => 'text/plain',
            charset => 'utf-8',
        },
        sender => {
            mailer => 'SMTP::TLS',
        },
    },
    'Plugin::Captcha'  => {
        session_name => 'captcha_string',
        new => {
            width => 90,
            height => 50,
            ptsize => '26',
            font => q{/usr/share/fonts/truetype/ttf-dejavu/DejaVuSans.ttf},
            rndmax => 3,
        },
        create => ['ttf', 'ec', '#0066CC', '#0066CC'],
        particle => [50],
        out => {force => 'jpeg'},
    },
   );

__PACKAGE__->setup();

1;
