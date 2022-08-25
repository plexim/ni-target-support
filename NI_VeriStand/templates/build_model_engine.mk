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

BASE_NAME=|>BASE_NAME<|
OUT_NAME=TestModel
TARGET_USER_NAME=|>TARGET_USER_NAME<|
TARGET_IP_ADDRESS=|>TARGET_IP_ADDRESS<|

all:
	"$(MAKE)" -f $(BASE_NAME)_model.mk
	"$(MAKE)" -f $(BASE_NAME)_engine.mk

clean:
	"$(MAKE)" -f $(BASE_NAME)_model.mk clean
	"$(MAKE)" -f $(BASE_NAME)_engine.mk clean

download: all
	"$(MAKE)" -f $(BASE_NAME)_model.mk download
	"$(MAKE)" -f $(BASE_NAME)_engine.mk download
