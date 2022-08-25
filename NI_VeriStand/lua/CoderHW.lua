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

local HW  = {}
local Utils = require('CoderUtils')
local VSD  = require('CoderVeristandSysDefAPI')
local DAQ = require('CoderDAQmx')
local MOD = require('CoderModules')

function HW.SetupHardwareModelPorts(Registry)
    --Deepcopy table to prevent circular references
    --https://gist.github.com/tylerneylon/81333721109155b2d244 
    function copy2(obj)
        if type(obj) ~= 'table' then return obj end
        local res = setmetatable({}, getmetatable(obj))
        for k, v in pairs(obj) do res[copy2(k)] = copy2(v) end
        return res
    end
    --   Insert source table to the beginning of dest list, maintaining ordering
    function InsertTableToBeginnging(src,dest,counter)
        for i = #src,1,-1 do
            local tmp = {}
	        counter = counter+1
            tmp = copy2(src[i])
	        table.insert(dest,1,tmp)
        end
        return counter
    end

    --Final order of packed model:
    --  inports = [Ain,Din,Cin,non-hardware ports]
    --  outports = [Aout,Dout,Cout,non-hardware ports]
    Registry.NumInports = InsertTableToBeginnging(Registry.CounterInputConfigs,Registry.InportConfigs,Registry.NumInports)
    Registry.NumInports = InsertTableToBeginnging(Registry.DigitalInputConfigs,Registry.InportConfigs,Registry.NumInports)
    Registry.NumInports = InsertTableToBeginnging(Registry.AnalogInputConfigs,Registry.InportConfigs,Registry.NumInports)
    Registry.NumOutports = InsertTableToBeginnging(Registry.CounterOutputConfigs,Registry.OutportConfigs,Registry.NumOutports)
    Registry.NumOutports = InsertTableToBeginnging(Registry.DigitalOutputConfigs,Registry.OutportConfigs,Registry.NumOutports)
    Registry.NumOutports = InsertTableToBeginnging(Registry.AnalogOutputConfigs,Registry.OutportConfigs,Registry.NumOutports)
end

function HW.GetHardwareConfig()
    local HardwareConfig = {}
    HardwareConfig["slotNames"] = {}
    HardwareConfig["slotProducts"]={}
    HardwareConfig["slotNums"]  = {}
    HardwareConfig["slotCount"] = 0
        
    --Hardware configuration in .nce file
    local cfgFile = Target.Variables.nimaxFile:gsub('%"+', ''):gsub('\\+','/') -- remove quotes, make all forward slashes

    if not Utils.FileExists(cfgFile) or cfgFile:lower():match('%.nce$')==nil then
        return "The hardware configuration file '%s' does not exist or has incorrect file type." % {cfgFile}
    end

    --Parse file to array with valid lines
    --https://www.lua.org/pil/21.2.2.html
    local file = io.open(cfgFile, "rb") --binary file
    local data = file:read("*all")
    local validchars = "[%w%p%s\n]"
    local pattern = string.rep(validchars, 6) .. "+%z"
    local lines = {}
    for line in data:gmatch(pattern) do
        for s in line:gmatch("[^\r\n]+") do
            table.insert(lines, s)
        end
    end

    for i, line in ipairs(lines) do
        local verheader = line:match("%[DAQmx%]")
        if verheader~=nil then 
            HardwareConfig.majorVer  = lines[i+1]:match("MajorVersion = (%d*)")
            HardwareConfig.minorVer = lines[i+2]:match("MinorVersion = (%d*)")
        end
        local name      = line:match("%[DAQmxDevice (%w*)%]")
        if name~=nil then
            local product   = lines[i+1]:match("ProductType = (%w*-%w*)")
            local num       = math.floor(lines[i+6]:match("PXI.SlotNum = (%d*)"))
            if product~=nil and num~=nil then 
                HardwareConfig.slotCount=HardwareConfig.slotCount+1
                HardwareConfig.slotNames[num]  =name
                HardwareConfig.slotProducts[num]=product
                HardwareConfig.slotNums[num]   =num
            else
                return  "Error Parsing hardware configuraiton file at line: "..line, HardwareConfig
            end
        end
    end
    io.close(file)
    return nil, HardwareConfig
end

function HW.GetPortTotals(cfgs)
    ret = 0
    for i, cfg in pairs(cfgs) do
        ret = ret + cfg.dim
    end
    return ret
end

