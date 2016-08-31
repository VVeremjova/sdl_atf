require('os')
local sdl_logger = require('sdl_logger')
local config = require('config')
local SDL = { }

require('atf.util')

SDL.exitOnCrash = true
SDL.STOPPED = 0
SDL.RUNNING = 1
SDL.CRASH = -1

function sleep(n)
  os.execute("sleep " .. tonumber(n))
end

function SDL:StartSDL(pathToSDL, smartDeviceLinkCore, ExitOnCrash)    
  sdl_logger.init_log(get_script_file_name())
  if ExitOnCrash then
    self.exitOnCrash = ExitOnCrash
  end
  local status = self:CheckStatusSDL()

  while status == self.RUNNING do
    sleep(1)
    print('Waiting for SDL shutdown')
    status = self:CheckStatusSDL()
  end

  if status == self.STOPPED  or status == self.CRASH then
    local result = os.execute ('./StartSDL.sh ' .. pathToSDL .. ' ' .. smartDeviceLinkCore)
    if result then
      local msg = "SDL started"
      xmlReporter.AddMessage("StartSDL", {["message"] = msg})
      return true
    else
      local msg = "SDL had already started not from ATF or unexpectedly crashed"
      xmlReporter.AddMessage("StartSDL", {["message"] = msg})
      print(console.setattr(msg, "cyan", 1))
      return nil, msg
    end
  end
  local msg = "SDL had already started from ATF"
  xmlReporter.AddMessage("StartSDL", {["message"] = msg})  
  print(console.setattr(msg, "cyan", 1))
  return nil, msg
end

function SDL:StopSDL()
  self.autoStarted = false
  local status = self:CheckStatusSDL()
  if status == self.RUNNING then
    local result = os.execute ('./StopSDL.sh')    
    if result then
      sdl_logger.close()
      return true
    end
  else
    local msg = "SDL had already stopped"
    xmlReporter.AddMessage("StopSDL", {["message"] = msg})
    print(console.setattr(msg, "cyan", 1))
    return nil, msg
  end
end

function SDL:CheckStatusSDL()
  local testFile = os.execute ('test -e sdl.pid')
  if testFile then
    local testCatFile = os.execute ('test -e /proc/$(cat sdl.pid)')
    if not testCatFile then
      return self.CRASH
    end
    return self.RUNNING
  end
  return self.STOPPED
end

function SDL:DeleteFile()
  if os.execute ('test -e sdl.pid') then
    os.execute('rm -f sdl.pid')
  end
end

return SDL
