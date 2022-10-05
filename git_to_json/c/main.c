// ASCII
#define PCRE2_CODE_UNIT_WIDTH 8
#include <pcre2.h>
#include <stdbool.h>
#include <stdio.h>
#include <string.h>

#include "git2.h"

void init();
bool clone(git_repository **repo, const char *upstream_url,
           const char *local_path, bool allow_failure);
void repository_open(git_repository **repo, const char *local_path);
void reference_list(git_repository *repo);
void reference_iterator_glob(git_repository *repo, const char *glob);
void deinit();

void check(int result, const char *description);

const char *local_repo_path = "./ephemeral_state/dotfiles";
const int MESSAGE_MAX = 200;

// struct repository {};

int main() {
  init();

  git_repository *repo = NULL;
  if (!clone(&repo, "http://github.com/flutter/flutter",
        "./ephemeral_state/flutter", true)) {
    repository_open(&repo, local_repo_path);
  }
  //reference_list(repo);
  reference_iterator_glob(repo, "refs/remotes/origin/*");
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
void repository_open(git_repository **repo, const char *local_path) {
  char message[MESSAGE_MAX];
  snprintf(message, MESSAGE_MAX, "Failed to load git repo from %s", local_path);
  check(git_repository_open(repo, local_path), message);
}

/// Print all refs.
void reference_list(git_repository *repo) {
  // https://stackoverflow.com/questions/7064314/what-is-0-in-c
  git_strarray refs = {0};
  check(git_reference_list(&refs, repo), "naming refs");

  for (int i = 0; i < refs.count; i++) {
    printf("Ref: \"%s\"\n", refs.strings[i]);
  }

  git_strarray_free(&refs);
}

void reference_iterator_glob(git_repository *repo, const char *glob) {
  int error_number;
  PCRE2_SIZE error_offset;
  pcre2_code *re = pcre2_compile(
    (PCRE2_SPTR)"refs\\/remotes\\/origin\\/([.\\w-]+)",
    PCRE2_ZERO_TERMINATED,
    0, // default options
    &error_number,
    &error_offset,
    NULL // use default compile context
  );

  if (re == NULL) {
    PCRE2_UCHAR buffer[256];
    pcre2_get_error_message(error_number, buffer, sizeof(buffer));
    fprintf(
      stderr,
      "PCRE2 compilation failed at offset %d: %s\n",
      (int)error_offset,
      buffer
    );
    exit(1);
  }

  git_reference_iterator *iter = NULL;
  char message[MESSAGE_MAX];
  snprintf(message, MESSAGE_MAX, "Failed to list refs from %s", glob);
  int error = git_reference_iterator_glob_new(&iter, repo, glob);
  check(error, message);

  const char *name = NULL;
  while (!(error = git_reference_next_name(&name, iter))) {
    // Using this function ensures that the block is exactly the right size for
    // the number of capturing parentheses in the pattern.
    pcre2_match_data *match_data = pcre2_match_data_create_from_pattern(re, NULL);

    int match_offset = pcre2_match(
      re,               // the compiled pattern
      (PCRE2_SPTR)name,          // the subject string
      strlen(name),  // the length of the subject
      0,                // start at offset 0 in the subject
      0,                // default options
      match_data,       // block for storing the result
      NULL);            // use default match context

    if (match_offset >= 0) {
      // Match succeded. Get a pointer to the output vector, where string
      // offsets are stored.
      PCRE2_SIZE *match_vector = pcre2_get_ovector_pointer(match_data);
      PCRE2_SPTR match_substring = (PCRE2_SPTR)name + match_vector[2];
      size_t match_length = match_vector[3] - match_vector[2];
      printf("remote branch: %.*s\n", (int)match_length, match_substring);
    } else {
      // TODO handle error
      switch (match_offset) {
        case PCRE2_ERROR_NOMATCH:
          fprintf(stderr, "No match\n");
      }
      fprintf(stderr, "Foo bar!\n");
      exit(1);
    }
  }
}

/// Log error and exit 1 if result is not 0.
void check(int result, const char *description) {
  if (result != 0) {
    const git_error *error = git_error_last();
    fprintf(stderr, "Error %s %d/%d: %s\n", description, result, error->klass, error->message);
    exit(1);
  }
}
