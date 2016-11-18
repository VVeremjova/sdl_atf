require('atf.util')
local expectations = require('expectations')
local events = require('events')
local functionId = require('function_id')
local json = require('json')
local load_schema = require('load_schema')
local services = require('services/control_service')
local heartbeatMonitor = require('services/heartbeat_monitor')
local mobileExpectations = require('expectations/mobile_expectations')
local mob_schema = load_schema.mob_schema

local Expectation = expectations.Expectation
local Event = events.Event
local SUCCESS = expectations.SUCCESS
local FAILED = expectations.FAILED
local module = {}
local mt = { __index = { } }
local wrong_function_name = "WrongFunctionName"

mt.__index.cor_id_func_map = { }

module.notification_counter = 0

function mt.__index:ExpectEvent(event, name)
  return self.mobile_expectations:ExpectEvent(event, name)
end

function mt.__index:ExpectResponse(cor_id, ...)
  return self.mobile_expectations:ExpectResponse(cor_id, ...)
end

function mt.__index:ExpectAny()
  return self.mobile_expectations:ExpectAny()
end
function mt.__index:ExpectNotification(funcName, ...)
   return self.mobile_expectations:ExpectNotification(funcName, ...)
end

function mt.__index:StartStreaming(service, filename, bandwidth)
  self.connection:StartStreaming(self.sessionId, service, filename, bandwidth)
end
function mt.__index:StopStreaming(filename)
  self.connection:StopStreaming(filename)
end

function mt.__index:Send(message)
  self.services:Send(message)  
end

function mt.__index:SendRPC(func, arguments, fileName)
  self.services:SendRPC(func, arguments, fileName)
  return self.correlationId
end

function mt.__index:StartService(service)
  return self.services:Start(service)
end

function mt.__index:StopService(service)
  return self.services:StopService(service)
end

function mt.__index:StopHeartbeat()
  self.heartbeat_monitor:StopHeartbeat()
end

function mt.__index:StartHeartbeat()
  self.heartbeat_monitor:StartHeartbeat()
end

function mt.__index:SetHeartbeatTimeout(timeout)
  self.heartbeat_monitor:SetHeartbeatTimeout(timeout)
end

function mt.__index:Start()
  return self.services:Start(7)
  :Do(function()
      -- Heartbeat
      if self.version > 2 then       
        self.heartbeat_monitor:PreconditionForStartHeartbeat()
        self.heartbeat_monitor:StartHeartbeat()
      end

      local correlationId = self:SendRPC("RegisterAppInterface", self.regAppParams)
      self:ExpectResponse(correlationId, { success = true })
    end)
end

function mt.__index:Stop()
  self.services:StopService(7)
end

function module.MobileSession(test, connection, regAppParams)
  local res = { }
  res.test = test
  res.regAppParams = regAppParams
  res.connection = connection
  res.exp_list = test.expectations_list
  res.messageId = 1
  res.correlationId = 1
  res.version = config.defaultProtocolVersion or 2
  res.hashCode = 0
  res.cor_id_func_map = { }
  -- Each session should be kept in connection and called from it
  res.sessionId = connection:AddSession(res)
  res.services = services.Service(res)
  res.heartbeat_monitor = heartbeatMonitor.HeartBeatMonitor(res)
  res.mobile_expectations = mobileExpectations.MobileExpectations(res)
  setmetatable(res, mt)
  return res
end

return module
