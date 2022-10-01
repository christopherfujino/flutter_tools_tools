#include <stdio.h>

#include "git2.h"

void init();
void clone(git_repository** repo, const char* upstream_url,
           const char* local_path);
void open_repo(git_repository** repo, const char* local_path);
void status(git_repository* repo);
void deinit();

void check(int result);

//struct repository {};

int main() {
  printf("Hello, world!\n");

  init();

  git_repository* repo = NULL;
  // clone(&repo, "http://github.com/christopherfujino/dotfiles",
  //       "./ephemeral_state/dotfiles");
  open_repo(&repo, "./ephemeral_state/dotfiles");
  status(repo);
  deinit();
  return 0;
}

void init() {
  // initialize global state
  git_libgit2_init();
}

void deinit() { git_libgit2_shutdown(); }
void clone(git_repository** repo, const char* upstream_url,
           const char* local_path) {
  check(git_clone(repo,  // TODO should be freed
                  upstream_url, "./ephemeral_state/dotfiles",
                  NULL  // const git_clone_options *options
                  ));
}

/// Open a repo from disk.
void open_repo(git_repository** repo, const char* local_path) {
  check(git_repository_open(repo, local_path));  // TODO repo should be freed
}

typedef struct {
  int foo;
} status_data;

int status_callback(const char* path, unsigned int status_flags,
                    void* payload) {
  status_data* ptr = (status_data*)payload;
  printf("wow! %d\n", ptr->foo);
  return 0;
}

void status(git_repository* repo) {
  status_data payload = {.foo = 0};
  check(git_status_foreach(repo, status_callback, &payload));
}

void check(int result) {
  if (result != 0) {
    const git_error* error = git_error_last();
    fprintf(stderr, "Error %d/%d: %s\n", result, error->klass, error->message);
    exit(1);
  }
}
