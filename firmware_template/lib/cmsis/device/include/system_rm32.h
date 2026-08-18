#ifndef SYSTEM_RM32_H
#define SYSTEM_RM32_H

#ifdef __cplusplus
extern "C" {
#endif /* __cplusplus */

#include <stdint.h>
#include "rm32.h"

#define HSI_RATE_HZ    (50000000UL)

extern volatile uint32_t cpu_rate_hz;
extern volatile uint32_t cpu_systick_rate_hz;
extern volatile uint32_t hclk_rate_hz;

/* Alias for variable cpu_rate_hz */
extern volatile uint32_t SystemCoreClock;

extern void __init(void);
extern void recalc_global_clock_rates(void);

/* Alias for function __init() */
extern void SystemInit(void);
/* Alias for function recalc_global_clock_rates() */
extern void SystemCoreClockUpdate(void);

#ifdef __cplusplus
}
#endif /* __cplusplus */

#endif /* SYSTEM_RM32_H */
