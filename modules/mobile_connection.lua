local ph = require('protocol_handler/protocol_handler')
local file_connection = require("file_connection")

local module = { 
  mt = { __index = {} }  
}

function module.MobileConnection(connection)
  res = { }
  res.connection = connection
  setmetatable(res, module.mt)
  return res
end
function module.mt.__index:Connect()
  self.connection:Connect()
end
function module.mt.__index:Send(data)
  local messages = { }
  local protocol_handler = ph.ProtocolHandler()
  for _, msg in ipairs(data) do
    atf_logger.LOG("MOBtoSDL", msg)
    local msgs = protocol_handler:Compose(msg)
    for _, m in ipairs(msgs) do
      table.insert(messages, m)
    end
  end
  self.connection:Send(messages)
end
function module.mt.__index:StartStreaming(session, service, filename, bandwidth)
  if getmetatable(self.connection) ~= file_connection.mt then
    error("Data streaming is impossible unless underlying connection is FileConnection")
  end
  xmlReporter.AddMessage("mobile_connection","StartStreaming", {["Session"]=session,
      ["Service"]=service,["FileName"]=filename,["Bandwidth"]=bandwidth })
  self.connection:StartStreaming(session, service, filename, bandwidth)
end
function module.mt.__index:StopStreaming(filename)
  xmlReporter.AddMessage("mobile_connection","StopStreaming", {["FileName"]=filename})
  self.connection:StopStreaming(filename)
end
function module.mt.__index:OnInputData(func)
  local this = self
  local protocol_handler = ph.ProtocolHandler()
  local f =
  function(self, binary)
    local msg = protocol_handler:Parse(binary)
    for _, v in ipairs(msg) do
      -- After refactoring should be moved in mobile session
      atf_logger.LOG("SDLtoMOB", v)
      func(this, v)
    end
  end
  self.connection:OnInputData(f)
end
function module.mt.__index:OnDataSent(func)
  self.connection:OnDataSent(func)
end
function module.mt.__index:OnMessageSent(func)
  self.connection:OnMessageSent(func)
end
function module.mt.__index:OnConnected(func)
  self.connection:OnConnected(function() func(self) end)
end
function module.mt.__index:OnDisconnected(func)
  self.connection:OnDisconnected(function() func(self) end)
end
function module.mt.__index:Close()
  self.connection:Close()
end
return module
