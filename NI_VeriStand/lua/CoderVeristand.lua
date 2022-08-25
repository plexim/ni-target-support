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

local Utils = require('CoderUtils')

local V = { }

function V.SetupVeristandStructs(HeaderDeclarations,Registry,DataTypeNum2StrLookup)
    -- Define Input, output, and signal structs and include them in the model header.
    -- The structs are referenced both by the step() function and the NI framework.

    -- For printing formatted variable types for inport/outport structs e.g. double In1
    local function SetupIOStructDeclarations(dec,cfgs)
        for _,params in ipairs(cfgs) do
            --{dim = dim, name = name, dataType = dataType}
            local name = Utils.MakeValidCName(params["name"])
            local dim = params["dim"]
            local dataType = params["dataType"]
            local dataTypeString = DataTypeNum2StrLookup[dataType]
            if dim==1 then
                dec:append("    %s %s;\n" % {dataTypeString,name})
            else
                dec:append("    %s %s[%i];\n" % {dataTypeString,name,dim})
            end 

        end
    end


	function SetupSignalStructDeclaration(dec)
		--Signals are not vectorized. Requires parsing signal names to determine common source and then vectorizing.
		for _,extsig in ipairs(Model["ExtModeSignals"]) do
            local blockPath = extsig["BlockPath"] 
			for _,plot in ipairs(extsig["Plots"]) do
				for i,signal in ipairs(plot["Signals"]) do
                     --Include blockpath and trace # (i) since cannot guarantee individual signal names are unique.
					local name = Utils.MakeValidCName("%s_%d_%s" % {blockPath, i, signal["Name"]})
					local dataType = signal["OrigDataType"]
					dec:append("    %s %s;\n" % {dataType ,name})
				end
			end
		end
	end

    HeaderDeclarations:append("/* Define Inport, Outport, and Signals structs */\n")

    -- Inports struct
    HeaderDeclarations:append("typedef struct {\n")
    SetupIOStructDeclarations(HeaderDeclarations,Registry.InportConfigs)
    HeaderDeclarations:append("} Inports;\n")
    HeaderDeclarations:append("\n")

    -- Outports struct
    HeaderDeclarations:append("typedef struct {\n")
    SetupIOStructDeclarations(HeaderDeclarations,Registry.OutportConfigs)
    HeaderDeclarations:append("} Outports;\n")
    HeaderDeclarations:append("\n")

    -- signals -- 
    HeaderDeclarations:append("typedef struct {\n")
    SetupSignalStructDeclaration(HeaderDeclarations)
	HeaderDeclarations:append("} Signals;\n\n")

    -- Static declaration of inports, outports, and signals with fixed names
    HeaderDeclarations:append("/* Create reference to external declaration of IO and Signals */\n")
    HeaderDeclarations:append("extern Inports  rtInport;\n")
    HeaderDeclarations:append("extern Outports rtOutport;\n")
    HeaderDeclarations:append("extern Signals  rtSignal;\n")
    HeaderDeclarations:append("\n")

    return nil
end

function V.SetupVeristandSignalsUpdates(PostInitCode)

	PostInitCode:append("/*Initialize signal addresses*/\n")

	local sigOffset = 0
	for _,extsig in ipairs(Model["ExtModeSignals"]) do
		for _,plot in ipairs(extsig["Plots"]) do
			for _,signal in ipairs(plot["Signals"]) do
				local symbol = signal["Symbol"]
				PostInitCode:append("   rtSignalAttribs[%i].addr = (uintptr_t)%s;\n" % {sigOffset ,symbol})
				sigOffset=sigOffset+1
			end
		end
	end

    return nil
end



