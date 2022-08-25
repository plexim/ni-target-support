# Background
With the NI Veristand™ Target Support Package (TSP), PLECS can generate simulation models compatible with the NI VeriStand software. 

The NI VeriStand TSP is targeted toward real-time control applications executing on NI hardware with Intel x64 processors and the NI Linux Real-Time (RT) operating system. The TSP also supports integration with NI PXIe DAQ hardware modules with a focus on X-Series DAQ devices.

Please watch the [Building Code for the NI PXI System from PLECS](https://www.youtube.com/watch?v=dP19uGeAiTc) video for an introduction to the TSP.

# Pre-requisite software

In order to use the PLECS NI VeriStand TSP you will need at the minimum:
- A host computer with Microsoft Windows 10 or newer
- PLECS Blockset or Standalone 4.5.4 or newer
- A PLECS Coder license
- A cross compiler to compile code for a NI Linux Real-Time target from Windows

Additional NI software packages are required on the host PC and NI Linux RT target device for additional functionality, as described in the NI VeriStand Target Support User Manual (`nimanual.pdf`).

If you do not have a PLECS license you can request one at https://www.plexim.com/trial.

# Installation Steps

Download the `NI_VeriStand` repository as a ZIP archive by clicking "Code + Download ZIP" or clone the respository.  Move the `NI_VeriStand` folder to the PLECS Coder target support packages path e.g. to `HOME/Documents/PLECS/CoderTargets`.

In PLECS, choose **Preferences...** from the **File** drop-down menu to open the PLECS Preferences dialog. Navigate to the **Coder** tab and click on the **Change** button to select the `HOME/Documents/PLECS/CoderTargets` folder. The NI VeriStand target should be listed under **Installed targets**. You will also see these targets available in the **Coder + Coder options...** window in the drop-down menu on the **Target** tab.

Refer to the Quick Start section of the NI VeriStand Target Support User Manual for additional installation instructions, including how to setup and configure the cross compiler.  A set of demos is also included with the TSP.

# Additional Tools
The NI VeriStand Target Support Package requires an auxiliary application to serve as a bridge between the PLECS application and the NI VeriStand toolchain.  The source code for this application is available in a separate repository: https://github.com/plexim/ni-tsp-dotnet-tools.
