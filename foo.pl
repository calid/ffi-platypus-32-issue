use strict;
use warnings;
use feature 'say';
use FFI::Platypus;
use Math::BigInt;
use Devel::Peek;

my $llu = Math::BigInt->new('18446744073709551615');
say "uint64: $llu\n";

my $ffi = FFI::Platypus->new( lib => './libfoo.so' );
$ffi->attach( 'get_uint64' => [] => 'uint64' );
$ffi->attach( 'print_uint64' => ['uint64'] => 'void' );

say "get_uint64: ";
say get_uint64();

print "\n";

say "print_uint64: ";
print_uint64($llu);
