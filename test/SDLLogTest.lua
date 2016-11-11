xmlReporter = require("reporter")
config = require("config")

local sdl_log = require('sdl_logger')
local atf_log = require('atf_logger')
local io = require("atf.stdlib.std.io")

function FindDirectory(directory, sub_directory)
  for filename in io.popen('ls -a "'..directory..'"'):lines() do
    if string.find(filename, sub_directory, 1, true) ~=nil then
      return filename
    end
  end
  print("ERROR: Directory \""..directory.."\" does not contain sub_folder \""..sub_directory.."'")
end

function FindReportPath(ReportPath)
  local filereport = assert(io.open(ReportPath, "r"))

  if filereport == nil then
    print("ERROR: Directory was not found. Possibly problem in date, look there")
  else
    print("Directory was successfully found")
  end

  filereport:close()
end

function FindReport(ReportPath, reporter_name, currDate)
  for reportName in io.popen('ls -a "'..ReportPath..'"'):lines() do
    if string.find(reportName, reporter_name,1,true) ~=nil then
      print("SDL log file was successfully found")
      return reportName
    end
  end
  print("ERROR: SDL log file \""..ReportPath.."\" does not exist")
end

--=================================
print ("Sdl Logger test started")
print("==============\n")

local dates = os.date("%Y%m%d%H%M")
sdl_log.init_log("SDLLogTest.lua")
local ReportPath = FindDirectory("./TestingReports/", "SDLLogs_"..dates)
ReportPath = "TestingReports/".. ReportPath .. "/"

FindReportPath(ReportPath)

ReportName = FindReport(ReportPath, "SDLLogTest_"..dates)
print("============== \n")
print ("Test ended")
quit()
