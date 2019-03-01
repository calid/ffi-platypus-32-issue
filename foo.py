from ctypes import *

libfoo = cdll.LoadLibrary('./libfoo.so')

get_uint64 = libfoo.get_uint64
get_uint64.restype = c_ulonglong

print(get_uint64())

print_uint64 = libfoo.print_uint64
print_uint64.argtypes = [c_ulonglong]

print_uint64(18446744073709551615)
