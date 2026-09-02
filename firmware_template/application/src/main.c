#include "main.h"

int main()
{
    board_clk_init();
    board_cpu_systick_init(1000UL);
    board_print_serial_port_init(hclk_rate_hz, 115200UL);

    /* Intialize PA01 */
    GPIOA->ODR.bit.PIN1 = 0x0UL;
    GPIOA->GPMODER.bit.PIN1 = 0x1UL;

    while (1) {
        /* Toggle PA01 */
        GPIOA->BTOGR.reg = 0x1UL << 1UL;

        /* Print (UART TX PA00) */
        printf("RM32: Hello World!\r\n");

        board_mdelay(500UL);
    }
}
