package Koha::Plugin::Com::Theke::MarcCard;

use Modern::Perl;
use utf8;

use base qw(Koha::Plugins::Base);

use C4::Auth;
use C4::Biblio;
use C4::Context;
use Koha::Biblios;
use Koha::Items;

use Data::Printer;
use MARC::Record;

our $VERSION = 1.01;

our $metadata = {
    name            => 'Koha Ficha ISBD Biblioteca Mayor UNC',
    author          => 'Tomás Cohen Arazi',
    description     => 'Generates a printable card for items on the DB',
    date_authored   => '2016-09-21',
    date_updated    => '2013-09-21',
    minimum_version => '16.0500000',
    maximum_version => undef,
    version         => $VERSION,
};

sub new {
    my ( $class, $args ) = @_;

    ## We need to add our metadata here so our base class can access it
    $args->{'metadata'} = $metadata;

    my $self = $class->SUPER::new($args);

    return $self;
}

sub tool {
    my ( $self, $args ) = @_;
    my $cgi = $self->{'cgi'};

    my $step = $cgi->param('step') // 'welcome';
    $step = 'welcome'
        unless ( $step eq 'results' or $step eq 'render' );

    if ( $step eq 'welcome' ) {
        $self->tool_step_welcome;
    }
    elsif ( $step eq 'results' ) {
        $self->tool_step_results;
    }
    else {
        # $step eq 'render'
        $self->tool_step_render;
    }
}

sub tool_step_welcome {
    my ( $self, $args ) = @_;
    my $cgi = $self->{'cgi'};

    my $template = $self->get_template( { file => 'tool-step-welcome.tt' } );

    if ( $args->{'error'} ) {
        $template->param( error =>  $args->{'error'} );
    }

    print $cgi->header( -charset => 'utf-8' );
    print $template->output();
}

sub tool_step_results {
    my ( $self, $args ) = @_;
    my $cgi = $self->{'cgi'};

    my $template;

    my $barcode = $cgi->param('barcode') // '';

    if ( $barcode eq '' ) {
        $template = $self->get_template( { file => 'tool-step-welcome.tt' } );
        $template->param( error => 'empty_barcode_passed' );
    }
    else {
        my $item = Koha::Items->search({ barcode => $barcode })->next;
        if ( not defined $item ) {
            $template = $self->get_template( { file => 'tool-step-welcome.tt' } );
            $template->param( error => 'item_not_found' );
        }
        else {
            my $biblio = Koha::Biblios->find( $item->biblionumber );
            $template = $self->get_template({ file => 'tool-step-results.tt' });
            $template->param(
                item => $item,
                biblio => $biblio
            );
        }
    }

    print $cgi->header( -charset => 'utf-8' );
    print $template->output();
}

sub tool_step_render {
    my ( $self, $args ) = @_;
    my $cgi = $self->{'cgi'};

    my $template = $self->get_template({ file => "tool-step-render.tt" });

    my $output  = $cgi->param('output');
    my $barcode = $cgi->param('barcode');


    # my @results;
    # while ( my $row = $sth->fetchrow_hashref() ) {
    #     my $marc = MARC::Record::new_from_usmarc( $row->{'marc'} );
    #     $lint->check_record($marc);
    #     my @warnings = grep ( !/Subfield _9/, $lint->warnings );

    #     push(
    #         @results,
    #         {   data     => $row,
    #             warnings => @warnings
    #         }
    #     ) if defined @warnings;
    # }

    # my $template = $self->get_template( { file => "report-step2.tt" } );

#    $template->param( results => \@results, );

    print $cgi->header( -charset => 'utf-8' );
    print $template->output();
}

1;
