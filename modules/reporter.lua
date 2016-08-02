local xml = require('xml')
local io = require('atf.stdlib.std.io')

local module = {
  timestamp='',
  script_file_name = '',
  ndoc = {},
  curr_node={},
  root = {},
  curr_report_name = {},
  mt={_index={}}
}

local escape_lua_pattern
do
  local matches =
  {
    ["'"] = "%'";
    ["#"] = "";
    ["&"] = "";
  }

  escape_lua_pattern = function(s)
    return (s:gsub(".", matches))
  end
end

local function dump(o)
  if type(o) == 'table' then
    local s = '{ '
    for k,v in pairs(o) do
      if type(k) ~= 'number' then k = '\''..k..'\'' end
      s = s .. '['..k..'] = \'' .. dump(v) .. '\','
    end
    return s .. '}'
  elseif string.match(tostring(o),'[%Wxyz]') then
    return escape_lua_pattern(tostring(o))
  end
  return tostring(o)
end

function module.AddCase(name)
  if(not config.excludeReport) then
    module.curr_node = module.root:addChild(name)
    module.ndoc:write(module.curr_report_name)
  end
end

function module.AddMessage(name,funcName,...)
  if(not config.excludeReport) then
    local attrib = table.pack(...)[1]
    local msg = module.curr_node:addChild(name)

    if (type(funcName) ~= 'table') then
      msg:attr('FunctionName',funcName)
    else
      for an, av in pairs(funcName) do
        msg:attr(an,av)
      end
    end
    if (type(attrib) == 'table') then
      msg:text(dump(attrib))
    elseif(attrib ~= nil) then
      msg:text(attrib)
    end
    module.ndoc:write(module.curr_report_name)
  end
end

function module.CaseMessageTotal(name, ... )
  if(not config.excludeReport) then
    local attrib = table.pack(...)[1]
    for attr_n,attr_v in pairs(attrib) do
      if (type(attr_v) == 'table') then attr_v = table.concat(attr_v, ';')
      elseif (type(attr_v) ~= 'string') then attr_v = tostring(attr_v)
      end
      module.curr_node:attr(attr_n, attr_v)
    end
  end
end

function module.finalize()
  if(not config.excludeReport) then
    module.ndoc:write(module.curr_report_name)
  end
end

local function get_script_name(str)
  local tbl = table.pack(string.match(str, '(.-)([^/]-([^%.]+))$'))
  local name = tbl[#tbl-1]:gsub('%.'..tbl[#tbl]..'$', '')
  return name
end

function module.init(script_file_name)
  module.script_file_name = script_file_name
  if(config.excludeReport) then return module end
  if (module.timestamp == '') then module.timestamp = tostring(os.date('%Y%m%d%H%M%S', os.time())) end
  local dir_name = './' .. script_file_name
  local curr_report_dir = ''
  if (config.reportPath ~= nil and config.reportPath ~= '') then
    curr_report_dir = config.reportPath .. '/TestingReports'
  else
    curr_report_dir = 'TestingReports'
  end
  local curr_report_path = io.catdir(curr_report_dir ..'_'..module.timestamp, io.catdir(io.dirname(dir_name)))
  local report_header_name = ''
  if (config.reportMark ~= nil and config.reportMark ~= '' ) then
    module.curr_report_name = io.catfile(curr_report_path,get_script_name(dir_name) ..'_'..module.timestamp ..'_'..config.reportMark .. '.xml')
    report_header_name = script_file_name:gsub('.lua', '') .. '_' .. module.timestamp .. '_' .. config.reportMark
  else
    module.curr_report_name = io.catfile(curr_report_path,get_script_name(dir_name) ..'_'..module.timestamp .. '.xml')
    report_header_name = script_file_name:gsub('.lua', '') .. '_' .. module.timestamp
  end
  os.execute('mkdir -p "'.. curr_report_path .. '"')
  module.ndoc = xml.new()
  local alias = report_header_name:gsub('%.', '_'):gsub('/','_')
  module.root = module.ndoc:createRootNode(alias)

  return module
end

return module