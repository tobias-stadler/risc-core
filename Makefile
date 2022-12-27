.PHONY: ctags clean

ctags:
	ctags -R hw/

cmake:
	cmake -G Ninja -S . -B build
	cmake --build build

clean:
	rm -rf build/ obj_dir/ compile_commands.json trace/ .cache/ tags
