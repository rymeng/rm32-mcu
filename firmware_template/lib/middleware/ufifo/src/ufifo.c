#include "ufifo.h"

void ufifo_init(struct ufifo *fifo)
{
    fifo->header = fifo->buffer;
    fifo->tail = fifo->buffer;
    fifo->count = 0UL;

    return;
}

void ufifo_enqueue(struct ufifo *fifo, uint32_t *buffer, uint32_t count)
{
    for (uint32_t i = 0UL; i < count; ++i) {
        if (ufifo_is_full(fifo)) {
            ;
        } else {
            // Enqueue
            *(fifo->header) = *(buffer + i);

            // Refresh header pointer
            if (fifo->header == fifo->buffer + UFIFO_BUFFER_SIZE - 1UL) {
                fifo->header = fifo->buffer;
            } else {
                ++(fifo->header);
            }

            // Refresh count
            ++fifo->count;
        }
    }

    return;
}

void ufifo_dequeue(struct ufifo *fifo, uint32_t *buffer, uint32_t count)
{
    for (uint32_t i = 0UL; i < count; ++i) {
        if (ufifo_is_empty(fifo)) {
            *(buffer + i) = 0UL;
        } else {
            // Dequeue
            *(buffer + i) = *(fifo->tail);

            // Refresh tail pointer
            if (fifo->tail == fifo->buffer + UFIFO_BUFFER_SIZE - 1UL) {
                fifo->tail = fifo->buffer;
            } else {
                ++(fifo->tail);
            }

            // Refresh count
            --fifo->count;
        }
    }

    return;
}
