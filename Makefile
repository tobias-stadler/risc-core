.PHONY: ctags clean

ctags:
	ctags -R hw/

cmake:
	cmake -G Ninja -S . -B build
	cmake --build build

run:
	./build/VPlaygroundTB

clean:
	rm -rf build/ obj_dir/ compile_commands.json .cache/ tags
