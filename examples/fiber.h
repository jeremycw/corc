#ifndef FIBER_H
#define FIBER_H

#include <ev.h>

#define FIBER_TIMEOUT 1

#define spawn_fiber(coroutine, param) \
  coroutine##_ctx_t* ctx = malloc(sizeof(coroutine##_ctx_t)); \
  ctx->state = 0; \
  ctx->arg = param; \
  ev_init(&ctx->timer, coroutine##_timeout); \
  ctx->timer.data = ctx; \
  ev_io_init(&ctx->io, coroutine##_callback, -1, EV_READ); \
  await_t await = call_##coroutine(&ctx->state, ctx->arg); \
  set_timeout() \
  schedule_fiber(await, &ctx->io, (void*)ctx, coroutine##_callback);

#define set_timeout() \
  if (ctx->state == -1) { \
    await.fd = -1; \
    ev_timer_stop(fiber_scheduler, &ctx->timer); \
  } else if (await.timeout > 0.f) { \
    ctx->timer.repeat = await.timeout; \
    ev_timer_again(fiber_scheduler, &ctx->timer); \
  } else if (await.timeout < 0.f) { \
    ev_timer_stop(fiber_scheduler, &ctx->timer); \
  } 

#define declare_fiber(name, type) \
  typedef struct { \
    int state; \
    type arg; \
    ev_timer timer; \
    ev_io io; \
  } name##_ctx_t; \
  void name##_callback(EV_P_ ev_io *w, int revents) { \
    name##_ctx_t* ctx = (name##_ctx_t*)w->data; \
    await_t await = call_##name(&ctx->state, ctx->arg); \
    set_timeout() \
    schedule_fiber(await, &ctx->io, (void*)ctx, name##_callback); \
  } \
  void name##_timeout(EV_P_ ev_timer *w, int revents) { \
    name##_ctx_t* ctx = (name##_ctx_t*)w->data; \
    fibererror = FIBER_TIMEOUT; \
    await_t await = call_##name(&ctx->state, ctx->arg); \
    set_timeout() \
    schedule_fiber(await, &ctx->io, (void*)ctx, name##_callback); \
  }

#define fiber_scheduler_init() fiber_scheduler = EV_DEFAULT

#define fiber_scheduler_run() ev_run(fiber_scheduler, 0)

typedef struct {
  int fd;
  int type;
  float timeout;
} await_t;

void schedule_fiber(await_t await, ev_io* io, void* ctx, void(*cb)(struct ev_loop*, ev_io*, int));
await_t fiber_await(int fd, int type, float timeout);

extern struct ev_loop* fiber_scheduler;
extern int fibererror;

#endif

#ifdef FIBER_IMPL

int fibererror = 0;

struct ev_loop* fiber_scheduler;

void schedule_fiber(await_t await, ev_io* io, void* ctx, void(*cb)(struct ev_loop*, ev_io*, int)) {
  ev_io_stop(fiber_scheduler, io);
  if (await.fd != -1) {
    io->data = ctx;
    ev_io_init(io, cb, await.fd, await.type);
    ev_io_start(fiber_scheduler, io);
  }
}

await_t fiber_await(int fd, int type, float timeout) {
  return (await_t) {
    .fd = fd,
    .type = type,
    .timeout = timeout
  };
}

#endif
