require('atf.util')
local mobile_session_impl = require('mobile_session_impl')

local module = {}
local mt = { __index = { } }

--! @brief Expectation of specific event
--! @param event 
--! @param name is event name
--! @return return expectation table
function mt.__index:ExpectEvent(event, name)
  return self.mobile_session_impl:ExpectEvent(event, name)
end

--! @brief Expectation of any event
--! @return return expectation table for any unprocessed event
function mt.__index:ExpectAny()
  return self.mobile_session_impl:ExpectAny()
end

--! @brief Expectation of responce with specific correlation_id
--! @param correlation_id - id_number of specific rpc event
--! @return return expectation table
function mt.__index:ExpectResponse(cor_id, ...)
  return self.mobile_session_impl:ExpectResponse(cor_id, ...)
end

--! @brief Expectation of notification with specific funcName
--! @param funcName - name of notification 
--! @return return expectation table for notification
function mt.__index:ExpectNotification(funcName, ...)
   return self.mobile_session_impl:ExpectNotification(funcName, ...)
end


--! @brief Start video streaming 
--! @param service - serviceType 
--! @param filename - file for streaming 
--! @param bandwidth - optional parameter (default value is 30 * 1024)
function mt.__index:StartStreaming(service, filename, bandwidth)
  self.mobile_session_impl:StartStreaming(self.SessionId.get(), service, filename, bandwidth)
end

--! @brief Stop video streaming 
--! @param filename -  streaming file
function mt.__index:StopStreaming(filename)
  self.mobile_session_impl:StopStreaming(filename)
end

--! @brief Send RPC 
--! @param func - RPC name  
--! @param arguments - arguments for RPC function 
--! @param fileName - path to file with binary data
function mt.__index:SendRPC(func, arguments, fileName)
  return self.mobile_session_impl:SendRPC(func, arguments, fileName)
end


--! @brief Start specific service
--! @brief For service == 7 should be used StartRPC() instead of this function
--! @param service - service type
--! @return return expectation for StartService Ack
function mt.__index:StartService(service)
  if service == 7 then
    return self.mobile_session_impl:StartRPC()
  end
  -- in case StartService(7) it should be change on StartRPC
  return self.mobile_session_impl:StartService(service)
end

--! @brief Stop specific service
--! @param service - service type
--! @return return expectation for EndService ACK
function mt.__index:StopService(service)
  return self.mobile_session_impl:StopService(service)
end

function mt.__index:StopHeartbeat()
  self.mobile_session_impl:StopHeartbeat()
end

function mt.__index:StartHeartbeat()
  self.mobile_session_impl:StartHeartbeat()
end

function mt.__index:SetHeartbeatTimeout(timeout)
  self.mobile_session_impl:SetHeartbeatTimeout(timeout)
end

--! @brief Start service 7 and heartBeat
--! @return return expectation for expectation for StartService Ack
function mt.__index:StartRPC()
  return self.mobile_session_impl:StartRPC()
end

--! @brief Stop service 7
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

--! @brief Start rpc service (7) and send RegisterAppInterface rpc 
function mt.__index:Start()
  self.mobile_session_impl:Start()
end

--! @brief Start rpc service (7) and stop Heartbeat 
function mt.__index:Stop()
  self.mobile_session_impl:Stop()
end


function module.MobileSession(test, connection, regAppParams)
  local res = { }
  res.correlationId = 1
  res.sessionId = 0


  res.SessionId = {}
  function res.SessionId.set(val) 
    res.sessionId = val 
  end
  function res.SessionId.get() 
    return res.sessionId
  end


  res.CorrelationId = {}
  function res.CorrelationId.set(val) 
    res.correlationId = val 
  end
  function res.CorrelationId.get() 
    return  res.correlationId 
  end


  res.mobile_session_impl = mobile_session_impl.MobileSessionImpl(
  res.SessionId, res.CorrelationId, test, connection, regAppParams)

  setmetatable(res, mt)
  return res
end

return module
