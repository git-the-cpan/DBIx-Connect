package DBIx::Connect;

use AppConfig qw(:argcount);
use AppConfig::Std;
use Data::Dumper;
use DBI;
use Term::ReadKey;

require 5.005_62;
use strict;
use warnings;

require Exporter;

our @ISA = qw(Exporter);

# Items to export into callers namespace by default. Note: do not export
# names by default without a very good reason. Use EXPORT_OK instead.
# Do not simply export all your public functions/methods/constants.

# This allows declarationuse DBIx::Connect ':all';
# If you do not need this, moving things directly into @EXPORT or @EXPORT_OK
# will save memory.
our %EXPORT_TAGS = ( 'all' => [ qw(
				   
				   ) ] );

our @EXPORT_OK = ( @{ $EXPORT_TAGS{'all'} } );

our @EXPORT = qw(
		 
		 );

our $VERSION = sprintf '%s', q{$Revision: 1.10 $} =~ /\S+\s+(\S+)/ ;

# Ensures we always have a copy of the original @ARGV, whatever else
# may be done with it.
			       our @argv_orig = @ARGV;

# Preloaded methods go here.

# dont you just love the emacs Perl mode :)

sub data_hash {
    my (undef, $config_name) = @_;

    my $conn_file = '';
    my $stdin_flag = '<STDIN>';

    local $^W = 0;

#    my $config = AppConfig::Std->new( { CASE=>1 } );
    my $config = AppConfig::Std->new({ CASE=>1, CREATE => '.*' });

    my $site   = "${config_name}_";

    $config->define("dbix_conn_file" => { ARGCOUNT => ARGCOUNT_ONE });

    $config->define("$site$_") for qw(user pass dsn);

    $config->define("${site}attr" => { ARGCOUNT => ARGCOUNT_HASH });
    # print Dumper($config);

    # Necessary because the args method consumes the array with shift - since
    # we want the command line to override anything else we need to copy it
    # out so the original @ARGV will be available after we check for a 
    # file specified on the command line

    my @args = @argv_orig;
    $config->args(\@args);

    $conn_file = $config->dbix_conn_file() || $ENV{DBIX_CONN};
    # print "Conn file: $conn_file\n";

    $config->file($conn_file) if $conn_file;

    @args = @argv_orig;
    $config->args(\@args);

    my %site   = $config->varlist("^$site", 1);
    die "Couldn't find data for $site" if (scalar keys %site == 0);

#    if ($site{pass} eq $stdin_flag) {
    if ($site{pass} and ($site{pass} eq $stdin_flag)) {
	ReadMode 2; 
	print "Enter Password for $config_name (will not be echoed to screen): ";
	$site{pass} = <STDIN>;
	chomp($site{pass});

	print "\n";
	ReadMode 0;
    }

    %site;
}

sub data_array {
    my %site = data_hash(@_);

    ($site{dsn}, $site{user}, $site{pass}, $site{attr});
}

sub to {

    my @connect_data = data_array(@_); 

    my $dbh = DBI->connect(@connect_data);

    defined $dbh or 
	die "error on connection to $_[1]: $DBI::errstr";

    $dbh;

}

1;
__END__
# Below is stub documentation for your module. You better edit it!

=head1 NAME

DBIx::Connect - DBI, DBIx::AnyDBD, and Alzabo database connection (info) via AppConfig 

=head1 SYNOPSIS

 # .cshrc
 setenv APPCONFIG /Users/metaperl/.appconfig
 setenv DBIX_CONN "${APPCONFIG}-dbi"

 # .appconfig-dbi
 [basic]
    user= postgres
 pass   = <STDIN>
    dsn= dbi:Pg:dbname=mydb
 attr RaiseError =  0
 attr PrintError =  0
 attr Taint      =  1

 # DBIx::AnyDBD usage:
    my @connect_data = DBIx::Connect->data_array('dev_db');
my $dbh          = DBIx::AnyDBD->connect(@connect_data, "MyClass");

 # Alzabo usage
