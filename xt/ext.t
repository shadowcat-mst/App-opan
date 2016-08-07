use strictures 2;
use Test::More;
use File::chdir;
use File::Path qw(mkpath rmtree);
use Mojo::Util qw(spurt);

my $app = require "./script/opan";

my $orig_dir = $CWD;

{
  rmtree my $wdir = 'xt/scratch';
  mkpath $wdir;
  local $CWD = $wdir;
  $app->start('init');
  $app->start(add => $orig_dir.'/t/fix/M-1.tar.gz');
  $app->start('merge');
  $app->start(cpanm => -L => 'cpanm' => -n => 'M');
  spurt("requires 'M';\n", 'cpanfile');
  $app->start(carton => 'install');

  ok(-d 'cpanm');
  ok(-d 'local');
  ok(-f 'cpanfile.snapshot');
}

done_testing;
