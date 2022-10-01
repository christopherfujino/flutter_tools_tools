build_dir=./build
binary = $(build_dir)/main
CC = clang
# -I means append to search path for headers
# -Wall means add all warnings
# -L means append to search path for linking
# -l means link the named library (excluding extensions and the prefix "lib")
# -Wl means pass the following to the linker
# -rpath update the runtime loader's dynamic library search path
CFLAGS=-I"../../third_party/libgit2/include" \
			 -Wall \
			 -L"../../third_party/libgit2/build" \
			 -lgit2 \
			 -Wl,-rpath,../../third_party/libgit2/build

# https://stackoverflow.com/questions/25160245/clang-linking-with-a-so-file
main: main.o $(build_dir) ephemeral_state
	$(CC) -o $(build_dir)/main -std=c17 $< $(CFLAGS)

debug: main.o $(build_dir) ephemeral_state
	$(CC) -g -o $(build_dir)/$@ $< $(CFLAGS)

run: main
	$(build_dir)/main
# https://www.gnu.org/software/make/manual/html_node/Automatic-Variables.html#Automatic-Variables
# $@ is the name of the current target
# $< is the first prerequisite
%.o: %.c
	$(CC) -c -o $@ $< $(CFLAGS)

# Ensure output dir exists
$(build_dir):
	mkdir -p $(build_dir)

ephemeral_state:
	mkdir -p ephemeral_state

clean:
	rm $(binary) main.o $(build_dir)
