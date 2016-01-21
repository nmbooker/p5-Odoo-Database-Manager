package Odoo::Database::Manager;
use v5.20;
use strict;
use warnings;

our $VERSION = "0.01";

use JSON::RPC2::Client;
use JSON::XS;
use LWP::UserAgent;
use HTTP::Request;


use failures qw/odoo::rpc::http odoo::rpc::http::connection odoo::rpc::response odoo::rpc::method/;

use Moose;
use namespace::autoclean;

has url => (is => 'ro', isa => 'Str', default => 'http://localhost:8069');
#has password => (is => 'ro', isa => 'Str', default => 'admin');

has ua => (is => 'ro', lazy => 1, builder => 'build_ua');
has json_rpc_client => (is => 'ro', lazy => 1, builder => 'build_json_rpc_client');

sub build_ua {
    return LWP::UserAgent->new();
}

sub build_json_rpc_client {
    return JSON::RPC2::Client->new();
}


sub list_databases {
    my ($self) = @_;
    my $url = $self->url.'/web/database/get_list';  # TODO Use a URI library
    my $method = 'call';

    my $jsonreq = $self->json_rpc_client->call($method);
    my $json = decode_json($jsonreq);
    $json->{params} //= {};
    $jsonreq = encode_json($json);
    my $request = HTTP::Request->new(POST => $url);
    $request->content_type('application/json');
    $request->header(Accept => 'application/json, text/javascript, */*; q=0.01');
    $request->content($jsonreq);

    my $res = $self->ua->request($request);

    unless ($res->is_success) {
        my $subclass = ($res->status_line =~ /^500 Can't connect to/) ? "::connection" : "";
        "failure::odoo::rpc::http$subclass"->throw({
            msg => $res->status_line,
            payload => { result => $res }
        });
    }

    my ($failed, $result, $error) = $self->json_rpc_client->response($res->content);
    _failure("rpc::response")->throw($failed)
        if $failed;

    if ($error) {
        my $code = $error->{code};
        my $message = $error->{message};
        _failure("rpc::method")->throw({
            msg => qq/method $method failed with code=$code: $message/,
            payload => $error,
        });
    }
    return @$result;
}

1;

=head1 NAME

Odoo::Database::Manager - database management for Odoo

=head1 DESCRIPTION

Create and drop Odoo databases from your Perl scripts

=head1 METHODS

=head2 list_databases

Return list of Odoo databases.

    my @dbs = $dbman->list_databases;

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2016 Nick Booker
 
This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.
 
See http://dev.perl.org/licenses/ for more information.

=cut
