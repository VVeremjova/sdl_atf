#line 16 "main.nw"
#include <getopt.h>
#include <iostream>
#line 5 "main.nw"
extern "C" {
#include <lua5.2/lua.h>
#include <lua5.2/lualib.h>
#include <lua5.2/lauxlib.h>
}
#line 19 "main.nw"
#include <QObject>
#include <QStringList>
#include <QCoreApplication>
#include <unistd.h>
#include <assert.h>
#include <iostream>
#include <csignal>
#include <csetjmp>
#include "lua_interpreter.h"

#line 32 "main.nw"
namespace {
void abrt_handler(int signal) {
  _exit(1);
}
}

static void Usage(const char* exe) {
  std::cout << "Usage: " << exe << " filename.lua [arguments] or" << std::endl <<
               "       " << exe << " -h|--help" << std::endl;
}

int main(int argc, char** argv)
{
  QCoreApplication app(argc, argv);
  QStringList arguments = QCoreApplication::instance()->arguments();

  auto arg = arguments.begin();
  for (++arg; arg != arguments.end(); ++arg) {
    if (*arg == "-h" ||
        *arg == "--help") {
        Usage(argv[0]);
        return 0;
    } else if (*arg == "--") {
        ++arg;
        break;
    } else if (arg->startsWith("-")){
      std::cerr << "Unknown argument " << arg->toStdString() << std::endl;
      return 1;
    } else {
      break;
    }
  }

  if (arg == arguments.end()) {
    std::cerr << "Path to Lua script expected. Run `" << argv[0] << " --help` to get arguments list" << std::endl;
    return 1;
  }

  QString fileName = *arg;

  LuaInterpreter lua_interpreter(&app, arg, arguments.end());

  struct sigaction sa, oldsa;
  sa.sa_handler = abrt_handler;
  sigemptyset(&sa.sa_mask);
  sigaction(SIGABRT, &sa, &oldsa);
  sa.sa_flags = 0;

  int res = lua_interpreter.load(fileName.toUtf8().constData());
  if (res) {
    return res;
  }
  if (lua_interpreter.quitCalled) {
    return lua_interpreter.retCode;
  }
  return app.exec();
}
