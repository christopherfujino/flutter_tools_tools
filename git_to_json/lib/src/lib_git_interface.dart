import 'dart:ffi';

import 'package:ffi/ffi.dart';

import '../generated_libgit2_bindings.dart' as lg;

T doThenFree<T>(T Function(Allocator) cb) {
  final Arena arena = Arena();
  final T t = cb(arena);
  arena.releaseAll();
  return t;
}

/// Dart wrapper around [LibGitBindings] for a managing a single repository.
///
/// https://libgit2.org/docs/guides/101-samples/
abstract class Repository {
  Repository._(DynamicLibrary dylib) : bindings = lg.LibGitBindings(dylib) {
    if (_instance != null) {
      throw StateError(
        // TODO or can it?
        'A repository can only be instantiated once!',
      );
    }
    _instance = this;
    // initialize global libgit2 state.
    // Should this be done at a library level?
    bindings.git_libgit2_init();
  }

  factory Repository.fromClone(
      DynamicLibrary dylib, String remoteUrl, String localPath) {
    return ClonedRepository(dylib, remoteUrl, localPath);
  }

  final lg.LibGitBindings bindings;
  Repository? _instance;

  Pointer<lg.git_repository> get repo => repoPtr.value;

  /// git_repository** repoPtr;
  ///
  /// More accurately, repoPtrPtr, but that would be annoying to type.
  late final Pointer<Pointer<lg.git_repository>> repoPtr =
      calloc.call<Pointer<lg.git_repository>>(1);

  status() {
    final int result = bindings.git_status_foreach(
      repo,
    );
  }

  void checkGitError(int result, String description) {
    if (result != 0) {
      final lg.git_error error = bindings.git_error_last().ref;
      throw Exception(
          '$description failed with ${error.klass}/${charStarToString(error.message)}');
    }
  }
}

class ClonedRepository extends Repository {
  ClonedRepository(super.dylib, this.remoteUrl, this.localPath) : super._() {
    doThenFree((Allocator allocator) {
      final Pointer<Char> remoteUrl = stringToCharStar(
        // TODO figure out how to support encryption in compiled libgit2
        'http://github.com/christopherfujino/dotfiles',
        allocator,
      );
      final Pointer<Char> localPath = stringToCharStar(
        './git-workspace/dotfiles',
        allocator,
      );

      checkGitError(
        bindings.git_clone(
          repoPtr,
          remoteUrl,
          localPath,
          nullptr, // git_clone_options* options
        ),
        'git clone dotfiles',
      );
    });
  }

  final String remoteUrl;
  final String localPath;
}

/// Create a Pointer<Int8> from a String.
///
/// This pointer must be freed by malloc.
Pointer<Char> stringToCharStar(String str, Allocator allocator) {
  return str.toNativeUtf8(allocator: allocator).cast<Char>();
}

String charStarToString(Pointer<Char> ptr) {
  return ptr.cast<Utf8>().toDartString();
}

/// Create a Pointer to a Pointer.
Pointer<Pointer<T>> reference<T extends NativeType>(Pointer<T> pointer) {
  return Pointer<Pointer<T>>.fromAddress(pointer.address);
}
