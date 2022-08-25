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

--List of Hardware Modules
--Modules consist of available ports, and the specific characteristics associated with each module
--
--https://www.ni.com/en-us/support/documentation/supplemental/18/daq-devices-with-hardware-timed-single-point-sampling-mode-suppo.html
--The following devices in the PCI/PXI/PCIe/PXIe form factor support AI/AO hardware-timed single point sample mode:
--
--    NI 63xx devices (X Series)
--    NI 62xx devices (M Series)
--    NI 61xx devices (S Series)
--    NI 60xxE devices (E Series)
--    NI 43xx (SC Express)
--    NI 67xx (Analog Output, excluding NI 6703 and 6704)
--    "DSA, S Series, X Series, and SC Express devices support including channels from multiple devices in a single task"


local MOD = {}

--X Series
----Simultaneous Sampling
local PXIe6349  =require('Modules/PXIe6349')
local PXIe6356  =require('Modules/PXIe6356')
local PXIe6358  =require('Modules/PXIe6358')
local PXIe6366  =require('Modules/PXIe6366')
local PXIe6368  =require('Modules/PXIe6368')
local PXIe6376  =require('Modules/PXIe6376')
local PXIe6378  =require('Modules/PXIe6378')
local PXIe6386  =require('Modules/PXIe6386')
local PXIe6396  =require('Modules/PXIe6396')
----Multiplexed Sampling
local PXIe6341  =require('Modules/PXIe6341')
local PXIe6345  =require('Modules/PXIe6345')
local PXIe6355  =require('Modules/PXIe6355')
local PXIe6361  =require('Modules/PXIe6361')
local PXIe6363  =require('Modules/PXIe6363')
local PXIe6365  =require('Modules/PXIe6365')
local PXIe6375  =require('Modules/PXIe6375')

--Analog Output Series
local PXI6722   =require('Modules/PXI6722')
local PXI6723   =require('Modules/PXI6723')
local PXI6731   =require('Modules/PXI6731')
local PXI6733   =require('Modules/PXI6733')

--Add functions. Allocates resources.
MOD.AddPXIe6349 = PXIe6349.Add
MOD.AddPXIe6356 = PXIe6356.Add
MOD.AddPXIe6358 = PXIe6358.Add
MOD.AddPXIe6366 = PXIe6366.Add
MOD.AddPXIe6368 = PXIe6368.Add
MOD.AddPXIe6376 = PXIe6376.Add
MOD.AddPXIe6378 = PXIe6378.Add
MOD.AddPXIe6386 = PXIe6386.Add
MOD.AddPXIe6396 = PXIe6396.Add

MOD.AddPXIe6341 = PXIe6341.Add
MOD.AddPXIe6345 = PXIe6345.Add
MOD.AddPXIe6355 = PXIe6355.Add
MOD.AddPXIe6361 = PXIe6361.Add
MOD.AddPXIe6363 = PXIe6363.Add
MOD.AddPXIe6365 = PXIe6365.Add
MOD.AddPXIe6375 = PXIe6375.Add

MOD.AddPXI6722  = PXI6722.Add
MOD.AddPXI6723  = PXI6723.Add
MOD.AddPXI6731  = PXI6731.Add
MOD.AddPXI6733  = PXI6733.Add

--Property functions. Describes hardware characteristics
MOD.PropertiesPXIe6349    = PXIe6349.Properties
MOD.PropertiesPXIe6356    = PXIe6356.Properties
MOD.PropertiesPXIe6358    = PXIe6358.Properties
MOD.PropertiesPXIe6366    = PXIe6366.Properties
MOD.PropertiesPXIe6368    = PXIe6368.Properties
MOD.PropertiesPXIe6376    = PXIe6376.Properties
MOD.PropertiesPXIe6378    = PXIe6378.Properties
MOD.PropertiesPXIe6386    = PXIe6386.Properties
MOD.PropertiesPXIe6396    = PXIe6396.Properties

MOD.PropertiesPXIe6341    = PXIe6341.Properties
MOD.PropertiesPXIe6345    = PXIe6345.Properties
MOD.PropertiesPXIe6355    = PXIe6355.Properties
MOD.PropertiesPXIe6361    = PXIe6361.Properties
MOD.PropertiesPXIe6363    = PXIe6363.Properties
MOD.PropertiesPXIe6365    = PXIe6365.Properties
MOD.PropertiesPXIe6375    = PXIe6375.Properties

MOD.PropertiesPXI6722     = PXI6722.Properties
MOD.PropertiesPXI6723     = PXI6723.Properties
MOD.PropertiesPXI6731     = PXI6731.Properties
MOD.PropertiesPXI6733     = PXI6733.Properties


return MOD


--[[
\section{PXI Modules}
\subsection{PXI Multifunction IO}
The following Multifunction IO devices are supported:
\begin{itemize}
\item PXIe-6349
\item PXIe-6356
\item PXIe-6358
\item PXIe-6366
\item PXIe-6368
\item PXIe-6376
\item PXIe-6378
\item PXIe-6386
\item PXIe-6396
\end{itemize}

\subsection{PXI Analog Output}
The following PXI Analog Output devices are supported:
\begin{itemize}
\item PXI-6723
\item PXI-6733
\end{itemize}
--]]
