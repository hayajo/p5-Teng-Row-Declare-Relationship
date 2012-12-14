package MyModel::Row::User;

use parent 'Teng::Row';
use Teng::Row::Declare::Relationship;

BEGIN {
    has_many bookmark => { alias => 'bookmarks' };
    has_many bookmark => { alias => 'is_google', conditions => { url => { like => '%google%' } } };
    has_many bookmark => { alias => 'desc_bookmarks', attributes => { order_by => 'id DESC' } };
}

1;

__END__
