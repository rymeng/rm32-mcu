#include "board.h"

void board_uart_init(void)
{
    UART1->CR2.bit.TXENA = 0x0UL;
    __DSB();

    UART1->BRR.bit.OSR = 0x7UL;
    UART1->BRR.bit.PSC = 0x28BUL;
    UART1->CR1.bit.DATALEN = 0x7UL;
    UART1->CR1.bit.PARITYENA = 0x0UL;
    UART1->CR1.bit.STOPLEN = 0x1UL;
    __DSB();

    UART1->CR2.bit.TXENA = 0x1UL;
    __DSB();

    for (uint32_t i = 0UL; i < 12UL; ++i) {
        UART1->NICR.reg[i] = 0x0UL;
    }

    return;
}

void board_uart_deinit(void)
{
    UART1->CR2.bit.TXENA = 0x0UL;
    __DSB();

    return;
}

_ARMABI __attribute__((__nonnull__(2))) int fputc(int c, FILE *stream)
{
    if (stream == stdout) {
        while (!UART1->SR1.bit.TXRDY) {
            ;
        }
        UART1->TDR.reg = c;
    }

    return c;
}
