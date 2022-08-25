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

local DAQ = { }
local MOD = require('CoderModules')

function DAQ.SetupAnalogInputs(reg,cfg)
    local ret = '\n'
    local slot,slotName,sigName,portName,scaleName,chan,min,max,mode,scale,offset,dim
    local terminalConfigs = { "DAQmx_Val_Cfg_Default",
                              "DAQmx_Val_RSE",
                              "DAQmx_Val_NRSE",
                              "DAQmx_Val_Diff",
                              "DAQmx_Val_PseudoDiff"}

    for i,block in pairs(reg) do
        slotName = cfg.slotNames[block.slot]
        terminalConfig = terminalConfigs[block.mode]
        --Since each channel can have independent min/max, forced to create function call for each channel
        ret = ret .. "    /* Creating Analog Input channels for Block \""..block.name.."\"*/\n    {\n"
        for j,ch in pairs(block.channel) do
            portName = slotName .. "/ai"..ch
            sigName  = block.name.."_"..ch
            scaleName = sigName.."_Scale"
            offset = block.offset[j]
            scale = block.scale[j]
            min = block.min[j] * scale + offset
            max = block.max[j] * scale + offset
            --Channel limits are based on scaled values. Negative scales result in min>max which is not allowed.
            if min>max then
                min = block.max[j] * scale + offset
                max = block.min[j] * scale + offset
            end
            --Create scale
            ret = ret .. ("        DAQmxErrChk(DAQmxCreateLinScale(\"%s\",%f,%f,DAQmx_Val_Volts,\"\"));\n"%{scaleName,scale,offset})
            --Create channel
            ret = ret .. ("        DAQmxErrChk(DAQmxCreateAIVoltageChan(%s,\"%s\",\"%s\",%s,%f,%f,DAQmx_Val_FromCustomScale,\"%s\"));\n"%{block.task,portName,sigName,terminalConfig,min,max,scaleName})
        end
        ret = ret .. "    }\n"
    end
    return ret            
end

function DAQ.SetupAnalogOutputs(reg,cfg)
    local ret = '\n'
    local slot,slotName,sigName,scaleName,portName,chan,min,max,mode,scale,offset,dim

    for i,block in pairs(reg) do
        slotName = cfg.slotNames[block.slot]
        ret = ret .. "    /* Creating Analog Output channels for Block \""..block.name.."\"*/\n    {\n"
        --Since each channel can have independent min/max, forced to create function call for each channel
        for j,ch in pairs(block.channel) do
            portName = slotName .. "/ao"..ch
            sigName  = block.name.."_"..ch
            scaleName = sigName.."_Scale"
            offset = block.offset[j]
            scale = block.scale[j]
            min = block.min[j] * scale + offset
            max = block.max[j] * scale + offset
            --Channel limits are based on scaled values. Negative scales result in min>max which is not allowed.
            if min>max then
                min = block.max[j] * scale + offset
                max = block.min[j] * scale + offset
            end
            --Create scale
            ret = ret .. ("        DAQmxErrChk(DAQmxCreateLinScale(\"%s\",%f,%f,DAQmx_Val_Volts,\"\"));\n"%{scaleName,scale,offset})
            --Create channel
            ret = ret .. ("        DAQmxErrChk (DAQmxCreateAOVoltageChan(%s,\"%s\",\"%s\",%f,%f,DAQmx_Val_FromCustomScale,\"%s\"));\n"%{block.task,portName,sigName,min,max,scaleName})
        end
        ret = ret .. "    }\n"
    end
    return ret            
end


function DAQ.SetupDigitalOutputs(reg,cfg)
    local ret = '\n'
    local slot,slotName,chan,dim,lines

    for i,block in pairs(reg) do
        slotName = cfg.slotNames[block.slot]
        ret = ret .. "    /* Creating Digital Output channels for Block \""..block.name.."\"*/\n    {\n"
        lines = ''
        --Create one long string with all channels and remove trailing comma
        for j,ch in ipairs(block.channel) do
            lines = lines .. ("%s/port%d/line%d," % {slotName,block.port,ch})
        end
        lines = lines:sub(1,-2)
        --Create channel
        ret = ret .. ("        DAQmxErrChk (DAQmxCreateDOChan(%s,\"%s\",\"%s\",DAQmx_Val_ChanForAllLines));\n" % {block.task,lines,block.name})
        ret = ret .. "    }\n"
    end
    return ret            
end

function DAQ.SetupDigitalInputs(reg,cfg)
    local ret = '\n'
    local slot,slotName,chan,dim,lines

    for i,block in pairs(reg) do
        slotName = cfg.slotNames[block.slot]
        ret = ret .. "    /* Creating Digital Input channels for Block \""..block.name.."\"*/\n    {\n"
        lines = ''
        --Create one long string with all channels and remove trailing comma
        for j,ch in ipairs(block.channel) do
            lines = lines .. ("%s/port%d/line%d," % {slotName,block.port,ch})
        end
        lines = lines:sub(1,-2)
        --Create channel
        ret = ret .. ("        DAQmxErrChk (DAQmxCreateDIChan(%s,\"%s\",\"%s\",DAQmx_Val_ChanForAllLines));\n" % {block.task,lines,block.name})
        ret = ret .. "    }\n"
    end
    return ret            
