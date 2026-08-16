#ifndef BOARD_SYSTICK_H
#define BOARD_SYSTICK_H

#ifdef __cplusplus
extern "C" {
#endif /* __cplusplus */

#include "rm32.h"

extern void board_cpu_systick_init(uint32_t underflow_rate_hz);

#ifdef __cplusplus
}
#endif /* __cplusplus */

#endif /* BOARD_SYSTICK_H */
