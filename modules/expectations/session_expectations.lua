local expectations = require('expectations')
local events = require('events')

local Expectation = expectations.Expectation
local Event = events.Event
local SUCCESS = expectations.SUCCESS
local FAILED = expectations.FAILED

local module = {}
local mt = { __index = { } }

--! @brief Expectation of specific event
--! @param event 
--! @param name is event name
--! @return return expectation table
function mt.__index:ExpectEvent(event, name)
  local ret = Expectation(name, self.session.connection)
  ret.event = event
  event_dispatcher:AddEvent(self.session.connection, event, ret)
  self.session.exp_list:Add(ret)
  return ret
end

--! @brief Expectation of any event
--! @return return expectation table for any unprocessed event
function mt.__index:ExpectAny()
  local event = events.Event()
  event.level = 1
  event.matches = function(_, data)
    return data.sessionId == self.session.sessionId.get()
  end
  local ret = Expectation("any unprocessed data", self.session.connection)
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