function HW.ConfigureDAQmx(HardwareConfig,Registry,installDir)
    --Resources on Timing and Synchro.
    --https://www.ni.com/en-us/support/documentation/supplemental/10/synchronization-explained.html
    --https://www.ni.com/content/ni/locales/en-us/support/documentation/supplemental/06/timing-and-synchronization-features-of-ni-daqmx.html
    --
    --http://www.ni.com/tutorial/3615/en/#toc5 (mseries)
    --https://www.ni.com/documentation/en/ni-daqmx/20.1/mxcncpts/readwritelate/
    
    
    --Substitution in Template Files
    local dict = {}
    local TaskManager,error

    error, TaskManager = DAQ.ConfigureTasks(Registry,HardwareConfig)
    if error~=nil then return error end

    --General variables
    table.insert(dict, {before = "|>BASE_NAME<|", after = Target.Variables.BASE_NAME})
    table.insert(dict, {before = "|>SAMPLE_FREQ<|", after = 1.0/Target.Variables.SAMPLE_TIME})
    --Channel creation
    table.insert(dict, {before = "|>DAQ_CREATE_AI_CHANS<|", after = DAQ.SetupAnalogInputs  (Registry.AnalogInputConfigs,HardwareConfig) })
    table.insert(dict, {before = "|>DAQ_CREATE_AO_CHANS<|", after = DAQ.SetupAnalogOutputs (Registry.AnalogOutputConfigs,HardwareConfig)}) 
    table.insert(dict, {before = "|>DAQ_CREATE_DI_CHANS<|", after = DAQ.SetupDigitalInputs (Registry.DigitalInputConfigs,HardwareConfig) })
    table.insert(dict, {before = "|>DAQ_CREATE_DO_CHANS<|", after = DAQ.SetupDigitalOutputs(Registry.DigitalOutputConfigs,HardwareConfig)}) 
    table.insert(dict, {before = "|>DAQ_CREATE_CI_CHANS<|", after = DAQ.SetupCounterInputs (Registry.CounterInputConfigs,HardwareConfig) })
    table.insert(dict, {before = "|>DAQ_CREATE_CO_CHANS<|", after = DAQ.SetupCounterOutputs(Registry.CounterOutputConfigs,HardwareConfig)}) 
    --Channel mapping to model
    table.insert(dict, {before = "|>MAP_DAQ_WRITE_TO_MODEL<|", after = DAQ.SetupDAQReadMap(Registry,TaskManager,HardwareConfig)})
    table.insert(dict, {before = "|>MAP_DAQ_READ_TO_MODEL<|", after = DAQ.SetupDAQWriteMap(Registry,TaskManager,HardwareConfig)})
    --Task management
    table.insert(dict, {before = "|>SOFTWARE_TIMER_FLAG<|", after = TaskManager.SoftwareTimerFlag})
    table.insert(dict, {before = "|>TASK_HANDLE_LIST<|", after = DAQ.TaskHandleList(TaskManager)})
    table.insert(dict, {before = "|>CLEAR_TASKS<|", after = DAQ.ClearTasks(TaskManager)})
    table.insert(dict, {before = "|>CREATE_TASKS<|", after = DAQ.CreateTasks(TaskManager)})
    table.insert(dict, {before = "|>START_TASKS<|", after = DAQ.StartTasks(TaskManager)})
    table.insert(dict, {before = "|>CONFIG_TASK_TIMING<|", after = DAQ.ConfigTaskTiming(Registry,TaskManager,1.0/Target.Variables.SAMPLE_TIME)})
    table.insert(dict, {before = "|>SETUP_TASKS<|", after = DAQ.SetupTasks(TaskManager)})
    table.insert(dict, {before = "|>RTLATE_TASKS<|", after = DAQ.RTLateTasks(TaskManager)})
    table.insert(dict, {before = "|>IO_DATA_FORMAT<|", after = DAQ.IODataFormat(TaskManager)})
    table.insert(dict, {before = "|>CLEANUP_TERMINAL_CONNECTIONS<|", after = DAQ.CleanupTerminalConnections(TaskManager)})

    Utils.CopyTemplateFile(Target.Variables.TARGET_ROOT .. "/templates/vdaq.c", "%s/%s_vdaq.c" % {installDir, Target.Variables.BASE_NAME}, dict)
    Utils.CopyTemplateFile(Target.Variables.TARGET_ROOT .. "/templates/vdaq.h", "%s/%s_vdaq.h" % {installDir, Target.Variables.BASE_NAME}, dict)

    return nil
