#   Copyright (c) 2020 by Plexim GmbH
#   All rights reserved.
#
#   A free license is granted to anyone to use this software for any legal
#   non safety-critical purpose, including commercial applications, provided
#   that:
#   1) IT IS NOT USED TO DIRECTLY OR INDIRECTLY COMPETE WITH PLEXIM, and
#   2) THIS COPYRIGHT NOTICE IS PRESERVED in its entirety.
#
#   THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS
#   OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
#   FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
#   AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
#   LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
#   OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
#   SOFTWARE.

include |>BASE_NAME<|_sources.mk

TOOLS_PATH=|>TOOLCHAIN_ROOT<|/sysroots
PLX_ASAM_PATH=|>TARGET_ROOT<|/tools/dnettools
VERISTAND_x64_PATH=|>VS_x64_INSTALL_DIR<|
VERISTAND_ASAM_PATH=|>VS_x86_ASAM_DIR<|
VERISTAND_PRODUCT_VERSION=|>VS_PRODUCT_VERSION<|
VERISTAND_MAJOR_VERSION=|>VS_VERSION_MAJOR<|
BIN_DIR=./model
DLL_NAME=|>BASE_NAME<|
OUT_NAME=TestModel
MAKEFILE=|>BASE_NAME<|_model.mk
INSTALL_DIR=./
BASE_NAME=|>BASE_NAME<|
TARGET_ROOT=|>TARGET_ROOT<|
TARGET_USER_NAME=|>TARGET_USER_NAME<|
TARGET_IP_ADDRESS=|>TARGET_IP_ADDRESS<|
TARGET_DIR=~/veritarget
BUILD_ROOT=|>BUILD_ROOT<|
PUTTY_DIR=|>TARGET_ROOT<|/tools/PuTTY

##############################################################

C_SOURCE_FILES=\
ni_modelframework.c

ASM_SOURCE_FILES=\

ifdef PART_ASM_SOURCE_FILES
ASM_SOURCE_FILES += $(PART_ASM_SOURCE_FILES)
endif

HFILES=\

SOURCE_FILES_NI=$(patsubst $(BASE_NAME).c, $(BASE_NAME)_ni.c, $(SOURCE_FILES))

##############################################################
space:=
space+=
# for MacOS - NOTE: not tolerant to leading space or already escaped spaces '\ '
EscapeSpaces=$(subst $(space),\$(space),$(1))
FlipSlashesBack=$(subst /,\,$(1))

ifeq ($(OS),Windows_NT)
# Windows
SHELL := cmd.exe
FixPath=$(call FlipSlashesBack,$(1))
ClearDir=del /F /Q "$(call FlipSlashesBack,$(1))\*.*"
MoveFile=move /Y "$(call FlipSlashesBack,$(1))" "$(call FlipSlashesBack,$(2))"
CopyFile=copy /Y "$(call FlipSlashesBack,$(1))" "$(call FlipSlashesBack,$(2))"
OPENSSH_PATH=$(windir)\Sysnative\OpenSSH
PUTTY_PATH="$(call FixPath,$(PUTTY_DIR))"
SSH_CMD=|>SSH_CMD<| $(TARGET_USER_NAME)@"$(TARGET_IP_ADDRESS)"
SCP_CMD=|>SCP_CMD<|

