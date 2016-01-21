use Test::Most;
use Try::Tiny;
use Safe::Isa;

use_ok 'Odoo::Database::Manager';


sub assuming_dbman_connection {
    my %params = @_;
    my %conninfo = %{$params{conninfo} // {}};
    my $test = $params{test};
    my $num_to_skip = $params{skip} // 1;
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
        skip $connectfailed->msg, $num_to_skip if $connectfailed;
        $test->($dbman);
    }
}


assuming_dbman_connection(skip => 1, test => sub {
    my ($dbman) = @_;
    subtest 'connected to server' => sub {
        my $initial_dbs;
        lives_ok { $initial_dbs = $dbman->list_databases } 'get list of databases';
        explain '$initial_dbs = ', $initial_dbs;
    };
});

done_testing;
