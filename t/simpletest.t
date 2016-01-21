use Test::Most;
use Try::Tiny;
use Safe::Isa;
use Carp;

use_ok 'Odoo::Database::Manager';


sub assuming_dbman_connection {
    my %params = @_;
    my %conninfo = %{$params{conninfo} // {}};
    my $test = $params{test};
    my $dbman = Odoo::Database::Manager->new(%conninfo);
    SKIP: {
        my $connectfailed;
        try {
            $dbman->list_databases;
        }
        catch {
            if ($_->$_isa('failure::odoo::rpc::http::connection')) {
                $connectfailed = $_;
            }
        };
        carp "Failed to connect to Odoo server, tests will be skipped" if $connectfailed;
        skip $connectfailed->msg, 1 if $connectfailed;
        subtest 'connected to server' => sub {
            $test->($dbman);
        };
    }
}


assuming_dbman_connection(test => sub {
    my ($dbman) = @_;
    my @initial_dbs;
    lives_ok { @initial_dbs = $dbman->list_databases } 'get list of databases';
    explain '\@initial_dbs = ', \@initial_dbs;
});

done_testing;
