.PHONY: verilate runv bear clean

verilate:
	verilator -cc -exe --trace --build -Wall hw/Top.sv sim/main.cpp

runv: verilate
	./obj_dir/Vmain

bear:
	bear -- make verilate

clean:
	rm -rf obj_dir/ compile_commands.json trace/ .cache/