end

function DAQ.SetupCounterOutputs(reg,cfg)
    local ret = '\n'
    local slot,slotName,chan,dim,lines,ctrName,pol,device

    for i,block in pairs(reg) do
        slotName = cfg.slotNames[block.slot]
        ctrName = slotName .. "/ctr" .. block.ctr
        device = cfg.slotProducts[block.slot]
        DutyMin,DutyMax,FreqMin,FreqMax = DAQ.GetCounterHWLimits(device,block.fc)
        if block.polarity==1 then
            pol = "DAQmx_Val_Low"
        else 
            pol = "DAQmx_Val_High"
        end
        ret = ret .. "    /* Creating Counter Output channels for Block \""..block.name.."\"*/\n    {\n"
        lines = ''
        --Create channel.  Note initial duty is hardcarded at 0.5, but updated before first execution.
        ret = ret .. ("        DAQmxErrChk (DAQmxCreateCOPulseChanFreq(%s,\"%s\",\"%s\",DAQmx_Val_Hz,%s,%f,%f,%3.9E));\n" % {block.task,ctrName,block.name,pol,block.ph/block.fc,block.fc,DutyMin})
        --If PFI Channel is specified
        if block.chSelect == 2 then
            for j,ch in ipairs(block.channel) do
                lines = lines .. ("/%s/PFI%d," % {slotName,ch}) 
            end
            lines = lines:sub(1,-2)
            ret = ret .. ("        DAQmxErrChk (DAQmxSetCOPulseTerm(%s,\"%s\",\"%s\"));\n" % {block.task,ctrName,lines})
        end
        ret = ret .. ("        DAQmxErrChk (DAQmxCfgImplicitTiming(%s,DAQmx_Val_ContSamps,1));\n" % {block.task}) --Implicit timing for clock generation
        ret = ret .. "    }\n"
    end
    return ret            
end

function DAQ.SetupCounterInputs(reg,cfg)
    local ret = '\n'
    local slot,slotName,chan,dim,lines,ctrName,indexMode,decoding,reset,edge,direction
    local indexModeLUT = {"DAQmx_Val_AHighBHigh","DAQmx_Val_AHighBLow","DAQmx_Val_ALowBHigh","DAQmx_Val_ALowBLow"}
    local decodingLUT = {"DAQmx_Val_X1","DAQmx_Val_X2","DAQmx_Val_X4","DAQmx_Val_TwoPulseCounting"} 
    local edgeLUT = {"DAQmx_Val_Rising","DAQmx_Val_Falling"}
    local directionLUT = {"DAQmx_Val_CountUp","DAQmx_Val_CountDown","DAQmx_Val_ExtControlled"}
    for i,block in ipairs(reg) do
        slotName = cfg.slotNames[block.slot]
        ctrName = slotName .. "/ctr" .. block.ctr
        if block.counterType=='position' then
            indexMode = indexModeLUT[block.indexMode]
            decoding = decodingLUT[block.decoding]
            reset = math.floor(block.reset-1) --0=freerunning, 1=index pulse
            --Create channel.  Note with Tick counting, PulsesPerRev is not used and is hardcoded as 1.
            ret = ret .. "    /* Creating Counter Input Position channels for Block \""..block.name.."\"*/\n    {\n"
            ret = ret .. ("        DAQmxErrChk (DAQmxCreateCIAngEncoderChan(%s,\"%s\",\"%s\",%s,%d,0.0,%s,DAQmx_Val_Ticks,1,0.0,NULL));\n" % {block.task,ctrName,block.name,decoding,reset,indexMode})
            --If PFI Channel is specified
            if block.chSelect==2 and #block.channel==3 then
                ret = ret .. ("        DAQmxErrChk (DAQmxSetCIEncoderAInputTerm(%s,\"%s\",\"/%s/PFI%d\"));\n" % {block.task,ctrName,slotName,block.channel[1]})
                ret = ret .. ("        DAQmxErrChk (DAQmxSetCIEncoderBInputTerm(%s,\"%s\",\"/%s/PFI%d\"));\n" % {block.task,ctrName,slotName,block.channel[2]})
                ret = ret .. ("        DAQmxErrChk (DAQmxSetCIEncoderZInputTerm(%s,\"%s\",\"/%s/PFI%d\"));\n" % {block.task,ctrName,slotName,block.channel[3]})
            end
            ret = ret .. "    }\n"
        elseif block.counterType=='edge' then
            edge = edgeLUT[block.edge]
            direction = directionLUT[block.direction]
            ret = ret .. "    /* Creating Counter Input Edge channels for Block \""..block.name.."\"*/\n    {\n"
            ret = ret .. ("        DAQmxErrChk (DAQmxCreateCICountEdgesChan(%s,\"%s\",\"%s\",%s,%d,%s));\n" % {block.task,ctrName,block.name,edge,block.init,direction})
            --If PFI Channel is specified
            if block.chSelect==2 then
                ret = ret .. ("        DAQmxErrChk (DAQmxSetCICountEdgesTerm(%s,\"%s\",\"/%s/PFI%d\"));\n" % {block.task,ctrName,slotName,block.channel[1]})
                if block.direction==3 and block.dirChannel == block.dirChannel then --assign terminal if not nan
                    ret = ret .. ("        DAQmxErrChk (DAQmxSetCICountEdgesDirTerm(%s,\"%s\",\"/%s/PFI%d\"));\n" % {block.task,ctrName,slotName,block.dirChannel})
                end
            end
            ret = ret .. "    }\n"
        elseif block.counterType=='period' then
            return "Counter type not implemented" --TODO:Proper error 
        elseif block.counterType=='frequency' then
            return "Counter type not implemented" --TODO:Proper error 
        else
            return "Counter type not implemented" --TODO:Proper error 
        end
    end
    return ret            
