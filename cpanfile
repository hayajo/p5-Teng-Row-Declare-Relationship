# vim: ft=perl :
requires 'perl', '5.010001';

# requires 'Some::Module', 'VERSION';
requires 'Teng', '>= 0.17';

on test => sub {
    requires 'Test::More', '0.88';
    requires 'DBD::SQLite', '>= 1.30';
    requires 'DBIx::QueryLog';
};
