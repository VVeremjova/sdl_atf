HEADERS = src/network.h \
          src/timers.h \
          src/qtdynamic.h \
          src/qtlua.h \
          src/qdatetime.h \
          src/marshal.h \
          src/lua_interpreter.h
          
SOURCES = src/network.cc \
          src/timers.cc \
          src/qtdynamic.cc \
          src/qtlua.cc \
          src/qdatetime.cc \
          src/marshal.cc \
          src/main.cc \
          src/lua_interpreter.cc
          
TARGET  = bin/interp
QT = core network websockets
CONFIG += c++11 qt debug
OBJECTS_DIR = bin/.obj
# link with libc to meet cross-platform restricts
QMAKE_LFLAGS += -static-libgcc -static-libstdc++
QMAKE_LFLAGS += '-Wl,-rpath,./libs'
QMAKE_RPATHDIR=""
LIBS += -llua5.2
