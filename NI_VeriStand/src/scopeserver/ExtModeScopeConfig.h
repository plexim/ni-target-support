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

#ifndef EXT_MODE_SCOPE_CONFIG_H_
#define EXT_MODE_SCOPE_CONFIG_H_

#include <vector>

#include "ExtModeMessage.h"

class ExtModeScopeConfig
{
public:
	ExtModeScopeConfig():
		mRequestedNumSamples(0){
	}

	bool parse(SharedExtModeMessage aMsg);

	bool equals(ExtModeScopeConfig &aRec)
	{
		return(
				//(mTransactionId == aRec.mTransactionId) &&
				(mSignalIds == aRec.mSignalIds) &&
				(mRequestedNumSamples == aRec.mRequestedNumSamples) &&
				(mDecimationPeriod == aRec.mDecimationPeriod) &&
				(mTriggerChannel == aRec.mTriggerChannel) &&
				(mTriggerEdge == aRec.mTriggerEdge) &&
				(mTriggerValue == aRec.mTriggerValue) &&
				(mTriggerDelay == aRec.mTriggerDelay)
		);
	}

	void setTo(ExtModeScopeConfig &aRec)
	{
		mTransactionId = aRec.mTransactionId;
		mSignalIds = aRec.mSignalIds;
		mRequestedNumSamples = aRec.mRequestedNumSamples;
		mDecimationPeriod = aRec.mDecimationPeriod;

		mTriggerChannel = aRec.mTriggerChannel;
		mTriggerEdge = aRec.mTriggerEdge;
		mTriggerValue = aRec.mTriggerValue;
		mTriggerDelay = aRec.mTriggerDelay;
	}

	size_t getNumSignals(){
		return mSignalIds.size();
	}

	int32_t getNumRequestedSamples(){
		return mRequestedNumSamples;
	}

	void setNumRequestedSamples(int32_t aNumRequestedSamples){
		mRequestedNumSamples = aNumRequestedSamples;
	}

	uint32_t getTransactionId(){
		return mTransactionId;
	}

	int32_t getDecimationPeriod(){
		return mDecimationPeriod;
	}

	int getTriggerChannel(){
		return mTriggerChannel;
	}

	float getTriggerLevel(){
		return mTriggerValue;
	}

	int getTriggerEdge(){
		return mTriggerEdge;
	}

	int getTriggerDelay(){
		return mTriggerDelay;
	}

	int32_t getSignalId(size_t aIndex){
		return mSignalIds[aIndex];
	}

private:

	uint32_t mTransactionId;
	std::vector<int32_t> mSignalIds;
	int32_t mRequestedNumSamples;
	int32_t mDecimationPeriod;

	int mTriggerChannel;
	int mTriggerEdge;
	float mTriggerValue;
	int mTriggerDelay;
};

#endif // EXT_MODE_SCOPE_CONFIG_H_
