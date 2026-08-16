#ifndef STARTUP_RM32_H
#define STARTUP_RM32_H

#ifdef __cplusplus
extern "C" {
#endif /* __cplusplus */

#include "rm32.h"

typedef void (*IRQHandler_Type)(void);

#if defined (__ARMCC_VERSION) && (__ARMCC_VERSION >= 6100100)
extern uint32_t Image$$ARM_LIB_STACK$$ZI$$Limit;
extern uint32_t Image$$ARM_LIB_STACK$$ZI$$Base;
extern __NO_RETURN void __main(void);
#endif

#ifdef __cplusplus
}
#endif /* __cplusplus */

#endif /* STARTUP_RM32_H */
