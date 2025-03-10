
SOURCES_DIR = src
SOURCES = $(wildcard $(SOURCES_DIR)/*.cpp)
HEADERS_DIR = ./headers
BUILD_DIR = build
EXECUTABLE = patcher

all:
	make compile
	make run

setup:
	mkdir $(BUILD_DIR)
	mkdir $(SOURCES_DIR)
	mkdir $(HEADERS_DIR)

compile:
	g++ -o $(BUILD_DIR)/$(EXECUTABLE) $(SOURCES) -I$(HEADERS_DIR) -lSDL2 -lSDL2_image -lSDL2_mixer -lSDL2_ttf

run:
	gdb ./$(BUILD_DIR)/$(EXECUTABLE)
