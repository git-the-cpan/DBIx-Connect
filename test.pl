# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl test.pl'

######################### We start with some black magic to print on failure.

# Change 1..1 below to 1..last_test_to_print .
# (It may become useful if the test is moved to ./t subdirectory.)

BEGIN { $tests = 4; $| = 1; print "1..$tests\n"; }
END {print "not ok 1\n" unless $loaded;}
use DBIx::Connect;
$loaded = 1;
print "ok 1\n";

######################### End of black magic.

# Insert your test code below (better if it prints "ok 13"
# (correspondingly "not ok 13") depending on the success of chunk 13
# of the test code):

# This should succeed.  Tests basic functionality (i.e. does it return a valid
# $dbh.
$test = 2;
$ENV{DBIX_CONN} = "testconf";
eval {
$dbh = DBIx::Connect->to("test1");
};

defined $dbh ? print "ok $test\n" : print "not ok $test\n";

# This should succeed.  Verifies we can use multiple configs in one file.
$test++;
eval {
$dbh = DBIx::Connect->to("test2");
};
defined $dbh ? print "ok $test\n" : print "not ok $test\n";

# This should fail.  "undefined" is not defined in our test config file.
$test++;
eval {
$dbh = DBIx::Connect->to("undefined");
};
not defined $dbh ? print "ok $test\n" : print "not ok $test\n";