end

function DAQ.SetupDAQReadMap(reg,mgr,hw)

    function ReadAnalog(taskName,dim)
        return  ("    DAQmxErrChk(DAQmxReadAnalogF64(%s,1,RT_TIMEOUT,DAQmx_Val_GroupByChannel,ioSignals.%s,%i,NULL,NULL));\n" % {taskName,taskName,dim})
    end

    function ReadDigital(taskName,dim)
        return ("    DAQmxErrChk(DAQmxReadDigitalLines(%s,1,RT_TIMEOUT,DAQmx_Val_GroupByChannel,ioSignals.%s,%i,NULL,NULL,NULL));\n" % {taskName,taskName,dim})
    end

    function ReadCounterFloat(taskName,dim)
        return ("    DAQmxErrChk(DAQmxReadCounterF64(%s,1,RT_TIMEOUT,ioSignals.%s,%i,NULL,NULL));\n" % {taskName,taskName,dim})
    end

    function ReadCounterInt(taskName,dim)
        return ("    DAQmxErrChk(DAQmxReadCounterU32(%s, 1, RT_TIMEOUT, ioSignals.%s, %i, NULL, NULL));\n" %{taskName,taskName,dim})
    end

    local ret = '\n'
    local read ='\n'
    local map = '\n'
    local AnalogInputCount = 0
    local DigitalInputCount = 0
    local CounterInputCount = 0
    local BlockInputCount = 0
    local dim = 0
    ret = ret .. "   //Pack input signals for models (daq->model)\n"

    --Read inputs
    for _,task in ipairs(mgr.HardwareTaskList) do
        dim = mgr.HardwareTaskDims[task]
        if DAQ.CheckTaskType(task)=="AI"  then
            read = read .. ReadAnalog(task,dim)
        elseif DAQ.CheckTaskType(task)=="DI" then
            read = read .. ReadDigital(task,dim)
        elseif DAQ.CheckTaskType(task)=="CI" then
            local counterType = DAQ.CheckCounterType(task)
            if counterType=="edge" or counterType == "position" then
                read = read .. ReadCounterInt(task,dim)
            elseif counterType == "frequency" or counterType=="period" then
                read = read .. ReadCounterFloat(task,dim)
            end
        end
    end
    for _,task in ipairs(mgr.SoftTaskList) do
        dim = mgr.SoftTaskDims[task]
        if DAQ.CheckTaskType(task)=="AI"  then
            read = read .. ReadAnalog(task,dim)
        elseif DAQ.CheckTaskType(task)=="DI" then
            read = read .. ReadDigital(task,dim)
        elseif DAQ.CheckTaskType(task)=="CI" then
            read = read .. ReadCounter(task,dim)
        end
    end

    --Map data
    if reg.NumAnalogInputs > 0 then
        for _,block in ipairs(reg.AnalogInputConfigs) do
            --reset block input count for soft tasks
            if string.find(block.task,"Soft")~=nil then
                AnalogInputCount=0
            end
            for _chan in ipairs(block.channel) do
                map = map .. ("    inData[%i] = ioSignals.%s[%i];\n" % {BlockInputCount,block.task,AnalogInputCount})
                AnalogInputCount = AnalogInputCount + 1
                BlockInputCount = BlockInputCount + 1
            end
        end
    end

    if reg.NumDigitalInputs > 0 then
        for _,block in ipairs(reg.DigitalInputConfigs) do
            --reset block input count for soft tasks
            if string.find(block.task,"Soft")~=nil then
                DigitalInputCount=0
            end
            for _,chan in ipairs(block.channel) do
                map = map .. ("    inData[%i] = (double)ioSignals.%s[%i];\n" % {BlockInputCount,block.task,DigitalInputCount})
                DigitalInputCount = DigitalInputCount + 1
                BlockInputCount = BlockInputCount + 1
            end
        end
    end
    
    if reg.NumCounterInputs > 0 then
        for _,block in ipairs(reg.CounterInputConfigs) do
            --reset block input count for soft tasks
            if string.find(block.task,"Soft")~=nil then
                CounterInputCount=0
            end
            for j,chan in ipairs(block.ctr) do
                --cast req'd. depending on counter type.  intermediate cast to signed int is to better handle negative counts
                if block.counterType == 'edge' or block.counterType =='position' then
                    map = map .. ("    inData[%i] = (double)(int32_t)ioSignals.%s[%i];\n" % {BlockInputCount,block.task,DigitalInputCount}) 
                else
                    map = map .. ("    inData[%i] = ioSignals.%s[%i];\n" % {BlockInputCount,block.task,DigitalInputCount}) 
                end
                CounterInputCount = CounterInputCount + 1
                BlockInputCount = BlockInputCount + 1
            end
        end
    end

    ret = ret .. read .. map
    return ret
