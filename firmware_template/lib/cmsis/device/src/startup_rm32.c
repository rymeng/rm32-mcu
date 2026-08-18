#include "startup_rm32.h"

__WEAK __NO_RETURN void reset_handler(void)
{
    /* Call __init() */
    __init();

    /* Enter user application */
    __PROGRAM_START();

    /* If the __main() function returns unexpectedly */
    while (1) {
        ;
    }
}

__WEAK __NO_RETURN void non_maskable_irq_handler(void)
{
    while (1) {
        ;
    }
}

__WEAK __NO_RETURN void hard_fault_irq_handler(void)
{
    while (1) {
        ;
    }
}

__WEAK void supervisor_call_irq_handler(void)
{
    ;
}

__WEAK void pend_supervisor_irq_handler(void)
{
    return;
}

__WEAK void systick_irq_handler(void)
{
    return;
}

__WEAK __NO_RETURN void default_irq_handler(void)
{
    while (1) {
        ;
    }
}

__VECTOR_TABLE_ATTRIBUTE const IRQHandler_Type __VECTOR_TABLE[16] = {
    (IRQHandler_Type)(&__INITIAL_SP),
    reset_handler,
    non_maskable_irq_handler,
    hard_fault_irq_handler,
    (IRQHandler_Type)0UL,
    (IRQHandler_Type)0UL,
    (IRQHandler_Type)0UL,
    (IRQHandler_Type)0UL,
    (IRQHandler_Type)0UL,
    (IRQHandler_Type)0UL,
    (IRQHandler_Type)0UL,
    supervisor_call_irq_handler,
    (IRQHandler_Type)0UL,
    (IRQHandler_Type)0UL,
    pend_supervisor_irq_handler,
    systick_irq_handler
};
