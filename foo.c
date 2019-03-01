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
