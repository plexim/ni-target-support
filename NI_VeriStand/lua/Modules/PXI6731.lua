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
-- PXI-6731 (Analog Out Series)
--------------------------------------------
function PRODUCT.Add(resources,slot)
    resources:add(("Slot%i-AnalogOutput" % {slot}),0,3)
    resources:add(("Slot%i-DigitalIO-Port0" % {slot}),0,7)
    resources:add(("Slot%i-PFI" % {slot}),0,9)
    resources:add(("Slot%i-CounterTimers" % {slot}),0,1)
end
function PRODUCT.Properties()
    --Only DIO Port 0 supports hardware timed singlepoint mode. Otherwise software triggered
    tbl = {}
    tbl['Series']='AO' --Hardware "series" of device
    tbl['WaveformDIO']={0} -- Digital outputs that support hardware timed single point outputs
    tbl['ClkFreqMax']=20e6 -- Maximum Input Clock Frequency
    tbl['CounterBitResolution']=24 --Maximum counter resolution
    tbl['MultideviceTaskSupport'] = false
    tbl['MapPFItoDIO']=nil  --independent pinsets
    tbl['MapDIOtoPFI']=nil  --independent pinsets
    tbl['DefaultCtrPFI']=nil --Cannot use PFI for DIO.  No mapping req'd.
    tbl['PXIBackplaneReferenceClock']='None' --Veristand DAQ device settings
    return tbl
end

return PRODUCT

