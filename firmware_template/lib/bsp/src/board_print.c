#include "board_print.h"

void board_print_serial_port_init(uint32_t pclk_rate_hz, uint32_t baud_rate)
{
    UART1->CR2.bit.TXENA = 0x0UL;
    __DSB();

    UART1->BRR.bit.OSR = 0x7UL;
    UART1->BRR.bit.PSC = pclk_rate_hz / 8UL / baud_rate;
    UART1->CR1.bit.DATALEN = 0x7UL;
    UART1->CR1.bit.PARITYENA = 0x0UL;
    UART1->CR1.bit.STOPLEN = 0x0UL;
    __DSB();

    UART1->CR2.bit.TXENA = 0x1UL;
    __DSB();

    for (uint32_t i = 0UL; i < 12UL; ++i) {
        UART1->NICR.reg[i] = 0x0UL;
    }

    return;
}

#if defined(__ARMCC_VERSION) && (__ARMCC_VERSION >= 6100100)
_ARMABI __attribute__((__nonnull__(2))) int fputc(int c, FILE *stream)
{
    if (stream == stdout) {
        while (!UART1->SR1.bit.TXRDY) {
            ;
        }
        UART1->TDR.reg = (uint32_t)c;
    } else {
        ;
    }

    return c;
}
#elif defined(__ICCARM__)
#endif
