Test = require('connecttest')
require('cardinalities')
local hmi_connection = require('hmi_connection')
local websocket      = require('websocket_connection')
local module         = require('testbase')
local events = require('events')
local mobile_session = require('mobile_session')
local mobile  = require('mobile_connection')
local tcp = require('tcp_connection')
local file_connection  = require('file_connection')
local config = require('config')


function DelayedExp(time)
  local event = events.Event()
  event.matches = function(self, e) return self == e end
  EXPECT_EVENT(event, "Delayed event")
  :Timeout(time+1000)
  RUN_AFTER(function()
              RAISE_EVENT(event, event)
            end, time)
end

local function SendOnSystemContext(self, ctx)
  self.hmiConnection:SendNotification("UI.OnSystemContext",{ appID = self.applications[config.application1.registerAppInterfaceParams.appName], systemContext = ctx })
end


function Test:ActivationApp()

    --hmi side: sending SDL.ActivateApp request
      local RequestId = self.hmiConnection:SendRequest("SDL.ActivateApp", { appID = self.applications[config.application1.registerAppInterfaceParams.appName]})

      --hmi side: expect SDL.ActivateApp response
    EXPECT_HMIRESPONSE(RequestId)
      :Do(function(_,data)
        --In case when app is not allowed, it is needed to allow app
          if
              data.result.isSDLAllowed ~= true then

                --hmi side: sending SDL.GetUserFriendlyMessage request
                  local RequestId = self.hmiConnection:SendRequest("SDL.GetUserFriendlyMessage", 
                          {language = "EN-US", messageCodes = {"DataConsent"}})

                  --hmi side: expect SDL.GetUserFriendlyMessage response
                EXPECT_HMIRESPONSE(RequestId)
                      :Do(function(_,data)

                    --hmi side: send request SDL.OnAllowSDLFunctionality
                    self.hmiConnection:SendNotification("SDL.OnAllowSDLFunctionality", 
                      {allowed = true, source = "GUI", device = {id = "12ca17b49af2289436f303e0166030a21e525d266e209267433801a8fd4071a0", name = "127.0.0.1"}})

                    --hmi side: expect BasicCommunication.ActivateApp request
                      EXPECT_HMICALL("BasicCommunication.ActivateApp")
                        :Do(function(_,data)

                          --hmi side: sending BasicCommunication.ActivateApp response
                          self.hmiConnection:SendResponse(data.id,"BasicCommunication.ActivateApp", "SUCCESS", {})

                      end)

                      end)

        end
          end)

    --mobile side: expect OnHMIStatus notification
      EXPECT_NOTIFICATION("OnHMIStatus", {hmiLevel = "FULL"}) 

  end

  --//////////////////////////////////////////////////////////////////////////////////--
--Precondition for Case_PerformInteractionTest execution
 function Test:Precondition_ForPITesrCreateInteractionChoiceSet()
	local CorIdChoice = self.mobileSession:SendRPC("CreateInteractionChoiceSet",
  {
    interactionChoiceSetID = 1,
    choiceSet = 
    {
    	{
			choiceID = 1,
			menuName = "Choice 1",
			vrCommands = {"Choice1"}

    	}
	 }
  })


  EXPECT_HMICALL("VR.AddCommand", 
  {
    cmdID = 1,
    vrCommands ={"Choice1"},
    type = "Choice"
  })
  :Do(function(_,data)
    self.hmiConnection:SendResponse(data.id, "VR.AddCommand", "SUCCESS", {})
      end)

  EXPECT_RESPONSE("CreateInteractionChoiceSet", { success = true, resultCode = "SUCCESS" })
  :Timeout(2000)

end

--//////////////////////////////////////////////////////////////////////////////////--
-- 2.Check processing messages on UI interface
function Test:Case_ShowTest()
	local CorIdShow = self.mobileSession:SendRPC("Show",
  {
    mainField1 = "Show main Field 1",
    mainField2 = "Show main Field 2",
    mainField3 = "Show main Field 3",
    mediaClock = "12:04"
  })

  EXPECT_HMICALL("UI.Show", 
  {
    showStrings = 
    {
    	{ fieldName = "mainField1",  fieldText = "Show main Field 1"},
    	{ fieldName = "mainField2",  fieldText = "Show main Field 2"},
    	{ fieldName = "mainField3",  fieldText = "Show main Field 3"},
    	{ fieldName = "mediaClock",  fieldText = "12:04"}
	},

  })
  :Do(function(_,data)
    self.hmiConnection:SendResponse(data.id,"UI.Show", "SUCCESS", {})
      end)

  EXPECT_RESPONSE(CorIdShow, { success = true, resultCode = "SUCCESS", info = nil })
  :Timeout(2000)

