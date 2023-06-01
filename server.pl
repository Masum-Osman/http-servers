use strict;
use warnings;
use DBI;
use JSON;
use Plack::Request;
use Plack::Response;

# MySQL connection settings
my $db_host = 'localhost';
my $db_user = 'username';
my $db_password = 'password';
my $db_name = 'dbname';

# Create Plack application
my $app = sub {
    my $req = Plack::Request->new(shift);

    if ($req->path eq '/users' && $req->method eq 'GET') {
        my $users = get_users();
        my $response = Plack::Response->new(200);
        $response->content_type('application/json');
        $response->body(encode_json($users));
        return $response->finalize;
    }

    return [404, ['Content-Type' => 'text/plain'], ['Not Found']];
};

# Execute the SELECT query and fetch users from the database
sub get_users {
    my $dbh = DBI->connect("dbi:mysql:dbname=$db_name;host=$db_host", $db_user, $db_password)
        or die "Could not connect to database: $DBI::errstr";

    my $query = 'SELECT * FROM users';
    my $stmt = $dbh->prepare($query);
    $stmt->execute();

    my @users;
    while (my $row = $stmt->fetchrow_hashref) {
        push @users, $row;
    }

    $dbh->disconnect;

    return \@users;
}

# Start the server
my $port = 8080;
my $server = Plack::Runner->new;
$server->parse_options('--port', $port);
$server->run($app);
