#ifndef BOARD_H
#define BOARD_H

#ifdef __cplusplus
extern "C" {
#endif /* __cplusplus */

#include <stdio.h>
#include "rm32.h"

extern void board_uart_init(void);
extern void board_uart_deinit(void);

#ifdef __cplusplus
}
#endif /* __cplusplus */

#endif /* BOARD_H */