end

function DAQ.SetupDAQWriteMap(reg,mgr,hw)

    function WriteAnalog(taskName)
        return  ("    DAQmxErrChk(DAQmxWriteAnalogF64(%s,1, FALSE, RT_TIMEOUT, DAQmx_Val_GroupByChannel,ioSignals.%s, NULL, NULL));\n" % {taskName,taskName} )
    end

    function WriteDigital(taskName)
        return ("    DAQmxErrChk(DAQmxWriteDigitalLines(%s,1,1,RT_TIMEOUT,DAQmx_Val_GroupByChannel,ioSignals.%s,NULL,NULL));\n" %{taskName,taskName} )
    end

    function WriteCounter(taskName)
        return ("    DAQmxErrChk(DAQmxWriteCtrFreq(%s,1,1,RT_TIMEOUT,DAQmx_Val_GroupByChannel,ioSignals.%sFreq,ioSignals.%sDuty,NULL,NULL));\n" %{taskName,taskName,taskName} )
    end

    local ret = '\n'
    local write ='\n'
    local map = '\n'
    local FirstRegisteredBlockName = ''
    local AnalogOutputCount = 0
    local DigitalOutputCount = 0
    local CounterOutputCount = 0
    local BlockOutputCount = 0
    
    ret = ret .. "   //Unpack output values from model (model->daq)\n"

    --Write outputs
    for _,task in ipairs(mgr.HardwareTaskList) do
        if DAQ.CheckTaskType(task)=="AO"  then
            write = write .. WriteAnalog(task)
        elseif DAQ.CheckTaskType(task)=="DO" then
            write = write .. WriteDigital(task)
        elseif DAQ.CheckTaskType(task)=="CO" then
            write = write .. WriteCounter(task)
        end
    end
    for _,task in ipairs(mgr.SoftTaskList) do
        if DAQ.CheckTaskType(task)=="AO"  then
            write = write .. WriteAnalog(task)
        elseif DAQ.CheckTaskType(task)=="DO" then
            write = write .. WriteDigital(task)
        elseif DAQ.CheckTaskType(task)=="CO" then
            write = write .. WriteCounter(task)
        end
    end

    if reg.NumAnalogOutputs > 0 then
        for _,block in ipairs(reg.AnalogOutputConfigs) do
            for j,chan in ipairs(block.channel) do
                --Soft tasks iterate different from common hardware task
                --Signal must be within DAQ channel limits, hence fmin/fmax
                if string.find(block.task,"Soft")~=nil then
                    map = map .. ("    ioSignals.%s[%i] = fmin(fmax(outData[%i],%f),%f);\n"%{block.task,j-1,BlockOutputCount,block.min[j],block.max[j]})
                else
                    map = map .. ("    ioSignals.%s[%i] = fmin(fmax(outData[%i],%f),%f);\n"%{block.task,AnalogOutputCount,BlockOutputCount,block.min[j],block.max[j]})
                    AnalogOutputCount = AnalogOutputCount + 1
                end
                BlockOutputCount = BlockOutputCount + 1
            end
        end
    end

    if reg.NumDigitalOutputs > 0 then
        for _,block in ipairs(reg.DigitalOutputConfigs) do
            --Soft tasks iterate different from common hardwarre task
            --Signal must be 0 or 1, hence && operator
            for j,chan in ipairs(block.channel) do
                if string.find(block.task,"Soft")~=nil then
                    map = map .. ("    ioSignals.%s[%i] = (uint8_t)(outData[%i] && 1);\n"%{block.task,j-1,BlockOutputCount}) 
                else
                    map = map .. ("    ioSignals.%s[%i] = (uint8_t)(outData[%i] && 1);\n"%{block.task,DigitalOutputCount,BlockOutputCount}) 
                    DigitalOutputCount = DigitalOutputCount + 1
                end
                BlockOutputCount = BlockOutputCount + 1
            end
        end
    end

    if reg.NumCounterOutputs > 0 then
        local Counts,DutyMax,DutyMin,device,FcnName,properties,CounterClkFreq,CountMax,CountMin,FreqMax,FreqMin,PolarityOffsetString
        for _,block in ipairs(reg.CounterOutputConfigs) do
            device = hw.slotProducts[block.slot] --HW product
            for j,chan in ipairs(block.channel) do
                DutyMin,DutyMax,FreqMin,FreqMax = DAQ.GetCounterHWLimits(device,block.fc)
                if block.polarity==1 then --Active logic 1
                    PolarityOffsetString = ("")
                else                      --Active logic 0 
                    PolarityOffsetString = ("1.0 -")
                end
                if string.find(block.task,"Soft")~=nil then
                    map = map .. ("    ioSignals.%sDuty[%i] = fmin(fmax(%E,%s outData[%i]),%3.9E);\n"%{block.task,j-1,DutyMin,PolarityOffsetString,BlockOutputCount+0,DutyMax}) 
                    map = map .. ("    ioSignals.%sFreq[%i] = fmin(fmax(%E,outData[%i]),%3.9E);\n"%{block.task,j-1,FreqMin,BlockOutputCount+0,FreqMax}) 
                else
                    map = map .. ("    ioSignals.%sDuty[%i] = fmin(fmax(%E,%s outData[%i]),%3.9E);\n"%{block.task,CounterOutputCount+0,DutyMin,PolarityOffsetString,BlockOutputCount+0,DutyMax}) 
                    map = map .. ("    ioSignals.%sFreq[%i] = fmin(fmax(%E,outData[%i]),%3.9E);\n"%{block.task,CounterOutputCount+0,FreqMin,BlockOutputCount+1,FreqMax})
                    CounterOutputCount = CounterOutputCount + 1
                end
                BlockOutputCount = BlockOutputCount + 2
            end
        end
    end


    ret = ret .. map .. write
    return ret
