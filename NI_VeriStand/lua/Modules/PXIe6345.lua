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

local PRODUCT = {}

--------------------------------------------
-- PXIe-6345 (X Series)
--------------------------------------------
function PRODUCT.Add(resources,slot)
    resources:add(("Slot%i-AnalogInput" % {slot}),0,79) --80 single ended, 40 differential.
    resources:add(("Slot%i-AnalogOutput" % {slot}),0,2)
    resources:add(("Slot%i-DigitalIO-Port0" % {slot}),0,7)
    resources:add(("Slot%i-DigitalIO-Port1" % {slot}),0,7)
    resources:add(("Slot%i-DigitalIO-Port2" % {slot}),0,7)
    resources:add(("Slot%i-PFI" % {slot}),0,15)
    resources:add(("Slot%i-CounterTimers" % {slot}),0,3)
end
function PRODUCT.Properties()
    function PFItoDIO(pfi)
        local port = math.floor(pfi/8)+1
	    local line  = pfi % 8
        return port, line
    end
    function DIOtoPFI(port,line)
        local pfi 
        if port==1 or port ==2 then
            pfi = 8*(port-1)+line
        else
            pfi=nil --no not claim
        end
        return  pfi
    end
    --Only DIO Port 0 supports hardware timed singlepoint mode. Otherwise software triggered
    tbl = {}
    tbl['Series']='X' --Hardware "series" of device
    tbl['WaveformDIO']={0} -- Digital outputs that support hardware timed single point outputs
    tbl['ClkFreqMax']=100e6 -- Maximum Input Clock Frequency
    tbl['CounterBitResolution']=32 --Maximum counter resolution
    tbl['MultideviceTaskSupport'] = true
    tbl['MapPFItoDIO']=PFItoDIO -- input PFI return (port,line) pairs
    tbl['MapDIOtoPFI']=DIOtoPFI -- input (port,line) return PFI
    tbl['DefaultCtrPFI']={position={{8,10,9},{3,11,4},{0,2,1},{5,7,6}},edge={{8,10},{3,11},{10,2},{5,7}},output={{12},{13},{14},{15}}}
    return tbl
end

return PRODUCT
