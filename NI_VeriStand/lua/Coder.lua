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

local Coder = { }

local Utils = require('CoderUtils')
local Veristand = require('CoderVeristand')
local HW = require('CoderHW')

local Registry = {
    NumInports = 0,
    InportConfigs={},
    NumOutports = 0,
    OutportConfigs={},
    SlotList = {},
    NumSlots = 0,
    SlotConfigs = {},
    NumAnalogInputs = 0,
    AnalogInputConfigs = {},
    NumAnalogOutputs = 0,
    AnalogOutputConfigs = {},
    NumDigitalInputs = 0,
    DigitalInputConfigs = {},
    NumDigitalOutputs = 0,
    DigitalOutputConfigs = {},
    NumCounterOutputs = 0,
    CounterOutputConfigs = {},
    NumCounterInputs = 0,
    CounterInputConfigs = {},
}

function Coder.GetInstallDir()
   local installDir

    installDir = Target.Variables.installDir:gsub('%"+', ''):gsub('\\+','/') -- remove quotes, make all forward slashes
    local tempDir = Target.Variables.BUILD_ROOT:gsub('%"+', ''):gsub('\\+','/') 
    if installDir..Target.Variables.BASE_NAME.."_codegen" == tempDir then -- when installDir entry is blank, returns current path
        installDir = Target.Variables.BUILD_ROOT --  use default codegen dir if installDir is blank
    end
    return installDir
end

function Coder.RegisterInport(params)
    local ret = Registry.NumInports + 1
    Registry.NumInports = ret
    Registry.InportConfigs[ret]=params
    return ret
end

function Coder.RegisterOutport(params)
    local ret = Registry.NumOutports + 1
    Registry.NumOutports = ret
    Registry.OutportConfigs[ret]=params
    return ret
end

function Coder.RegisterAnalogInput(params)
    local ret = Registry.NumAnalogInputs + 1
    Registry.NumAnalogInputs = ret
    --Pack scalars into tables to make iteration consistent
    if params.dim == 1 then
        params.offset = {params.offset}
        params.scale  = {params.scale}
        params.channel = {params.channel}
        params.min = {params.min}
        params.max = {params.max}
    end
    --Force ints
    params.slot = math.floor(params.slot)
    params.mode = math.floor(params.mode)
    for i,k in ipairs(params.channel) do 
        params.channel[i]=math.floor(k) 
    end
    --Add min/max values
    local minmax = Utils.ParseMinMaxEntry(Target.Variables.aiMinMaxVal)
    if minmax==nil then 
       return "Failure in parsing target 'Analog input voltage range' setting: "..Target.Variables.aiMinMaxVal
    end
    for i = 1,params.dim do
        if params.min==nil or params.min[i]<minmax[1] then params.min[i]=minmax[1] end
        if params.max==nil or params.max[i]>minmax[2] then params.max[i]=minmax[2] end
    end
    --assign
    Registry.AnalogInputConfigs[ret]=params
    --Take note if this is a new slot
    if Registry.SlotList[params.slot]==nil then
        Registry.SlotList[params.slot]=true
        Registry.NumSlots = Registry.NumSlots+1
    end
    return ret
end

function Coder.RegisterAnalogOutput(params)
    local ret = Registry.NumAnalogOutputs + 1
    Registry.NumAnalogOutputs = ret
    --Pack scalars into tables to make iteration consistent
    if params.dim == 1 then
        params.offset = {params.offset}
        params.scale  = {params.scale}
        params.channel = {params.channel}
        params.min = {params.min}
        params.max = {params.max}
    end
    --Force ints
    params.slot = math.floor(params.slot)
    for i,k in ipairs(params.channel) do 
        params.channel[i]=math.floor(k) 
    end
    --Add min/max values
    local minmax = Utils.ParseMinMaxEntry(Target.Variables.aoMinMaxVal)
    if minmax==nil then 
       return "Failure in parsing target 'Analog output voltage range' setting: "..Target.Variables.aoMinMaxVal
    end
    for i = 1,params.dim do
        if params.min==nil or params.min[i]<minmax[1] then params.min[i]=minmax[1] end
        if params.max==nil or params.max[i]>minmax[2] then params.max[i]=minmax[2] end
    end
    --assign    
    Registry.AnalogOutputConfigs[ret]=params
    --Take note if this is a new slot
    if Registry.SlotList[params.slot]==nil then
        Registry.SlotList[params.slot]=true
        Registry.NumSlots = Registry.NumSlots+1
    end
    return ret
end

