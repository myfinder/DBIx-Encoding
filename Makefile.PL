use inc::Module::Install;
name 'DBIx-Encoding';
all_from 'lib/DBIx/Encoding.pm';

# requires '';

tests 't/*.t';
author_tests 'xt';

build_requires 'Test::More';
use_test_base;
auto_include;
WriteAll;
