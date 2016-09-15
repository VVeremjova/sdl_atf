local module = { }
console = require('console')
function module.PrintCaseResult(startCaseTime, caseName, success, errorMessage, timespan)
  caseName = tostring(caseName)
  if #caseName > 85 then
    caseName = string.sub(caseName, 1, 82) .. "..."
  else
    caseName = caseName .. string.rep(' ', 85 - #caseName)
  end

  local result
  if config.color then
    result = console.setattr(
      success and "[SUCCESS]" or "[FAIL]",
      success and "green" or "red",
      2, false)
  else
    result = success and "[SUCCESS]" or "[FAIL]"
  end

  print(string.format("[%s] %s %s (%d ms)",startCaseTime, caseName, result, timespan))
  if not success and errorMessage then
    for k, v in pairs(errorMessage) do
      local errmsg = " " .. k .. ": " .. v
      if config.color then
        print(console.setattr(errmsg, "cyan", 1))
      else
        print(errmsg)
      end
    end
  end
  return module
end
return module
