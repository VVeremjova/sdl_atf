local expectations = require('expectations')
local events = require('events')
local load_schema = require('load_schema')
local functionId = require('function_id')
local mob_schema = load_schema.mob_schema

local Expectation = expectations.Expectation
local Event = events.Event
local SUCCESS = expectations.SUCCESS
local FAILED = expectations.FAILED

local module = {}
local mt = { __index = { } }
module.notification_counter = 0


function mt.__index:ExpectEvent(event, name)
  local ret = Expectation(name, self.session.connection)
  ret.event = event
  event_dispatcher:AddEvent(self.session.connection, event, ret)
  self.session.exp_list:Add(ret)
  return ret
end
function mt.__index:ExpectResponse(cor_id, ...)
  local temp_cor_id = cor_id
  local func_name = self.session.cor_id_func_map[cor_id]
  local tbl_corr_id = {}
  if func_name then
    self.session.cor_id_func_map[cor_id] = nil
  else
    if type(cor_id) == 'string' then 
        for fid, fname in pairs(self.session.cor_id_func_map) do
           if fname == cor_id then 
                func_name = fname
                table.insert(tbl_corr_id, fid)
                table.removeKey(self.session.cor_id_func_map, fid)
            end
        end
    cor_id = tbl_corr_id[1]

    end
    if not func_name then 
      error("Function with cor_id : "..temp_cor_id.." was not sent by ATF")
    end
  end
  local args = table.pack(...)
  local event = events.Event()
  if type(cor_id) ~= 'number' then
    error("ExpectResponse: argument 1 (cor_id) must be number")
    return nil
  end
  if(#tbl_corr_id>0) then 
       event.matches = function(_, data)
               for k,v in pairs(tbl_corr_id) do
                    if data.rpcCorrelationId  == v and  data.sessionId == self.session.sessionId then
                        return true
                    end
                 end
             return false
      end
  else
    event.matches = function(_, data)
        return data.rpcCorrelationId == cor_id and
        data.sessionId == self.session.sessionId
      end
  end
  local ret = Expectation("response to " .. cor_id, self.session.connection)
  if #args > 0 then
    ret:ValidIf(function(self, data)
        local arguments
        if self.occurences > #args then
          arguments = args[#args]
        else
          arguments = args[self.occurences]
        end
        xmlReporter.AddMessage("EXPECT_RESPONSE",{["id"] = tostring(cor_id),["name"] = tostring(func_name),["Type"]= "EXPECTED_RESULT"}, arguments)
        xmlReporter.AddMessage("EXPECT_RESPONSE",{["id"] = tostring(cor_id),["name"] = tostring(func_name),["Type"]= "AVALIABLE_RESULT"}, data.payload)
        local _res, _err = mob_schema:Validate(func_name, load_schema.response, data.payload)

        if (not _res) then return _res,_err end
        -- Workaround for non-existed value in enum
        if _err~=nil and err~="" then
          return true, _err
        end
        -- Finish workaround
        return compareValues(arguments, data.payload, "payload")
      end)
  end
  ret.event = event
  event_dispatcher:AddEvent(self.session.connection, event, ret)
  self.session.exp_list:Add(ret)
  return ret
end
function mt.__index:ExpectAny()
  local event = events.Event()
  event.level = 1
  event.matches = function(_, data)
    return data.sessionId == self.session.sessionId
  end
  local ret = Expectation("any unprocessed data", self.session.connection)
  ret.event = event
  event_dispatcher:AddEvent(self.session.connection, event, ret)
  self.session.exp_list:Add(ret)
  return ret
end
function mt.__index:ExpectNotification(funcName, ...)
  local event = events.Event()
  event.matches = function(_, data)
    return data.rpcFunctionId == functionId[funcName] and
    data.sessionId == self.session.sessionId
  end
  local args = table.pack(...)

  if #args ~= 0 and (#args[1] > 0 or args[1].n == 0) then
    -- These conditions need to validate expectations received from EXPECT_NOTIFICATION
    -- Second condition - to put out array with expectations which already packed in table
    -- Third condition - to put out expectation without parameters
    -- Only args[1].n == 0 allow to validate notifications without parameters from EXPECT_NOTIFICATION
    args = args[1]
  end

  local ret = Expectation(funcName .. " notification", self.session.connection)
  if #args > 0 then
    local notify_id = args.notifyId
    args = table.removeKey(args,'notifyId')
    ret:ValidIf(function(self, data)
        local arguments
        if self.occurences > #args then
          arguments = args[#args]
        else
          arguments = args[self.occurences]
        end
        module.notification_counter = module.notification_counter + 1
        xmlReporter.AddMessage("EXPECT_NOTIFICATION",{["Id"] = module.notification_counter, 
          ["name"] = tostring(funcName),["Type"]= "EXPECTED_RESULT"}, arguments)
        xmlReporter.AddMessage("EXPECT_NOTIFICATION",{["Id"] = module.notification_counter, 
          ["name"] = tostring(funcName),["Type"]= "AVALIABLE_RESULT"}, data.payload)      
        local _res, _err = mob_schema:Validate(funcName, load_schema.notification, data.payload)
        if (not _res) then
          return _res,_err
        end
        return compareValues(arguments, data.payload, "payload")
    end)
  end
  ret.event = event
  event_dispatcher:AddEvent(self.session.connection, event, ret)
  self.session.exp_list:Add(ret)
  return ret
end


function module.MobileExpectations(session)
  local res = { }
  res.session = session
  setmetatable(res, mt)
  return res
end


return module