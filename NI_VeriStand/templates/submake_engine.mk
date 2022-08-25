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

TOOLS_PATH="|>TOOLCHAIN_ROOT<|/sysroots"
BOOST_PATH="|>TARGET_ROOT<|/tools/boostlib"
DAQMX_PATH="|>DAQMX_LIB_DIR<|"
BIN_DIR=./engine
OUT_NAME=TestModel
MAKEFILE=|>BASE_NAME<|_engine.mk
INSTALL_DIR=./
BASE_NAME=|>BASE_NAME<|
TARGET_ROOT=|>TARGET_ROOT<|
TARGET_USER_NAME=|>TARGET_USER_NAME<|
TARGET_IP_ADDRESS=|>TARGET_IP_ADDRESS<|
TARGET_DIR=~/veritarget
PUTTY_DIR=|>TARGET_ROOT<|/tools/PuTTY

##############################################################

C_SOURCE_FILES=\
$(BASE_NAME)_vdaq.c

CPP_SOURCE_FILES=\
VeristandExtModeAdapter.cpp \
VeristandModel.cpp \
main.cpp

ASM_SOURCE_FILES=\

HFILES=\

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

CGT_EXE_PATH=$(TOOLS_PATH)/i686-nilrtsdk-mingw32/usr/bin/x86_64-nilrt-linux

BIN_DIR_OS=$(call FixPath,$(BIN_DIR))

# compiler
C_OPTIONS=\
--sysroot=$(TOOLS_PATH)/core2-64-nilrt-linux \
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
-I$(TOOLS_PATH)/core2-64-nilrt-linux/usr/include/c++/6.3.0 \
-I$(TOOLS_PATH)/core2-64-nilrt-linux/usr/include/c++/6.3.0/x86_64-nilrt-linux \
-I$(TOOLS_PATH)/core2-64-nilrt-linux/usr/include \
-I"$(TARGET_ROOT)/src/veritarget" \
-I$(DAQMX_PATH)/include \
-I$(BOOST_PATH)/include \
-I. \

L_OPTIONS=\
--sysroot=$(TOOLS_PATH)/core2-64-nilrt-linux \
-Wl,-rpath=$$ORIGIN \
-Wl,-rpath=$$ORIGIN/lib \
-lstdc++ \
-std=c++11 \
-L"$(TARGET_ROOT)/build/veritarget" \
-L"$(TARGET_ROOT)/build/scopeserver" \
-L"$(TARGET_ROOT)/tools/scopeserver" \
-L$(DAQMX_PATH)/lib64/gcc \
-L$(BOOST_PATH)/lib \
-lnidaqmx \
-lnisyscfg \
-lscope-server \
-lboost_system \
-lboost_thread \
-lpthread \
-ldl \
-lm

C_OBJFILES=$(patsubst %.c, $(BIN_DIR)/%.os, $(C_SOURCE_FILES)) 
CPP_OBJFILES=$(patsubst %.cpp, $(BIN_DIR)/%.os, $(CPP_SOURCE_FILES)) 

ASM_OBJFILES=$(patsubst %.S, $(BIN_DIR)/%.os, $(ASM_SOURCE_FILES))

OBJFILES=$(C_OBJFILES) $(CPP_OBJFILES) $(ASM_OBJFILES)

# make all variables available to sub-makes
export

# Top level 
##########################################################################
all: applicationcopy
ifneq ($(wildcard $(BIN_DIR_OS)),  $(BIN_DIR_OS))
	"$(MAKE)" -f $(MAKEFILE) clean
endif
	"$(MAKE)" -f $(MAKEFILE) $(INSTALL_DIR)/$(OUT_NAME).out

# Process 1) Test directories and make if DNE 2) Kill any running models 3) Transfer application 4) change permissions 5) start proc with log 6) dump log to window
download: $(INSTALL_DIR)/$(OUT_NAME).out
	$(SSH_CMD) "[ -d $(TARGET_DIR) ]" && \
		@echo Target directory exists on remote target || \
		$(SSH_CMD) "mkdir $(TARGET_DIR)" 
	
	$(SSH_CMD) "[ -d $(TARGET_DIR)/lib ]" && \
		@echo Boost directory exists on remote target || \
		$(SCP_CMD) -r "$(BOOST_PATH)/lib" $(TARGET_USER_NAME)@"$(TARGET_IP_ADDRESS)":$(TARGET_DIR) 
	
	$(SSH_CMD) "$$(ps aux | grep '$(OUT_NAME).out' | grep -v grep >/dev/null)" && \
		$(SSH_CMD) "kill -2 $$(ps aux | grep '$(OUT_NAME).out' | grep -v grep | awk '{print $$1}')" || \
		@echo $(OUT_NAME) process is not running 
	
	$(SCP_CMD) "$(INSTALL_DIR)/$(OUT_NAME).out" $(TARGET_USER_NAME)@"$(TARGET_IP_ADDRESS)":$(TARGET_DIR)/$(OUT_NAME).out 
	
	$(SSH_CMD) chmod 755 $(TARGET_DIR)/$(OUT_NAME).out 
	
	$(SSH_CMD) "nohup $(TARGET_DIR)/$(OUT_NAME).out > $(TARGET_DIR)/$(BASE_NAME).log 2> $(TARGET_DIR)/$(BASE_NAME).err < /dev/null &"
	
	$(SSH_CMD) "cat $(TARGET_DIR)/$(BASE_NAME).err"

# Move application files to relative path due to spaces in target path
applicationcopy:
	$(call CopyFile,$(TARGET_ROOT)/src/veritarget/main.cpp,$(INSTALL_DIR)/main.cpp)
	$(call CopyFile,$(TARGET_ROOT)/src/veritarget/VeristandModel.cpp,$(INSTALL_DIR)/VeristandModel.cpp)
	$(call CopyFile,$(TARGET_ROOT)/src/veritarget/VeristandExtModeAdapter.cpp,$(INSTALL_DIR)/VeristandExtModeAdapter.cpp)

# Linker
##########################################################################
$(INSTALL_DIR)/$(OUT_NAME).out:  $(BIN_DIR)/$(OUT_NAME).out
							$(call CopyFile,$(BIN_DIR)/$(OUT_NAME).out,$(INSTALL_DIR)/$(OUT_NAME).out)

$(BIN_DIR)/$(OUT_NAME).out: 	$(OBJFILES)
							"$(CGT_EXE_PATH)"/x86_64-nilrt-linux-gcc -o $(BIN_DIR)/$(OUT_NAME).out $(OBJFILES) $(L_OPTIONS)

# Implicit Rules for generated files
##########################################################################
$(BIN_DIR)/%.os:		%.c	$(HFILES)
						"$(CGT_EXE_PATH)"/x86_64-nilrt-linux-gcc $(C_OPTIONS) -c -o $(BIN_DIR)/$*.os $<

$(BIN_DIR)/%.os:		%.cpp	$(HFILES)
						"$(CGT_EXE_PATH)"/x86_64-nilrt-linux-gcc $(C_OPTIONS) -c -o $(BIN_DIR)/$*.os $<

clean:
ifeq ($(wildcard $(BIN_DIR_OS)),  $(BIN_DIR_OS))
		$(call ClearDir,$(BIN_DIR_OS))
		del $(INSTALL_DIR)/$(OUT_NAME).out
else
		mkdir $(BIN_DIR_OS)
endif
