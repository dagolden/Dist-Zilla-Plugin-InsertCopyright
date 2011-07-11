use 5.008001;
use strict;
use warnings;
use utf8;

package Dist::Zilla::Plugin::InsertCopyright;
# ABSTRACT: Insert copyright statement into source code files

use PPI;
use Moose;

with 'Dist::Zilla::Role::FileMunger';

# -- public methods

sub munge_file {
    my ($self, $file) = @_;

    return $self->_munge_perl($file) if $file->name    =~ /\.(?:pm|pl)$/i;
    return $self->_munge_perl($file) if $file->content =~ /^#!(?:.*)perl(?:$|\s)/;
    return;
}

# -- private methods

#
# $self->_munge_perl($file);
#
# munge content of perl $file: add stuff at a #COPYRIGHT comment
#

sub _munge_perl {
  my ($self, $file) = @_;

  my @copyright = (
    "This file is part of " . $self->zilla->name,
    '',
    split(/\n/, $self->zilla->license->notice),
    '',
  );

  my @copyright_comment = map { length($_) ? "# $_" : '#' } @copyright;

  my $content = $file->content;

  my $doc = PPI::Document->new(\$content)
    or croak( PPI::Document->errstr );

  my $comments = $doc->find('PPI::Token::Comment');

  if ( ref($comments) eq 'ARRAY' ) {
    foreach my $c ( @{ $comments } ) {
      if ( $c =~ /^(\s*)(\#\s+COPYRIGHT\b)$/xms ) {
        my ( $ws, $comment ) =  ( $1, $2 );
        my $code = join( "\n", map { "$ws $_" } @copyright_comment );
        $c->set_content("$code\n");
      }
    }
    $file->content( $doc->serialize );
  }
  else {
    my $fn = $file->name;
    $self->log( "File: $fn"
      . ' consider adding a "# COPYRIGHT" commment'
    );
  }
  return;
}

__PACKAGE__->meta->make_immutable;
no Moose;
1;

__END__

=encoding utf8

=for Pod::Coverage
munge_file

=head1 SYNOPSIS

In your F<dist.ini>:

    [InsertCopyright]

In your source files:

  # COPYRIGHT

=head1 DESCRIPTION

This module replaces a special C<# COPYRIGHT> comment in your Perl source
files with a short notice appropriate to your declared copyright.

It is inspired by excellent L<Dist::Zilla::Plugin::Prepender> but gives control
of the copyright notice placement instead of always adding it at the start of a
file.

I wrote this to let me put copyright statements at the end of my code to keep
line numbers of code consistent between the generated distribution and the
repository source.  See L<Dist::Zilla::Plugin::OurPkgVersion> for another
useful plugin that preserves line numbering.

=head1 ACKNOWLEDGMENTS

Code in this module is based heavily on Dist::Zilla::Plugin::OurPkgVersion
by Caleb Cushing and Dist::Zilla::Plugin::Prepender by Jérôme Quelin.  Thank
you to both of them for their work and for releasing it as open source for
reuse.

=head1 SEE ALSO

=over 4

=item *

L<Dist::Zilla> and L<dzil.org|http://dzil.org/>

=item *

L<Dist::Zilla::Plugin::OurPkgVersion>

=item *

L<Dist::Zilla::Plugin::Prepender>

=back

=cut