else
# Linux style
FixPath = $(1)
ClearDir=rm -Rf $(call EscapeSpaces,$(1))/*
MoveFile=mv $(call EscapeSpaces,$(1)) $(call EscapeSpaces,$(2))
CopyFile=cp $(call EscapeSpaces,$(1)) $(call EscapeSpaces,$(2))
OPENSSH_PATH=
PUTTY_PATH=
SSH_CMD=ssh -T -v $(TARGET_USER_NAME)@"$(TARGET_IP_ADDRESS)" 
SCP_CMD=scp 

endif 

CGT_EXE_PATH="$(TOOLS_PATH)/i686-nilrtsdk-mingw32/usr/bin/x86_64-nilrt-linux"

BIN_DIR_OS=$(call FixPath,$(BIN_DIR))
VERISTAND_x64_PATH_OS=$(call FixPath,$(VERISTAND_x64_PATH))

# compiler
C_OPTIONS=\
--sysroot="$(TOOLS_PATH)/core2-64-nilrt-linux" \
-O0 \
-g3 \
-Wall \
-c \
-fmessage-length=0 \
-fPIC \
-DkNIOSLinux \
-DSCONS_TARGET_UNIX \
-DSCONS_TARGET_LINUX \
-DBASE_NAME=|>BASE_NAME<| \
-I"$(TOOLS_PATH)/core2-64-nilrt-linux/usr/include/c++/6.3.0" \
-I"$(TOOLS_PATH)/core2-64-nilrt-linux/usr/include/c++/6.3.0/x86_64-nilrt-linux" \
-I"$(TOOLS_PATH)/core2-64-nilrt-linux/usr/include" \
-I"$(TARGET_ROOT)/src/veritarget" \
-I. \

ifdef PART_C_OPTIONS
C_OPTIONS += $(PART_C_OPTIONS)
endif

A_OPTIONS=\

ifdef PART_A_OPTIONS
A_OPTIONS += $(PART_A_OPTIONS)
endif

L_OPTIONS=\
--sysroot="$(TOOLS_PATH)/core2-64-nilrt-linux" \

ifdef PART_L_OPTIONS
L_OPTIONS += $(PART_L_OPTIONS)
endif

C_OBJFILES=$(patsubst %.c, $(BIN_DIR)/%.os, $(C_SOURCE_FILES)) $(patsubst %.c, $(BIN_DIR)/%.os, $(SOURCE_FILES_NI))
ASM_OBJFILES=$(patsubst %.S, $(BIN_DIR)/%.os, $(ASM_SOURCE_FILES))

OBJFILES=$(C_OBJFILES) $(ASM_OBJFILES)

#DLLs required for dnet tools
VS_REQ_ASAM_DLLS=\
ASAM.XIL.Implementation.Framework.dll \
ASAM.XIL.Implementation.FrameworkFactory.dll \
ASAM.XIL.Implementation.ManifestReader.dll \
ASAM.XIL.Implementation.Testbench.dll \
ASAM.XIL.Implementation.TestbenchFactory.dll \
ASAM.XIL.Implementation.XILSupportLibrary.dll \
ASAM.XIL.Interfaces.dll

VS_REQ_x64_DLLS=\
Antlr3.Runtime.dll \
NationalInstruments.VeriStand.APIInterface.dll \
NationalInstruments.VeriStand.ATMLTestResults.dll \
NationalInstruments.VeriStand.ClientAPI.dll \
NationalInstruments.VeriStand.Compiler.dll \
NationalInstruments.VeriStand.DataTypes.dll \
NationalInstruments.VeriStand.dll \
NationalInstruments.VeriStand.RealTimeSequenceDefinitionApi.dll \
NationalInstruments.VeriStand.ServerAPI.dll \
NationalInstruments.VeriStand.SystemDefinitionAPI.dll \
NationalInstruments.VeriStand.UsiDotNetApi.dll \
NationalInstruments.VeriStand.VMWrapper.dll \
NationalInstruments.VeriStand.WorkspaceMacro.dll

ifeq ($(VERISTAND_MAJOR_VERSION),$(filter $(VERISTAND_MAJOR_VERSION),2019 2020)))
	VS_REQ_x64_DLLS+=MdlWrapExe.exe
endif


# make all variables available to sub-makes
export

# Top level 
##########################################################################
all:	frameworkcopy
ifneq ($(wildcard $(BIN_DIR_OS)),  $(BIN_DIR_OS))
	"$(MAKE)" -f $(MAKEFILE) clean
endif
	"$(MAKE)" -f $(MAKEFILE) $(INSTALL_DIR)/$(DLL_NAME).so
	
# Process 1) Test directories and make if DNE 2) transfer model
download: $(INSTALL_DIR)/$(DLL_NAME).so
	$(SSH_CMD) "[ -d $(TARGET_DIR) ]" && \
		@echo Target directory exists on remote target || \
		$(SSH_CMD) "mkdir $(TARGET_DIR)" 
	
	$(SSH_CMD) "$$(ps aux | grep '$(OUT_NAME).out' | grep -v grep >/dev/null)" && \
		$(SSH_CMD) "kill -2 $$(ps aux | grep '$(OUT_NAME).out' | grep -v grep | awk '{print $$1}')" || \
		@echo $(OUT_NAME) process is not running 
	
	$(SCP_CMD) "$(INSTALL_DIR)/$(DLL_NAME).so" $(TARGET_USER_NAME)@"$(TARGET_IP_ADDRESS)":$(TARGET_DIR)/$(DLL_NAME).so

veridownload: $(INSTALL_DIR)/$(DLL_NAME).so
ifeq ($(OS),Windows_NT)
	$(PLX_ASAM_PATH)/plx-asam-xil-tool LoadModel -m="$(BASE_NAME)" -c="$(BUILD_ROOT)\$(BASE_NAME)_portconfig.xml" -v=$(VERISTAND_PRODUCT_VERSION)
else
	@echo "Build and deploy for VeriStand is only supported on Windows OS."
endif

sysdef: $(INSTALL_DIR)/$(DLL_NAME).so dllcopy
ifeq ($(OS),Windows_NT)
	$(PLX_ASAM_PATH)/plx-asam-xil-tool SystemDefinition -b="$(BASE_NAME)" -p=$(INSTALL_DIR) -f="$(BUILD_ROOT)\$(DLL_NAME).so"
else
	@echo "Build for VeriStand target is only supported on Windows OS."
endif

dllcopy:
ifeq ($(OS),Windows_NT)
	"$(MAKE)" -f $(MAKEFILE) DLL_CPY_SRC='$(VERISTAND_x64_PATH)' $(VS_REQ_x64_DLLS)
	"$(MAKE)" -f $(MAKEFILE) DLL_CPY_SRC='$(VERISTAND_ASAM_PATH)' $(VS_REQ_ASAM_DLLS)
else
	@echo "Build and deploy for VeriStand is only supported on Windows OS."
endif

# Move framework file to relative path due to spaces in target path
frameworkcopy:
	$(call CopyFile,$(TARGET_ROOT)/src/veritarget/ni_modelframework.c,$(INSTALL_DIR)/ni_modelframework.c)
	

# Linker
##########################################################################
$(INSTALL_DIR)/$(DLL_NAME).so:  $(BIN_DIR)/$(DLL_NAME).so
							$(call CopyFile,$(BIN_DIR)/$(DLL_NAME).so,$(INSTALL_DIR)/$(DLL_NAME).so)

$(BIN_DIR)/$(DLL_NAME).so: 	$(OBJFILES)
							$(CGT_EXE_PATH)/x86_64-nilrt-linux-gcc -shared -o $(BIN_DIR)/$(DLL_NAME).so $(OBJFILES) $(L_OPTIONS)

# Special rules to convert principal model file
##########################################################################
$(BIN_DIR)/$(BASE_NAME)_ni.os:	$(BASE_NAME)_ni.c $(BASE_NAME)_plx.c $(HFILES)					
						$(CGT_EXE_PATH)/x86_64-nilrt-linux-gcc $(C_OPTIONS) -c -o $(BIN_DIR)/$(BASE_NAME)_ni.os $(BASE_NAME)_ni.c
						
$(BASE_NAME)_plx.c:		$(BASE_NAME).c $(HFILES)	
						$(PLX_ASAM_PATH)/plx-asam-xil-tool CodegenParameterModifier -b=$(BASE_NAME) -p=$(INSTALL_DIR)

# DLL files from VeriStand Installation
##########################################################################						
%.dll:					
		@xcopy /D /I /Y /Q "$(call FlipSlashesBack,$(DLL_CPY_SRC)/$@)" "$(call FlipSlashesBack,$(PLX_ASAM_PATH))" > NUL

%.exe:					
		@xcopy /D /I /Y /Q /K "$(call FlipSlashesBack,$(DLL_CPY_SRC)/$@)" "$(call FlipSlashesBack,$(PLX_ASAM_PATH))" > NUL

# Explicit rule to always make ni_modelframework.c since contains structures that depend on prinicpal model file
##########################################################################
.PHONY:		$(BIN_DIR)/ni_modelframework.os

$(BIN_DIR)/ni_modelframework.os:		$(INSTALL_DIR)/ni_modelframework.c	$(HFILES)
	$(CGT_EXE_PATH)/x86_64-nilrt-linux-gcc $(C_OPTIONS) -c -o $(BIN_DIR)/ni_modelframework.os $<

# Implicit Rules for generated files
##########################################################################
$(BIN_DIR)/%.os:		%.c	$(HFILES)
						$(CGT_EXE_PATH)/x86_64-nilrt-linux-gcc $(C_OPTIONS) -c -o $(BIN_DIR)/$*.os $<
						
$(BIN_DIR)/%.os:		$(TARGET_ROOT)/src/veritarget/%.c	$(HFILES)
						$(CGT_EXE_PATH)/x86_64-nilrt-linux-gcc $(C_OPTIONS) -c -o $(BIN_DIR)/$*.os $<



clean:
ifeq ($(wildcard $(BIN_DIR_OS)),  $(BIN_DIR_OS))
		$(call ClearDir,$(BIN_DIR_OS))
		del $(INSTALL_DIR)/$(DLL_NAME).so
else
		mkdir $(BIN_DIR_OS)
endif
