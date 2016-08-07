use strictures 2;
use Test::More;
use File::chdir;
use File::Temp qw(tempdir);
use Capture::Tiny qw(capture);
use IPC::System::Simple ();
use Mojo::Util qw(slurp);
use Import::Into;

my $test_cwd = $CWD;

delete @ENV{grep /^OPAN_/, keys %ENV};

my $tempdir = tempdir(CLEANUP => 1);

sub entries_for {
  my ($pan) = @_;
  App::opan::entries_from_packages_file($tempdir."/pans/${pan}/index");
}

sub App::opan::gmtime { 'TIME GOES HERE' }

subs->import::into('App::opan', 'gmtime');

my $app = require "./script/opan";

sub run {
  local $CWD = $tempdir;
  local $ENV{OPAN_MIRROR} = '/fakepan/';
  my @args = @_;
  my ($stdout, $stderr) = capture { $app->start(@args) };
  diag("STDERR for ".join(' ', @args)." was\n".$stderr) if $stderr;
  #is($stderr, '', 'No stderr output running '.join(' ', @args));
  return $stdout;
}

$app->ua->server->app(my $fakepan = Mojolicious->new);

$fakepan->log->level('fatal');

$fakepan->routes->tap(sub {
  $_[0]->get('/fakepan/modules/02packages.details.txt.gz' => sub {
    $_[0]->render(data =>
      scalar IPC::System::Simple::capture(
        gzip => '-c', $test_cwd.'/t/fix/upstream.fragment'
      )
    );
  });
  foreach my $f (map "AAAAAAAAA-1.0${_}.tar.gz", qw(0 1)) {
    $_[0]->get("/fakepan/authors/id/M/MS/MSCHWERN/${f}" => sub {
      $_[0]->reply->asset(
        Mojo::Asset::File->new(
          path => $test_cwd.'/t/fix/'.$f
        )
      );
    });
  }
});

run('init');

is(
  slurp($tempdir.'/pans/upstream/index'),
  slurp('t/fix/upstream.fragment'),
  'init fetch ok'
);

foreach my $pan (qw(pinset custom)) {

  is(
    slurp($tempdir."/pans/${pan}/index"),
    slurp('t/fix/empty.index'),
    "index for ${pan} initialized ok"
  );
}

foreach my $pan (qw(nopin combined)) {
  is_deeply(
    entries_for('upstream'), entries_for($pan),
    "index for ${pan} initialized ok"
  );
}

my $aaa = slurp('t/fix/AAAAAAAAA-1.00.tar.gz');

foreach my $pan (qw(upstream nopin combined)) {
  ok(
    run(get => "/${pan}/authors/id/M/MS/MSCHWERN/AAAAAAAAA-1.00.tar.gz")
    eq $aaa,
    "Served upstream tarball via ${pan}"
  );
}

# 0 for release, 1 for debugging, not allowed to barf

if (1) {
  warn "Tempdir is $tempdir; hit enter to finish and cleanup\n";
  <STDIN>;
}

done_testing;