function Coder.RegisterDigitalInput(params)
    local ret = Registry.NumDigitalInputs + 1
    Registry.NumDigitalInputs = ret
    --Pack scalars into tables to make iteration consistent
    if params.dim == 1 then
        params.channel = {params.channel}
    end
    --Force ints
    params.slot = math.floor(params.slot)
    params.port = math.floor(params.port-1)
    for i,k in ipairs(params.channel) do 
        params.channel[i]=math.floor(k) 
    end
    Registry.DigitalInputConfigs[ret]=params
    --Take note if this is a new slot
    if Registry.SlotList[params.slot]==nil then
        Registry.SlotList[params.slot]=true
        Registry.NumSlots = Registry.NumSlots+1
    end
    return ret
end

function Coder.RegisterDigitalOutput(params)
    local ret = Registry.NumDigitalOutputs + 1
    Registry.NumDigitalOutputs = ret
    --Pack scalars into tables to make iteration consistent
    if params.dim == 1 then
        params.channel = {params.channel}
    end
    --Force ints
    params.slot = math.floor(params.slot)
    params.port = math.floor(params.port-1)
    for i,k in ipairs(params.channel) do 
        params.channel[i]=math.floor(k) 
    end
    Registry.DigitalOutputConfigs[ret]=params
    --Take note if this is a new slot
    if Registry.SlotList[params.slot]==nil then
        Registry.SlotList[params.slot]=true
        Registry.NumSlots = Registry.NumSlots+1
    end
    return ret
end

function Coder.RegisterCounterOutput(params)
    local ret = Registry.NumCounterOutputs + 1
    Registry.NumCounterOutputs = ret
    --Pack scalars into tables to make iteration consistent
    if #params.channel == 1 then
        params.channel = {params.channel}
    end
    --Force ints
    params.slot = math.floor(params.slot)
    for i,k in ipairs(params.channel) do 
        params.channel[i]=math.floor(k)
    end
    params.polarity = math.floor(params.polarity)
    Registry.CounterOutputConfigs[ret]=params
    --Take note if this is a new slot
    if Registry.SlotList[params.slot]==nil then
        Registry.SlotList[params.slot]=true
        Registry.NumSlots = Registry.NumSlots+1
    end
    return ret
end

function Coder.RegisterCounterInput(params)
    local ret = Registry.NumCounterInputs + 1
    Registry.NumCounterInputs = ret
    --Pack scalars into tables to make iteration consistent
    if #params.channel == 1 then
        params.channel = {params.channel}
    end
    --Force ints
    params.slot = math.floor(params.slot)
    for i,k in ipairs(params.channel) do 
        params.channel[i]=math.floor(k) 
    end
    if params.decoding  ~= nil then params.decoding   =math.floor(params.decoding)    end
    if params.indexMode ~= nil then params.indexMode  =math.floor(params.indexMode)   end
    if params.reset     ~= nil then params.reset      =math.floor(params.reset)       end
    if params.dirChannel~= nil then params.dirChannel =math.floor(params.dirChannel)  end
    if params.direction ~= nil then params.direction  =math.floor(params.direction)   end
    if params.edge      ~= nil then params.edge       =math.floor(params.edge)        end
    Registry.CounterInputConfigs[ret]=params
    --Take note if this is a new slot
    if Registry.SlotList[params.slot]==nil then
        Registry.SlotList[params.slot]=true
        Registry.NumSlots = Registry.NumSlots+1
    end
    return ret
end

function Coder.Initialize()
    local Resources = ResourceList:new()
    local error
    
    --Parse allocate hardware resources if not targeting VM
    if Target.Variables.buildType ~= 3 then
        error = HW.RegisterHardwareResources(Resources)
        if error ~=nil then return error end
    end

    return {
        Resources = Resources
    }
end

