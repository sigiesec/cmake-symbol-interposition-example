#include "static.h"

#include <stdio.h>

#include <dlfcn.h>

using var_t = int;

static var_t *global_registry;

#if 0
extern "C" {
int __attribute__((visibility("hidden"))) RegisterInternal(const char *name) {
#endif
int Register(const char *name) {
  static auto local_registry = new var_t();
  global_registry = local_registry;

  Dl_info dlInfo;

  printf("caller: %s\n", name);

  if (!dladdr(reinterpret_cast<void *>(Register), &dlInfo)) {
    printf("dladdr failed\n");
  } else {
    printf("fname: %s\n", dlInfo.dli_fname);
    printf("sname: %s\n", dlInfo.dli_sname);
  }

  printf("&local_registry: %p\n", &local_registry);
  printf("local_registry: %p\n", local_registry);

  printf("&global_registry: %p\n", &global_registry);
  printf("global_registry: %p\n", global_registry);

  printf("\n");

  return 42;
}
#if 0
}

// see https://stackoverflow.com/a/45972300/2019765
extern int Register(const char *name)
    __attribute__((alias("RegisterInternal")));
#endif
