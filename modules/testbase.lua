---- Test Cases executor.
--
--  Runs all new methods with a first Capital letter as a Tests.
--  Tests are being executed one by one and interrupt execution is case of
--  any critical issues (each Test could be marked as Critical)
--
--  For component overview description and a list of responsibilities, please, follow [ATF SAD Component View](https://smartdevicelink.com/en/guides/pull_request/93dee199f30303b4b26ec9a852c1f5261ff0735d/atf/components-view/#test-base).
--  @module TestBase
--  @copyright [Ford Motor Company](https://smartdevicelink.com/partners/ford/) and [SmartDeviceLink Consortium](https://smartdevicelink.com/consortium/)
--  @license <https://github.com/smartdevicelink/sdl_core/blob/master/LICENSE>

local ed = require("event_dispatcher")
local events = require("events")
local expectations = require('expectations')
local console = require('console')
local fmt = require('format')
local SDL = require('SDL')
local exit_codes = require('exit_codes')


local module = { }

local Expectation = expectations.Expectation
local SUCCESS = expectations.SUCCESS
local FAILED = expectations.FAILED

local STOPPED = SDL.STOPPED
local RUNNING = SDL.RUNNING
local CRASH = SDL.CRASH

local total_testset_result = true


SDL.is_SDL_stopped = true

-- Support table for controlling Test Cases execution status
-- @table control
local control = qt.dynamic()

local function isCapital(c)
  return 'A' <= c and c <= 'Z'
end

os.setlocale("C")

local mt =
{
  __index =
  {
    test_cases = { },
    case_names = { },
    descriptions = { },
    current_case_name = nil,
    current_case_index = 0,
    current_case_mandatory = false,
    expectations_list = expectations.ExpectationsList(),
    AddExpectation = function(self,e)
      self.expectations_list:Add(e)
    end,
    RemoveExpectation = function(self, e)
      self.expectations_list:Remove(e)
    end,
  },
  __newindex = function(t, k, v)
    local firstLetter = string.sub(k, 1, 1)
    if type(v) == "function" and isCapital(firstLetter)then
      local function testcase(test)
        function description(desc)
          t.descriptions[k] = desc
        end
        --- Set current test criticalness
        --  Failed critical test stops all following tests execution
        --  @param is_critical new bool value of current test criticalness
        --  @function TestBase:critical
        function critical(val)
          t.current_case_mandatory = val
        end
        t.current_case_name = k
        t.current_case_mandatory = false
        v(test)
        t.ts = timestamp()
      end
      t.case_names[testcase] = k
      table.insert(t.test_cases, testcase)
    else
      rawset(t, k, v)
    end
  end,
  __metatable = { }
}


--- Runs next Test Case or quit ATF execution
--  Test case is any testbase inheritor
-- with a first capital letter
-- @lfunction control.runNextCase
function control.runNextCase()
  module.ts = timestamp()
  module.current_case_time = atf_logger.formated_time(true)
  module.current_case_index = module.current_case_index + 1
  local testcase = module.test_cases[module.current_case_index]
  if testcase then
    module.current_case_name = module.case_names[testcase]
    xmlReporter.AddCase(module.current_case_name)
    atf_logger.LOGTestCaseStart(module.current_case_name)
    testcase(module)
  else
    if SDL.autoStarted then
      SDL:StopSDL()
    end
    module.current_case_name = nil
    print_stopscript()
    xmlReporter:finalize()
    if total_testset_result == false then
      quit(exit_codes.failed)
    else
      quit()
    end
  end
end

--- Support method for asynchronous start Tests execution
-- @lfunction control.start
function control:start()
  -- if 'color' is not set, it is true as default value
  if config.color == nil then config.color = true end
  if is_redirected then config.color = false end
  SDL:DeleteFile()
  self:next()
end

--- Checks Test Case result and SDL status
--- In case of any critical issues - interrupts Test Suit execution
local function CheckStatus()
  if module.current_case_name == nil or module.current_case_name == '' then return end
  -- Check the test status
  local success = true
  local errorMessage = {}
  if SDL:CheckStatusSDL() == RUNNING then
    SDL.is_SDL_stopped = false
  end
  if SDL:CheckStatusSDL() == CRASH then
    if SDL.exitOnCrash == true then
      success = false
    end
    print(console.setattr("SDL has unexpectedly crashed or stop responding!", "cyan", 1))
    critical(SDL.exitOnCrash)
    SDL:DeleteFile()
  elseif module.expectations_list:Any(function(e) return not e.status end) then return end
  for _, e in ipairs(module.expectations_list) do
    if e.status ~= SUCCESS then
      success = false
      total_testset_result = false
    end
    if not e.pinned and e.connection then
      event_dispatcher:RemoveEvent(e.connection, e.event)
    end
    for k, v in pairs(e.errorMessage) do
      errorMessage[e.name .. ": " .. k] = v
    end
  end
  fmt.PrintCaseResult(module.current_case_time, module.current_case_name, success, errorMessage, timestamp() - module.ts)
  xmlReporter.CaseMessageTotal(module.current_case_name,{ ["result"] = success, ["timestamp"] = (timestamp() - module.ts)} )
  if (not success) then xmlReporter.AddMessage("ErrorMessage", {["Status"] = "FAILD"}, errorMessage ) end
  module.expectations_list:Clear()
  module.current_case_name = nil
  if module.current_case_mandatory and not success then
    SDL:StopSDL()
    if SDL.exitOnCrash == true then
      quit(exit_codes.aborted)
    end
  end
  control:next()
end

--- Fail the current Test execution
-- @param self TestBase table
-- @param cause reason of test fail
-- @function FailTestCase
local function FailTestCase(self, cause)
  local exp = expectations.Expectation("AutoFail")
  exp.status = FAILED
  table.insert(exp.errorMessage, cause)
  module.expectations_list:Add(exp)
  CheckStatus()
end

--- Supports method for async Test Case status validation
-- @lfunction control.start
function control:checkstatus()
  event_dispatcher:validateAll()
  CheckStatus()
end

--- testbase module initialization on `testbase.lua` loading
local function main()
  setmetatable(module, mt)

  qt.connect(control, "next()", control, "runNextCase()")

  rawset(module, "FailTestCase", FailTestCase)

  event_dispatcher = ed.EventDispatcher()
  event_dispatcher:OnPostEvent(CheckStatus)
  timeoutTimer = timers.Timer()
  qt.connect(timeoutTimer, "timeout()", control, "checkstatus()")

  timeoutTimer:start(100)
  control:next()
end

-- Execute main and return result metatable
main()
return module