end

--//////////////////////////////////////////////////////////////////////////////////--
-- 3.Check processing messages on TTS interface, EXPECT_ANY function
function Test:Case_SpeakTest()

  local TTSSpeakRequestId
  EXPECT_HMICALL("TTS.Speak",
    {
      speakType = "SPEAK",
      ttsChunks = { { text = "ttsChunks", type = "TEXT" } }
    })
    :DoOnce(function(_, data)
          TTSSpeakRequestId = data.id
          self.hmiConnection:SendNotification("TTS.Started",{ })
        end)

  EXPECT_NOTIFICATION("OnHMIStatus",
    { systemContext = "MAIN", hmiLevel = "FULL", audioStreamingState = "ATTENUATED" },
    { systemContext = "MAIN",  hmiLevel = "FULL", audioStreamingState = "AUDIBLE"    })
    :Times(2)
    :Do(function(exp, data)
          if exp.occurences == 1 then
            self.hmiConnection:SendResponse(TTSSpeakRequestId,"TTS.Speak", "SUCCESS", {})
            self.hmiConnection:SendNotification("TTS.Stopped",{ })
          end
        end)

  local SpeakCId = self.mobileSession:SendRPC("Speak",
  {
    ttsChunks = { { text = "ttsChunks", type = "TEXT"} }
  })

  EXPECT_ANY()
  :ValidIf(function(_, data)
       if data.payload.success == true and
        data.payload.resultCode == "SUCCESS" then
        print (" \27[32m  Message with expected data came \27[0m")
        return true
      else
         print (" \27[36m Some wrong message came"..tostring(data.rpcFunctionId)..", expected 12 \27[0m ")
         return false
      end
    end)

end

--//////////////////////////////////////////////////////////////////////////////////--
-- 4.Check processing messages on TTS, UI interfaces
function Test:Case_AlertTest()
  local AlertRequestId
  EXPECT_HMICALL("UI.Alert", 
  {
    softButtons = 
    {
      {
        text = "Button",
        isHighlighted = false,
        softButtonID = 1122,
        systemAction = "DEFAULT_ACTION"
      }
    }
  })
  :Do(function(_,data)
        AlertRequestId = data.id
        SendOnSystemContext(self, "ALERT")
      end)

  local TTSSpeakRequestId
  EXPECT_HMICALL("TTS.Speak",
    {
      speakType = "ALERT",
      ttsChunks = { { text = "ttsChunks", type = "TEXT" } }
    })
    :Do(function(_, data)
          TTSSpeakRequestId = data.id
        end)

  EXPECT_NOTIFICATION("OnHMIStatus",
    { systemContext = "ALERT", hmiLevel = "FULL", audioStreamingState = "AUDIBLE"    },
    { systemContext = "ALERT", hmiLevel = "FULL", audioStreamingState = "ATTENUATED" },
    { systemContext = "ALERT", hmiLevel = "FULL", audioStreamingState = "AUDIBLE"    },
    { systemContext = "MAIN",  hmiLevel = "FULL", audioStreamingState = "AUDIBLE"    })
    :Times(4)
    :Do(function(exp, data)
          if exp.occurences == 1 then
            self.hmiConnection:SendNotification("TTS.Started",{ })
          elseif exp.occurences == 2 then
            self.hmiConnection:SendResponse(TTSSpeakRequestId,"TTS.Speak", "SUCCESS", {})
            self.hmiConnection:SendNotification("TTS.Stopped",{ })
          elseif exp.occurences == 3 then
            self.hmiConnection:SendResponse(AlertRequestId,"UI.Alert", "SUCCESS", {})
          end
        end)
  local cid = self.mobileSession:SendRPC("Alert",
  {
    ttsChunks = { { text = "ttsChunks", type = "TEXT"} },
    softButtons =
    {
      {
         type = "TEXT",
         text = "Button",
         isHighlighted = false,
         softButtonID = 1122,
         systemAction = "DEFAULT_ACTION"
      }
    }
  })
  EXPECT_RESPONSE(cid, { success = true, resultCode = "SUCCESS" })
    :Do(function()
          SendOnSystemContext(self, "MAIN")
        end)
end


--//////////////////////////////////////////////////////////////////////////////////--
-- 5.Check processing messages on VR, UI interfaces
function Test:Case_PerformInteractionTest()

	local CorIdPI = self.mobileSession:SendRPC("PerformInteraction",
  {
    initialText = "initialText",
    interactionMode = "BOTH",
    interactionChoiceSetIDList = {1},
  })

