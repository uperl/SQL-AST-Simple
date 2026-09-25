package SQL::AST::Simple;

use 5.042;
use warnings;
use FFI::Platypus 2.00;

my $ffi = FFI::Platypus->new(
    api => 2,
    lang => 'Rust',
);
$ffi->bundle;
