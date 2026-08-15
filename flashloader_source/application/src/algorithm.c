#include "algorithm.h"

/* Import framework macros */
#include "framework.h"

uint32_t __mem_region_init(uint32_t address, uint32_t function)
{
    uint32_t ret = RESULT_OK;

    if ((address >= OCSRAM1_BASE_ADDR) &&
        (address <= OCSRAM1_END_ADDR)) {
        ;
    } else if ((address >= OCSRAM2_BASE_ADDR) &&
               (address <= OCSRAM2_END_ADDR)) {
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

    address = OCSRAM1_BASE_ADDR;
    for (uint32_t i = 0UL; i < OCSRAM1_SIZE / 4UL; i+= 4UL) {
        *(volatile uint32_t *)(address + i) = 0x0UL;
    }

    address = OCSRAM2_BASE_ADDR;
    for (uint32_t i = 0UL; i < OCSRAM2_SIZE / 4UL; i+= 4UL) {
        *(volatile uint32_t *)(address + i) = 0x0UL;
    }

    return ret;
}

uint32_t __mem_region_erase_sector(uint32_t address)
{
    uint32_t ret = RESULT_OK;

    if ((address >= OCSRAM1_BASE_ADDR) &&
        (address <= OCSRAM1_LAST_ERASE_UNIT_ADDR)) {
        for (uint32_t i = 0UL; i < ERASE_SIZE / 4UL; i+= 4UL) {
            *(volatile uint32_t *)(address + i) = 0x0UL;
        }
    } else if ((address >= OCSRAM2_BASE_ADDR) &&
               (address <= OCSRAM2_LAST_ERASE_UNIT_ADDR)) {
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

    if ((address >= OCSRAM1_BASE_ADDR) &&
        (address <= OCSRAM1_LAST_PROGRAM_UNIT_ADDR)) {
        for (uint32_t i = 0UL; i < size; ++i) {
            *(volatile uint8_t *)(address + i) = *(buffer + i);
        }
    } else if ((address >= OCSRAM2_BASE_ADDR) &&
               (address <= OCSRAM2_LAST_PROGRAM_UNIT_ADDR)) {
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
    /* Byte-by-byte verify */
    for (uint32_t i = 0UL; i < size; ++i) {
        if (*(uint8_t *)(address + i) != *(buffer + i)) {
            return address + i;
        }
    }

    return address + size;
}
