require('atf.util')
local expectations = require('expectations')
local events = require('events')
local control_services = require('services/control_service')
local rpc_services = require('services/rpc_service')
local heartbeatMonitor = require('services/heartbeat_monitor')
local mobileExpectations = require('expectations/session_expectations')

local Event = events.Event
local FAILED = expectations.FAILED
local module = {}
local mt = { __index = { } }

function mt.__index:ExpectEvent(event, name)
  return self.mobile_expectations:ExpectEvent(event, name)
end

function mt.__index:ExpectAny()
  return self.mobile_expectations:ExpectAny()
end

function mt.__index:ExpectResponse(cor_id, ...)
  return self.rpc_services:ExpectResponse(cor_id, ...)
end

function mt.__index:ExpectNotification(funcName, ...)
   return self.rpc_services:ExpectNotification(funcName, ...)
end

function mt.__index:StartStreaming(session_id, service, filename, bandwidth)
  self.connection:StartStreaming(session_id, service, filename, bandwidth)
end
function mt.__index:StopStreaming(filename)
  self.connection:StopStreaming(filename)
end

function mt.__index:SendRPC(func, arguments, fileName)
  return self.rpc_services:SendRPC(func, arguments, fileName)
end

function mt.__index:StartService(service)
  return self.control_services:StartService(service)
end

function mt.__index:StopService(service)
  return self.control_services:StopService(service)
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

function mt.__index:StartRPC()
  local ret = self:StartService(7)
  ret:Do(function()
      -- Heartbeat
      if self.version > 2 then
        self.heartbeat_monitor:PreconditionForStartHeartbeat()
        self.heartbeat_monitor:StartHeartbeat()
      end
    end)
  ret:Do(function(s, data)
      if s.status == FAILED then return end
      self.sessionId.set(data.sessionId)
      self.hashCode = data.binaryData
    end)
  return ret
end

function mt.__index:StopRPC()
  local ret = self.control_services:StopService(7)
  self:StopHeartbeat()
  return ret
end

function mt.__index:Send(message)
  if not message.serviceType then
    error("MobileSession:Send: serviceType must be specified")
  end
  if not message.frameInfo then
    error("MobileSession:Send: frameInfo must be specified")
  end

  self.messageId = self.messageId + 1
  message.version = message.version or self.version
  message.encryption = message.encryption or false
  message.frameType = message.frameType or 1
  message.sessionId = self.sessionId.get()
  message.messageId = self.messageId


  self.connection:Send({message})
  xmlReporter.AddMessage("e","Send",{message})
  return message
end

function mt.__index:Start()
  self:StartRPC()
  :Do(function()
    local correlationId = self:SendRPC("RegisterAppInterface", self.regAppParams)
    self:ExpectResponse(correlationId, { success = true })
    end)
end

function mt.__index:Stop()
  self:StopRPC()
end

function module.MobileSessionImpl(session_id, correlation_id, test, connection, sendHeartbeatToSDL, answerHeartbeatFromSDL, ignoreHeartBeatAck, regAppParams)
  local res = { }
  res.test = test
  res.regAppParams = regAppParams
  res.connection = connection
  res.exp_list = test.expectations_list
  res.messageId = 1

  res.version = config.defaultProtocolVersion or 2
  res.hashCode = 0
  res.correlationId = correlation_id
  res.sessionId = session_id

  res.control_services =  control_services.Service(res)
  res.rpc_services = rpc_services.RPCService(res)
  res.mobile_expectations = mobileExpectations.MobileExpectations(res)

  res.sendHeartbeatToSDL = sendHeartbeatToSDL
  res.answerHeartbeatFromSDL = answerHeartbeatFromSDL
  res.ignoreHeartBeatAck = ignoreHeartBeatAck

  res.heartbeat_monitor = heartbeatMonitor.HeartBeatMonitor(res)

  setmetatable(res, mt)
  return res
end

return module
