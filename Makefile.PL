use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    'NAME'		=> 'DBIx::Connect',
    'VERSION_FROM'	=> 'lib/DBIx/Connect.pm', # finds $VERSION
    'PREREQ_PM'		=> {
      AppConfig::Std => 1.05,
      Term::ReadKey => 2.18,
	DBI => 1.19
	}, # e.g., Module::Name => 1.1
);
