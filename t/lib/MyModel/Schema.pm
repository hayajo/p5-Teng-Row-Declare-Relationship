package MyModel::Schema;
use Teng::Schema::Declare;

table {
    name 'user';
    pk 'id';
    columns qw{ id name };
};

table {
    name 'bookmark';
    pk 'id';
    columns qw{ id user_id url };
};

sub create_table {
    my ($class, $model) = @_;
    Carp::croak "$model is not Teng object" unless (eval { $model->isa('Teng') } );
    my ( undef, $driver ) = DBI->parse_dsn( $model->connect_info->[0] );
    my $sqls = _get_data_section();
    for my $key (sort keys %$sqls) {
        $model->do( $sqls->{$key} );
    }
}

sub _get_data_section {
    my $content = do { local $/; <DATA> };
    my @data = split /^@@\s+(.+?)\s*\r?\n/m, $content;
    shift @data; # trailing whitespaces
    my $all = {};
    while (@data) {
        my ($name, $content) = splice @data, 0, 2;
        $all->{$name} = $content;
    }
    return $all;
}

1;

__DATA__

@@ 00-user
CREATE TABLE user (
    id    INTEGER PRIMARY KEY AUTOINCREMENT,
    name  TEXT NOT NULL
)

@@ 01-bookmark
CREATE TABLE bookmark (
    id      INTEGER PRIMARY KEY AUTOINCREMENT,
    user_id INTEGER NOT NULL,
    url     TEXT NOT NULL
)

@@ 02-index_user_id
CREATE INDEX user_id ON bookmark(user_id)
