#ifndef ALGORITHM_H
#define ALGORITHM_H

#ifdef __cplusplus
extern "C" {
#endif /* __cplusplus */

#include <stdint.h>
#include "rm32.h"

#define ERASE_SIZE                        (4UL)
#define PROGRAM_SIZE                      (4UL)
#define PROGRAM_CHUNK_SIZE                (PROGRAM_SIZE * 128UL)

#define ERASE_TIMEOUT                     (5000UL)
#define PROGRAM_TIMEOUT                   (5000UL)

#define OCSRAM1_BASE_ADDR                 (0x00000000UL)
#define OCSRAM1_SIZE                      (0x00002000UL)

#define OCSRAM2_BASE_ADDR                 (0x20000000UL)
#define OCSRAM2_SIZE                      (0x00002000UL)

#define OCSRAM1_END_ADDR                  (    \
    OCSRAM1_BASE_ADDR +                        \
    OCSRAM1_SIZE -                             \
    0x1UL)
#define OCSRAM1_LAST_ERASE_UNIT_ADDR      (    \
    OCSRAM1_BASE_ADDR +                        \
    OCSRAM1_SIZE -                             \
    ERASE_SIZE)
#define OCSRAM1_LAST_PROGRAM_UNIT_ADDR    (    \
    OCSRAM1_BASE_ADDR +                        \
    OCSRAM1_SIZE -                             \
    PROGRAM_SIZE)

#define OCSRAM2_END_ADDR                  (    \
    OCSRAM2_BASE_ADDR +                        \
    OCSRAM2_SIZE -                             \
    0x1UL)
#define OCSRAM2_LAST_ERASE_UNIT_ADDR      (    \
    OCSRAM2_BASE_ADDR +                        \
    OCSRAM2_SIZE -                             \
    ERASE_SIZE)
#define OCSRAM2_LAST_PROGRAM_UNIT_ADDR    (    \
    OCSRAM2_BASE_ADDR +                        \
    OCSRAM2_SIZE -                             \
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
