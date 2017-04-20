#include <stdlib.h>
#include <stdio.h>
#include <fcntl.h>
#include <unistd.h>
#include "timing.h"

int main(int argc, char *argv[]) {
  if (argc < 3) {
    fprintf(stderr, "usage: %s <iters> <file>\n", argv[0]);
    return 1;
  }
  int iters = atoi(argv[1]);
  char *path = argv[2];

  measurement m = init_measurement();

  char buf[4096];
  for (int i = 1; i < iters; i++) {
    int fd = open(path, O_RDONLY);
    while (read(fd, &buf, 4096) > 0) { }
  }

  finish_measurement(m);
}
