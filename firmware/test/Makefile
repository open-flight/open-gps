# Host-side simulation of the firmware: stubs out Arduino + SparkFun libraries,
# feeds fake GPS positions and dial events, and plays a round through the real
# state machine + storage code. Run: make -C firmware/test
# AddressSanitizer hangs at startup on recent macOS, so it's Linux-only.
SAN := $(if $(filter Darwin,$(shell uname -s)),-fsanitize=undefined,-fsanitize=address,undefined)

sim: sim.cpp ../shot_tracker/*.cpp ../shot_tracker/*.h
	g++ -std=c++17 -O0 -g $(SAN) -Istubs -I../shot_tracker -o sim sim.cpp
	./sim
clean:
	rm -f sim round1.geojson
