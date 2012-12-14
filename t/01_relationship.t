use strict;
use Test::More tests => 1;

use lib './t/lib';
use MyModel;

my $guard = eval "
require DBIx::QueryLog;
\$DBIx::QueryLog::OUTPUT = *STDOUT;
return DBIx::QueryLog->guard();
";

my $model = MyModel->new( {
    connect_info => [ 'dbi:SQLite::memory:' ],
} );
$model->schema->create_table($model);

my $row_user = $model->insert(user => {
    name => 'taro yamada',
} );

my @urls = <DATA>;
for my $url (@urls) {
    $model->insert(bookmark => {
        user_id => $row_user->id,
        url     => $url,
    } );
}

subtest 'relationship' => sub {
    no strict 'refs';
    no warnings 'redefine';
    my $orig_execute = *{"Teng::_execute"}{CODE};
    my $sql;
    local *{"Teng::_execute"} = sub {
        ( $sql = $_[1] ) =~ s/[\r\n]/ /mg;
        $orig_execute->(@_);
    };

    my $bookmarks;
    subtest 'has_many' => sub {
        $bookmarks = $row_user->bookmarks;
        is scalar(@$bookmarks), scalar @urls;
        is $sql, 'SELECT "id", "user_id", "url" FROM "bookmark" WHERE ("user_id" = ?) ORDER BY id';
    };

    my $idx = rand( scalar(@urls) );
    is $bookmarks->[$idx]->url, $urls[$idx];

    subtest 'belongs_to' => sub {
        is $bookmarks->[$idx]->user->name, $row_user->name;
        is $sql, 'SELECT "id", "name" FROM "user" WHERE ("id" = ?) ORDER BY id LIMIT 1';
    };

    subtest 'add conditions' => sub {
        my $bookmarks = $row_user->is_google;
        is scalar(@$bookmarks), scalar( grep /google/, @urls );
        is $sql, 'SELECT "id", "user_id", "url" FROM "bookmark" WHERE ("user_id" = ?) AND ("url" LIKE ?) ORDER BY id';
    };

    subtest 'add attributes' => sub {
        my $bookmarks = $row_user->desc_bookmarks;
        is $bookmarks->[0]->url, [ reverse @urls ]->[0];
        is $sql, 'SELECT "id", "user_id", "url" FROM "bookmark" WHERE ("user_id" = ?) ORDER BY id DESC';
    };
};

$row_user->bookmarks;

__DATA__
twitter.com
www.amazon.com
www.facebook.com
www.google.co.jp
www.google.com
www.google.net
www.yahoo.com