end

function DAQ.GetPortTotals(cfgs)
    local ret = 0
    for i, cfg in pairs(cfgs) do
        ret = ret + cfg.dim
    end
    return ret
end

function DAQ.ConfigureTasks(reg,hw)
    local mgr = {
        MasterTask = nil,       --The master task for multidevice triggering
        HardwareTaskList = {},  --List of tasks with hardware/multidevice triggering
        SoftTaskList = {},      --List of devices with software triggering
        HardwareTaskDims = {},  --Dimension for each signal read in the slave task
        SoftTaskDims = {},      --Dimension for each signal read in the soft task
        SoftwareTimerFlag = 0, --Use Software Trigger. HW trigger = 0, SW trigger = 1
        MasterTaskSlotName = "",
        HardwareTaskSlotNames = {},
        SoftwareTaskSlotNames = {},
        HardwareTaskProducts = {},
        SoftwareTaskProducts = {},
        ClockSource = '',
        ClockRate = 0,
        SignalEventID = ''      --Signal event used in DAQmxRegisterSignalEvent
    }

    local properties, device
    local error=nil

    function ParseBlockTasks(cfgs,hw,mgr,taskNameStub,sigType)

        function HasValue(tbl,val)
            ret = false
            for i,k in ipairs(tbl) do
                if k==val then
                    ret = true
                end
            end
            return  ret
        end

        local device,FcnName,taskName,slotHardwareTiming,portHardwareTiming,acceptableMasterTask,taskType,slotName


        for id,block in ipairs(cfgs) do
            device = hw.slotProducts[block.slot]
            FcnName = "Properties"..device:gsub('%-','')
            taskName = taskNameStub
            softTaskName=taskName..'Soft'..id
            slotHardwareTiming = false
            portHardwareTiming = false
            acceptableMasterTask = false

            if MOD[FcnName]~=nil then
                --Get HW properties.
                properties = MOD[FcnName]()

                slotHardwareTiming = properties.MultideviceTaskSupport
                slotName = hw.slotNames[block.slot]

                taskType = DAQ.CheckTaskType(taskName)

                --For digital signals determine if port supports hardware timing
                if taskType=='DO' or taskType=='DI' then
                    if block.port ~=nil then
                        for _,port in ipairs(properties.WaveformDIO) do
                            if port==block.port then
                                portHardwareTiming=true
                            end
                        end
                    end
                else --non DO ports do not have similar limitations
                    portHardwareTiming=true
                end

                --Counter inputs must each be placed into own tasks.
                if taskType=='CI' then
                    taskName = taskName .. block.counterType .. id
                end

                --ai/ao are always acceptable master tasks
                --di/do are acceptable if the port supports hardware timing
                --Counter outputs can only be master task if same as base sample rate.
                --Counter inputs can never be master task
                if (slotHardwareTiming and portHardwareTiming and taskType~='CI' and taskType~='CO') then
                    acceptableMasterTask=true
                elseif ( taskType =='CO' and (math.abs(block.fc - 1/Target.Variables.SAMPLE_TIME) < (1.0/10.0e6))) then
                    --1/10e6 is for 10 MHz PXI_Clk10
                    acceptableMasterTask=true
                end

                --Make Master Task if none
                if acceptableMasterTask and mgr.MasterTask==nil then
                    mgr.MasterTask = taskName
                    mgr.MasterTaskSlotName = slotName
                end

                if (slotHardwareTiming and portHardwareTiming) then -- add to hardware task
                    if HasValue(mgr.HardwareTaskList,taskName) then -- add to existing
                        mgr.HardwareTaskDims[taskName] = mgr.HardwareTaskDims[taskName] + block.dim
                    else -- new task
                        if mgr.MasterTask==taskName then --add to beginning
                            table.insert(mgr.HardwareTaskList,1,taskName)
                            table.insert(mgr.HardwareTaskProducts,1,properties.Series)
                        else --add to end
                            table.insert(mgr.HardwareTaskList,taskName)
                            table.insert(mgr.HardwareTaskProducts,properties.Series)
                        end
                        mgr.HardwareTaskDims[taskName] = block.dim
                        mgr.HardwareTaskSlotNames[taskName] = slotName
                    end
                    block['task']=taskName
                else --make soft task.  Each soft task matches source block
                    table.insert(mgr.SoftTaskList,softTaskName)
                    table.insert(mgr.SoftwareTaskProducts,properties.Series)
                    mgr.SoftTaskDims[softTaskName]=block.dim
                    block['task']=softTaskName
                    mgr.SoftwareTaskSlotNames[taskName] = slotName
                end
            else
                return  nil
            end
        end
        return mgr
    end


    --make task associated with each type of output.
    --master task always first task in hardware task list
    if reg.NumAnalogInputs > 0 then
        ParseBlockTasks(reg.AnalogInputConfigs,hw,mgr,'taskHandleAI')
    end
    if reg.NumDigitalInputs > 0 then
        ParseBlockTasks(reg.DigitalInputConfigs,hw,mgr,'taskHandleDI')
    end
    if reg.NumAnalogOutputs > 0 then
        ParseBlockTasks(reg.AnalogOutputConfigs,hw,mgr,'taskHandleAO')
    end
    if reg.NumDigitalOutputs > 0 then
        ParseBlockTasks(reg.DigitalOutputConfigs,hw,mgr,'taskHandleDO')
    end
    --Counters at end since do not support master task type
    if reg.NumCounterInputs > 0 then
        ParseBlockTasks(reg.CounterInputConfigs,hw,mgr,'taskHandleCI')
    end
    if reg.NumCounterOutputs > 0 then
        ParseBlockTasks(reg.CounterOutputConfigs,hw,mgr,'taskHandleCO')
    end

    --Cannot find master task, assign to software triggering
    if mgr.MasterTask==nil then
        mgr.SoftwareTimerFlag = 1
        if reg.NumCounterInputs > 0 then
            error = "Counter inputs require a separate Sample Clock input for timing purposes." .. 
                    " Adding an Analog In, Analog Out, or Digital IO with Waveform support to the schematic will automatically generate an appropriate Sample Clock."
            return error, mgr
        end
    end
    --DIO cannot use DAQmx_Val_SampleCompleteEvent.  Assign sample clock
    if DAQ.CheckTaskType(mgr.MasterTask)=='AI' then
        mgr.SignalEventID = 'DAQmx_Val_SampleCompleteEvent'
    elseif DAQ.CheckTaskType(mgr.MasterTask)=='CO'  then
        mgr.SignalEventID = 'DAQmx_Val_CounterOutputEvent'
    elseif mgr.MasterTask==nil then
        mgr.SignalEventID = ''
    else
        mgr.SignalEventID = 'DAQmx_Val_SampleClock'
    end

    --Find Clock Source for hardware timed tasks
    local XSeriesCount = 0
    local MSeriesCount = 0
    for _,product in ipairs(mgr.HardwareTaskProducts) do
        if product=='X' then XSeriesCount = XSeriesCount+1 end
        if product=='M' then MSeriesCount = MSeriesCount+1 end
    end

    --Force PXI_Clk10 since PXIe_Clk100 not routed on test device
    mgr.ClockSource = 'PXI_Clk10'  --10 MHz clock
    mgr.ClockRate = 10e6

    return error,mgr
