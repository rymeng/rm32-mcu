#include "main.h"

int main()
{
    board_clk_init();
    board_cpu_systick_init(1000UL);
    board_print_serial_port_init(hclk_rate_hz, 115200UL);

    while (1) {
        printf("RM32: Hello World!\r\n");
        board_mdelay(1000UL);
    }
}
