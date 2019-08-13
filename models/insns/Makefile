CXX=g++
SOURCES=main.cpp
CFLAGS=-O2 -std=c++17
LDFLAGS=-std=c++17
OBJECTS=$(addprefix build/,$(SOURCES:.cpp=.cpp.o))
EXECUTABLE=build/test

all: $(SOURCES) $(EXECUTABLE)

build:
	mkdir -p build

$(EXECUTABLE): $(OBJECTS) build
	$(CXX) $(LDFLAGS) $(OBJECTS) -o $@


build/%.cpp.o: %.cpp build
	$(CXX) -c $(CFLAGS) $< -o $@

.PHONY: clean
clean:
	rm -f $(OBJECTS) $(EXECUTABLE)
	rm -d build
