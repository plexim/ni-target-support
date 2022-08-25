--[[
    Copyright (c) 2022 Plexim GmbH
    
    Permission is hereby granted, free of charge, to any person obtaining a copy
    of this software and associated documentation files (the "Software"), to deal
    in the Software without restriction, including without limitation the rights
    to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
    copies of the Software, and to permit persons to whom the Software is
    furnished to do so, subject to the following conditions:
    
    The above copyright notice and this permission notice shall be included in all
    copies or substantial portions of the Software.
    
    THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
    IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
    FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
    AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
    LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
    OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
    SOFTWARE.
--]]

local U = require('CoderUtils')
local Veristand = require('CoderVeristand')

if Target.Variables.EXTERNAL_MODE ~= 1 then
  return {}
end

if Target.Variables.HOST_OS ~= "win" then
    return "External Mode only supported on windows architecture."
end

local buildType=Target.Variables.buildType
local debugServerCmd = ""
local error

if buildType == 1 then --VeriStandEngine
  local plxAsamExe=("%s/%s"%{Target.Variables.TARGET_ROOT,'tools/dnettools'}):gsub('%"+', ''):gsub('\\+','/') -- remove quotes, make all forward slashes=
  local portConfigXml=("%s/%s_portconfig.xml"%{Target.Variables.BUILD_ROOT,Target.Variables.BASE_NAME}):gsub('%"+', ''):gsub('\\+','/')

  if not U.FileExists(portConfigXml) then
    return "Port Configuration xml file '%s' not found." % {portConfigXml}
  end 
  if not U.FileExists(plxAsamExe) then
    return "PlxAsamXil Tool directory '%s' not found." % {plxAsamExe}
  end 

  error, VeriStandMajorVersion, VeriStandMinorVersion, VeriStandProductVersion =  Veristand.GetVeriStandVersion(Target.Variables.VeriStandVersion)
  if error~=nil then return error end

  --usage:
  --    plx-asam-xil-tool ExtModeServer -m=BASE_NAME -c=codegendir/BASE_NAME_portconfig.xml -v=2019.1.0 -l=logfile.log -a -k 
  --    (optional) a = non intrusive or attach to already running.
  --    (optional) k = don't quit after external mode disconnect.
  --    (optional) l = add log
  debugServerCmd = '"%s/plx-asam-xil-tool" ExtModeServer -m=%s -c="%s" -v="%s" -a' % {plxAsamExe, Target.Variables.BASE_NAME,portConfigXml,VeriStandProductVersion}
else --Default to RT Box style connection.
  return nil
end

return {
  ConnectionHelper = {
    Command = debugServerCmd,
    DelayBeforeConnectMs = 1000,
    DelayAfterDisconnectMs = 1000,
    WaitForFinishedMs = 1000,
  },
}
