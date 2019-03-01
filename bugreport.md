*Expect*

When passing or receving 64 bit integer types (sint64, uint64) via ffi I expect integer width to be preserved, even when using a 32 bit perl/32 bit machine.

*Actual*

64 bit integers are being truncated when passed/received via FFI::Platypus

*Reproduce*

A minimal set of examples can be found here: https://github.com/calid/ffi-platypus-32-issue

For example consider these simple library routines:

_foo.c_
```C
#include <stdio.h>
#include <stdint.h>

uint64_t get_uint64(void)
{
    return 18446744073709551615ULL;
}

void print_uint64(uint64_t llu)
{
    printf("%llu\n", llu);
}
```

I can use these natively without issue as:

_usefoo.c_
```C
#include <stdio.h>
#include <stdint.h>


extern uint64_t get_uint64(void);
extern uint64_t print_uint64(uint64_t);


int main(void)
{
    printf("%llu\n", get_uint64());
    print_uint64(18446744073709551615ULL);
}
```

which produces the expected output:

```
$ ./usefoo
18446744073709551615
18446744073709551615
```

I then try to use these routines from Perl using FFI::Platypus:

_foo.pl_
```perl
use FFI::Platypus;
use Math::BigInt;

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
```

which produces the output:

```
$ perl foo.pl
uint64: 18446744073709551615

get_uint64:
4294967295

print_uint64:
4294967295
```

So at the pure perl level the 64 bit integer is as expected, but something is lost in translation during the ffi calls.

Tracing with gdb shows that all is well just before FFI::Platypus returns from the XS layer:

```
Breakpoint 1, ffi_pl_sub_call (cv=0x8478800) at include/ffi_platypus_call.h:976
976               XSRETURN_UV(result.uint64);
(gdb) p result.uint64
$1 = 18446744073709551615
(gdb)
```

Unfortunately this is where I start to get out of my depth.  Is the wrong XSRETURN being used?  Is that why result.uint64 is being truncated?

By way of comparison I get the expected results when using Python's ctypes:

_foo.py_
```python
from ctypes import *

libfoo = cdll.LoadLibrary('./libfoo.so')

get_uint64 = libfoo.get_uint64
get_uint64.restype = c_ulonglong

print(get_uint64())

print_uint64 = libfoo.print_uint64
print_uint64.argtypes = [c_ulonglong]

print_uint64(18446744073709551615)
```

Output:
```
$ python foo.py
18446744073709551615
18446744073709551615
```

I've included my complete system configuration below.  Apologies in advance if I've misunderstood things and this is user error.


```
Summary of my perl5 (revision 5 version 22 subversion 0) configuration:
   
  Platform:
    osname=linux, osvers=3.2.0-4-686-pae, archname=i686-linux
    uname='linux localhost 3.2.0-4-686-pae #1 smp debian 3.2.65-1 i686 gnulinux '
    config_args='-Dprefix=/home/vagrant/.plenv/versions/5.22.0 -de -Dversiononly -DDEBUGGING=-g -A'eval:scriptdir=/home/vagrant/.plenv/versions/5.22.0/bin''
    hint=recommended, useposix=true, d_sigaction=define
    useithreads=undef, usemultiplicity=undef
    use64bitint=undef, use64bitall=undef, uselongdouble=undef
    usemymalloc=n, bincompat5005=undef
  Compiler:
    cc='cc', ccflags ='-fwrapv -fno-strict-aliasing -pipe -fstack-protector -I/usr/local/include -D_LARGEFILE_SOURCE -D_FILE_OFFSET_BITS=64 -D_FORTIFY_SOURCE=2',
    optimize='-O2 -g',
    cppflags='-fwrapv -fno-strict-aliasing -pipe -fstack-protector -I/usr/local/include'
    ccversion='', gccversion='4.7.2', gccosandvers=''
    intsize=4, longsize=4, ptrsize=4, doublesize=8, byteorder=1234, doublekind=3
    d_longlong=define, longlongsize=8, d_longdbl=define, longdblsize=12, longdblkind=3
    ivtype='long', ivsize=4, nvtype='double', nvsize=8, Off_t='off_t', lseeksize=8
    alignbytes=4, prototype=define
  Linker and Libraries:
    ld='cc', ldflags =' -fstack-protector -L/usr/local/lib'
    libpth=/usr/local/lib /usr/lib/gcc/i486-linux-gnu/4.7/include-fixed /usr/include/i386-linux-gnu /usr/lib /lib/i386-linux-gnu /lib/../lib /usr/lib/i386-linux-gnu /usr/lib/../lib /lib
    libs=-lpthread -lnsl -ldl -lm -lcrypt -lutil -lc
    perllibs=-lpthread -lnsl -ldl -lm -lcrypt -lutil -lc
    libc=libc-2.13.so, so=so, useshrplib=false, libperl=libperl.a
    gnulibc_version='2.13'
  Dynamic Linking:
    dlsrc=dl_dlopen.xs, dlext=so, d_dlsymun=undef, ccdlflags='-Wl,-E'
    cccdlflags='-fPIC', lddlflags='-shared -O2 -g -L/usr/local/lib -fstack-protector'


Characteristics of this binary (from libperl): 
  Compile-time options: HAS_TIMES PERLIO_LAYERS PERL_DONT_CREATE_GVSV
                        PERL_HASH_FUNC_ONE_AT_A_TIME_HARD PERL_MALLOC_WRAP
                        PERL_NEW_COPY_ON_WRITE PERL_PRESERVE_IVUV
                        USE_LARGE_FILES USE_LOCALE USE_LOCALE_COLLATE
                        USE_LOCALE_CTYPE USE_LOCALE_NUMERIC USE_LOCALE_TIME
                        USE_PERLIO USE_PERL_ATOF
  Locally applied patches:
	Devel::PatchPerl 1.52
  Built under linux
  Compiled at Mar  1 2019 11:04:06
  %ENV:
    PERL5LIB="/home/vagrant/perl5/lib/perl5"
    PERL_LOCAL_LIB_ROOT="/home/vagrant/perl5"
    PERL_MB_OPT="--install_base "/home/vagrant/perl5""
    PERL_MM_OPT="INSTALL_BASE=/home/vagrant/perl5"
  @INC:
    /home/vagrant/perl5/lib/perl5/5.22.0/i686-linux
    /home/vagrant/perl5/lib/perl5/5.22.0
    /home/vagrant/perl5/lib/perl5/i686-linux
    /home/vagrant/perl5/lib/perl5
    /home/vagrant/.plenv/versions/5.22.0/lib/perl5/site_perl/5.22.0/i686-linux
    /home/vagrant/.plenv/versions/5.22.0/lib/perl5/site_perl/5.22.0
    /home/vagrant/.plenv/versions/5.22.0/lib/perl5/5.22.0/i686-linux
    /home/vagrant/.plenv/versions/5.22.0/lib/perl5/5.22.0
    .
```