end

function DAQ.TaskHandleList(mgr)
    local ret='\n'
    for _,task in ipairs(mgr.HardwareTaskList) do
        ret = ret .. ("static TaskHandle %s=0;\n"%{task})
    end
    for _,task in ipairs(mgr.SoftTaskList) do
        ret = ret .. ("static TaskHandle %s=0;\n"%{task})
    end
    return ret
end

function DAQ.ClearTasks(mgr)
    local ret = '\n'
    --reverse parse since master always first task in Hardware Task List
    for i=#mgr.SoftTaskList,1,-1 do
		ret = ret .. ('		StopAndClearTask(%s);\n'%{mgr.SoftTaskList[i]});
    end
    for i = #mgr.HardwareTaskList,1,-1 do
		ret = ret .. ('		StopAndClearTask(%s);\n'%{mgr.HardwareTaskList[i]});
    end
    return ret
end

function DAQ.RTLateTasks(mgr)
    --Only relevant for hardware timed tasks
    local ret = '\n'
    for i = #mgr.HardwareTaskList,1,-1 do
		ret = ret .. ('	DAQmxErrChk (DAQmxSetRealTimeConvLateErrorsToWarnings(%s,RTLATE_ERROR_OR_WARN));\n'%{mgr.HardwareTaskList[i]});
    end
    return ret
end

function DAQ.StartTasks(mgr)
    local ret = '\n'
    --reverse parse since master always first task in Hardware Task List
    for i=#mgr.SoftTaskList,1,-1 do
		ret = ret .. ('	DAQmxErrChk (DAQmxStartTask(%s));\n'%{mgr.SoftTaskList[i]})
    end
    for i = #mgr.HardwareTaskList,1,-1 do
		ret = ret .. ('	DAQmxErrChk (DAQmxStartTask(%s));\n'%{mgr.HardwareTaskList[i]})
    end
    return ret
