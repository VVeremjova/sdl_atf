local events = require('events')
local d = qt.dynamic()
 
 local module = {}
 local mt = { __index = { } }
 
 
 
function mt.__index:PreconditionForStartHeartbeat()

end

function mt.__index:StartHeartbeat()
  if self.session.heartbeatToSDLTimer and self.session.heartbeatFromSDLTimer then
    self.session.heartbeatEnabled = true
    self.session.heartbeatToSDLTimer:start(config.heartbeatTimeout)
    self.session.heartbeatFromSDLTimer:start(config.heartbeatTimeout + 1000)
    xmlReporter.AddMessage("StartHearbeat", "True", (config.heartbeatTimeout + 1000))
  end
end


function mt.__index:StopHeartbeat()
  if self.session.heartbeatToSDLTimer and self.session.heartbeatFromSDLTimer then
    self.session.heartbeatEnabled = false
    self.session.heartbeatToSDLTimer:stop()
    self.session.heartbeatFromSDLTimer:stop()
    xmlReporter.AddMessage("StopHearbeat", "True")
  end
end

function mt.__index:SetHeartbeatTimeout(timeout)
  if self.session.heartbeatToSDLTimer and self.sessionheartbeatFromSDLTimer then
    self.session.heartbeatToSDLTimer:setInterval(timeout)
    self.session.heartbeatFromSDLTimer:setInterval(timeout + 1000)
  end
end


function d.SendHeartbeat()
  if self.heartbeatEnabled and self.sendHeartbeatToSDL then
    self:Send( { frameType = constants.FRAME_TYPE.CONTROL_FRAME,
        serviceType = constants.SERVICE_TYPE.CONTROL,
        frameInfo = constants.FRAME_INFO.HEARTBEAT } )
    self.heartbeatFromSDLTimer:reset()
  end
end

function d.CloseSession()
  if self.heartbeatEnabled then
    self.services:StopService(7)
    self.test:FailTestCase("SDL didn't send anything for " .. self.heartbeatFromSDLTimer:interval()
      .. " msecs. Closing session # " .. self.sessionId)
  end
end



function module.HeartBeatMonitor(session)
  local res = { }
  res.session = session

  res.qt_dynamic = d
  res.heartbeatToSDLTimer = timers.Timer()
  res.heartbeatFromSDLTimer = timers.Timer()

  res.heartbeatEnabled = true
  res.sendHeartbeatToSDL = true
  res.answerHeartbeatFromSDL = true
  res.ignoreHeartBeatAck = false

  setmetatable(res, mt)
  return res
end

 
 return module
