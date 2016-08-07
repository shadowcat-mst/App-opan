use strictures 2;
use Test::More;
use File::chdir;
use File::Path qw(mkpath rmtree);
use Mojo::Util qw(spurt);
use Capture::Tiny qw(capture_merged);

my $app = require "./script/opan";

my $orig_dir = $CWD;

{
  rmtree my $wdir = 'xt/scratch';
  mkpath $wdir;
  local $CWD = $wdir;
  $app->start('init');
  $app->start(add => $orig_dir.'/t/fix/M-1.tar.gz');
  $app->start('merge');
  diag(capture_merged { $app->start(cpanm => -L => 'cpanm' => -n => 'M') });
  spurt("requires 'M';\n", 'cpanfile');
  diag(capture_merged { $app->start(carton => 'install') });

  ok(-d 'cpanm');
  ok(-d 'local');
  ok(-f 'cpanfile.snapshot');
}

done_testing;
