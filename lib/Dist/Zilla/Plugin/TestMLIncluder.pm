package Dist::Zilla::Plugin::TestMLIncluder;
use version;
use Moose;

use version;
use MooseX::Types::Perl 'VersionObject';

has module => (
  isa => 'ArrayRef[Str]',
  traits => ['Array'],
  handles => {
    modules => 'elements',
  },
  default => [
  ],
);

sub gather_files {
  my ($self) = shift;
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

=head1 NAME

Dist::Zilla::Plugin::TestMLIncluder - Ship your TestML version

=head1 SYNOPSIS

In dist.ini:

   [TestMLIncluder]

=head1 DESCRIPTION

This module includes the version of TestML on your system with your module dist.