end

function DAQ.CreateTasks(mgr)
    local ret = '\n'
    for i=1,#mgr.HardwareTaskList do
		ret = ret .. ('	DAQmxErrChk(DAQmxCreateTask("%s", &%s));\n'% {mgr.HardwareTaskList[i],mgr.HardwareTaskList[i]})
    end
    for i=1,#mgr.SoftTaskList do
		ret = ret .. ('	DAQmxErrChk(DAQmxCreateTask("%s", &%s));\n'% {mgr.SoftTaskList[i],mgr.SoftTaskList[i]})
    end
    return ret
end

function DAQ.ConfigTaskTiming(reg,mgr,freq)
    local ret = '\n'
    local smpl = ''
    local clk = ''
    local taskName,sampleClockSource,startTrigger,signalID,block,ctr

    if mgr.MasterTask ~= nil then
        --Determine sample clock
        if DAQ.CheckTaskType(mgr.MasterTask)=="CO" then --CO does not use sample clock timing. Must find counter # for mapping
            for _,block in ipairs(reg.CounterOutputConfigs) do
                if block.task==mgr.MasterTask then
                    ctr=block.ctr
                end
            end
            sampleClockSource=("Ctr%dInternalOutput" % {ctr})
            startTrigger=("Ctr%dGate" % {ctr})
            signalID ="DAQmx_Val_CounterOutputEvent"
        else --AI,AO,DI,DO use sample clock.
            sampleClockSource=("%s/SampleClock" % {string.lower(DAQ.CheckTaskType(mgr.MasterTask))})
            startTrigger=("%s/StartTrigger" % {string.lower(DAQ.CheckTaskType(mgr.MasterTask))})
            smpl = smpl .. ("	DAQmxErrChk(DAQmxCfgSampClkTiming(%s,\"\",%f,DAQmx_Val_Rising,DAQmx_Val_HWTimedSinglePoint,1)); //Master Task\n" 
                    % {mgr.MasterTask,freq} )
            signalID ="DAQmx_Val_SampleClock"
        end

        --Master Task
        smpl = smpl .. ("    DAQmxErrChk (GetTerminalNameWithDevPrefix(%s,\"%s\",sampleClockName)); //For setting up triggers on other devices\n" 
                        % {mgr.MasterTask,sampleClockSource} )
        smpl = smpl .. ("    DAQmxErrChk (GetTerminalNameWithDevPrefix(%s,\"%s\",startTriggerName)); //For setting up triggers on other devices\n" 
                        % {mgr.MasterTask,startTrigger})
        smpl = smpl .. ("    printf(\"Trigger Name: %%s, SampleClockName: %%s\\n\",startTriggerName,sampleClockName);\n") 

        -- Sample clock output on PXI_Trig0.
        -- Note on ConnectTerms vs. ExportSignal calls.  ConnectTerms needs to be explicity disconnected.  ExportSignal automatically disconnects at end, but does not seem to work with counter0 due to resource conflict. 
        smpl = smpl .. ("    //DAQmxErrChk(DAQmxConnectTerms (sampleClockName, \"/%s/PXI_Trig0\",DAQmx_Val_DoNotInvertPolarity ));\n" % {mgr.MasterTaskSlotName}) 
        smpl = smpl .. ("    DAQmxErrChk(DAQmxExportSignal (%s, %s, \"/%s/PXI_Trig0\"));\n" % {mgr.MasterTask,signalID,mgr.MasterTaskSlotName}) 

        -- Hardware timed slave tasks 
        for i = 2,#mgr.HardwareTaskList do
            taskName = mgr.HardwareTaskList[i]
            if DAQ.CheckTaskType(taskName)~='CO' then --Counter outputs use implicit timing
                smpl = smpl .. ("	DAQmxErrChk(DAQmxCfgSampClkTiming(%s,\"/%s/PXI_Trig0\",%f,DAQmx_Val_Rising,DAQmx_Val_HWTimedSinglePoint,1)); //Slave Task\n" 
                        % {taskName,mgr.HardwareTaskSlotNames[taskName],freq} )
            elseif DAQ.CheckTaskType(taskName)=='CO' then --Counter output start trigger for synchronization
                smpl = smpl .. ("    DAQmxErrChk(DAQmxCfgDigEdgeStartTrig(%s,startTriggerName,DAQmx_Val_Rising));" % {taskName})
            end
        end
        --Software timed tasks do not have timing configured - free running.
    end			
    ret = ret .. smpl .. "\n" ..clk 
    return ret
end

