local config = require('config')
local io = require('atf.stdlib.std.io')

local module = { 
  is_open = true,
  full_sdlLog_name = '',
  script_file_name = '',
  sdl_log_file = '',
  timestamp = 0,
  mt = { 
    __index={} 
  }
}

local function get_script_name(script_file_name)
  local tbl = table.pack(string.match(script_file_name, '(.-)([^/]-([^%.]+))$'))
  local name = tbl[#tbl-1]:gsub('%.'..tbl[#tbl]..'$', '')
  return name
end

local function get_log_file_name(timestamp, log_file_type)
  local dir_name = './' .. module.script_file_name
  local script_name = get_script_name(dir_name)
  if not timestamp then timestamp = tostring(os.date('%Y%m%d%H%M%S', os.time())) end
  module.timestamp = timestamp
  if (config.reportPath == nil or config.reportPath == '') then
    config.reportPath = "."
  end
  local reportMark = config.reportMark
  if (reportMark == nil) then 
    reportMark = ''
  else 
    reportMark = "_" .. reportMark 
  end
  
  local curr_log_dir = config.reportPath .. '/' .. log_file_type
  local curr_log_path = io.catdir(curr_log_dir ..'_'.. timestamp, io.catdir(io.dirname(dir_name)))
  local full_log_name = io.catfile(curr_log_path, script_name ..'_'..timestamp .. reportMark)  
  os.execute('mkdir -p "'.. curr_log_path .. '"')
  return full_log_name
end

local function init(host,port)    
  local res =
  {
    host = host,
    port = port
  }
  module.socket = network.TcpClient()
  if not module.socket then
    print("TcpClient returns nothing")
    return nil
  end  
  module.sdl_log_file = io.open(module.full_sdlLog_name,"r")
  if module.sdl_log_file ~= nil then    
    io.close(module.sdl_log_file)
    print("sdl_logger: file already created")
  end
  module.sdl_log_file = io.open(module.full_sdlLog_name,"w+")
  res.qtproxy = qt.dynamic()
  setmetatable(res, module.mt)
  return res
end

function module.init_log(script_name)
  module.script_file_name = script_name
  local timestamp = tostring(os.date('%Y%m%d%H%M%S', os.time()))
  module.full_sdlLog_name = get_log_file_name(timestamp, "SDLLogs")..".log"
  module.Connect(init(config.sdl_logs_host, config.sdl_logs_port))   
end

function module.dataReady()
  local data = module.socket:read_all()
  module.sdl_log_file:write(data)
end

function module.Connect(self)  
  self.qtproxy.dataReady = function() module.dataReady() end
  qt.connect(module.socket, "readyRead()", self.qtproxy, "dataReady()")
  module.socket:connect(self.host, self.port)
end

function module.close()  
  if(module.socket) then module.socket:close() end
  os.execute('bash ./WaitClosingSocket.sh '..config.sdl_logs_port)  
end

return module