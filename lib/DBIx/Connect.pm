=for comment

COPYRIGHT NOTICE:

This software, a Perl package named DBIx::Connect, 
is released under the same copyright terms as Perl itself.

=cut


package DBIx::Connect;

use AppConfig qw(:argcount);
use AppConfig::Std;
use Data::Dumper;
use DBI;
use Term::ReadKey;
use Carp;

require 5.005;
use strict;
use vars qw( @ISA $VERSION );

require Exporter;

@ISA = qw(Exporter);

$VERSION = sprintf '%s', q{$Revision: 1.13 $} =~ /\S+\s+(\S+)/ ;

# Ensures we always have a copy of the original @ARGV, whatever else
# may be done with it.  AppConfig::Args consumes its argument (@ARGV by default
# so it is unsafe to call more than once without having the previous copy for
# reference.
my @argv_orig = @ARGV;

# Preloaded methods go here.

# dont you just love the emacs Perl mode :)

sub data_hash {
    my (undef, $config_name) = @_;

    my $conn_file = '';
    my $stdin_flag = '<STDIN>';

    my $config = AppConfig::Std->new({ CASE=>1, 
    				CREATE => '.*', ERROR => sub {} });

    my $site   = "${config_name}_";

    $config->define("dbix_conn_file" => { ARGCOUNT => ARGCOUNT_ONE });

    $config->define("$site$_") for qw(user pass dsn);

    $config->define("${site}attr" => { ARGCOUNT => ARGCOUNT_HASH });

    # This is necessary because of the destructive nature of the args method.
    # If we want to call this function several times (e.g. for multiple data
    # sources in the same script or module) the command line overrides will
    # not be preserved after the first call to data_hash.
    #
    # We have to check the args here to see if the config file is passed there
    my @args = @argv_orig;
    $config->args(\@args);

    # Check for a command line arg first, then the environment variable
    $conn_file = $config->dbix_conn_file() || $ENV{DBIX_CONN};

    # Since all parameters may be passed on the command line, the file isn't
    # absolutely necessary.
    $config->file($conn_file) if $conn_file;

    # Check args again to ensure that command line parameters override config
    # file settings for consistent behavior.
    @args = @argv_orig;
    $config->args(\@args);

    # XXX Note that this approach to processings args will leave the original
    # @ARGV unchanged, so any other modules that process command line arguments
    # (such as Getopt::Std and Getopt::Long) need to be aware of this.

    my %site   = $config->varlist("^$site", 1);
    die "Couldn't find data for $config_name" if (scalar keys %site == 0);


    if ($site{pass} and ($site{pass} eq $stdin_flag)) {
	# Prevents input from being echoed to screen
	ReadMode 2; 
	print "Enter Password for $config_name (will not be echoed to screen): ";
	$site{pass} = <STDIN>;
	chomp($site{pass});

	print "\n";
	# Allows input to be directed to the screen again
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

    my $dbh;
    
    eval {
    	$dbh = DBI->connect(@connect_data);
    };

    # This will be triggered if the RaiseError attribute is set
    if ($@)
    {
        croak "Error on connection to $_[1]: $@";
    }


    # This will be triggered if the connection fails but RaiseError is not set
    defined $dbh or 
	croak "Failed to connect to $_[1]: $DBI::errstr";

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

 # Note that the DBIX_CONN environment variable is now optional -
 # a file can be specified using the command line parameter
 # -dbix_conn_file, e.g.:
 perl dbi_script.pl -dbix_conn_file /Users/metaperl/.appconfig-dbi

 # Any number of blocks may be specified in the config file - one block
 # per connection handle.  Any of the options specified in the file
 # can be overridden # by using the command line syntax shown below.
 
 # .appconfig-dbi
 [basic]
 user= postgres
 pass   = <STDIN>
 dsn= dbi:Pg:dbname=mydb
 attr RaiseError =  0
 attr PrintError =  0
 attr Taint      =  1

 [dev_db]
 user = root
 pass = w00t!
 dsn = dbi:mysql:database=mysqldb;host=localhost
 attr RaiseError = 1
 attr PrintError = 1

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
 perl dbi-script.pl basic -dbix_conn_file .appconfig-dbi \
 	-basic_user tim_bunce -basic_pass dbi_rocks
 perl dbi-script.pl basic -basic_attr "RaiseError=1" \
 	-basic_attr "Taint=0"

 # Note that all parameters can be specified on the command line, 
 # so the file is not strictly necessary.  As a practical matter, 
 # this is not a likely scenario, but it is supported.
 perl dbi-script.pl -basic_user basic -basic_pass "<STDIN>" \
 	-basic_dsn "dbi:Pg:dbname=basic" -basic_attr "AutoCommit=0"

DBIx::Connect will croak wth the DBI error if it cannot create a valid database handle.

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

=head1 PARAMETER PRECEDENCE 

In order to preserve maximum flexibility, DBIx::Connect does not do any
verification of completeness or correctness of connection parameters, deferring
these checks to the DBI itself.  This is because different drivers (and the 
DBI itself) can use environment variables (or nothing) to represent valid 
connection attributes.

DBIx::Connect maintains a strict priority for overlay of connection paramters:

  * Environment variables
  * Config file options
  * Command line parameters

This means that if the user attribute for a connection block is not specified
either by the file or command line, undef will be sent to the DBI, which will
instruct it to examine DBI_PASS, if defined, or send undef to the database,
which is common with certain databases.

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

=head1 KNOWN ISSUES

The args method of AppConfig::Args is called on a copy of @ARGV, not the
actual @ARGV.  This allows us to reparse command line arguments multiple times,
for multiple calls within the same script/module.  The only (possibly) negative
effect of this is that the elements of @ARGV will not be consumed as they
normally would be by the args method.  Be aware of this if you are parsing
command line options besides the DBIx::Connect ones.

=head1 SEE ALSO

L<DBIx::Password|DBIx::Password>
L<AppConfig|AppConfig>
L<AppConfig::Std|AppConfig::Std>
L<DBI|DBI>
L<Term::ReadKey|Term::ReadKey>

=cut
