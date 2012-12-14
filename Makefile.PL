use inc::Module::Install;
use Module::Install::Repository;
use Module::Install::ReadmePodFromPod;
name 'Teng-Row-Declare-Relationship';
all_from 'lib/Teng/Row/Declare/Relationship.pm';
readme_pod_from 'lib/Teng/Row/Declare/Relationship.pm';

requires 'Teng' => '0.16';

tests 't/*.t';
author_tests 'xt';

recommends 'DBIx::QueryLog';

test_requires 'Test::More';
test_requires 'DBD::SQLite' => '1.30';

auto_set_repository;
auto_include;
WriteAll;
