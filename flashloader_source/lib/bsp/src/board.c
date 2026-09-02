#include "board.h"

void board_uart_init(void)
{
    RCC->AHBENR1.bit.GPIOBENA = 0x1UL;
    RCC->AHBENR2.bit.UART1ENA = 0x1UL;
    __DSB();

    RCC->AHBRSTR1.bit.GPIOBRST = 0x1UL;
    RCC->AHBRSTR2.bit.UART1RST = 0x1UL;
    __DSB();

    RCC->AHBRSTR1.bit.GPIOBRST = 0x0UL;
    RCC->AHBRSTR2.bit.UART1RST = 0x0UL;
    __DSB();

    GPIOB->AFR2.bit.PIN14 = 0x1UL;
    __DSB();

    UART1->CR2.bit.TXENA = 0x0UL;
    __DSB();

    UART1->BRR.bit.OSR = 0x7UL;
    UART1->BRR.bit.PSC = 0x32UL;
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
    RCC->AHBRSTR1.bit.GPIOBRST = 0x1UL;
    RCC->AHBRSTR2.bit.UART1RST = 0x1UL;
    __DSB();

    RCC->AHBRSTR1.bit.GPIOBRST = 0x0UL;
    RCC->AHBRSTR2.bit.UART1RST = 0x0UL;
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
