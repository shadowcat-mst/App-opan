use Test::Mojo;
use Test::More;

use FindBin;
use File::chdir;
use File::Temp qw(tempdir);


my $tempdir = tempdir(CLEANUP => 1);

BEGIN { $ENV{OPAN_AUTH_TOKENS} = 'abc:bcd'; }

require "$FindBin::Bin/../script/opan";

{
  local $CWD = $tempdir;
  my $t = Test::Mojo->new;
  $t->app->start('init');

  $t->post_ok('/upload')->status_is('401');
  $t->post_ok('/upload', {Authorization => "Basic OmFiYw=="})->status_is('400');
  my $upload = {file => {content => 'HELLO', filename => 'world.tgz'}};
  $t->post_ok('/upload', {Authorization => "Basic OmFiYw=="}, form=> $upload)->status_is('200');
}

done_testing;
