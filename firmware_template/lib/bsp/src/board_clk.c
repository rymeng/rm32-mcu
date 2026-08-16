#include "board_clk.h"

void board_clk_init(void)
{
    /* Call recalc_global_clock_rates() */
    recalc_global_clock_rates();

    return;
}
