#include "framework.h"

/* Import functions for erasure or programming */
#include "algorithm.h"

/* Import functions for debug */
#ifdef DEBUG
#include "board.h"
#endif /* DEBUG */

__attribute__((section(".descriptor")))
const struct mem_region_descriptor FlashDevice = {
    .framework_version      = FRAMEWORK_VERSION,
    .name                   = "RM32",
    .type                   = ONCHIP_DEVICE,
    .address                = OCSRAM1_BASE_ADDR,
    .size                   = OCSRAM1_SIZE,
    .program_chunk_size     = PROGRAM_CHUNK_SIZE,
    .__reserved             = 0UL,
    .erased_byte            = 0xFFU,
    .program_timeout        = PROGRAM_TIMEOUT,
    .erase_timeout          = ERASE_TIMEOUT,
    .sector_descriptor_list = {
        { .size = ERASE_SIZE, .offset = 0x0UL },
        SECTOR_DESCRIPTOR_LIST_END_SYMBOL
    }
};

int Init(unsigned long address, unsigned long clock, unsigned long function)
{
#ifdef DEBUG
    board_uart_init();
#endif /* DEBUG */

#ifdef DEBUG
    printf("Enter function: Init().\r\n");
    printf("address = 0x%08lX.\r\n", address);
    printf("clock = 0x%08lX.\r\n", clock);
    printf("function = 0x%08lX.\r\n", function);
#endif /* DEBUG */

    /* Only for old version uVision debugger */
    (void)clock;

    uint32_t ret = __mem_region_init((uint32_t)address, (uint32_t)function);

#ifdef DEBUG
    printf("Exit function: Init(). ");
    printf("Return status = 0x%08X.\r\n", ret);
    printf("\r\n");
#endif /* DEBUG */

    return (int)ret;
}

int UnInit(unsigned long function)
{
#ifdef DEBUG
    printf("Enter function: UnInit().\r\n");
#endif /* DEBUG */

    uint32_t ret = __mem_region_deinit((uint32_t)function);

#ifdef DEBUG
    printf("Exit function: UnInit(). ");
    printf("Return status = 0x%08X.\r\n", ret);
    printf("\r\n");
#endif /* DEBUG */

#ifdef DEBUG
    board_uart_deinit();
#endif /* DEBUG */

    return (int)ret;
}

int EraseChip(void)
{
#ifdef DEBUG
    printf("Enter function: EraseChip().\r\n");
#endif /* DEBUG */

    uint32_t ret =  __mem_region_erase_bank();

#ifdef DEBUG
    printf("Exit function: EraseChip(). ");
    printf("Return status = 0x%08X.\r\n", ret);
    printf("\r\n");
#endif /* DEBUG */

    return (int)ret;
}

int EraseSector(unsigned long address)
{
#ifdef DEBUG
    printf("Enter function: EraseSector().\r\n");
    printf("address = 0x%08lX.\r\n", address);
#endif /* DEBUG */

    uint32_t ret = __mem_region_erase_sector((uint32_t)address);

#ifdef DEBUG
    printf("Exit function: EraseSector(). ");
    printf("Return status = 0x%08X.\r\n", ret);
    printf("\r\n");
#endif /* DEBUG */

    return (int)ret;
}

int ProgramPage(unsigned long address, unsigned long size,
                unsigned char *buffer)
{
#ifdef DEBUG
    printf("Enter function: ProgramPage().\r\n");
    printf("address = 0x%08lX.\r\n", address);
    printf("size = 0x%08lX.\r\n", size);
    printf("buffer = 0x%08X.\r\n", (uint32_t)buffer);
#endif /* DEBUG */

    uint32_t ret = __mem_region_program((uint32_t)address, (uint32_t)size,
                                        (uint8_t *)buffer);

#ifdef DEBUG
    printf("Exit function: ProgramPage(). ");
    printf("Return status = 0x%08X.\r\n", ret);
    printf("\r\n");
#endif /* DEBUG */

    return (int)ret;
}

unsigned long Verify(unsigned long address, unsigned long size,
                     unsigned char *buffer)
{
#ifdef DEBUG
    printf("Enter function: Verify().\r\n");
    printf("address = 0x%08lX.\r\n", address);
    printf("size = 0x%08lX.\r\n", size);
    printf("buffer = 0x%08X.\r\n", (uint32_t)buffer);
#endif /* DEBUG */

    uint32_t ret = __mem_region_verify((uint32_t)address, (uint32_t)size,
                                       (uint8_t *)buffer);

#ifdef DEBUG
    printf("Exit function: Verify(). ");
    printf("Return address = 0x%08X.\r\n", ret);
    printf("\r\n");
#endif /* DEBUG */

    return (unsigned long)ret;
}
