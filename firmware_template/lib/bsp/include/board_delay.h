#ifndef BOARD_DELAY_H
#define BOARD_DELAY_H

#ifdef __cplusplus
extern "C" {
#endif /* __cplusplus */

#include "rm32.h"

extern void board_nop_delay(uint32_t count);
extern void board_udelay(uint32_t time_us);
extern void board_mdelay(uint32_t time_ms);

#ifdef __cplusplus
}
#endif /* __cplusplus */

#endif /* BOARD_DELAY_H */
