
use DBIx::Connect;

my $config = shift or die  'MUST SUPPLY CONFIG';
warn "CONFIG: $config";

DBIx::Connect->to($config);

