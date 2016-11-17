require('atf.util')

local functionId = require('function_id')
local json = require('json')
local constants = require('protocol_handler/ford_protocol_constants')
local events = require('events')
local Event = events.Event
local expectations = require('expectations')


local Expectation = expectations.Expectation
local SUCCESS = expectations.SUCCESS
local FAILED = expectations.FAILED


local module = {}
local mt = { __index = { } }

function module.Service(session)
  local res = { }
  res.session = session
  setmetatable(res, mt)
  return res
end

function mt.__index:CheckCorrelationID(message)
	local message_correlation_id
  if message.rpcCorrelationId then
    message_correlation_id = message.rpcCorrelationId 
  else
    self.session.correlationId = self.session.correlationId + 1
    message_correlation_id = self.session.correlationId
  end
  if not self.session.cor_id_func_map[message_correlation_id] then
    self.session.cor_id_func_map[message_correlation_id] = wrong_function_name
    for fname, fid in pairs(functionId) do
      if fid == message.rpcFunctionId then
        self.session.cor_id_func_map[message_correlation_id] = fname
        break
      end
    end    
  else
    error("MobileSession:Send: message with correlationId: "..message_correlation_id.." in session "..self.session.sessionId .." was sent earlier by ATF")
  end
end

function mt.__index:Send(message)
  if not message.serviceType then
    error("MobileSession:Send: sessionId must be specified")
  end
  if not message.frameInfo then
    error("MobileSession:Send: frameInfo must be specified")
  end

  self.session.messageId = self.session.messageId + 1

  local sending_message = {
        version = message.version or self.session.version,
        encryption = message.encryption or false,
        frameType = message.frameType or 1,
        serviceType = message.serviceType,
        frameInfo = message.frameInfo,
        sessionId = self.session.sessionId,
        messageId = self.session.messageId,
        rpcType = message.rpcType,
        rpcFunctionId = message.rpcFunctionId,
        rpcCorrelationId = message.rpcCorrelationId,
        payload = message.payload,
        binaryData = message.binaryData
      }

  self:CheckCorrelationID(message)
  self.session.connection:Send({sending_message})
  xmlReporter.AddMessage("mobile_connection","Send",{sending_message})    
  return sending_message
end

function mt.__index:SendRPC(func, arguments, fileName)
  self.session.correlationId = self.session.correlationId + 1
  local msg =
  {
    serviceType = 7,
    frameInfo = 0,
    rpcType = 0,
    rpcFunctionId = functionId[func],
    rpcCorrelationId = self.session.correlationId,
    payload = json.encode(arguments)
  }
  if fileName then
    local f = assert(io.open(fileName))
    msg.binaryData = f:read("*all")
    io.close(f)
  end
  self:Send(msg)
end

function mt.__index:Start(service)
	xmlReporter.AddMessage("StartService", service)
  if service ~= 7 and self.session.sessionId == 0 then error("Session cannot be started") end
  local startSession =
  {
    frameType = 0,
    serviceType = service,
    frameInfo = 1,
    sessionId = self.session.sessionId,
  }
  self:Send(startSession)
  -- prepare event to expect
  local startserviceEvent = Event()
  startserviceEvent.matches = function(_, data)
    return data.frameType == 0 and
    data.serviceType == service and
    (service == 7 or data.sessionId == self.session.sessionId) and
    (data.frameInfo == 2 or -- Start Service ACK
      data.frameInfo == 3) -- Start Service NACK
  end

  -- return startserviceEvent
  local ret = self.session:ExpectEvent(startserviceEvent, "StartService ACK")
  :ValidIf(function(s, data)
      if data.frameInfo == 2 then
        xmlReporter.AddMessage("StartService", "StartService ACK", "True")
        return true
      else return false, "StartService NACK received" end
    end)
  if service == 7 then
    ret:Do(function(s, data)
        if s.status == FAILED then return end
        -- !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
        self.session.sessionId = data.sessionId
        -- !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
        self.session.hashCode = data.binaryData
      end)
  end
  return ret
end


function mt.__index:StopService(service)
  if self.hashCode == 0 then
    -- StartServiceAck was not received. Unable to stop not started service
    return nil
  end
  xmlReporter.AddMessage("StopService", service)
  local stopService =
  self:Send(
    {
      frameType = 0,
      serviceType = service,
      frameInfo = 4,
      sessionId = self.sessionId,
      binaryData = self.hashCode,
    })
  local event = Event()
  -- prepare event to expect
  event.matches = function(_, data)
    return data.frameType == 0 and
    data.serviceType == service and
    (service == 7 or data.sessionId == self.session.sessionId) and
    (data.frameInfo == 5 or -- End Service ACK
      data.frameInfo == 6) -- End Service NACK
  end

	-- return event
  local ret = self.session:ExpectEvent(event, "EndService ACK")
  :ValidIf(function(s, data)
      if data.frameInfo == 5 then return true
      else return false, "EndService NACK received" end
    end)
  if service == 7 then 
  	self.session:StopHeartbeat() 
  end
  return ret
end


return module
