#!/usr/bin/perl -w

=for comment

COPYRIGHT NOTICE:

This software, a Perl package named DBIx::Connect, 
is released under the same copyright terms as Perl itself.

=cut


use DBIx::Connect;
use Data::Dumper;

#BEGIN { $ENV{DBIX_CONN} = "/home/mjackson/test_conf"; };

foreach my $db ("slash", "template1", "foo")
{
	print "data_hash for $db\n";
	print Dumper(DBIx::Connect->data_hash($db));

	print "data_array for $db\n";
	print Dumper(DBIx::Connect->data_array($db));

	$dbh = DBIx::Connect->to($db);
	print "Connection to $db successful\n" if $dbh->ping;
	$dbh->disconnect;
}

exit;
