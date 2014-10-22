#!/usr/bin/env perl
# IMPORTANT: if you delete this file your app will not work as
# expected.  You have been warned.
use inc::Module::Install 1.02;
use Module::Install::Catalyst; # Complain loudly if you don't have
                               # Catalyst::Devel installed or haven't said
                               # 'make dist' to create a standalone tarball.

name 'wkp';
all_from 'lib/wkp.pm';

requires 'Catalyst::Runtime' => '5.90042';
requires 'Catalyst::Plugin::ConfigLoader';
requires 'Catalyst::Plugin::Static::Simple';
requires 'Catalyst::Action::RenderView';
requires 'Moose';
requires 'namespace::autoclean';
requires 'Config::General'; # This should reflect the config file format you've chosen
                 # See Catalyst::Plugin::ConfigLoader for supported formats

requires 'Email::Sender::Transport::SMTP::TLS';
requires 'Catalyst::View::Email';
requires 'DBIx::Class::DeleteAction';
requires 'Catalyst::Plugin::Captcha';
requires 'Catalyst::Plugin::Authentication';
requires 'Catalyst::Plugin::Session';
requires 'Catalyst::Plugin::Session::Store::File';
requires 'Catalyst::Plugin::Session::State::Cookie';
requires 'Catalyst::Plugin::ErrorCatcher';
requires 'Digest::SHA1';
requires 'JSON';
requires 'DateTime';
requires 'Text::Unidecode';
requires 'Number::Format';
requires 'HTML::Scrubber';
requires 'DBIx::Class';
requires 'DBIx::Class::TimeStamp';
requires 'Catalyst::Authentication::Store::DBIx::Class';
requires 'Catalyst::View::TT';
requires 'MooseX::MarkAsMethods';
requires 'MooseX::NonMoose';
requires 'DBD::Pg';
requires 'DateTime::Format::Pg';
requires 'DBIx::Class::Schema::Loader';
requires 'Catalyst::Plugin::Cache';
requires 'Cache::FastMmap';

test_requires 'Test::More' => '0.88';
catalyst;

install_script glob('script/*.pl');
auto_install;
WriteAll;
