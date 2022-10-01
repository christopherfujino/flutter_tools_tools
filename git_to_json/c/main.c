#include <stdio.h>

#include "git2.h"

void init();
void deinit();
void check(int result);

struct repository {};

int main() {
  printf("Hello, world!\n");

  init();

  git_repository *repo = NULL;
  check(
    git_clone(
      &repo, // TODO should be freed
      "http://github.com/christopherfujino/dotfiles",
      "./ephemeral_state/dotfiles",
      NULL // const git_clone_options *options
    )
  );

  deinit();
  return 0;
}

void init() {
  // initialize global state
  git_libgit2_init();
}

void deinit() { git_libgit2_shutdown(); }

void check(int result) {
  if (result != 0) {
    const git_error *error = git_error_last();
    fprintf(stderr, "Error %d/%d: %s\n", result, error->klass, error->message);
    exit(1);
  }
}
