#include <stdbool.h>
#include <stdio.h>

#include "git2.h"

void init();
bool clone(git_repository **repo, const char *upstream_url,
           const char *local_path, bool allow_failure);
void open_repo(git_repository **repo, const char *local_path);
void name_each_ref(git_repository *repo);
void deinit();

void check(int result, const char *description);

const char *local_repo_path = "./ephemeral_state/dotfiles";
const int MESSAGE_MAX = 200;

// struct repository {};

int main() {
  printf("Hello, world!\n");

  init();

  git_repository *repo = NULL;
  clone(&repo, "http://github.com/flutter/flutter",
        "./ephemeral_state/dotfiles", true);
  git_repository_free(repo);
  open_repo(&repo, local_repo_path);
  name_each_ref(repo);
  deinit();
  return 0;
}

void init() {
  // initialize global state
  git_libgit2_init();
}

void deinit() { git_libgit2_shutdown(); }
bool clone(git_repository **repo, const char *upstream_url,
           const char *local_path, bool allow_failure) {
  int result = git_clone(repo, // TODO should be freed
                         upstream_url, "./ephemeral_state/dotfiles",
                         NULL // const git_clone_options *options
  );

  if (!allow_failure) {
    char message[MESSAGE_MAX];
    snprintf(message, 200, "git clone failed to clone %s to %s", upstream_url, local_path);
    check(result, message);
    return true;
  }
  return result == 0;
}

/// Open a repo from disk.
void open_repo(git_repository **repo, const char *local_path) {
  char message[MESSAGE_MAX];
  snprintf(message, MESSAGE_MAX, "Failed to load git repo from %s", local_path);
  check(git_repository_open(repo, local_path), message);
}

void name_each_ref(git_repository *repo) {
  // https://stackoverflow.com/questions/7064314/what-is-0-in-c
  git_strarray refs = {0};
  check(git_reference_list(&refs, repo), "naming refs");

  for (int i = 0; i < refs.count; i++) {
    printf("Ref: \"%s\"\n", refs.strings[i]);
  }

  git_strarray_free(&refs);
}

/// Log error and exit 1 if result is not 0.
void check(int result, const char *description) {
  if (result != 0) {
    const git_error *error = git_error_last();
    fprintf(stderr, "Error %s %d/%d: %s\n", description, result, error->klass, error->message);
    exit(1);
  }
}
