
use DBIx::Connect;

=for comment

COPYRIGHT NOTICE:

This software, a Perl package named DBIx::Connect, 
is released under the same copyright terms as Perl itself.

=cut


my $config = shift or die  'MUST SUPPLY CONFIG';
warn "CONFIG: $config";

DBIx::Connect->to($config);

