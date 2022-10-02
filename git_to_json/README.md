## Compiling

Depends on //flutter_tools_tools/third_party/libgit2. Build with:

```bash
cd flutter_tools_tools
git submodule init
git submodule update

cd third_party/libgit2
mkdir build

cd build
# BUILD_SHARED_LIBS=OFF means build a static library
# BUILD_CLAR=OFF means exclude test suite
#cmake .. -DBUILD_SHARED_LIBS=OFF -DLINK_WITH_STATIC_LIBRARIES=ON BUILD_CLAR=OFF
cmake .. -DBUILD_SHARED_LIBS=OFF
cmake --build .
```
