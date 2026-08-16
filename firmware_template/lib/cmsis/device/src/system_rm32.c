#include "board.h"
#include "system_rm32.h"

volatile uint32_t cpu_rate_hz = 0UL;
volatile uint32_t cpu_systick_rate_hz = 0UL;
volatile uint32_t hclk_rate_hz = 0UL;

extern __ALIAS("cpu_rate_hz") volatile uint32_t SystemCoreClock;

void recalc_global_clock_rates(void)
{
    cpu_rate_hz = HSI_RATE_HZ / 4UL;
    cpu_systick_rate_hz = HSI_RATE_HZ / 4UL;
    hclk_rate_hz = HSI_RATE_HZ / 4UL;

    return;
}

void __init(void)
{
    return;
}

extern __ALIAS("__init") void SystemInit(void);
extern __ALIAS("recalc_global_clock_rates") void SystemCoreClockUpdate(void);