end

function HW.ConfigureVeristandProject(HardwareConfig,Registry,installDir)
    local function CheckProjectFileStatus(fileType,installDir)
        local error = nil
        local extensions = {vsWorkspaceScreen='.nivsscreen',vsEditorScreen='.nivsscr',vsCalibration='.nivscf'}
        local ext = ''
        local isTemplate=true


        --get extension from table.
        if extensions[fileType]~=nil then
            ext = extensions[fileType]
        else
            error = {"Cannot interpret extension for %s." % fileType}
            return error, ''
        end

        --check if file or folder.  io.open for folder returns nil.
        local fileName = Target.Variables[fileType]:gsub('%"+', ''):gsub('/+','\\') -- remove quotes, make all backward(!) slashes

        if not Utils.FileExists(fileName) then
            error = "Specified veristand project file %s does not exist." % {fileName}
            return error,''
        end

        local fileHandle = io.open(fileName)
       
        --use provided file
        if fileHandle~=nil then 
            if Target.Variables[fileType]:lower():match('%'..ext..'$')==nil then
                error = "Specified veristand project file %s does not have the expected file extension of %s." % {fileName,ext}
            end
            isTemplate=false
            io.close(fileHandle)
        --use template
        else 
            fileName = (installDir.."\\"..Target.Variables.BASE_NAME .. ext):gsub('%"+', ''):gsub('/+','\\') -- remove quotes, make all backward(!) slashes
        end

        return error,fileName,isTemplate
    end

    local error

    --Check default pins are used.
    error = VSD.CheckUsingDefaultCounterPins(Registry)
    if error ~= nil then return error end
    
    --Use screen and calibration files, if available.
    local vsWorkspaceScreen, vsEditorScreen, vsCalibration
    error, vsWorkspaceScreen, vsWorkspaceScreenIsTemplate= CheckProjectFileStatus('vsWorkspaceScreen',installDir)
    if error ~= nil then return error end
    error, vsEditorScreen, vsEditorScreenIsTemplate= CheckProjectFileStatus('vsEditorScreen',installDir)
    if error ~= nil then return error end
    error, vsCalibration, vsCalibrationIsTemplate = CheckProjectFileStatus('vsCalibration',installDir)
    if error ~= nil then return error end

    --Substitution in Template Files
    local dict = {}
    
    --General variables
    table.insert(dict, {before = "|>BASE_NAME<|", after = Target.Variables.BASE_NAME})
    table.insert(dict, {before = "|>WORKSPACE_SCREEN_FILE<|", after = vsWorkspaceScreen})
    table.insert(dict, {before = "|>EDITOR_SCREEN_FILE<|", after = vsEditorScreen})
    table.insert(dict, {before = "|>CALIBRATION_FILE<|", after = vsCalibration})
    table.insert(dict, {before = "|>BASE_NAME<|", after = Target.Variables.BASE_NAME})
    table.insert(dict, {before = "|>SAMPLE_TIME<|", after = Target.Variables.SAMPLE_TIME})
    table.insert(dict, {before = "|>CREATOR<|", after = ("PLECS " .. Target.Name .. " Target v" .. Target.Version)})

    Utils.CopyTemplateFile(Target.Variables.TARGET_ROOT .. "/templates/vprj.nivssdf",   "%s/%s.nivssdf.tmp" % {installDir, Target.Variables.BASE_NAME}, dict)
    Utils.CopyTemplateFile(Target.Variables.TARGET_ROOT .. "/templates/vprj.nivsproj",  "%s/%s.nivsproj"    % {installDir, Target.Variables.BASE_NAME}, dict)
    Utils.CopyTemplateFile(Target.Variables.TARGET_ROOT .. "/templates/vprj.nivsprj",   "%s/%s.nivsprj"     % {installDir, Target.Variables.BASE_NAME}, dict)

    --Copy empty template files
    if vsWorkspaceScreenIsTemplate then Utils.CopyTemplateFile(Target.Variables.TARGET_ROOT .. "/templates/vprj.nivsscreen","%s/%s.nivsscreen"  % {installDir, Target.Variables.BASE_NAME}, dict) end
    if vsEditorScreenIsTemplate    then Utils.CopyTemplateFile(Target.Variables.TARGET_ROOT .. "/templates/vprj.nivsscr",   "%s/%s.nivsscr"     % {installDir, Target.Variables.BASE_NAME}, dict) end
    if vsCalibrationIsTemplate     then Utils.CopyTemplateFile(Target.Variables.TARGET_ROOT .. "/templates/vprj.nivscf",    "%s/%s.nivscf"      % {installDir, Target.Variables.BASE_NAME}, dict) end
    
    error = VSD.GenerateConfigurationJSON(HardwareConfig,Registry,installDir)
    if error ~= nil then return error end
