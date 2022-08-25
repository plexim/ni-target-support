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

INSTALL_DIR=|>INSTALL_DIR<|
MAKEFILE=|>BASE_NAME<|.mk
HFILE=|>BASE_NAME<|.h |>BASE_NAME<|_ni.h |>BASE_NAME<|_plx.h
FRAMEWORK_FILES=|>BASE_NAME<|_ni.c

##############################################################
space:=
space+=
EscapeSpaces=$(subst $(space),\$(space),$(1))
FlipSlashesBack=$(subst /,\,$(1))

ifeq ($(OS),Windows_NT)
# Windows
SHELL := cmd.exe
ClearDir=del /F /Q "$(call FlipSlashesBack,$(1))\*.*"
MoveFile=move /Y "$(call FlipSlashesBack,$(1))" "$(call FlipSlashesBack,$(2))"
CopyFile=copy /Y "$(call FlipSlashesBack,$(1))" "$(call FlipSlashesBack,$(2))"

else
# Linux style
ClearDir=rm -Rf $(call EscapeSpaces,$(1))/*
MoveFile=mv $(1) $(call EscapeSpaces,$(2))
CopyFile=cp $(1) $(call EscapeSpaces,$(2))

endif 

INSTALL_FILES=\
  $(patsubst %.h, "$(INSTALL_DIR)/%.h", $(HFILE)) \
  $(patsubst %.c, "$(INSTALL_DIR)/%.c", $(SOURCE_FILES)) \
  $(patsubst %.c, "$(INSTALL_DIR)/%.c", $(FRAMEWORK_FILES))

INSTALL_DIR_ESC=$(call EscapeSpaces,$(INSTALL_DIR))

# make all variables available to sub-makes
export

##########################################################################
all:
	"$(MAKE)" -f $(MAKEFILE) $(INSTALL_FILES)

##########################################################################
$(INSTALL_DIR_ESC)/%.c:		%.c
							$(call CopyFile,$*.c,$@)

$(INSTALL_DIR_ESC)/%.h:		%.h
							$(call CopyFile,$*.h,$@)

# no action for download
download:
	
