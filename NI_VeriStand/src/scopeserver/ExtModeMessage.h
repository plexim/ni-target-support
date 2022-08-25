/*
 *  Copyright (c) 2022 Plexim GmbH
 *  
 *  Permission is hereby granted, free of charge, to any person obtaining a copy
 *  of this software and associated documentation files (the "Software"), to deal
 *  in the Software without restriction, including without limitation the rights
 *  to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
 *  copies of the Software, and to permit persons to whom the Software is
 *  furnished to do so, subject to the following conditions:
 *  
 *  The above copyright notice and this permission notice shall be included in all
 *  copies or substantial portions of the Software.
 *  
 *  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 *  IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 *  FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
 *  AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
 *  LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
 *  OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
 *  SOFTWARE.
 */

#ifndef EXT_MODE_MESSAGE_H_
#define EXT_MODE_MESSAGE_H_

#include <stdint.h>
#include <string>
#include <deque>

#include <boost/noncopyable.hpp>
#include <boost/shared_ptr.hpp>
#include <boost/shared_array.hpp>

class ExtModeMessage;
typedef boost::shared_ptr<ExtModeMessage> SharedExtModeMessage;

class ExtModeMessage : private boost::noncopyable {
public:
	typedef enum MessageType {
	   NULL_MSG = -1,

	   // packets sent by client
	   REQUEST_MODELINFO = 0,
	   REQUEST_SIGNALDATA,
	   REQUEST_TUNE_PARAMS,

	   // packets sent by server
	   REPLY_MODELINFO,
	   REPLY_SIGNALDATA,
	   REPLY_TUNE_PARAMS,
	   REPLY_ERROR
	} MessageType_t;

	typedef struct VersionType {
	   int mVersionMajor;
	   int mVersionMinor;
	   int mVersionPatch;
	} VersionType_t;

	ExtModeMessage();
	ExtModeMessage(std::deque<char> aMsg);
	virtual ~ExtModeMessage();

	bool toJson(std::string &aJsonString);
	bool fromJson(std::string &aJsonString);

	MessageType_t getType();

	size_t getData(boost::shared_array<char> &aBuffer){
		aBuffer.reset(new char[mMsg.size()]);
		copy(mMsg.begin(), mMsg.end(), aBuffer.get());
		return mMsg.size();
	}

    boost::shared_array<char> writeBuffer; // data being written
    size_t writeBufferSize; // size of writeBuffe

	size_t popData(char * data, size_t maxSize);
	size_t pushData(const char * data, size_t maxSize);
	size_t pushInt(int aValue);
	size_t pushDouble(double aValue);
	size_t pushFloat(float aValue);

	size_t available() const;
	void clear();

private:
	std::deque<char> mMsg;
};

#endif // EXT_MODE_MESSAGE_H_
