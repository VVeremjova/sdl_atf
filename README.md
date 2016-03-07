# Automated Test Framework (ATF)
Current release version: 2.2 (https://github.com/CustomSDL/sdl_atf/releases/tag/ATF2.2)

## Dependencies:
Library            | License
------------------ | -------------
**Lua libs**       |
liblua5.2          | MIT
json4lua           | MIT
lua-stdlib         | MIT
lua-lpeg           |
**Qt libs**        |
Qt5.3 WebSockets   | LGPL 2.1
Qt5.3 Network      | LGPL 2.1
Qt5.3 Core         | LGPL 2.1
Qt5.3 Test         | LGPL 2.1
**Other libs**     |
lpthread           | LGPL
libxml2            | MIT

For ATF usage:
```sudo apt-get install liblua5.2 libxml2 lua-lpeg```

[Qt5](https://download.qt.io/archive/qt/5.3/5.3.1/)

## Get source code:
```
$ git clone https://github.com/CustomSDL/sdl_atf
$ cd sdl_atf
$ git submodule init
$ git submodule update
```
## Compilation:
**1** Install 3d-parties developers libraries
```sudo apt-get install liblua5.2-dev libxml2-dev lua-lpeg-dev```

**2** Install Qt5.3+

**2** Setup QMAKE environment variable to path to qmake
```export QMAKE=${PATH_TO_QMAKE} ``` 
*You can get path to qmake this way:*
```
$ sudo find / -name qmake
/usr/bin/qmake
/opt/Qt5.3.1/5.3/gcc/bin/qmake
```
/usr/bin/qmake in most cases does not work as it is just soft link to qtchooser

**2**  ```$ make```

 1) If during executing "make" command you have the following problem:
   Project ERROR: Unknown module(s) in QT: websockets

   Solution:
   You have to change location of qmake in Makefile in atf root directory
   Find location of qmake executable on your local PC:
   (It should look like: .../Qt/5.3/gcc_64/bin/qmake)

   and put it into Makefile to the line:
   QMAKE=<your path to qmake>
   Sometimes you will need reinstall QT Creator to get correct qmake executable
   Also you can open QT Creator. Then go to: Tool->Options->Build & Run. Find Qt Versions Tab.
   Here you can find qmake location.

## Run:
**3**
``` ./start.sh [options] [script file name] ```

## Run tests
``` make test```
