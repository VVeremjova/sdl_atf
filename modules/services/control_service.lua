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

function mt.__index:Send(message)
  message.frameType = constants.FRAME_TYPE.CONTROL_FRAME    
  self.session:Send(message)
  xmlReporter.AddMessage("mobile_connection","Send",{message})    
  return message
end

function mt.__index:StartService(service)
	xmlReporter.AddMessage("StartService", service)
  local startSession =
  {
    frameType = 0,
    serviceType = service,
    frameInfo = 1,
    sessionId = self.session.sessionId.get(),
  }
  self:Send(startSession)
  -- prepare event to expect
  local startserviceEvent = Event()
  startserviceEvent.matches = function(_, data)
    return data.frameType == 0 and
    data.serviceType == service and
    (service == 7 or data.sessionId == self.session.sessionId.get()) and
    (data.frameInfo == 2 or -- Start Service ACK
      data.frameInfo == 3) -- Start Service NACK
  end

  local ret = self.session:ExpectEvent(startserviceEvent, "StartService ACK")
  :ValidIf(function(s, data)
      if data.frameInfo == 2 then
        xmlReporter.AddMessage("StartService", "StartService ACK", "True")
        return true
      else return false, "StartService NACK received" end
    end)
  return ret
end


function mt.__index:StopService(service)
  if self.session.hashCode == 0 then
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
      sessionId = self.session.sessionId.get(),
      binaryData = self.session.hashCode,
    })
  local event = Event()
  -- prepare event to expect
  event.matches = function(_, data)
    return data.frameType == 0 and
    data.serviceType == service and
    (service == 7 or data.sessionId == self.session.sessionId.get()) and
    (data.frameInfo == 5 or -- End Service ACK
      data.frameInfo == 6) -- End Service NACK
  end

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
