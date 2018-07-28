package Dist::Zilla::Plugin::TestMLIncluder;
our $VERSION = '0.14';

use Moose;
with 'Dist::Zilla::Role::FileGatherer';
with 'Dist::Zilla::Role::FileMunger';

use Dist::Zilla::File::InMemory;
use IO::All;

# Check that author has TestML enabled:
my $testml_root;
BEGIN {
  $testml_root = $ENV{TESTML_ROOT};

  if (not $ENV{PERL_ZILD_TEST_000_COMPILE_MODULES}) {
    die <<'...' if not defined $testml_root;
--------------------------------------------------------------------------------
TESTML_ROOT is not set in your environment.
This means TestML is not set up properly.

For more information, see:
https://github.com/testml-lang/testml/wiki/publishing-cpan-modules-with-testml-tests
--------------------------------------------------------------------------------
...

    -d $testml_root and -f "$testml_root/bin/testml"
      or die "Invalid TESTML_ROOT '$testml_root'";

    # Load the local TestML::Compiler:
    unshift @INC, "$testml_root/src/testml-compiler-perl5/lib";
    require TestML::Compiler;
  }
}

# Pull the local Perl5 TestML modules into inc/lib/:
sub gather_files {
  my ($self) = @_;

  for my $file (io("$testml_root/src/perl5/lib")->All_Files) {
    my $path = $file->pathname;
    $path =~ s{\Q$testml_root\E/src/perl5/}{};
    $self->add("inc/$path", $file->all);
  }

  # Also add the user-side-only TestML runner bin: 'testml-cpan':
  $self->add(
    "inc/bin/testml-cpan",
    io("$testml_root/src/perl5/pkg/bin/testml-cpan")->all,
  );
}

# Modify TestML .t files and the Makefile.PL (on the user side):
sub munge_file {
  my ($self, $file) = @_;

  # Change shebang lines for TestML .t files:
  if ($file->name =~ m{^t/.*\.t$}) {
    my $content = $file->content;
    return unless $content =~ /\A#!.*testml.*/;
    $content =~ s{\A#!.*testml.*}{#!inc/bin/testml-cpan};
    $file->content($content);

    # Then precompile the TestML .t files to Lingy/JSON:
    my $compiler = TestML::Compiler->new;
    my $json = $compiler->compile($content, $file->name);
    my $name = $file->name;
    $name =~ s/\.t$// or die;
    $name = "inc/$name.tml.json";

    $self->add($name => $json);
  }
  # Add a footer to Makefile.PL to use the user's perl in testml-cpan:
  elsif ($file->name eq 'Makefile.PL') {
    my $content = $file->content;
    $content .= <<'...';

use Config;
open IN, '<', 'inc/bin/testml-cpan' or die;
my @bin = <IN>;
close IN;

shift @bin;
unshift @bin, "#!$Config{perlpath}\n";
open OUT, '>', 'inc/bin/testml-cpan' or die;
print OUT @bin;
close OUT;

chmod 0755, 'inc/bin/testml-cpan';
...
    $file->content($content);
  }
}

sub add {
  my ($self, $name, $content) = @_;

  $self->add_file(
    Dist::Zilla::File::InMemory->new(
      name => $name,
      content => $content,
    )
  );
}

__PACKAGE__->meta->make_immutable;

no Moose;

1;