end


function HW.RegisterHardwareResources(resources)
    local err, HardwareConfig, FcnName
    
    err, HardwareConfig = HW.GetHardwareConfig()
    if err~=nil then return err end
    
    --For each device, call function allocating resources
    for slot,device in pairs(HardwareConfig.slotProducts) do
        resources:add("Slot",slot)
        FcnName = "Add"..device:gsub('%-','')
        if MOD[FcnName]~=nil then
            MOD[FcnName](resources,slot)
        else
            return "Hardware Device " .. device .. " not supported"
        end
    end
 
    return nil
end

function HW.ClaimAssociatedPFIandDIO(hw,reg,req)
    --for signals entered as PFI
    function FromPFIClaimDIO(hw,block,req)
        local device = hw.slotProducts[block.slot]
        local FcnName = "Properties"..device:gsub('%-','')
        local port, line, channels
        if MOD[FcnName]~=nil then
            properties = MOD[FcnName]()
            if block.chSelect==1 and properties.DefaultCtrPFI~=nil then --Default counter PFI 
                channels = properties.DefaultCtrPFI[block.counterType][block.ctr+1]
            elseif block.chSelect==2 then --User specified counter PFI
                channels = block.channel
                if block.counterType=='edge' and block.direction == 3 then
                    table.insert(channels,block.dirChannel)
                end
            end
            if properties.MapDIOtoPFI ~= nil then
                for _,ch in ipairs(channels) do
                    if ch == ch and ch~=nil then  --check if nan
                        req:add(("Slot%i-PFI" % {block.slot} ), ch, ("%s/%s"%{Target.Variables.BASE_NAME,block.name})) --claim PFI
                        port,line=properties.MapPFItoDIO(ch)
                        if line~=nil and port~=nil then -- if nil then no mapping, do not claim
        	                req:add(("Slot%i-DigitalIO-Port%i" % {block.slot,port}),line,("%s/%s"%{Target.Variables.BASE_NAME,block.name}))
                        end
                    end
                end
            else
                --no mapping defined - assume independent
            end
        else
            return ("Module properties are missing for device %s." % {device})
        end
        return nil
    end
    
    --for signals entered as digital IO
    function FromDIOClaimPFI(hw,block,req)
        local device = hw.slotProducts[block.slot]
        local FcnName = "Properties"..device:gsub('%-','')
        local pfi
        if MOD[FcnName]~=nil then
            properties = MOD[FcnName]()
            if properties.MapPFItoDIO ~= nil then
                for _,ch in ipairs(block.channel) do
                    if ch==ch and ch~=nil then --check if nan
                        pfi=properties.MapDIOtoPFI(block.port,ch)
                        if pfi~=nil then-- if nil then no mapping, do not claim
                            req:add(("Slot%i-PFI" % {block.slot} ), pfi, ("%s/%s"%{Target.Variables.BASE_NAME,block.name}))
                        end
                    end
                end
            else
                --no mapping defined - assume independent
            end
        else
            return ("Module properties are missing for device %s." % {device})
        end
        return nil
    end

    local block,error
    if reg.NumDigitalInputs > 0 then
        for _,block in ipairs(reg.DigitalInputConfigs) do
            error = FromDIOClaimPFI(hw,block,req)
            if error~=nil then return error end
        end
    end
    if reg.NumDigitalOutputs > 0 then
        for _,block in ipairs(reg.DigitalOutputConfigs) do
            error = FromDIOClaimPFI(hw,block,req)
            if error~=nil then return error end
        end
    end
    if reg.NumCounterInputs > 0 then
        for _,block in ipairs(reg.CounterInputConfigs) do
            error = FromPFIClaimDIO(hw,block,req)
            if error~=nil then return error end
        end
    end
    if reg.NumCounterOutputs > 0 then
        for _,block in ipairs(reg.CounterOutputConfigs) do
            error = FromPFIClaimDIO(hw,block,req)
            if error~=nil then return error end
        end
    end
    return nil    
end

return HW