function V.GenerateWrapper(installDir,Registry, DataTypeNum2StrLookup)
	-- Remap datatype table to go from datatype string ("double") to number (8)
	local DataTypeStr2NumLookup = {}
	for k,v in ipairs(DataTypeNum2StrLookup) do
	   DataTypeStr2NumLookup[v]=k
	end

    --Local Helper Functions for Inport and Export Config
    local function SetupExtList(reg)
        local function SetupRtIOAttribs(cfgs,io)
            local ret = ""
            local error = nil
            for i,params in ipairs(cfgs) do
                local name = ("%s_(%i)"%{Utils.MakeValidVeristandName(params.name),i-1}) --Add port order ID
                local dim = params.dim
                if io == 'Inport' then
                    ret = ret .. ("    {0, \"%s\", 0, 0, 1, %i, 1},\n" % {name,dim}) -- define all along the x dimension
                elseif io == 'Outport' then
                    ret = ret .. ("    {0, \"%s\", 0, 1, 1, %i, 1},\n" % {name,dim}) -- define all along the x dimension
                else
                    error = ("Error in DLL generation. Invalid IO type for signal %s in SetupRtIOAttribs()." % {params.name})
                end
            end
            return error, ret
        end

        local ret = ''
        local error, inports,outports

        error,inports = SetupRtIOAttribs(reg.InportConfigs,"Inport")
        if error~=nil then return error,inports end

        error,outports = SetupRtIOAttribs(reg.OutportConfigs,"Outport")
        if error~=nil then return error,outports end

        ret = ("\n%s%s    { -1 },\n" %{inports,outports})

        return error,ret
    end

    local function SetupMapIndataInport(cfgs)
        local ret = "\n"
		local inDataIdx=0
        local error = nil

        for i,params in ipairs(cfgs) do
            local name = Utils.MakeValidCName(params.name)
	    	local dim  = params.dim
            local dataTypeString = DataTypeNum2StrLookup[params.dataType]
	    	if dim == 1 then
                ret = ret .. ("		rtInport.%s = inData[%i];\n" % {name,inDataIdx})
                inDataIdx=inDataIdx+1
                --ret = ret .. ("		rtInport.%s = (%s)((%s*)(inData+offsetof(Inports,%s)))[0];\n" % {name,dataTypeString,dataTypeString,name})
    	    elseif dim>1 then
			    for j = 0,(dim-1) do
                    ret = ret .. ("		rtInport.%s[%i] = inData[%i];\n" % {name,j,inDataIdx})
                    inDataIdx=inDataIdx+1
                    --ret = ret .. ("		rtInport.%s[%i] = (%s)((%s*)(inData+offsetof(Inports,%s)))[%i];\n" % {name,j,dataTypeString,dataTypeString,name,j})
			    end
	    	else
				error = ("Error in DLL generation. Invalid signal dimension for signal %s in SetupMapIndataInport()" % {params.name})
            end
        end
        return error, ret
    end

    local function SetupMapOutdataOutport(cfgs)
        local ret = "\n"
		local outDataIdx=0
        local error = nil

        for _,params in ipairs(cfgs) do
            local name = Utils.MakeValidCName(params.name)
	    	local dim  = params.dim
            local dataTypeString = DataTypeNum2StrLookup[params.dataType]

	    	if dim == 1 then
        	    ret = ret .. ("		outData[%i] = rtOutport.%s;\n" % {outDataIdx,name})
                outDataIdx=outDataIdx+1
        	    --ret = ret .. ("		((%s*)(outData+offsetof(Outports,%s)))[0] = rtOutport.%s;\n" % {dataTypeString,name,name})
    		elseif dim>1 then
				for j = 0,(dim-1) do
        	        ret = ret .. ("		outData[%i] = rtOutport.%s[%i];\n" % {outDataIdx,name,j})
                    outDataIdx=outDataIdx+1
        	        --ret = ret .. ("		((%s*)(outData+offsetof(Outports,%s)))[%i] = rtOutport.%s[%i];\n" % {dataTypeString,name,j,name,j})
				end
	    	else
				error = ("Error in DLL generation. Invalid signal dimension for signal %s in SetupMapOutdataOutport()" % {params.name})
            end
        end
        return error,ret
    end

	function SetupSigList()
		local ret = '\n'
		local sigDimOffset=0

		for _,extsig in ipairs(Model["ExtModeSignals"]) do
			for _,plot in ipairs(extsig["Plots"]) do
				local signalNameList = {}
				for i,signal in ipairs(plot["Signals"]) do
					local blockName = Utils.MakeValidVeristandName(extsig["BlockPath"])
					local signalName = Utils.MakeValidVeristandName(signal["Name"])
					local dataType = DataTypeStr2NumLookup[signal["OrigDataType"]]
					--Check if signal name in list and append unique ID if common.
					if signalNameList[signalName]~=nil then
						signalName=signalName.."_"..tostring(i)
					end
					ret = ret .. ("    { 0, \"%s\", 0, \"%s\", 0, 0, %i, 1, 2, %i, 0},\n" % {blockName,signalName,dataType,sigDimOffset})
					sigDimOffset=sigDimOffset+2 -- for NXN matrix
					signalNameList[signalName]=signalName
				end
			end
		end
		return ret
	end

	function SetupSigDimList()
		local ret = '\n'
		for _,extsig in ipairs(Model["ExtModeSignals"]) do
			for _,plot in ipairs(extsig["Plots"]) do
				for _,signal in ipairs(plot["Signals"]) do
			    	ret = ret .. ("    1,1,         /* %s */\n" % {Utils.MakeValidVeristandName(extsig["BlockPath"] .."/"..signal["Name"])})
				end
			end
		end
		return ret
	end

    function SetupParamList()
        local ret = '\n'
        local paramDimOffset=0
        local error = nil
        for i,param in ipairs(Model["ExtModeParameters"]) do
            local name = ("%s/%s_(%i)"%{Utils.MakeValidVeristandName(param["BlockPath"]),param["Symbol"],i-1})
            local symbol = param["Symbol"]
            local dataTypeString = param["OrigType"]
            local dataType = DataTypeStr2NumLookup[dataTypeString] 
            local dimensions = param["Dimensions"]
            local dim = 1
            -- Parameters be fixed as NxN.  It is possible that Veristand supports higher dimensions.
            if #dimensions==0 then      --scalar
                dim = 1
            elseif #dimensions==1 then  --vector
                dim=dimensions[1] 
            elseif #dimensions==2 then  --matrix
                dim=dimensions[1]*dimensions[2]
            else 
                error = ("Error in DLL generation. Only 2-dimensional tunable parameters are supported by the Veristand target support package. Parameter %s/%s has %d dimensions." % {param["BlockPath"],param["Symbol"],#dimensions} ) 
                return error,ret
            end
            ret = ret .. ("    { 0, \"%s\", offsetof(Parameters, %s), %i, %i, 2, %i, 0},\n"%{name,symbol,dataType,dim,paramDimOffset})
            paramDimOffset=paramDimOffset+2 -- for NXN matrix
        end
        if V.GenerateChecksumCondition() then
            local checksumName = "Model_checksum"
            local checksumDataType =Target.Variables.checksumDataType
            local checksumLength =Target.Variables.checksumLength 
            ret = ret .. ("    { 0, \"%s/PLECS/%s\", offsetof(Parameters, %s), %i, %i, 2, %i, 0},\n"%{Target.Variables.BASE_NAME,checksumName,checksumName,checksumDataType,checksumLength,paramDimOffset})
        end
        return error,ret
    end

    function SetupParamDimList()
        local ret = '\n'
        local error = nil
        for _,param in ipairs(Model["ExtModeParameters"]) do
            local dimensions = param["Dimensions"]
            local name = Utils.MakeValidVeristandName(param["BlockPath"]).."/"..param["Symbol"]
            --The parameters are fixed as NxN.  It is possible that Veristand supports higher dimensions.
            local dimx, dimy
            if #dimensions==0 then      --scalar
                dimx=1
                dimy=1
            elseif #dimensions==1 then  --vector
                dimx=dimensions[1]
                dimy=1
            elseif #dimensions==2 then  --matrix
                dimx=dimensions[1]
                dimy=dimensions[2]
            else 
                error = ("Error in DLL generation. Only 2-dimensional tunable parameters are supported by the Veristand target support package. Parameter %s/%s has %d dimensions." % {param["BlockPath"],param["Symbol"],#dimensions} ) 
                return error,ret
            end
            ret = ret .. ("    %i,%i,        /* %s */\n"%{dimx,dimy,name})
        end
        if V.GenerateChecksumCondition() then
            ret = ret .. ("    %i,1,        /* checksum */\n" % {Target.Variables.checksumLength})
        end        
        return error, ret
    end

    function SetupDefaultParams()
        local ret = '\n'
        local error = nil

        for _,param in ipairs(Model["ExtModeParameters"]) do
            local name = Utils.MakeValidVeristandName(param["BlockPath"]).."/"..param["Symbol"]
            local default = param["Default"]
            local dimensions = param["Dimensions"]
            local dataTypeString = param["OrigType"]
            local dataType = DataTypeStr2NumLookup[dataTypeString] 
            local value = ''
            local groupedDim = ''

            if #dimensions==0 then      --scalar
                error, value = HandleInfValues(default,dataType)
                ret = ret .. "    %s,\t\t\t/* %s */\n" % {value,name}
            elseif #dimensions==1 then  --vector
                for _,d in ipairs(default) do
                    error, value = HandleInfValues(d,dataType)
                    groupedDim = groupedDim .. value .. " ,"
                end
                ret = ret .. "    {%s},\t\t\t/* %s */\n" % {groupedDim,name}
            elseif #dimensions==2 then  --matrix
                groupedDim = groupedDim .. "\n"
                for _,drow in ipairs(default) do
                    groupedDim = groupedDim .. "        {"
                    for _,dcol in ipairs(drow) do
                        error, value = HandleInfValues(dcol,dataType)
                        groupedDim = groupedDim .. value .. " ,"
                    end
                    groupedDim = groupedDim .. "},\n"
                end
                ret = ret .. "    {%s    },\t\t\t/* %s */\n" % {groupedDim,name}
            else 
                error = ("Error in DLL generation. Only 2-dimensional tunable parameters are supported by the Veristand target support package. Parameter %s/%s has %d dimensions." % {param["BlockPath"],param["Symbol"],#dimensions} ) 
                return error,ret
            end
        end
        if V.GenerateChecksumCondition() then        
            ret = ret .. "    {0x00000000,0x00000000,0x00000000,0x00000000,0x00000000}, /* checksum */\n"
        end
        return error, ret
    end
    
    function SetupDefaultParamSizes()
        local ret = '\n    { sizeof(initParams)},\n'
        local error = nil

        for _,param in ipairs(Model["ExtModeParameters"]) do
            local name = Utils.MakeValidVeristandName(param["BlockPath"]).."/"..param["Symbol"]
            local dataTypeString = param["OrigType"]
            local dataType = DataTypeStr2NumLookup[dataTypeString] 
            local dimensions = param["Dimensions"]
            local dim = 1
            --The parameters are fixed as NxN.  It is possible that Veristand supports higher dimensions.
            if #dimensions==0 then      --scalar
                dim = 1
            elseif #dimensions==1 then  --vector
                dim=dimensions[1] 
            elseif #dimensions==2 then  --matrix
                dim=dimensions[1]*dimensions[2]
            else 
                error = ("Error in DLL generation. Only 2-dimensional tunable parameters are supported by the Veristand target support package. Parameter %s/%s has %d dimensions." % {param["BlockPath"],param["Symbol"],#dimensions} ) 
                return error,ret
            end
            ret = ret .. ("    { sizeof(%s), %i, %i},\n"%{dataTypeString,dim,dataType})
        end
        if V.GenerateChecksumCondition() then
            local checksumDataTypeString = DataTypeNum2StrLookup[math.floor(Target.Variables.checksumDataType)] 
            ret = ret .. ("    { sizeof(%s), %i, %i}, /* checksum */\n" % {checksumDataTypeString,Target.Variables.checksumLength,Target.Variables.checksumDataType})
        end
        return error, ret
    end

    function HandleInfValues(value,dataType)
        local ret = ''
        local error
        --    1     2           3           4           5           6           7       8        9          10
        -- {"bool", "uint8_t", "int8_t", "uint16_t", "int16_t", "uint32_t", "int32_t", "float", "double", "double"}
        local dataType2Limit = {"BOOL","UINT8","INT8","UINT16","INT16","UINT32","INT32","FLT","DBL","DBL"}

        if value==math.huge then --max
            if dataType==1 then --Handle bool seperately
                ret = '1'
            elseif dataType2Limit[dataType]~=nil then
                ret = dataType2Limit[dataType].."_MAX"
            else
                error = ("Error in determining parameter max limit for data type %d." % {dataType})
            end
        elseif value==-math.huge then --min
            if dataType==1 then --Handle bool seperately
                ret = '0'
            elseif dataType2Limit[dataType]~=nil then
                ret = dataType2Limit[dataType].."_MIN"
            else
                error = ("Error in determining parameter min limit for data type %d." % {dataType})
            end
        else
            ret = tostring(value)
        end
        return error, ret
    end

    --Substitution in Template Files
    local dict = {}
    local error, ret

    --Pre Initialization
    table.insert(dict, {before = "|>USER_PRE_INITIALIZE<|", after = V.ParseChecksum() }) 
 
    --General variables
    table.insert(dict, {before = "|>BASE_NAME<|", after = Target.Variables.BASE_NAME})
    table.insert(dict, {before = "|>INSTALL_DIR<|", after = installDir})
    table.insert(dict, {before = "|>BUILDER_NAME<|", after = ("PLECS " .. Target.Variables.PLECS_VERSION .. " CodeGen " .. Target.Name .. " " .. Target.Version)})
    table.insert(dict, {before = "|>SAMPLE_TIME<|", after = Target.Variables.SAMPLE_TIME})

    -- Substitutions for Signal Inports and Outports
    table.insert(dict, {before = "|>INPORT_SIZE<|", after =  Registry.NumInports})
    table.insert(dict, {before = "|>OUTPORT_SIZE<|", after =  Registry.NumOutports})
    table.insert(dict, {before = "|>EXT_LIST_SIZE<|", after =  (Registry.NumInports+Registry.NumOutports)})

    error,ret = SetupExtList(Registry)
    if error~=nil then return error end
    table.insert(dict, {before = "|>EXT_LIST<|", after = ret })

    error,ret = SetupMapIndataInport(Registry.InportConfigs)
    if error~=nil then return error end
    table.insert(dict, {before = "|>MAP_INDATA_INPORT<|"  , after = ret})

    error,ret = SetupMapOutdataOutport(Registry.OutportConfigs)
    if error~=nil then return error end
    table.insert(dict, {before = "|>MAP_OUTDATA_OUTPORT<|", after = ret})

    -- Substitutions for Signals
    table.insert(dict, {before = "|>SIG_LIST_SIZE<|", after = Model["NumExtModeSignals"] })
    table.insert(dict, {before = "|>SIG_LIST<|", after = SetupSigList() })
    table.insert(dict, {before = "|>SIG_DIM_LIST<|", after = SetupSigDimList() })

    -- Substitutions for Parameters
    local NumExtModeParameters =  #Model["ExtModeParameters"]
    if V.GenerateChecksumCondition() then
        NumExtModeParameters = NumExtModeParameters + 1   --+1 for checksum
    end
    table.insert(dict, {before = "|>PARAM_LIST_SIZE<|", after = tostring(NumExtModeParameters)}) 

    error,ret = SetupParamList()
    if error~=nil then return error end
    table.insert(dict, {before = "|>PARAM_LIST<|", after = ret }) 

    error,ret = SetupParamDimList() 
    if error~=nil then return error end
    table.insert(dict, {before = "|>PARAM_DIM_LIST<|", after = ret }) 

    error,ret = SetupDefaultParams()
    if error~=nil then return error end
    table.insert(dict, {before = "|>DEFAULT_PARAMS<|", after = ret }) 

    error,ret = SetupDefaultParamSizes() 
    if error~=nil then return error end
    table.insert(dict, {before = "|>DEFAULT_PARAM_SIZES<|", after = ret }) 

    Utils.CopyTemplateFile(Target.Variables.TARGET_ROOT .. "/templates/nimodel.c", Target.Variables.BUILD_ROOT .. "/" .. Target.Variables.BASE_NAME .. "_ni.c", dict)
    Utils.CopyTemplateFile(Target.Variables.TARGET_ROOT .. "/templates/nimodel.h", Target.Variables.BUILD_ROOT .. "/" .. Target.Variables.BASE_NAME .. "_ni.h", dict)

    return nil
end

function V.GenerateIncHeader(installDir,DataTypeNum2StrLookup)
    dest=Target.Variables.BUILD_ROOT .. "/" .. Target.Variables.BASE_NAME .. "_plx.h"
    guardname = "BUILD_VERITARGET_CG_PLX_SYMBOLS_INC"
    file = io.open(dest, "w+")
    io.output(file)
    io.write('/* This is auto-generated */\n')
    io.write('#ifndef ' .. guardname .. '\n')		
    io.write('#define ' .. guardname .. '\n')		
    io.write('typedef struct {\n')

    for _,param in ipairs(Model["ExtModeParameters"]) do
        local dimensions = param["Dimensions"]
        local symbol = param["Symbol"]
        local dataTypeString = param["OrigType"]
        --The parameters are fixed as NxN.  It is possible that Veristand supports higher dimensions.
        local dimx, dimy
        if #dimensions==0 then      --scalar
            io.write("   %s %s;\n"%{dataTypeString,symbol})
        elseif #dimensions==1 then  --vector
            io.write("   %s %s[%i];\n"%{dataTypeString,symbol,dimensions[1]})
        elseif #dimensions==2 then  --matrix
            io.write("   %s %s[%i][%i];\n"%{dataTypeString,symbol,dimensions[1],dimensions[2]})
        else 
            return ("Error in DLL generation. Only 2-dimensional tunable parameters are supported by the Veristand target support package. Parameter %s/%s has %d dimensions." % {param["BlockPath"],param["Symbol"],#dimensions} ) 
        end
    end
    if V.GenerateChecksumCondition() then    
        local checksumDataTypeString = DataTypeNum2StrLookup[math.floor(Target.Variables.checksumDataType)]
        io.write("   %s Model_checksum[%i];\n"%{checksumDataTypeString,Target.Variables.checksumLength})
    end
    io.write('} Parameters;\n')
    io.write('#endif // ' .. guardname .. '\n')
    file.close()    

    return nil
end

function V.GenerateChecksumCondition()
    --When using veristand engine, a separate checksum parameter is required. 
    if Target.Variables.buildType == 1 or Target.Variables.buildType == 3 then
        return true
    else
        return false
    end
end

function V.ParseChecksum()
    local ret = ''
    if V.GenerateChecksumCondition() then
        ret =   "uint32_t checksumLength = strlen(|>BASE_NAME<|_checksum);\n"..
                "    for (int i = 0; i < (checksumLength / 8); i++) {\n"..
                "       sscanf(|>BASE_NAME<|_checksum + 8*i, \"%%08x\", &rtParameter[0].Model_checksum[i]);\n"..
                "       sscanf(|>BASE_NAME<|_checksum + 8*i, \"%%08x\", &rtParameter[1].Model_checksum[i]);\n"..
                "    }\n"
    end
    return ret
end

function V.GetVeriStandVersion(verIndexStr)
    local error=nil
    local verIndex=tonumber(verIndexStr)
    --                                   2019r1,2019r2,2019r3,2020r1,2020r2,2020r3,2020r4,2020r4,2020r6,2021r1,2021r2,2021r3
    local VeriStandVersionMajorLookup = {"2019","2019","2019","2020","2020","2020","2020","2020","2020","2021","2021","2021"}
    local VeriStandVersionMinorLookup = {"0"   ,"1"   ,"2"   ,"0"   ,"1"   ,"2"   ,"3"   ,"4"   ,"5"   ,"0"   ,"1"   ,"2"   }
    local VeriStandProductVersionLookup =    {"2019.0.0","2019.1.0","2019.2.0","2020","2020","2020","2020","2020","2020","2021","2021","2021"} --Testbench string in ASAM XIL
    local major = VeriStandVersionMajorLookup[verIndex]
    local minor = VeriStandVersionMinorLookup[verIndex]
    local product = VeriStandProductVersionLookup[verIndex]
    if major==nil or minor==nil or product==nil then
        error = "Invalid VeriStand Software Version."
    end
    return error, major, minor, product
end

return V
