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


local VSD = { }
local Utils = require('CoderUtils')
local MOD = require('CoderModules')
local json = require("dkjson")

function VSD.GenerateConfigurationJSON(hw,reg,dir)
    -- Generate JSON file that contain information for making the Veristand project.

    -- Registry
    local regJSON = json.encode( reg , {indent = true}) 
    local regFilePath = ( "%s/%s_reg.json" % {dir, Target.Variables.BASE_NAME})
    local file = io.open(regFilePath, "w+")
    if file==nil then
        return "Failure in generating Veristand configuration intermediate file " .. regFilePath
    else
        file:write(regJSON)
        io.close(file)
    end

    -- Hardware
    -- Append additional target information
    local aiMinMaxVal = Utils.ParseMinMaxEntry(Target.Variables.aiMinMaxVal)
    local aoMinMaxVal = Utils.ParseMinMaxEntry(Target.Variables.aoMinMaxVal)
    if aiMinMaxVal==nil then 
        return "Failure in parsing target min/max analog input entry: "..Target.Variables.aiMinMaxVal
    elseif aoMinMaxVal==nil then
        return "Failure in parsing target min/max analog output entry: "..Target.Variables.aoMinMaxVal
    end

    -- Some cards to not support
    hw['PXIBackplaneReferenceClock']={}
    for i,device in pairs(hw.slotProducts) do
        local FcnName = "Properties"..device:gsub('%-','')
        if MOD[FcnName]~=nil then
            properties = MOD[FcnName]()
            hw['PXIBackplaneReferenceClock'][i]=properties.PXIBackplaneReferenceClock
        end
    end
    
    hw['aiMinMaxVal']=aiMinMaxVal
    hw['aoMinMaxVal']=aoMinMaxVal
    hw['targRate'] = 1/Target.Variables.SAMPLE_TIME
    hw['targIP']=Target.Variables.targIP
    hw['targUserName']=Target.Variables.targUserName
    hw['targPassword']=Target.Variables.targPassword
   
    local hwJSON = json.encode( hw, {indent = true}) 
    local hwFilePath = ( "%s/%s_hw.json" % {dir, Target.Variables.BASE_NAME})
    local file = io.open(hwFilePath, "w+")
    if file==nil then
        return "Failure in generating Veristand configuration intermediate file " .. hwFilePath
    else
        file:write(hwJSON)
        io.close(file)
    end
    return nil
end

function VSD.CheckUsingDefaultCounterPins(reg)
    function CheckIfDefault(cfgs)
        for _,block in ipairs(cfgs) do
            if block.chSelect == 2 then
                return "Veristand Engine only supports default PFI channels for counters. Set counter " .. block.name .. " to use the default PFI channels."
            end
        end
        return nil
    end
    if reg.NumCounterInputs > 0 then
       error =  CheckIfDefault(reg.CounterInputConfigs) 
       if error~=nil then return error end
    end    
    if reg.NumCounterOutputs > 0 then
       error =  CheckIfDefault(reg.CounterOutputConfigs) 
       if error~=nil then return error end
    end    
    return nil
end


return VSD
