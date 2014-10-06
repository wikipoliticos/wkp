package wkp::View::TT;
use Moose;
use namespace::autoclean;
use Number::Format qw/format_number/;

extends 'Catalyst::View::TT';

sub number_formater {
    my ($self, $c, $number) = @_;

    my $number_formater = Number::Format->new(-thousands_sep => '.',
                                              -decimal_point => ',');
    return $number_formater->format_number($number, 2, 2);
}

sub label_cpf_or_cnpj {
    my ($self, $c, $string) = @_;

    return 'CPF' if length $string == 11;
    return 'CNPJ' if length $string == 14;
}

__PACKAGE__->config(
    TEMPLATE_EXTENSION => '.tt',
    render_die => 1,
    WRAPPER => 'wrapper.tt',
    ENCODING => 'UTF-8',
    RECURSION => 1,
    expose_methods => [qw/number_formater/]
);

1;
