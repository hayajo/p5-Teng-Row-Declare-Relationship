package Teng::Row::Declare::Relationship;
use strict;
use warnings;
our $VERSION = '0.01';

use parent qw(Exporter);
our @EXPORT = qw(
    has_one
    has_many
    blongs_to
);
use Carp ();

use constant DEFAULT_PRIMARY_KEY       => 'id';
use constant DEFAULT_FORIGN_KEY_SUFFIX => '_id';
use constant MODE_HAS_ONE              => 0;
use constant MODE_HAS_MANY             => 1;
use constant MODE_BELONGS_TO           => 2;

our $FETCH;

sub has_one($;$);
sub has_many($;$);
sub belongs_to($;$);

sub import {
    my $class = shift;
    my $opts  = {@_};

    my $pkg = caller;
    return unless $pkg->isa('Teng::Row');

    $opts->{fetch} ||= $FETCH || sub {
        my $row = shift;
        my ( $name, $conds, $attrs, $has_one, $alias, @args ) = @_;
        ($has_one)
            ? $row->handle->single( $name => $conds, $attrs )
            : [ $row->handle->search( $name => $conds, $attrs )->all ];
    };
    Carp::croak "Invalid value for fetch: " . $opts->{fetch}
        if ( ref $opts->{fetch} ne 'CODE' );

    my $_has = sub {
        my $mode = shift || MODE_HAS_ONE;    # default has_one
        return sub ($;$) {
            my $name  = shift;
            my $relation_opts  = shift || {};

            my $alias        = delete $relation_opts->{alias} || $name;
            my $primary_key  = delete $relation_opts->{primary_key} || DEFAULT_PRIMARY_KEY;
            my $foreign_key  = delete $relation_opts->{foreign_key};
            my $search_conds = delete $relation_opts->{conditions} || [];
            $search_conds = [ %$search_conds ] if ( ref $search_conds eq 'HASH' );
            my $search_attrs = delete $relation_opts->{attributes} || {};
            $search_attrs->{order_by} ||= $primary_key;

            my $code = ( $mode == MODE_BELONGS_TO )
                ? sub {
                    my $self = shift;
                    $foreign_key ||= $name . DEFAULT_FORIGN_KEY_SUFFIX;
                    return $self->_fetch( $name, [ $primary_key => $self->$foreign_key, @$search_conds ], $search_attrs, 1, $alias, @_ );
                }
                : sub {
                    my $self = shift;
                    $foreign_key ||= lc( $self->{table_name} ) . DEFAULT_FORIGN_KEY_SUFFIX;
                    return $self->_fetch( $name, [ $foreign_key => $self->$primary_key, @$search_conds ], $search_attrs, ( $mode == MODE_HAS_ONE ) ? 1 : 0, $alias, @_ );
                };

            {
                no strict 'refs';
                *{"$pkg\::$alias"} = $code;
            }
        };
    };

    {
        no strict 'refs';
        *{"$pkg\::has_one"}     = $_has->(MODE_HAS_ONE);
        *{"$pkg\::has_many"}    = $_has->(MODE_HAS_MANY);
        *{"$pkg\::belongs_to"}  = $_has->(MODE_BELONGS_TO);
        *{"$pkg\::_fetch"}      = $opts->{fetch};
    }
}

1;
__END__

=head1 NAME

Teng::Row::Declare::Relationship - DSL for declaring relationships

=head1 SYNOPSIS

  package MyModel::Row::User;
  use parent 'Teng::Row';
  use Teng::Row::Declare::Relationship;
  BEGIN {
      has_many bookmark => { alias => 'bookmarks' };
  }
  1;

in your script.

  my $user = $teng->single('user', { id => 1 });
  my $bookmarks = $user->bookmarks;
  # => SELECT "id", "user_id", "url" FROM "bookmark" WHERE ("user_id" = '1')

=head1 DESCRIPTION

Teng::Row::Declare::Relationship is set of macro-like class methods for declaring method to set up a simple relationships.

=head1 METHODS

=head2 C<has_one>

Specifies a one-to-one relationship with another table.

  has_one 'section';

=head2 C<has_many>

Specifies a one-to-many relationship with another table.

  has_many 'bookmark' => { alias => 'bookmarks' };

=head2 C<belongs_to>

Specifies a one-to-one relationship with another table.

  belongs_to 'user';

=head1 OPTIONS

  has_many bookmark => { primary_key => 'name', foreign_key => 'person_name', alias => 'fetch_bookmarks' }

=head2 C<alias>

set alias.

=head2 C<primary_key>

set primary key used for the relationship. By default this is 'id'.

=head2 C<foreign_key>

set foreign key used for the relationship.

=over 4

=item has_*

By default this is guessed to be the name of this table in lower-case and  "_id" suffixed.

=item belongs_to

By default this is guessed to be the name of the relationship with an "_id" suffix.

=back

=head2 C<conditions>

set the conditions that the relationship objects must meet in order to be included.

  has_many post => { alias => 'posts', conditions => { published => 1 } };

  my $published_posts = $blog->posts;
  # => SELECT "id", "user_id", "title", "published" FROM "post" WHERE ("user_id" = ?) AND ("published" = '1')

see L<Teng search/single methods|https://metacpan.org/module/Teng#METHODS>.

=head2 C<attributes>

set attributes for search.

  has_many bookmark => { alias => 'bookmarks', attributes => { order_by => 'url DESC' } };

  my $sorted_bookmarks = $user->bookmarks;
  # => SELECT "id", "user_id", "url" FROM "bookmark" WHERE ("user_id" = ?) ORDER BY url DESC

see L<Teng search method|https://metacpan.org/module/Teng#METHODS>.

=head1 EXAMPLES

=head2 caching

  package MyModel;
  use parent 'Teng::Row';
  use Teng::Row::Declare::Relationship;
  $Teng::Row::Declare::Relationship::FETCH = sub {
      my $self = shift;
      my ( $name, $conds, $attrs, $has_one, $alias, @args ) = @_;
      my $key = "__cached_$alias";
      $self->{$key} = undef if ( @args && $args[0] ); # refetch
      $self->{$key} ||= ($has_one)
          ? $self->handle->single( $name => $conds, $attrs )
          : [ $self->handle->search( $name => $conds, $attrs )->all ];
  };
  1;

=head1 AUTHOR

hayajo E<lt>hayajo@cpan.orgE<gt>

=head1 SEE ALSO

L<Teng>, L<DBIx::Skinny>, L<http://perl-users.jp/articles/advent-calendar/2009/dbix-skinny/21.html>

=head1 LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
