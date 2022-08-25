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

local U = { }

math.randomseed(os.time())
local random = math.random

-- https://stackoverflow.com/questions/1340230/check-if-directory-exists-in-lua
function U.FileExists(file)
   if (Target.Variables.HOST_OS == "win") and (string.sub(file, 1, 1) == "/") then
       -- this check is necessary, because Lua will silently replace "/" with "C:/"
       return false
   end
   local ok, err, code = os.rename(file, file)
   if not ok then
      if (code == 13) or (code == 17) then
         -- Permission denied, but it exists
         return true
      end
   end
   return ok, err
end

function U.CopyTemplateFile(src, dest, subs)
  local file = io.open(src, "rb")
  local src_content = file:read("*all")
  io.close(file)
  local dest_content

  file = io.open(dest, "rb")
  if(file == nil) then
    dest_content = nil
  else
    dest_content = file:read("*all")
    io.close(file)
  end
  
  if subs ~= nil then
  	for _,v in pairs(subs) do 
  		local before = v["before"]
  		local after = v["after"]
  		src_content = string.gsub( src_content, before, after)  
	end
  end

  src_content = string.gsub(src_content, "\r", "") 
  
  if not (src_content == dest_content) then
    file = io.open(dest, "w")
    io.output(file)
    io.write(src_content)
    file.close() 
  end
end

function U.GetFromArrayOrScalar(field, index, majordim)
	if #field == 1 then
   	return field[1]
  	elseif #field == majordim then
  	 	return field[index]
  	else
    	return nil	
  	end  
end

function U.Round(num, numDecimalPlaces)
  if numDecimalPlaces and numDecimalPlaces>0 then
    local mult = 10^numDecimalPlaces
    return math.floor(num * mult + 0.5) / mult
  end
  return math.floor(num + 0.5)
end

function U.guid()
    local template ='{0xXX, 0xXX, 0xXX, 0xXX, 0xXX, 0xXX, 0xXX, 0xXX}'
    return string.gsub(template, '[X]', function (c)
        local v = (c == 'X') and random(0, 0xf) 
        return string.format('%x', v)
    end)
end

function U.IsValidCName(name)
	if string.match(name, '[^a-zA-Z0-9_]') ~= nil then
  		return false
	end
	if string.match(string.sub(name, 1, 1), '[0-9]') ~= nil then
  		return false
	end
	return true
end

function U.MakeValidCName(name)
	out,_ =string.gsub(name,"[^A-Za-z0-9_]","_")
	out,_ =string.gsub(out,"%c","_")
	firstChar = string.sub(out,1,1)
	if string.match(firstChar,"%a")~=firstChar then
    		out = "var"..out 
	end

	return out 
end

function U.MakeValidVeristandName(name)
    --https://zone.ni.com/reference/en-XX/help/372846M-01/veristand/model_param_file_format/
    --Allows for path entry (/ or \)
	out,_ =string.gsub(name,"[^A-Za-z0-9_/\\]","_")
	out,_ =string.gsub(out,"\\n","_")
	out,_ =string.gsub(out,"\\t","_")
	out,_ =string.gsub(out,"%c","_")
	firstChar = string.sub(out,1,1)
	if string.match(firstChar,"%a")~=firstChar then
    		out = "var"..out 
	end

	return out 
end


function U.ParseMinMaxEntry(minmax)
    --Data entered as a string representing an array e.g. "[-10.0,10.0]"
    local tbl = {}
    for v1,v2 in string.gmatch(minmax,"%[%s*([%d%.-+]+)%s*,%s*([%d%.-+]+)%s*%]") do
      table.insert(tbl,tonumber(v1))
      table.insert(tbl,tonumber(v2))
    end
    if (#tbl~=2 or tbl[1]==nil or tbl[2]==nil) then
        return nil
    else
        return tbl
    end
end


return U
