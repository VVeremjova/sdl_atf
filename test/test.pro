QT = core
SOURCES = ../src/test/qttest.cc \
          ../src/test/object1.cc

HEADERS = object1.h

OBJECTS_DIR = .obj

TEMPLATE = lib
CONFIG = qt c++11 debug
TARGET = qttest
