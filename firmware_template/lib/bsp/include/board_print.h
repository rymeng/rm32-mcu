#ifndef BOARD_PRINT_H
#define BOARD_PRINT_H

#ifdef __cplusplus
extern "C" {
#endif /* __cplusplus */

#include <stdio.h>
#include "rm32.h"

extern void board_print_serial_port_init(
    uint32_t pclk_rate_hz, uint32_t baud_rate);

#ifdef __cplusplus
}
#endif /* __cplusplus */

#endif /* BOARD_PRINT_H */
