package MyModel::Row::Bookmark;

use parent 'Teng::Row';
use Teng::Row::Declare::Relationship;

BEGIN {
    belongs_to 'user';
}

1;

__END__
