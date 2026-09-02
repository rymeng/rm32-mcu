#ifndef ALGORITHM_H
#define ALGORITHM_H

#ifdef __cplusplus
extern "C" {
#endif /* __cplusplus */

#include <stdint.h>
#include "rm32.h"

#define ERASE_SIZE                                (400UL)
#define PROGRAM_SIZE                              (4UL)
#define PROGRAM_CHUNK_SIZE                        (PROGRAM_SIZE * 128UL)

#define ERASE_TIMEOUT                             (5000UL)
#define PROGRAM_TIMEOUT                           (5000UL)

#define FLASH_MAIN_BANK_BASE_ADDR                 (0x00000000UL)
#define FLASH_MAIN_BANK_SIZE                      (0x00010000UL)

#define FLASH_MAIN_BANK_END_ADDR                  (    \
    FLASH_MAIN_BANK_BASE_ADDR +                        \
    FLASH_MAIN_BANK_SIZE -                             \
    0x1UL)
#define FLASH_MAIN_BANK_LAST_ERASE_UNIT_ADDR      (    \
    FLASH_MAIN_BANK_BASE_ADDR +                        \
    FLASH_MAIN_BANK_SIZE -                             \
    ERASE_SIZE)
#define FLASH_MAIN_BANK_LAST_PROGRAM_UNIT_ADDR    (    \
    FLASH_MAIN_BANK_BASE_ADDR +                        \
    FLASH_MAIN_BANK_SIZE -                             \
    PROGRAM_SIZE)

extern uint32_t __mem_region_init(uint32_t address, uint32_t function);
extern uint32_t __mem_region_deinit(uint32_t function);
extern uint32_t __mem_region_erase_bank(void);
extern uint32_t __mem_region_erase_sector(uint32_t address);
extern uint32_t __mem_region_program(
    uint32_t address, uint32_t size, uint8_t *buffer);
extern uint32_t __mem_region_verify(
    uint32_t address, uint32_t size, uint8_t *buffer);

#ifdef __cplusplus
}
#endif /* __cplusplus */

#endif /* ALGORITHM_H */
