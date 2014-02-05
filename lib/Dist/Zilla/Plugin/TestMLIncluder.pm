package Dist::Zilla::Plugin::TestMLIncluder;

use Moose;

# ABSTRACT: Ship your TestML version

extends 'Dist::Zilla::Plugin::ModuleIncluder';

has module => (
  isa => 'ArrayRef[Str]',
  traits => ['Array'],
  handles => {
    modules => 'elements',
  },
  default => sub {[qw(
    Pegex::Input
    Pegex::Grammar
    Pegex::Base
    Pegex::Parser
    Pegex::Tree
    Pegex::Receiver
    TestML::Util
    TestML::Compiler::Pegex::Grammar
    TestML::Compiler::Pegex::AST
    TestML::Compiler::Pegex
    TestML::Library::Debug
    TestML::Library::Standard
    TestML::Compiler
    TestML::Runtime::TAP
    TestML::Runtime
    TestML::Base
    TestML::Bridge
    TestML
  )]},
);

sub gather_files {
  my $self = shift;
  my $pegex = '../pegex-pm';
  my $testml = '../testml-pm';
  if (
    -d "$pegex/.git" and
    -d "$testml/.git"
  ) {
    eval "use lib '$pegex/lib', '$testml/lib'; 1" or die $@;
    $self->SUPER::gather_files(@_);
    return;
  }
  die "Pegex and TestML repos missing or not in right state";
}

__PACKAGE__->meta->make_immutable;

no Moose;

1;

__END__

=head1 SYNOPSIS

In dist.ini:

   [TestMLIncluder]

=head1 DESCRIPTION

This module includes the version of TestML on your system with your module dist.