local VRPIid
  EXPECT_HMICALL("VR.PerformInteraction", 
  {
  })
  :Do(function(_,data)
  	VRPIid = data.id
    self.hmiConnection:SendNotification("VR.Started",{ })
      end)

local UIPIid
  EXPECT_HMICALL("UI.PerformInteraction", 
  {
  })
  :Do(function(_,data)
  	UIPIid = data.id
      end)


	EXPECT_NOTIFICATION("OnHMIStatus",
      { systemContext = "MAIN", hmiLevel = "FULL", audioStreamingState = "NOT_AUDIBLE" },
      { systemContext = "MAIN", hmiLevel = "FULL", audioStreamingState = "AUDIBLE"},
	    { systemContext = "HMI_OBSCURED", hmiLevel = "FULL", audioStreamingState = "AUDIBLE"},
	    { systemContext = "MAIN", hmiLevel = "FULL", audioStreamingState = "AUDIBLE"    })
	    :Times(4)
	    :Do(function(exp, data)
	          if exp.occurences == 1 then
	            self.hmiConnection:SendError(VRPIid, "VR.PerformInteraction", "ABORTED", "VR.PerformInteraction is aborted by user")
	            self.hmiConnection:SendNotification("VR.Stopped",{ })

	            SendOnSystemContext(self, "HMI_OBSCURED")
	          elseif exp.occurences == 3 then
	            self.hmiConnection:SendResponse(UIPIid,"UI.PerformInteraction", "SUCCESS", {choiceID = 1})
	          end
	        end)


  EXPECT_RESPONSE(CorIdPI, { success = true, resultCode = "SUCCESS", choiceID = 1, triggerSource = "MENU" })
  :Do(function(_,data)
  	SendOnSystemContext(self, "MAIN")
  		end)

end

--//////////////////////////////////////////////////////////////////////////////////--
-- 6.Check creation of the new session
function Test:Case_SecondSession()
  -- Connected expectation
  self.mobileSession1 = mobile_session.MobileSession(
    self,
    self.mobileConnection)
end

--//////////////////////////////////////////////////////////////////////////////////--
-- 7.Check starting RPC service and registration app througt second created session
function Test:Case_AppRegistrationInSecondSession()
    self.mobileSession1:StartService(7)
    :Do(function()
            local CorIdRegister = self.mobileSession1:SendRPC("RegisterAppInterface",
            {
              syncMsgVersion =
              {
                majorVersion = 3,
                minorVersion = 0
              },
              appName = "Test2 Application",
              isMediaApplication = true,
              languageDesired = 'EN-US',
              hmiDisplayLanguageDesired = 'EN-US',
              appHMIType = { "NAVIGATION" },
              appID = "8675309"
            })

            EXPECT_HMINOTIFICATION("BasicCommunication.OnAppRegistered", 
            {
              application = 
              {
                appName = "Test2 Application"
              }
            })
            :Do(function(_,data)
              self.applications["Test2 Application"] = data.params.application.appID
                end)

            self.mobileSession1:ExpectResponse(CorIdRegister, { success = true, resultCode = "SUCCESS" })
            :Timeout(2000)

            self.mobileSession1:ExpectNotification("OnHMIStatus", 
            { systemContext = "MAIN", hmiLevel = "NONE", audioStreamingState = "NOT_AUDIBLE"})
            :Timeout(2000)
            :Times(1)

            DelayedExp(2000)
        end)
end

--//////////////////////////////////////////////////////////////////////////////////--
-- 8.Check receiving messages on mobile side according to mobile session
function Test:ActivateSecondApp()
  self.mobileSession1:ExpectNotification("OnHMIStatus",
    { systemContext = "MAIN", hmiLevel = "FULL", audioStreamingState = "AUDIBLE"}
    )

    self.mobileSession:ExpectNotification("OnHMIStatus", 
    { systemContext = "MAIN", hmiLevel = "BACKGROUND", audioStreamingState = "NOT_AUDIBLE"}
    )

    local RequestId = self.hmiConnection:SendRequest("SDL.ActivateApp", { appID = self.applications["Test2 Application"]})

    --hmi side: expect SDL.ActivateApp response
    EXPECT_HMIRESPONSE(RequestId)
      :Do(function(_,data)
        --In case when app is not allowed, it is needed to allow app
          if
              data.result.isSDLAllowed ~= true then

                --hmi side: sending SDL.GetUserFriendlyMessage request
                  local RequestId = self.hmiConnection:SendRequest("SDL.GetUserFriendlyMessage", 
                          {language = "EN-US", messageCodes = {"DataConsent"}})

                  --hmi side: expect SDL.GetUserFriendlyMessage response
                EXPECT_HMIRESPONSE(RequestId)
                      :Do(function(_,data)

                    --hmi side: send request SDL.OnAllowSDLFunctionality
                    self.hmiConnection:SendNotification("SDL.OnAllowSDLFunctionality", 
                      {allowed = true, source = "GUI", device = {id = config.deviceMAC, name = "127.0.0.1"}})

                    --hmi side: expect BasicCommunication.ActivateApp request
                      EXPECT_HMICALL("BasicCommunication.ActivateApp")
                        :Do(function(_,data)

                          --hmi side: sending BasicCommunication.ActivateApp response
                          self.hmiConnection:SendResponse(data.id,"BasicCommunication.ActivateApp", "SUCCESS", {})

                      end)
                      :Times(2)

                      end)

        end
          end)

