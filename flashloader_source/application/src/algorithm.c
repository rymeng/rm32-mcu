#include "algorithm.h"

/* Import framework macros */
#include "framework.h"

uint32_t __mem_region_init(uint32_t address, uint32_t function)
{
    uint32_t ret = RESULT_OK;

    if ((address >= FLASH_MAIN_BANK_BASE_ADDR) &&
        (address <= FLASH_MAIN_BANK_END_ADDR)) {
        FMC->KEYR.reg = 0x5555AAAAUL;
        __DSB();
        FMC->KEYR.reg = 0x3333CCCCUL;
        __DSB();
    } else {
        ret = RESULT_ERROR;
    }

    (void)function;

    return ret;
}

uint32_t __mem_region_deinit(uint32_t function)
{
    uint32_t ret = RESULT_OK;

    FMC->CR1.bit.LOCK = 1UL;
    __DSB();

    (void)function;

    return ret;
}

uint32_t __mem_region_erase_bank(void)
{
    uint32_t ret = RESULT_OK;

    FMC->ICR.reg = 0xFFFFFFFFUL;
    __DSB();

    FMC->CR1.bit.BEREN = 1UL;
    __DSB();

    FMC->CR2.reg = FMC_CR2_START_Msk;
    while (FMC->SR.bit.BUSY) {
        ;
    }

    if (FMC->ISR.bit.DONE) {
        ret = RESULT_OK;
        FMC->ICR.reg = FMC_ICR_DONE_Msk;
        __DSB();
    } else {
        ret = RESULT_ERROR;
    }

    FMC->CR1.bit.BEREN = 0UL;
    __DSB();

    return ret;
}

uint32_t __mem_region_erase_sector(uint32_t address)
{
    uint32_t ret = RESULT_OK;

    if ((address >= FLASH_MAIN_BANK_BASE_ADDR) &&
        (address <= FLASH_MAIN_BANK_LAST_ERASE_UNIT_ADDR)) {
        FMC->ICR.reg = 0xFFFFFFFFUL;
        __DSB();

        FMC->CR1.bit.SEREN = 1UL;
        FMC->AR.reg = address;
        __DSB();

        FMC->CR2.reg = FMC_CR2_START_Msk;
        while (FMC->SR.bit.BUSY) {
            ;
        }

        if (FMC->ISR.bit.DONE) {
            ret = RESULT_OK;
            FMC->ICR.reg = FMC_ICR_DONE_Msk;
            __DSB();
        } else {
            ret = RESULT_ERROR;
        }

        FMC->CR1.bit.SEREN = 0UL;
        __DSB();
    } else {
        ret = RESULT_ERROR;
    }

    return ret;
}

uint32_t __mem_region_program(uint32_t address, uint32_t size, uint8_t *buffer)
{
    uint32_t ret = RESULT_OK;

    if ((address >= FLASH_MAIN_BANK_BASE_ADDR) &&
        (address <= FLASH_MAIN_BANK_LAST_PROGRAM_UNIT_ADDR)) {
        FMC->ICR.reg = 0xFFFFFFFFUL;
        __DSB();

        uint32_t aligned_size = ALIGN(size, PROGRAM_SIZE);
        if (aligned_size != size) {
            memset(buffer + size, 0xFF, aligned_size - size);
            size = aligned_size;
        }

        FMC->CR1.bit.PGEN = 1UL;
        __DSB();

        for (uint32_t i = 0UL; i < size; i += PROGRAM_SIZE) {
            *(volatile uint64_t *)(address + i) = *(uint64_t *)(buffer + i);
            __DSB();
            while (FMC->SR.bit.BUSY) {
                ;
            }
        }

        if (FMC->ISR.bit.DONE) {
            FMC->ICR.reg = FMC_ICR_DONE_Msk;
            __DSB();
            if (FMC->ISR.bit.PGERR || FMC->ISR.bit.PGNALN) {
                ret = RESULT_ERROR;
            } else {
                ret = RESULT_OK;
            }
        } else {
            ret = RESULT_ERROR;
        }

        FMC->CR1.bit.PGEN = 0UL;
        __DSB();
    } else {
        ret = RESULT_ERROR;
    }

    return ret;
}

uint32_t __mem_region_verify(uint32_t address, uint32_t size, uint8_t *buffer)
{
    for (uint32_t i = 0UL; i < size; ++i) {
        if (*(volatile uint8_t *)(address + i) != *(buffer + i)) {
            return address + i;
        }
    }

    return address + size;
}
