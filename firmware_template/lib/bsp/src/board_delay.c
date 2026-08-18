#include "board_delay.h"

void board_nop_delay(uint32_t loops)
{
    volatile uint32_t remaining = loops;

    while (remaining--) {
        __NOP();
        __NOP();
        __NOP();
        __NOP();
    }

    return;
}

void board_udelay(uint32_t time_us)
{
    uint32_t reload_cycles = SysTick->LOAD;

    if (time_us > 28UL) {
        time_us -= 28UL;
    }

    uint64_t cumulative_limit =
        (uint64_t)cpu_systick_rate_hz * (uint64_t)time_us / 1000000ULL;

    uint32_t cycle_last = 0x0UL;
    uint32_t cycle_now = 0x0UL;
    uint64_t running_cumulative = 0UL;

    cycle_last = SysTick->VAL;
    while (running_cumulative < cumulative_limit) {
        cycle_now = SysTick->VAL;
        if (cycle_now < cycle_last) {
            running_cumulative += cycle_last - cycle_now;
        } else if (cycle_now >= cycle_last) {
            running_cumulative += reload_cycles - cycle_now + cycle_last + 1UL;
        }
        cycle_last = cycle_now;
    }

    return;
}

void board_mdelay(uint32_t time_ms)
{
    uint32_t reload_cycles = SysTick->LOAD;
    uint64_t cumulative_limit =
        (uint64_t)cpu_systick_rate_hz * (uint64_t)time_ms / 1000ULL;

    uint32_t cycle_last = 0x0UL;
    uint32_t cycle_now = 0x0UL;
    uint64_t running_cumulative = 0UL;

    cycle_last = SysTick->VAL;
    while (running_cumulative < cumulative_limit) {
        cycle_now = SysTick->VAL;
        if (cycle_now < cycle_last) {
            running_cumulative +=
                (uint64_t)(cycle_last - cycle_now);
        } else if (cycle_now > cycle_last) {
            running_cumulative +=
                (uint64_t)(reload_cycles - cycle_now + cycle_last + 1ULL);
        }
        cycle_last = cycle_now;
    }

    return;
}
