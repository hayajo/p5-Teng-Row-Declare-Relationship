# NAME

Teng::Row::Declare::Relationship - DSL for declaring relationships

# SYNOPSIS

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

# DESCRIPTION

Teng::Row::Declare::Relationship is set of macro-like class methods for declaring method to set up a simple relationships.

# METHODS

## `has_one`

Specifies a one-to-one relationship with another table.

    has_one 'section';

## `has_many`

Specifies a one-to-many relationship with another table.

    has_many 'bookmark' => { alias => 'bookmarks' };

## `belongs_to`

Specifies a one-to-one relationship with another table.

    belongs_to 'user';

# OPTIONS

    has_many bookmark => { primary_key => 'name', foreign_key => 'person_name', alias => 'fetch_bookmarks' }

## `alias`

set alias.

## `primary_key`

set primary key used for the relationship. By default this is 'id'.

## `foreign_key`

set foreign key used for the relationship.

- has\_\*

    By default this is guessed to be the name of this table in lower-case and  "\_id" suffixed.

- belongs\_to

    By default this is guessed to be the name of the relationship with an "\_id" suffix.

## `conditions`

set the conditions that the relationship objects must meet in order to be included.

    has_many post => { alias => 'posts', conditions => { published => 1 } };

    my $published_posts = $blog->posts;
    # => SELECT "id", "user_id", "title", "published" FROM "post" WHERE ("user_id" = ?) AND ("published" = '1')

see [Teng search/single methods](https://metacpan.org/module/Teng\#METHODS).

## `attributes`

set attributes for search.

    has_many bookmark => { alias => 'bookmarks', attributes => { order_by => 'url DESC' } };

    my $sorted_bookmarks = $user->bookmarks;
    # => SELECT "id", "user_id", "url" FROM "bookmark" WHERE ("user_id" = ?) ORDER BY url DESC

see [Teng search method](https://metacpan.org/module/Teng\#METHODS).

# EXAMPLES

## caching

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

# AUTHOR

hayajo <hayajo@cpan.org>

# SEE ALSO

[Teng](http://search.cpan.org/perldoc?Teng), [DBIx::Skinny](http://search.cpan.org/perldoc?DBIx::Skinny), [http://perl-users.jp/articles/advent-calendar/2009/dbix-skinny/21.html](http://perl-users.jp/articles/advent-calendar/2009/dbix-skinny/21.html)

# LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.
