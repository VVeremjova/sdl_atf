local utils = require("atf.stdlib.argument_parser")
config = require('config')
xmlReporter = require("reporter")
atf_logger = require("atf_logger")

local module = { 
  script_file_name = ""
}
local script_files = {}

RequiredArgument = utils.RequiredArgument
OptionalArgument = utils.OptionalArgument
NoArgument = utils.NoArgument

function get_script_file_name()
  return module.script_file_name
end

function table2str(o)
  if type(o) == 'table' then
    local s = '{ '
    for k,v in pairs(o) do
      if type(k) ~= 'number' then k = '"'..k..'"' end
      s = s .. '['..k..'] = ' .. table2str(v) .. ','
    end
    return s .. '} \n'
  end
  return tostring(o)
end
function print_table(t,... )
  if (type(t) == 'table' ) then
    print(table2str(t).. table2str(table.pack(...)))
  else
    print(tostring(t).. table2str(table.pack(...)))
  end
end
function is_file_exists(name)
  local f = io.open(name,"r")
  if f ~=nil then io.close(f) return true else return false end
end
function table.removeKey(t, k)
  local i = 0
  local keys, values = {},{}
  for k,v in pairs(t) do
    i = i + 1
    keys[i] = k
    values[i] = v
  end
                             
  while i>0 do
    if keys[i] == k then
        table.remove(keys, i)
        table.remove(values, i)
    break
    end
    i = i - 1
  end
                                     
  local a = {}
    for i = 1,#keys do
        a[keys[i]] = values[i]
    end
  return a
end

function print_startscript(script_name)
  print("==============================")
  print(string.format("Start '%s'",script_name))
  print("==============================")
end
function print_stopscript(script_name)
  print("==============================")
  print(string.format("Finish '%s'",script_name or script_files[1]))
  print("==============================")
end
function compareValues(a, b, name)
  local function iter(a, b, name, msg)
    if type(a) == 'table' and type(b) == 'table' then
      local res = true
      for k, v in pairs(a) do
        res = res and iter(v, b[k], name .. "." .. k, msg)
      end
      return res
    else
      if (type(a) ~= type(b)) then
        if (type(a) == 'string' and type(b) == 'number') then
          b = tostring(b)
        else
          table.insert(msg, string.format("type of data %s: expected %s, actual type: %s", name, type(a), type(b)))
          return false
        end
      end
      if a == b then
        return true
      else
        table.insert(msg, string.format("%s: expected: %s, actual value: %s", name, a, b))
        return false
      end
    end
  end
  local message = { }
  local res = iter(a, b, name, message)
  return res, table.concat(message, '\n')
end
--------------------------------------------------
-- parsing commad line part

function module.config_file(config_file)
  if (is_file_exists(config_file)) then
    config_file = config_file:gsub('%.', " ")
    config_file = config_file:gsub("/", ".")
    config_file = config_file:gsub("[%s]lua$", "")
    config = require(tostring(config_file))
  else
    print("Incorrect config file type")
    print("Uses default config")
    print("==========================")
  end
end
function module.mobile_connection(str)
  config.mobileHost = str
end
function module.mobile_connection_port(src)
  config.mobilePort= src
end
function module.hmi_connection(str)
  config.hmiUrl = str
end
function module.hmi_connection_port(src)
  config.hmiPort = src
end
function module.perflog_connection(str)
  config.perflogConnection=str
end
function module.perflog_connection_port(str)
  config.perflogConnectionPort=str
end
function module.report_path(str)
  config.reportPath=str
end
function module.report_mark(str)
  config.reportMark=str
end
function module.add_script(src)
  table.insert(script_files,src)
end
function module.storeFullSDLLogs(str)
  config.storeFullSDLLogs=str
end
function module.heartbeat(str)
  config.heartbeatTimeout=str
end

function module.sdl_core(str)
  if (not is_file_exists(str.."smartDeviceLinkCore")) and 
     (not is_file_exists(str.."/smartDeviceLinkCore")) then
    error("SDL is not accessible at the specified path: "..str)
    os.exit(1)
  end
  config.pathToSDL = str
end

function parse_cmdl()
  arguments = utils.getopt(argv, opts)
  if (arguments) then
    if (arguments['config-file']) then module.config_file(arguments['config-file']) end
    for k,v in pairs(arguments) do
      if (type(k) ~= 'number') then
        if ( k ~= 'config-file') then
          k = (k):gsub ("%W", "_")
          module[k](v)
        end
      else
        if k >= 2 and v ~= "modules/launch.lua" then
          module.add_script(v)
        end
      end
    end
  end
  return script_files
end
function PrintUsage()
  utils.PrintUsage()
end
function declare_opt(...)
  utils.declare_opt(...)
end
function declare_long_opt(...)
  utils.declare_long_opt(...)
end
function declare_short_opt(...)
  utils.declare_short_opt(...)
end
function script_execute(script_name)
  module.script_file_name = script_name  
  xmlReporter = xmlReporter.init(tostring(script_name))
  atf_logger = atf_logger.init_log(tostring(script_name))
  dofile(script_name)
end