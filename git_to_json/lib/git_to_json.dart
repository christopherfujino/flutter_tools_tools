import 'src/lib_git_interface.dart';
import 'dart:ffi' as ffi;

Future<void> main() {
  ffi.DynamicLibrary libgit2 = ffi.DynamicLibrary.open('../third_party/libgit2/build/libgit2.so');
  return run(libgit2);
}

Future<void> run(ffi.DynamicLibrary dylib) async {
  Repository(dylib);
  //libGit.status();
}
