#include "board_systick.h"

void board_cpu_systick_init(uint32_t underflow_rate_hz)
{
    SysTick->CTRL |= SysTick_CTRL_CLKSOURCE_Msk;
    __DSB();

    recalc_global_clock_rates();

    SysTick->CTRL &= ~SysTick_CTRL_ENABLE_Msk & ~SysTick_CTRL_TICKINT_Msk;
    __DSB();

    SysTick->LOAD =
        (cpu_systick_rate_hz / underflow_rate_hz) - 1UL;
    SysTick->VAL = 0x0UL;
    __DSB();

    SysTick->CTRL |= SysTick_CTRL_ENABLE_Msk;
    __DSB();

    return;
}
