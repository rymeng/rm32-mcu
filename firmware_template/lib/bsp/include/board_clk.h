#ifndef BOARD_CLK_H
#define BOARD_CLK_H

#ifdef __cplusplus
extern "C" {
#endif /* __cplusplus */

#include "rm32.h"

#define HSE_RATE_HZ    (50000000UL)

extern void board_clk_init(void);

#ifdef __cplusplus
}
#endif /* __cplusplus */

#endif /* BOARD_CLK_H */
