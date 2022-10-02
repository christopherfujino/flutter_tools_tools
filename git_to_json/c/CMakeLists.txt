# https://cmake.org/cmake/help/latest/guide/tutorial/A%20Basic%20Starting%20Point.html
cmake_minimum_required(VERSION 3.16)

# Set the project name
project(CGit VERSION 0.1)

# define executable target
add_executable(main main.c)

include_directories(../../third_party/libgit2/include)
link_directories(../../third_party/libgit2/build)

# set cache var LIBGIT2 = resolved path
find_library(LIBGIT2 libgit2.a ../../third_party/libgit2/build/)

target_link_libraries(main ${LIBGIT2} crypto pthread ssl z)

# C17 requires CMAKE 3.21, while Ubuntu 20.04 LTS comes with 3.16
set_property(TARGET main PROPERTY C_STANDARD 11)

# For consumption by clangd
set(CMAKE_EXPORT_COMPILE_COMMANDS ON)
