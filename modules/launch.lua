require ("atf.util")

declare_opt("-c", "--config-file", RequiredArgument, "Config file")
declare_long_opt("--mobile-connection", RequiredArgument, "Mobile connection IP")
declare_long_opt("--mobile-connection-port", RequiredArgument, "Mobile connection port")
declare_long_opt("--hmi-connection", RequiredArgument, "HMI connection IP")
declare_long_opt("--hmi-connection-port", RequiredArgument, "HMI connection port")
declare_long_opt("--perflog-connection", RequiredArgument, "PerfLog connection IP")
declare_long_opt("--perflog-connection-port", RequiredArgument, "Perflog connection port")
declare_long_opt("--report-path", RequiredArgument, "Path for a report collecting.")
declare_long_opt("--report-mark", RequiredArgument, "Specify label of string for marking test report.")
declare_short_opt("-r", NoArgument, "Recursively scan of folders")
declare_short_opt("-p", NoArgument, "Parallel script running mode")
declare_long_opt("--storeFullSDLLogs", NoArgument, "Store Full SDL Logs enable")
declare_long_opt("--heartbeat", RequiredArgument, "Hearbeat timeout value")
declare_long_opt("--sdl-core", RequiredArgument, "Path to folder with SDL binary")
declare_long_opt("--report-mark", RequiredArgument, "Marker of testing report")

local script_files = parse_cmdl()

if (#script_files > 0) then
  for _,scpt in ipairs(script_files) do
    print_startscript(scpt)
    script_execute(scpt)
  end
end
