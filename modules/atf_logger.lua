local json = require('json')
local config = require('config')
local io = require('atf.stdlib.std.io')
local ford_constants = require("protocol_handler/ford_protocol_constants")

local Logger = 
{  
  is_open = true,
  full_atf_log_file = '',
  script_file_name = '',
  atf_log_file = '',
  timestamp = 0,
  mobile_log_format = '',
  hmi_log_format = '',
  start_file_timestamp = 0,
  mt = { 
    __index={} 
  }
}

Logger.mobile_log_format = "%s(%s) [version: %s, frameType: %s, encryption: %s, serviceType: %s, frameInfo: %s, messageId: %s] : %s \n"
Logger.hmi_log_format = "%s[%s] : %s \n"

function Logger.formated_time(withoutDate)
  if withoutDate ==true then
    return qdatetime.get_datetime("hh:mm:ss,zzz")  
  end
  return qdatetime.get_datetime("dd MM yyyy hh:mm:ss, zzz")  
end

local function is_hmi_tract(tract, message)
  local str = string.format("%s", tract)
  if string.find(str, "HMI") or
    (message.frameType ~= ford_constants.FRAME_TYPE.CONTROL_FRAME) and
    (message.serviceType ~= ford_constants.SERVICE_TYPE.PCM) and
    (message.serviceType ~= ford_constants.SERVICE_TYPE.VIDEO) then 
    return true
  end 
  return false
end


function Logger:MOBtoSDL(track, message)
  local log_str = string.format(Logger.mobile_log_format,"MOB->SDL ", Logger.formated_time(), 
    message.version, message.frameType, message.encryption, message.serviceType, message.frameInfo, 
    message.messageId, message.payload)
  if is_hmi_tract(tract, message) then
    self.atf_log_file:write(log_str)
  end
  if config.storeFullATFLogs then
    self.full_atf_log_file:write(log_str)
  end
end

function Logger:StartTestCase(test_case_name)
  self.atf_log_file:write(string.format("\n\n===== %s : \n", test_case_name))
  if config.storeFullATFLogs then
    self.full_atf_log_file:write(string.format("\n\n===== %s : \n", test_case_name))
  end
end

function Logger:SDLtoMOB(tract, message)
  local payload = message.payload
  if type(payload) == "table" then
    payload = json.encode(payload)
  end
  local log_str = string.format(Logger.mobile_log_format,"SDL->MOB", Logger.formated_time(), 
    message.version, message.frameType, message.encryption, message.serviceType, message.frameInfo, 
    message.messageId, payload)
  if is_hmi_tract(tract, message) then
    self.atf_log_file:write(log_str)
  end
  if config.storeFullATFLogs then
    self.full_atf_log_file:write(log_str)
  end
end

function Logger:HMItoSDL(tract, message)
  local log_str = string.format(Logger.hmi_log_format, "HMI->SDL", Logger.formated_time(), message)
  if is_hmi_tract(tract, message) then
    self.atf_log_file:write(log_str)
  end
  if config.storeFullATFLogs then
    self.full_atf_log_file:write(log_str)
  end
end

function Logger:SDLtoHMI(tract, message)
  local log_str = string.format(Logger.hmi_log_format, "SDL->HMI", Logger.formated_time(), message)
  if is_hmi_tract(tract, message) then
    self.atf_log_file:write(log_str)
  end
  if config.storeFullATFLogs then
    self.full_atf_log_file:write(log_str)
  end
end

local function get_script_name(script_file_name)
  local tbl = table.pack(string.match(script_file_name, '(.-)([^/]-([^%.]+))$'))
  local name = tbl[#tbl-1]:gsub('%.'..tbl[#tbl]..'$', '')
  return name
end

local function get_log_file_name(timestamp, log_file_type)
  local dir_name = './' .. Logger.script_file_name
  local script_name = get_script_name(dir_name)
  if not timestamp then timestamp = tostring(os.date('%Y%m%d%H%M%S', os.time())) end
  if (config.reportPath == nil or config.reportPath == '') then
    config.reportPath = "."
  end
  local reportMark = config.reportMark
  if (reportMark == nil) then reportMark = ''
  else reportMark = "_" .. reportMark end
  local curr_log_dir = config.reportPath .. '/' .. log_file_type
  local curr_log_path = io.catdir(curr_log_dir ..'_'.. timestamp, io.catdir(io.dirname(dir_name)))
  local full_log_name = io.catfile(curr_log_path, script_name ..'_'..timestamp .. reportMark)
  os.execute('mkdir -p "'.. curr_log_path .. '"')
  return full_log_name
end

function Logger.init_log(script_name)
  Logger.script_file_name = script_name
  Logger.start_file_timestamp = timestamp()

  local timestamp = tostring(os.date('%Y%m%d%H%M%S', os.time()))
  local log_file_name = get_log_file_name(timestamp, "ATFLogs") 
  local atf_log_file_name = log_file_name ..".txt"
  Logger.atf_log_file = io.open(atf_log_file_name, "r") 
  if Logger.atf_log_file ~= nil then 
    io.close(Logger.atf_log_file)
  end
  Logger.atf_log_file = io.open(atf_log_file_name, "w+")
  
  if config.storeFullATFLogs then
    local full_atf_log_file_name = log_file_name .. "_full.txt";
    Logger.full_atf_log_file = io.open(full_atf_log_file_name, "r")
    if Logger.full_atf_log_file ~= nil then
      io.close(Logger.full_atf_log_file)      
    end
    Logger.full_atf_log_file = io.open(full_atf_log_file_name, "w+")
  end

  setmetatable(Logger, Logger.mt)
  is_open = true
  return Logger
end

function Logger.LOGTestCaseStart(test_case)
  if config.excludeReport then return end
  Logger:StartTestCase(test_case)
end

function Logger.LOG(tract, message)
  if config.excludeReport then return end
  Logger[tract](Logger, tract, message)
end

function Logger.LOGTestFinish(count)
  Logger.atf_log_file:write(string.format("\n\n===== Total executing time is %s ms =====n", count))
  if config.storeFullATFLogs then
    Logger.full_atf_log_file:write(string.format("\n\n===== Total executing time is %s ms =====\n", count))
  end
end

return Logger
