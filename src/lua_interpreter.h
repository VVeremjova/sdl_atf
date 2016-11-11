#line 95 "main.nw"
#pragma once
#line 5 "main.nw"
extern "C" {
#include <lua5.2/lua.h>
#include <lua5.2/lualib.h>
#include <lua5.2/lauxlib.h>
}
#line 97 "main.nw"
#include <QObject>
#include <QMetaObject>
#include <QHash>
#include <QByteArray>
#include <QString>
#include <QStringList>

class LuaInterpreter : public QObject {
  Q_OBJECT
 private:
  lua_State* lua_state;
  int testObject;
 public:
  bool quitCalled = false;
  int retCode = 0;
  LuaInterpreter(QObject *parent, const QStringList::iterator& args, const QStringList::iterator& end);
  int load(const char *filename);
 public slots:
  void quit();
 public:
  ~LuaInterpreter();
};