end

--//////////////////////////////////////////////////////////////////////////////////--
-- Precondition: activation of first app
function Test:WaitActivation()
  EXPECT_NOTIFICATION("OnHMIStatus",
    { systemContext = "MAIN", hmiLevel = "FULL", audioStreamingState = "AUDIBLE" })
  local RequestId = self.hmiConnection:SendRequest("SDL.ActivateApp", { appID = self.applications["Test Application"]})
  EXPECT_HMIRESPONSE(RequestId)
end


--//////////////////////////////////////////////////////////////////////////////////--
-- 10.Check RUN_AFTER function execution
function Test:Case_PerformAudioPassThruTest()
	local CorIdPAPT = self.mobileSession:SendRPC("PerformAudioPassThru",
  {
  	audioPassThruDisplayText1 = "audioPassThruDisplayText1",
  	samplingRate = "16KHZ",
  	maxDuration = 10000,
  	bitsPerSample = "16_BIT",
  	audioType = "PCM"
  })

	local UIPAPTid
  EXPECT_HMICALL("UI.PerformAudioPassThru", 
  {
  })
  :Do(function(_,data)
  	UIPAPTid = data.id
    local function to_be_run()
      self.hmiConnection:SendResponse(UIPAPTid,"UI.PerformAudioPassThru", "SUCCESS", {})
    end 
    RUN_AFTER(to_be_run,7000)
      end)

	EXPECT_RESPONSE(CorIdPAPT, { success = true, resultCode = "SUCCESS" })
	:Timeout(15000)

end

--//////////////////////////////////////////////////////////////////////////////////--
-- Precondition: activation of second app
function Test:ActivateSecondApp()
  EXPECT_ANY_SESSION_NOTIFICATION("OnHMIStatus",
  { systemContext = "MAIN", hmiLevel = "FULL", audioStreamingState = "AUDIBLE"},
  { systemContext = "MAIN", hmiLevel = "BACKGROUND", audioStreamingState = "NOT_AUDIBLE"})
  :Times(2)

  local RequestId = self.hmiConnection:SendRequest("SDL.ActivateApp", { appID = self.applications["Test2 Application"]})

    --hmi side: expect SDL.ActivateApp response
    EXPECT_HMIRESPONSE(RequestId)
      :Do(function(_,data)
        --In case when app is not allowed, it is needed to allow app
          if
              data.result.isSDLAllowed ~= true then

                --hmi side: sending SDL.GetUserFriendlyMessage request
                  local RequestId = self.hmiConnection:SendRequest("SDL.GetUserFriendlyMessage", 
                          {language = "EN-US", messageCodes = {"DataConsent"}})

                  --hmi side: expect SDL.GetUserFriendlyMessage response
                EXPECT_HMIRESPONSE(RequestId)
                      :Do(function(_,data)

                    --hmi side: send request SDL.OnAllowSDLFunctionality
                    self.hmiConnection:SendNotification("SDL.OnAllowSDLFunctionality", 
                      {allowed = true, source = "GUI", device = {id = c"12ca17b49af2289436f303e0166030a21e525d266e209267433801a8fd4071a0", name = "127.0.0.1"}})

                    --hmi side: expect BasicCommunication.ActivateApp request
                      EXPECT_HMICALL("BasicCommunication.ActivateApp")
                        :Do(function(_,data)

                          --hmi side: sending BasicCommunication.ActivateApp response
                          self.hmiConnection:SendResponse(data.id,"BasicCommunication.ActivateApp", "SUCCESS", {})

                      end)
                      :Times(2)

                      end)

        end
          end)
end

--//////////////////////////////////////////////////////////////////////////////////--
-- 11.Check sending empty request
function Test:Case_ListFilesTest()
  local CorIdList = self.mobileSession1:SendRPC("ListFiles",{})

  self.mobileSession1:ExpectResponse(CorIdList, { success = true, resultCode = "SUCCESS"})
  :Timeout(2000)

end