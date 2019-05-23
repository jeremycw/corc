#ifndef FIBER_H
#define FIBER_H

#include <ev.h>

#define spawn_fiber(coroutine, param) \
  coroutine##_ctx_t* ctx = malloc(sizeof(coroutine##_ctx_t)); \
  ctx->state = 0; \
  ctx->arg = param; \
  await_t await = call_##coroutine(&ctx->state, ctx->arg); \
  schedule_fiber(await, NULL, (void*)ctx, coroutine##_callback);

#define declare_fiber(name, type) \
  typedef struct { \
    int state; \
    type arg; \
  } name##_ctx_t; \
  void name##_callback(EV_P_ ev_io *w, int revents) { \
    name##_ctx_t* ctx = (name##_ctx_t*)w->data; \
    await_t await = call_##name(&ctx->state, ctx->arg); \
    if (ctx->state == -1) await.fd = -1; \
    schedule_fiber(await, w, (void*)ctx, name##_callback); \
  }

#define fiber_scheduler_init() fiber_scheduler = EV_DEFAULT

#define fiber_scheduler_run() ev_run(fiber_scheduler, 0)

typedef struct {
  int fd;
  int type;
} await_t;

void schedule_fiber(await_t await, ev_io *io, void* ctx, void(*cb)(struct ev_loop*, ev_io*, int));
await_t fiber_await(int fd, int type);

extern struct ev_loop* fiber_scheduler;

#endif

#ifdef FIBER_IMPL

struct ev_loop* fiber_scheduler;

void schedule_fiber(await_t await, ev_io *io, void* ctx, void(*cb)(struct ev_loop*, ev_io*, int)) {
  if (io) {
    ev_io_stop(fiber_scheduler, io);
  } else {
    io = malloc(sizeof(ev_io));
  }
  if (await.fd == -1) {
    ev_io_stop(fiber_scheduler, io);
    free(io);
  } else {
    io->data = ctx;
    ev_io_init(io, cb, await.fd, await.type);
    ev_io_start(fiber_scheduler, io);
  }
}

await_t fiber_await(int fd, int type) {
  await_t await;
  await.fd = fd;
  await.type = type;
  return await;
}

#endif
