#include "algorithm.h"

/* Import framework macros */
#include "framework.h"

uint32_t __mem_region_init(uint32_t address, uint32_t function)
{
    uint32_t ret = RESULT_OK;

    if ((address >= FLASH_MAIN_BANK_BASE_ADDR) &&
        (address <= FLASH_MAIN_BANK_END_ADDR)) {
        ;
    } else {
        ret = RESULT_ERROR;
    }

    (void)function;

    return ret;
}

uint32_t __mem_region_deinit(uint32_t function)
{
    uint32_t ret = RESULT_OK;

    (void)function;

    return ret;
}

uint32_t __mem_region_erase_bank(void)
{
    uint32_t ret = RESULT_OK;
    uint32_t address = 0UL;

    address = FLASH_MAIN_BANK_BASE_ADDR;
    for (uint32_t i = 0UL; i < FLASH_MAIN_BANK_SIZE / 4UL; i+= 4UL) {
        *(volatile uint32_t *)(address + i) = 0x0UL;
    }

    return ret;
}

uint32_t __mem_region_erase_sector(uint32_t address)
{
    uint32_t ret = RESULT_OK;

    if ((address >= FLASH_MAIN_BANK_BASE_ADDR) &&
        (address <= FLASH_MAIN_BANK_LAST_ERASE_UNIT_ADDR)) {
        for (uint32_t i = 0UL; i < ERASE_SIZE / 4UL; i+= 4UL) {
            *(volatile uint32_t *)(address + i) = 0x0UL;
        }
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
        for (uint32_t i = 0UL; i < size; ++i) {
            *(volatile uint8_t *)(address + i) = *(buffer + i);
        }
    } else {
        ret = RESULT_ERROR;
    }

    return ret;
}

uint32_t __mem_region_verify(uint32_t address, uint32_t size, uint8_t *buffer)
{
    for (uint32_t i = 0UL; i < size; ++i) {
        if (*(uint8_t *)(address + i) != *(buffer + i)) {
            return address + i;
        }
    }

    return address + size;
}