function DAQ.SetupTasks(mgr)
    local ret = '\n'
    if mgr.MasterTask~=nil then
	    ret = ret .. ("	DAQmxErrChk (DAQmxRegisterSignalEvent(%s,%s,0,SignalCallback,NULL));\n"%{mgr.MasterTask,mgr.SignalEventID})
	    ret = ret .. "	printf(\"DAQmxRegisterSignalEvent Done ...\\n\");\n"
        ret = ret .. ("	DAQmxErrChk (DAQmxRegisterDoneEvent(%s,0,DoneCallback,NULL));\n"%{mgr.MasterTask})
        ret = ret .. "	printf(\"DAQmxRegisterDoneEvent Done\\n\");\n"
    else
        ret = ret.. "   //No master task - timing handled in software"
    end
    return ret
end

function DAQ.CleanupTerminalConnections(mgr)
    local ret = '\n'
    if mgr.MasterTask~=nil then -- See previous comment on ConnectTerms vs. ExportSignal.
        ret = ret .. ("    //DAQmxErrChk(DAQmxDisconnectTerms(sampleClockName, \"/%s/PXI_Trig0\" ));\n" % {mgr.MasterTaskSlotName}) 
    end
    return ret
end

function DAQ.IODataFormat(mgr)
    function GetDataType(taskName)
        local taskType = DAQ.CheckTaskType(taskName)
        local counterType = ''
        if taskType=="AI" or taskType == "AO" or taskType=="CO" then 
            return "float64"
        elseif taskType=="DI" or taskType == "DO" then
            return "uInt8"
        elseif taskType=="CI" then
            counterType = DAQ.CheckCounterType(taskName)
            if counterType=="edge" or counterType == "position" then
                return "uInt32"
            elseif counterType == "frequency" or counterType=="period" then
                return "float64"
            end
        end
        return nil
    end    
    local ret = '\n'
    
    local task
    for i=1,#mgr.HardwareTaskList do
        task = mgr.HardwareTaskList[i]
        if DAQ.CheckTaskType(task)~='CO' then
		    ret = ret .. ('	%s %s[%d];\n' % {GetDataType(task),task,mgr.HardwareTaskDims[task]})
        else --Counter requires two fields - claim two in hardware dims, hence divide by 2
		    ret = ret .. ('	%s %sDuty[%d];\n' % {GetDataType(task),task,mgr.HardwareTaskDims[task]/2}) 
		    ret = ret .. ('	%s %sFreq[%d];\n' % {GetDataType(task),task,mgr.HardwareTaskDims[task]/2})
        end
    end
    for i=1,#mgr.SoftTaskList do
        task = mgr.SoftTaskList[i]
        if DAQ.CheckTaskType(task)~='CO' then
		    ret = ret .. ('	%s %s[%d];\n' % {GetDataType(task),task,mgr.SoftTaskDims[task]})
        else --Counter requires two fields - claim two in hardware dims, hence divide by 2
		    ret = ret .. ('	%s %sDuty[%d];\n' % {GetDataType(task),task,mgr.SoftTaskDims[task]/2})
		    ret = ret .. ('	%s %sFreq[%d];\n' % {GetDataType(task),task,mgr.SoftTaskDims[task]/2}) 
        end
    end
    return ret
end

function DAQ.CheckTaskType(taskName)
    local ret
    if taskName==nil then 
        ret = "" --No master task assigned
    elseif string.find(taskName,"AI")~=nil then
        ret = "AI"
    elseif string.find(taskName,"AO")~=nil then 
        ret = "AO"
    elseif string.find(taskName,"DI")~=nil then
        ret = "DI"
    elseif string.find(taskName,"DO")~=nil then
        ret = "DO"
    elseif string.find(taskName,"CI")~=nil then
        ret = "CI"
    elseif string.find(taskName,"CO")~=nil then
        ret = "CO"
    else
        ret = "" --No master task assigned
    end
    return ret
end

function DAQ.CheckCounterType(taskName)
    local ret
    if taskName==nil then 
        ret = "" --error
    elseif string.find(taskName,"edge")~=nil then
        ret = "edge"
    elseif string.find(taskName,"position")~=nil then 
        ret = "position"
    elseif string.find(taskName,"period")~=nil then
        ret = "period"
    elseif string.find(taskName,"frequency")~=nil then
        ret = "frequency"
    else
        ret = "" --error
    end
    return ret
end

function DAQ.GetCounterHWLimits(device,fc)
    --Note: 
    --  device is hw properties (hw.slotProducts[block.slot])
    --  fc is frequency of counter
    local Counts,DutyMax,DutyMin,FcnName,properties,CounterClkFreq,CountMax,CountMin,FreqMax,FreqMin
    --Counter properties
    FcnName = "Properties"..device:gsub('%-','')
    if MOD[FcnName]~=nil then
        properties = MOD[FcnName]()
        CountMin = 4
        CountMax = 2^(properties.CounterBitResolution)-1
        CounterClkFreq = properties.ClkFreqMax
    else --Assume 32 bit and 100 MHz.
        CountMin = 4
        CountMax = 2^32-1 
        CounterClkFreq = 100e6
    end
    FreqMax = CounterClkFreq/CountMin
    FreqMin = 2*CounterClkFreq/CountMax
    Counts = math.floor(CounterClkFreq/fc-1)
    DutyMin = 2/Counts
    DutyMax = 1-DutyMin
    return DutyMin,DutyMax,FreqMin,FreqMax
end

return DAQ