my %connect_data = DBIx::Connect->data_hash('dev_db');

 # pure DBI usage
use DBIx::Connect;

my $dbh    = DBIx::Connect->to('dev_db');

 # over-ride .appconfig-dbi from the command line
 # not recommended for passwords as C<ps> will reveal the password
 perl dbi-script.pl basic -basic_user tim_bunce -basic_pass dbi_rocks
 perl dbi-script.pl basic -basic_attr "RaiseError=1" -basic_attr "Taint=0"

=head1 DESCRIPTION

This module facilitates 
L<DBI|DBI> -style, 
L<DBIx::AnyDBD|DBIx::AnyDBD> -style, or 
L<Alzabo|Alzabo> -style
database connections for sites and applications
which make use of L<AppConfig|AppConfig> and related modules
to configure their applications via files
and/or command-line arguments. 

It provides three methods, C<to>, C<data_array>, and C<data_hash>
which return a DBI database handle and an array of DBI connection info, 
respectively.

Each of the 4 DBI connection parameters (username, password, dsn, attr)
can be defined via any of the methods supported by AppConfig, meaning
via a configuration file, or simple-style command-line arguments.
AppConfig also provides support for both simple and Getopt::Long style,
but Getopt::Long is overkill for a module this simple.

=head1 RELATED MODULES / MOTIVATION FOR THIS ONE

The only module similar to this on CPAN is DBIx::Password. Here are some
points of comparison/contrast.

=over 4

=item * DBI configuration info location

DBIx::Password uses an autogenerated Perl module for its connection 
data storage. DBIx::Connect uses a Windows INI-style AppConfig file
for its connection information.

The advantage of a config file is that each programmer can have his own
config file whereas it could prove tedious for each programmer to
have his own personal copy of a Perl configuration module.

Not to mention the fact that if each Perl module in your large application
went this route, you would be stuck with n-fold Perl configuration modules
as opposed to one centralized AppConfig file. For example, my module
SQL::Catalog, used to use on-the-fly Config modules and Net::FTP::Common
did as well. 

=item * Routes to configurability and password security

DBIx::Password DBI connection options (username, password, dsn, attr) are 
not over-ridable or settable at the command line. This means passwords must 
be stored in the configuration file and that efforts must be taken to
make a module readable by a program not readable by a human.

In contrast, DBIx::Connect can add configuration information upon
invocation via the command-line or via the C<read-from-STDIN-flag>,
C<<STDIN>>, which will overwrite or set arguments which
could have been in the configuration file, which means your passwords need not
be stored on disk at all.

=item * Support for indirect connection

vis-a-vis connection,
DBIx::Password has one method, C<connect> which returns a C<$dbh>. While
DBIx::Connect also supplies such a method (named C<to>), it also supplies a 
C<data_hash> and C<data_array> method which can be passed to
any other DBI connection scheme, the must ubiquitous of which are Alzabo and
DBIx::AnyDBD, which handles connections for you after you give it the
connection data.

I submitted a patch to the author of DBIx::Password to support such
functionality, but it was rejected on the grounds that DBIx::Password is
designed to secure connection data, not make it available in any form
or fashion.

=back

=head2 My CPAN module set will be AppConfig-dependant

From now on, any module of mine which requires configuration info will
use L<AppConfig|AppConfig> to get it. I thought about using XML but a
discussion on Perlmonks.Org and one on p5ee@perl.org both made strong
arguments in favor of AppConfig.

=head2 EXPORT

None by default.

=head1 AUTHOR

T. M. Brannon <tbone@cpan.org> and 
Martin Jackson <mhjacks - NOSPAN - at - swbell - dot - net>

=head1 SEE ALSO

L<DBIx::Password|DBIx::Password>
L<AppConfig|AppConfig>
L<AppConfig::Std|AppConfig::Std>
L<DBI|DBI>
L<Term::ReadKey|Term::ReadKey>

=cut
