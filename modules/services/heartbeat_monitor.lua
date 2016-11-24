local events = require('events')
local constants = require('protocol_handler/ford_protocol_constants')
 
 local module = {}
 local mt = { __index = { } }
  
 
function mt.__index:PreconditionForStartHeartbeat()
    local event = events.Event()
    event.matches = function(s, data)
      return data.frameType == constants.FRAME_TYPE.CONTROL_FRAME and
      data.serviceType == constants.SERVICE_TYPE.CONTROL and
      data.frameInfo == constants.FRAME_INFO.HEARTBEAT   and
      self.session.sessionId == data.sessionId
    end
    self.expectations:ExpectEvent(event, "Heartbeat")
    :Pin()
    :Times(AnyNumber())
    :Do(function(data)
        if self.heartbeatEnabled and self.answerHeartbeatFromSDL then
          self.session:Send( { frameType = constants.FRAME_TYPE.CONTROL_FRAME,
              serviceType = constants.SERVICE_TYPE.CONTROL,
              frameInfo = constants.FRAME_INFO.HEARTBEAT_ACK } )
        end
      end)

    local d = qt.dynamic()
    self.heartbeatToSDLTimer = timers.Timer()
    self.heartbeatFromSDLTimer = timers.Timer()

    function d.SendHeartbeat()
      if self.heartbeatEnabled and self.sendHeartbeatToSDL then
        self.session:Send( { frameType = constants.FRAME_TYPE.CONTROL_FRAME,
            serviceType = constants.SERVICE_TYPE.CONTROL,
            frameInfo = constants.FRAME_INFO.HEARTBEAT } )
        self.heartbeatFromSDLTimer:reset()
      end
    end

    function d.CloseSession()
      if self.heartbeatEnabled then
         self.control_services:StopService(7)
         self.session.test:FailTestCase("SDL didn't send anything for " .. self.heartbeatFromSDLTimer:interval()
          .. " msecs. Closing session # " .. self.session.sessionId)
      end
    end

    self.expectations:ExpectAny()
    :Pin()
    :Times(AnyNumber())
    :Do(function(data)
    -- self.session.connection:OnInputData(function(_, msg)
        if self.session.sessionId.get() ~= data.sessionId then return end
        if self.heartbeatEnabled then
          print (data.frameType)
          print(data.frameInfo)
            if data.frameType == constants.FRAME_TYPE.CONTROL_FRAME and
               data.frameInfo == constants.FRAME_INFO.HEARTBEAT_ACK and
               self.ignoreHeartBeatAck then
                return
            end
            self.heartbeatFromSDLTimer:reset()
        end
      end)

            self.session.connection:OnInputData(function(_, msg)
            if self.session.sessionId.get() ~= msg.sessionId then return end
            if self.heartbeatEnabled then
                if msg.frameType == constants.FRAME_TYPE.CONTROL_FRAME and
                   msg.frameInfo == constants.FRAME_INFO.HEARTBEAT_ACK and
                   self.ignoreHeartBeatAck then
                    return
                end
                self.heartbeatFromSDLTimer:reset()
            end
          end)

    self.session.connection:OnMessageSent(function(sessionId)
        if self.heartbeatEnabled and self.session.sessionId.get() == sessionId then
          self.heartbeatToSDLTimer:reset()
        end
      end)
    qt.connect(self.heartbeatToSDLTimer, "timeout()", d, "SendHeartbeat()")
    qt.connect(self.heartbeatFromSDLTimer, "timeout()", d, "CloseSession()")
end

function mt.__index:StartHeartbeat()
  if self.heartbeatToSDLTimer and self.heartbeatFromSDLTimer then
    self.heartbeatEnabled = true
    self.heartbeatToSDLTimer:start(config.heartbeatTimeout)
    self.heartbeatFromSDLTimer:start(config.heartbeatTimeout + 1000)
    xmlReporter.AddMessage("StartHearbeat", "True", (config.heartbeatTimeout + 1000))
  end
end


function mt.__index:StopHeartbeat()
  if self.heartbeatToSDLTimer and self.heartbeatFromSDLTimer then
    self.heartbeatEnabled = false
    self.heartbeatToSDLTimer:stop()
    self.heartbeatFromSDLTimer:stop()
    xmlReporter.AddMessage("StopHearbeat", "True")
  end
end

function mt.__index:SetHeartbeatTimeout(timeout)
  if self.heartbeatToSDLTimer and self.sessionheartbeatFromSDLTimer then
    self.heartbeatToSDLTimer:setInterval(timeout)
    self.heartbeatFromSDLTimer:setInterval(timeout + 1000)
  end
end

function module.HeartBeatMonitor(session)
  local res = { }
  res.session = session

  res.sessionId = session.sessionId
  res.control_services = session.control_services
  res.expectations = session.mobile_expectations

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
