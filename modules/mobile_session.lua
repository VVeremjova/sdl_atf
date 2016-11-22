require('atf.util')
local mobileSessionImpl = require('mobile_session_impl')

local module = {}
local mt = { __index = { } }

function mt.__index:ExpectEvent(event, name)
  return self.mobile_session_impl.mobile_expectations:ExpectEvent(event, name)
end

function mt.__index:ExpectAny()
  return self.mobile_session_impl.mobile_expectations:ExpectAny()
end


function mt.__index:ExpectResponse(cor_id, ...)
  return self.mobile_session_impl.rpc_services:ExpectResponse(cor_id, ...)
end

function mt.__index:ExpectNotification(funcName, ...)
   return self.mobile_session_impl.rpc_services:ExpectNotification(funcName, ...)
end

function mt.__index:StartStreaming(service, filename, bandwidth)
  self.mobile_session_impl:StartStreaming(self.SessionId.get(), service, filename, bandwidth)
end
function mt.__index:StopStreaming(filename)
  self.mobile_session_impl:StopStreaming(filename)
end

function mt.__index:SendRPC(func, arguments, fileName)
  return self.mobile_session_impl:SendRPC(func, arguments, fileName)
end

function mt.__index:StartService(service)
  if service == 7 then
    return self.mobile_session_impl:StartRPC()
  end
  -- TODO() : It is workaround
  -- in case StartService(7) it should be change on StartRPC
  return self.mobile_session_impl:StartService(service)
end

function mt.__index:StopService(service)
  return self.mobile_session_impl.control_services:StopService(service)
end

function mt.__index:StopHeartbeat()
  self.mobile_session_impl.heartbeat_monitor:StopHeartbeat()
end

function mt.__index:StartHeartbeat()
  self.mobile_session_impl.heartbeat_monitor:StartHeartbeat()
end

function mt.__index:SetHeartbeatTimeout(timeout)
  self.mobile_session_impl.heartbeat_monitor:SetHeartbeatTimeout(timeout)
end

function mt.__index:StartRPC()
  return self.mobile_session_impl:StartRPC()
end

function mt.__index:StopRPC()
  self.mobile_session_impl:StopRPC()
end

function mt.__index:Send(message)
  -- Workaround
    if message.serviceType == 7 then 
      self.mobile_session_impl.rpc_services:CheckCorrelationID(message)
    end
  -- 
  self.mobile_session_impl:Send(message)
  return message
end

function mt.__index:Start()
  self.mobile_session_impl:Start()
end

function mt.__index:Stop()
  self.mobile_session_impl:Stop()
end


function module.MobileSession(test, connection, regAppParams)
  local res = { }
  res.correlationId = 1
  res.cor_id_func_map = { }
  res.sessionId = 0


  res.SessionId = {}
  function res.SessionId.set(val) 
    res.sessionId = val 
  end
  function res.SessionId.get() 
    return res.sessionId
  end


  res.CorrelationId = {}
  function res.CorrelationId.set(val) res.correlationId = val end
  function res.CorrelationId.get() 
    return  res.correlationId 
  end


  res.mobile_session_impl = mobileSessionImpl.MobileSessionImpl(
  res.SessionId, res.CorrelationId, res.cor_id_func_map, test, connection, regAppParams)

  setmetatable(res, mt)
  return res
end

return module
