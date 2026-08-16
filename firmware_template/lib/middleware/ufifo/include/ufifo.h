#ifndef __UFIFO_H__
#define __UFIFO_H__

#ifdef __cplusplus
extern "C" {
#endif

#include <stdbool.h>
#include <stdint.h>

#define UFIFO_BUFFER_SIZE    (1024UL)

struct ufifo {
  uint32_t buffer[UFIFO_BUFFER_SIZE];
  uint32_t *header;
  uint32_t *tail;
  uint32_t count;
};

static inline bool ufifo_is_empty(struct ufifo *fifo)
{
    return (fifo->count == 0UL) ? true : false;
}

static inline bool ufifo_is_full(struct ufifo *fifo)
{
    return (fifo->count == UFIFO_BUFFER_SIZE) ? true : false;
}

static inline uint32_t ufifo_get_counter(struct ufifo *fifo)
{
    return fifo->count;
}

extern void ufifo_init(struct ufifo *fifo);
extern void ufifo_enqueue(struct ufifo *fifo, uint32_t *buffer, uint32_t count);
extern void ufifo_dequeue(struct ufifo *fifo, uint32_t *buffer, uint32_t count);

#ifdef __cplusplus
}
#endif /* __cplusplus */

#endif /* UFIFO_H */
