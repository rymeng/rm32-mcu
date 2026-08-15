#ifndef FRAMEWORK_H
#define FRAMEWORK_H

#ifdef __cplusplus
extern "C" {
#endif /* __cplusplus */

#include <stdint.h>
#include <string.h>

#define FRAMEWORK_VERSION                    (0x0101U)

#define FUNCTION_ERASE                       (1UL)
#define FUNCTION_PROGRAM                     (2UL)
#define FUNCTION_VERIFY                      (3UL)

#define RESULT_OK                            (0UL)
#define RESULT_ERROR                         (1UL)

#define UNKNOWN_DEVICE                       (0U)
#define ONCHIP_DEVICE                        (1U)
#define EXTERN_8BIT_DEVICE                   (2U)
#define EXTERN_16BIT_DEVICE                  (3U)
#define EXTERN_32BIT_DEVICE                  (4U)
#define EXTERN_SPI_DEVICE                    (5U)

#define SECTOR_DESCRIPTOR_MAX_NUMBER         (512U)
#define SECTOR_DESCRIPTOR_LIST_END_SYMBOL    {0xFFFFFFFFUL, 0xFFFFFFFFUL}

#define ALIGN(SIZE, BASE)                    (    \
    ((SIZE) + (BASE) - 1UL) & ~((BASE) - 1U))

struct mem_region_sector_descriptor
{
    uint32_t size;
    uint32_t offset;
};

struct mem_region_descriptor
{
    uint16_t framework_version;
    char name[128];
    uint16_t type;
    uint32_t address;
    uint32_t size;
    uint32_t program_chunk_size;
    uint32_t __reserved;
    uint8_t erased_byte;
    uint32_t program_timeout;
    uint32_t erase_timeout;
    struct mem_region_sector_descriptor
        sector_descriptor_list[SECTOR_DESCRIPTOR_MAX_NUMBER];
};

extern int Init(
    unsigned long address, unsigned long clock, unsigned long function);
extern int UnInit(unsigned long function);
extern int EraseChip(void);
extern int EraseSector(unsigned long address);
extern int ProgramPage(
    unsigned long address, unsigned long size, unsigned char *buffer);
extern unsigned long Verify(
    unsigned long address, unsigned long size, unsigned char *buffer);

#ifdef __cplusplus
}
#endif /* __cplusplus */

#endif /* FRAMEWORK_H */
