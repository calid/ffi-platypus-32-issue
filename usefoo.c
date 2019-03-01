#include <stdio.h>
#include <stdint.h>

extern uint64_t get_uint64(void);
extern uint64_t print_uint64(uint64_t);

int main(void)
{
    printf("%llu\n", get_uint64());
    print_uint64(18446744073709551615ULL);
}