function Coder.Finalize()

    local Include = StringList:new()
    local Require = ResourceList:new()
    local HeaderDeclarations = StringList:new()
    local Declarations = StringList:new()
    local PreInitCode = StringList:new()
    local PostInitCode = StringList:new()
    local TerminateCode = StringList:new()
    local error, HardwareConfig
    local VeriStandMajorVersion, VeriStandMinorVersion, VeriStandProductVersion


    -------------------------------------------------------------------------------- 
    --  Output file targets
    -------------------------------------------------------------------------------- 
    local installDir
    if Target.Variables.codegenFlag == '1' then
        installDir = Coder.GetInstallDir()
        if not Utils.FileExists(installDir.."/") then
            return "The directory '%s' does not exist." % {installDir}
        end
    else
        installDir = Target.Variables.BUILD_ROOT
    end

    -------------------------------------------------------------------------------- 
    --  Configure Hardware Mapping
    -------------------------------------------------------------------------------- 
    
    --Parse hardware configuration files if not targeting VM
    if Target.Variables.buildType ~= 3 then
        error, HardwareConfig = HW.GetHardwareConfig()
        if error~=nil then return error end
        for slot,_ in pairs(Registry.SlotList) do
            if HardwareConfig.slotNums[slot]==nil then
                return "PXI chassis slot " .. slot .. " is used but not specified in the hardware configuration file."
            end
        end
        error  = HW.ClaimAssociatedPFIandDIO(HardwareConfig,Registry,Require)
        if error~=nil then return error end

        --TODO: Check analog inputs if differential vs. single-ended.  Impacts # of HW resources available on certain X series cards

        --Check analog ranges specified
        local minmax
        minmax = Utils.ParseMinMaxEntry(Target.Variables.aiMinMaxVal)
        if minmax==nil then 
           return "Failure in parsing target 'Analog input voltage range' setting: "..Target.Variables.aiMinMaxVal
        elseif minmax[1]>=minmax[2] then
           return "The 'Analog input voltage range' minimum value exceeds the specified maximum value " .. Target.Variables.aiMinMaxVal
        end
        minmax = Utils.ParseMinMaxEntry(Target.Variables.aoMinMaxVal)
        if minmax==nil then 
           return "Failure in parsing target 'Analog output voltage range' setting: "..Target.Variables.aoMinMaxVal
        elseif minmax[1]>=minmax[2] then
            return "The 'Analog output voltage range' minimum value exceeds the specified maximum value " .. Target.Variables.aoMinMaxVal
        end
    end

    --Create inports and outports for each hardware IO (ordered)
    error = HW.SetupHardwareModelPorts(Registry)
    if error~=nil then return error end

    --Veristand engine map IO to signal inports and outports
    if Target.Variables.buildType == 1 then
        error = HW.ConfigureVeristandProject(HardwareConfig,Registry,installDir)
    --Custom engine using DAQmx to map io
    elseif Target.Variables.buildType == 2 then
        error = HW.ConfigureDAQmx(HardwareConfig,Registry,installDir)
    --Model only
    elseif Target.Variables.buildType == 3 then
        --continue
    else
        error = "Invalid Build Type"
    end
    if error~=nil then return error end

    -------------------------------------------------------------------------------- 
    --  Generate code for compiled model (*.so, *.dll)
    -------------------------------------------------------------------------------- 
       
    local DataTypeNum2StrLookup ={"bool", "uint8_t", "int8_t", "uint16_t", "int16_t", "uint32_t", "int32_t", "float", "double", "double"}

    -- Add the generated BASE_NAME_plx.h file which inclues the Parameters structure.
    Include:append(Target.Variables.BASE_NAME..'_plx.h')   

    -- For signals
    Declarations:append("/* Extern to signal attributes from BASE_NAME_ni.c */\n")
    Declarations:append("extern NI_Signal rtSignalAttribs[];\n")

    --For external mode
    if(Target.Variables.EXTERNAL_MODE ~= 0) then
        HeaderDeclarations:append('#define EXTERNAL_MODE 1\n')
    else
        HeaderDeclarations:append('#undef EXTERNAL_MODE\n')
    end
    
    --Reference global parameter structure within the generated code. 
    Declarations:append("/* Extern to parameters structures from ni_modelframework.c */\n")
    Declarations:append("extern Parameters rtParameter[2];\n")
    Declarations:append("extern int32_t READSIDE;\n")
    Declarations:append("#define readParam rtParameter[READSIDE]\n")
    
    error = Veristand.SetupVeristandSignalsUpdates(PostInitCode)
    if error~=nil then return error end

    error = Veristand.SetupVeristandStructs(HeaderDeclarations,Registry,DataTypeNum2StrLookup)
    if error~=nil then return error end

    error = Veristand.GenerateIncHeader(installDir,DataTypeNum2StrLookup)
    if error~=nil then return error end

    error = Veristand.GenerateWrapper(installDir,Registry,DataTypeNum2StrLookup)
    if error~=nil then return error end

    error, VeriStandMajorVersion, VeriStandMinorVersion, VeriStandProductVersion =  Veristand.GetVeriStandVersion(Target.Variables.VeriStandVersion)
    if error~=nil then return error end

    if Target.Variables.codegenFlag == '1' then  --Only generating code, not making.
        local dict = {}
        table.insert(dict, {before = "|>BASE_NAME<|", after = Target.Variables.BASE_NAME})
        table.insert(dict, {before = "|>INSTALL_DIR<|", after = installDir})
        
        Utils.CopyTemplateFile(Target.Variables.TARGET_ROOT .. "/templates/install.mk", Target.Variables.BUILD_ROOT .. "/" .. Target.Variables.BASE_NAME .. ".mk", dict)
        Utils.CopyTemplateFile(Target.Variables.TARGET_ROOT .. "/templates/basename_cg.h", installDir .. "/basename_cg.h", dict)
    else
        local codegenDir = Target.FamilySettings.ExternalTools.niOecoreToolchainDir:gsub('%"+', ''):gsub('\\+','/') -- remove quotes, make all forward slashes
        if not Utils.FileExists(codegenDir) then
           return "NI toolchain directory '%s' not found." % {codegenDir}
        end

        local DAQmxLibDir = Target.FamilySettings.ExternalTools.DAQmxLibDir:gsub('%"+', ''):gsub('\\+','/') -- remove quotes, make all forward slashes
        if Target.Variables.buildType == 2 and (not Utils.FileExists(DAQmxLibDir)) then
           return "DAQmx ANSI C support directory '%s' not found. Reference required for Custom Engine.\nIf you do not have the files in that location, be sure you selected 'ANSI C support' as an item to install when installing NI-DAQmx drivers on your PC. If the files are in a different directory refer to the 'NI Software Requirements' section of the TSP documentation." % {DAQmxLibDir}
           end

        local VeriStandx86InstallDir = Target.FamilySettings.ExternalTools.VeriStandx86InstallDir:gsub('%"+', ''):gsub('\\+','/') -- remove quotes, make all forward slashes
        local VeriStandx64InstallDir = Target.FamilySettings.ExternalTools.VeriStandx64InstallDir:gsub('%"+', ''):gsub('\\+','/') -- remove quotes, make all forward slashes
        --if directories blank, assume default paths
        if VeriStandx64InstallDir=='' then
            VeriStandx64InstallDir="C:/Program Files/National Instruments/VeriStand "..VeriStandMajorVersion
        end
        if VeriStandx86InstallDir=='' then
            if tonumber(VeriStandMajorVersion)<2021 then
                VeriStandx86InstallDir="C:/Program Files (x86)/National Instruments/VeriStand "..VeriStandMajorVersion               
            else
                VeriStandx86InstallDir=VeriStandx64InstallDir
            end
        end
        local VeriStandx86ASAMDir= VeriStandx86InstallDir.."/nivs.lib/Reference Assemblies"

        if Target.Variables.buildType==1 then
            if (not Utils.FileExists(VeriStandx86InstallDir)) then
               return "VeriStand x86 install directory '%s' not found.  Reference required to build a project for the VeriStand Engine. Confirm the desired 'VeriStand version' target setting and installation directory." % {VeriStandx86InstallDir}
            elseif (not Utils.FileExists(VeriStandx64InstallDir)) then
               return "VeriStand x64 install directory '%s' not found.  Reference required to build a project for the VeriStand Engine. Confirm the desired 'VeriStand version' target setting and installation directory." % {VeriStandx64InstallDir}
            elseif (not Utils.FileExists(VeriStandx86ASAMDir)) then
               return "VeriStand x86 install directory '%s' does not contain required assemblies." % {VeriStandx86ASAMDir}
            end
        end

        local VeriStandAssemblyVersion
        if VeriStandMajorVersion=="2019" then
            VeriStandAssemblyVersion="7.0.0.0"
        elseif VeriStandMajorVersion=="2020" then
            VeriStandAssemblyVersion="8.0.0.0"
        elseif VeriStandMajorVersion=="2021" then
            VeriStandAssemblyVersion="9.0.0.0"
        end

        --Custom engine file transfer settings
        local SSHCommand, SCPCommand
        if (Target.Variables.buildType ~= 2) or (Target.Variables.targKeyAuth ~= '0') then 
            -- Using Model Only, Veristand, or Custom Engine with SSH key based auth (openSSH)
            SSHCommand = "$(OPENSSH_PATH)\\ssh -T -v" % {Target.Variables.targUserName,Target.Variables.targIP} 
            SCPCommand = "$(OPENSSH_PATH)\\scp" 
        else
            -- Using Custom Engine with less secure command line passwords (PuTTY)
            -- Sanitize for makefile. Quotes around pw for command line compatibility.
            local TargetPasswordSanitized =Target.Variables.targPassword
            TargetPasswordSanitized = string.gsub(TargetPasswordSanitized,'[%$]', '%0%0')  -- $ -> $$
            TargetPasswordSanitized = string.gsub(TargetPasswordSanitized,'[%%]', '%0%0%0%0') -- Lua S&R requirement
            TargetPasswordSanitized = string.gsub(TargetPasswordSanitized,'[#"]', '\\%0') -- # --> \# 
            SSHCommand = "echo y | $(PUTTY_PATH)\\plink -ssh -batch -pw \"%s\"" % {TargetPasswordSanitized} 
            SCPCommand = "echo y | $(PUTTY_PATH)\\pscp -scp -pw \"%s\"" % {TargetPasswordSanitized}
        end

        local dict = {}
        table.insert(dict, {before = "|>BASE_NAME<|", after = Target.Variables.BASE_NAME})
        table.insert(dict, {before = "|>TARGET_ROOT<|", after = Target.Variables.TARGET_ROOT})
        table.insert(dict, {before = "|>TOOLCHAIN_ROOT<|", after = codegenDir})
        table.insert(dict, {before = "|>BUILD_ROOT<|", after = installDir:gsub('%"+', ''):gsub('/+','\\') })-- remove quotes, make all backwards slashes (Veristand req.)
        table.insert(dict, {before = "|>TARGET_USER_NAME<|", after = Target.Variables.targUserName})
        table.insert(dict, {before = "|>TARGET_IP_ADDRESS<|", after = Target.Variables.targIP})
        table.insert(dict, {before = "|>SSH_CMD<|", after = SSHCommand})
        table.insert(dict, {before = "|>SCP_CMD<|", after = SCPCommand})
        table.insert(dict, {before = "|>DAQMX_LIB_DIR<|", after = DAQmxLibDir})
        table.insert(dict, {before = "|>VS_x86_INSTALL_DIR<|", after = VeriStandx86InstallDir})
        table.insert(dict, {before = "|>VS_x64_INSTALL_DIR<|", after = VeriStandx64InstallDir})
        table.insert(dict, {before = "|>VS_x86_ASAM_DIR<|"   , after = VeriStandx86ASAMDir})
        table.insert(dict, {before = "|>VS_VERSION_MAJOR<|",after = VeriStandMajorVersion}) --portconfig.xml
        table.insert(dict, {before = "|>VS_VERSION_MINOR<|",after = VeriStandMinorVersion}) --portconfig.xml
        table.insert(dict, {before = "|>VS_PRODUCT_VERSION<|",after = VeriStandProductVersion}) --testbench creation
        table.insert(dict, {before = "|>VS_ASSEMBLY_VERSION<|",after = VeriStandAssemblyVersion}) --dll assembly versions
          
        Utils.CopyTemplateFile(Target.Variables.TARGET_ROOT .. "/templates/submake_model.mk", Target.Variables.BUILD_ROOT .. "/" .. Target.Variables.BASE_NAME .. "_model.mk", dict)
        if Target.Variables.buildType == 1 then --VeriStand engine
            Utils.CopyTemplateFile(Target.Variables.TARGET_ROOT .. "/templates/build_model_veristand.mk", Target.Variables.BUILD_ROOT .. "/" .. Target.Variables.BASE_NAME .. ".mk", dict)
            Utils.CopyTemplateFile(Target.Variables.TARGET_ROOT .. "/templates/vprj.xml", Target.Variables.BUILD_ROOT .. "/" .. Target.Variables.BASE_NAME .. "_portconfig.xml", dict)  
            Utils.CopyTemplateFile(Target.Variables.TARGET_ROOT .. "/templates/app.config", Target.Variables.TARGET_ROOT .. "/tools/dnettools/plx-asam-xil-tool.exe.config", dict)  
        elseif Target.Variables.buildType == 2 then --Custom engine
            Utils.CopyTemplateFile(Target.Variables.TARGET_ROOT .. "/templates/submake_engine.mk", Target.Variables.BUILD_ROOT .. "/" .. Target.Variables.BASE_NAME .. "_engine.mk", dict)  
            Utils.CopyTemplateFile(Target.Variables.TARGET_ROOT .. "/templates/build_model_engine.mk", Target.Variables.BUILD_ROOT .. "/" .. Target.Variables.BASE_NAME .. ".mk", dict)
        elseif Target.Variables.buildType == 3 then --Model only (no download)
            Utils.CopyTemplateFile(Target.Variables.TARGET_ROOT .. "/templates/build_model.mk", Target.Variables.BUILD_ROOT .. "/" .. Target.Variables.BASE_NAME .. ".mk", dict)
        end
    end
    
    return {
        Include = Include,
        Require = Require,
        Declarations = Declarations,
        HeaderDeclarations = HeaderDeclarations,
        PreInitCode = PreInitCode,
        PostInitCode = PostInitCode,
        TerminateCode = TerminateCode
    }
end

return Coder


