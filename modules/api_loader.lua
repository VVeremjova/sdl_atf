local xml = require('xml')
local module = { }

local function get_name(xml_element)
    local parent_name = xml_element:parent():attr("name")
    local name = xml_element:attr("name")
    if(module.include_parent_name) then
        name = parent_name .. "." .. name
    end
    return name
end
 

local function LoadResultCodes( param )
  local resultCodes ={}
  local i = 1
  for _, item in ipairs(param:children("element")) do
     local name = item:attr("name")
     resultCodes[i]=name
     i=i + 1
    end
  return resultCodes
end

local function LoadParamsInFunction(param, interface)
  local name = param:attr("name")
  local p_type = param:attr("type")
  local minlength = param:attr("minlength")
  local maxlength = param:attr("maxlength")
  local minsize =  param:attr("minsize")
  local maxsize = param:attr("maxsize")
  local mandatory = param:attr("mandatory")
  local array = param:attr("array")

  if mandatory == nil then 
    mandatory = true
  end

  if array == nil then 
    array = false
  end

  local result_codes = nil
  if name == "resultCode" and p_type == "Result" then 
    result_codes  = LoadResultCodes(param) 
  end
  local data = {}
  data["type"]=p_type
  data["mandatory"]= mandatory
  data["array"] = array
  data["minlength"] = minlength
  data["maxlength"] = maxlength
  data["minsize"] = minsize
  data["maxsize"] = maxsize
  data["resultCodes"] = result_codes
  return name, data
end



 local function LoadEnums(api, dest)
   local enums = api:xpath("//interface/enum")
   for _, e in ipairs(enums) do
     local enum = { }
     local i = 1
     for _, item in ipairs(e:children("element")) do
       enum[item:attr("name")] = i
       i = i + 1
     end
     dest.enum[get_name(e)] = enum
   end

   for first, v in pairs (dest.interface) do
    for _, s in ipairs(v.body:children("enum")) do
      local name = s:attr("name")
      dest.interface[first].enum[name]={}
      local i = 1
      for _,e in ipairs(s:children("element")) do
        local enum_value = e:attr("name")
        dest.interface[first].enum[name][enum_value]=i
        i= i + 1
      end
    end
  end
 end
 
 local function LoadStructs(api, dest)
   for first, v in pairs (dest.interface) do
    for _, s in ipairs(v.body:children("struct")) do

      local name = s:attr("name")
      local temp_param = {}
      local temp_func = {}
      temp_func["name"] = name
      for _, item in ipairs(s:children("param")) do
        param_name, param_data = LoadParamsInFunction(item, first)
        temp_param[param_name] = param_data
      end
      temp_func["param"] = temp_param
      dest.interface[first].struct[name]=temp_func
    end
   end

   local structs = api:xpath("//interface/struct")
   for _, s in ipairs(structs) do
     local struct = { }
     for _, item in ipairs(s:children("param")) do
       struct[item:attr("name")] = item:attributes()
     end
     dest.struct[get_name(s)] = struct
   end
 
   for n, s in pairs(dest.struct) do
     for _, p in pairs(s) do
       if type(p.type) == 'string' then
         if p.type == "Integer" then
           p.class = dest.classes.Integer
         elseif p.type == "String" then
           p.class = dest.classes.String
         elseif p.type == "Float" then
           p.class = dest.classes.Float
         elseif p.type == "Boolean" then
           p.class = dest.classes.Boolean
         elseif dest.enum[p.type] then
           p.class = dest.classes.Enum
           p.type = dest.enum[p.type]
         elseif dest.struct[p.type] then
           p.class = dest.classes.Struct
           p.type = dest.struct[p.type]
         end
       end
     end
   end
 end
 




local function LoadFunction( api, dest  )
  for first, v in pairs (dest.interface) do
    for _, s in ipairs(v.body:children("function")) do
      local name = s:attr("name")
      local msg_type = s:attr("messagetype")
      local temp_func = {}
      local temp_param = {}
      temp_func["name"] = name
      temp_func["messagetype"] = msg_type
      for _, item in ipairs(s:children("param")) do
        param_name, param_data = LoadParamsInFunction(item, first)
        temp_param[param_name] = param_data
      end

      temp_func["param"] = temp_param
      dest.interface[first].type[msg_type].functions[name]=temp_func
    end
  end

end

local function LoadInterfaces( api, dest )
  local interfaces = api:xpath("//interface")
  for _, s in ipairs(interfaces) do
    name = s:attr("name")
    dest.interface[name] ={}
    dest.interface[name].body = s
    dest.interface[name].type={}
    dest.interface[name].type['request']={}
    dest.interface[name].type['request'].functions={}
    dest.interface[name].type['response']={}
    dest.interface[name].type['response'].functions={}
    dest.interface[name].type['notification']={}
    dest.interface[name].type['notification'].functions={}
    dest.interface[name].enum={}
    dest.interface[name].struct={}
  end
end


 function module.init(path, include_parent_name)
   module.include_parent_name = include_parent_name
   local result = {}
   result.classes = {
     String = { },
     Integer = { },
     Float = { },
     Boolean = { },
     Struct = { },
     Enum = { }
   }
   result.enum = { }
   result.struct = { }
  result.interface = { }
 
  module.msg_type = {'request', 'response', 'notification'}
   local _api = xml.open(path)
   if not _api then error(path .. " not found") end
 
  LoadInterfaces(_api, result)
   LoadEnums(_api, result)
   LoadStructs(_api, result)

  LoadFunction(_api, result)

   return result
 end
 
 return module
