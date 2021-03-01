use Test::Mojo;
use Test::More;

use FindBin;
use File::chdir;
use Mojo::File qw/tempdir path/;

my $tempdir = tempdir(CLEANUP => 1);

# user1:pass
# user2:foobar
BEGIN { $ENV{OPAN_AUTH_TOKENS} = 'dXNlcjE6cGFzcw==:dXNlcjI6Zm9vYmFy'; }

require "$FindBin::Bin/../script/opan";

local $CWD = $tempdir;
my $t = Test::Mojo->new;
$t->app->start('init');

$t->post_ok('/upload')->status_is('401');
$t->post_ok('/upload', {Authorization => "Basic dXNlcjE6cGFzcw=="})->status_is('400');
my $upload = {dist => {content => 'HELLO', filename => 'world.tgz'}};
$t->post_ok('/upload', {Authorization => "Basic dXNlcjE6cGFzcw=="}, form => $upload)->status_is('200');
my $f=$tempdir->child('test')->spurt('TEST');
my $url=$t->ua->server->url->path('upload')->to_abs.'';

if (eval { require CPAN::Uploader; 1 }) {
  Mojo::IOLoop->subprocess(sub {
          my $sub = shift;
          return CPAN::Uploader->upload_file($f.'', {upload_uri => $url, user => 'user1', password => 'pass', debug => 1 });
      }, sub {
          my ($sub,$ret) = @_;
          ok(!$ret, 'no return is good return');
          Mojo::IOLoop->stop;
      });
  Mojo::IOLoop->start;
  ok( -s 'pans/custom/dists/M/MY/MY/test', 'file got uploaded');
}

done_testing
