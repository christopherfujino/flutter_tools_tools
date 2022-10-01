build_dir=./build
binary = $(build_dir)/main
CC = clang
CFLAGS=-I"../../third_party/libgit2/include"

main: main.o $(build_dir) ephemeral_state
	$(CC) -o $(build_dir)/$@ -std=c17 $< $(CFLAGS)

debug: main.o $(build_dir) ephemeral_state
	$(CC) -g -o $(build_dir)/$@ $< $(CFLAGS)

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
