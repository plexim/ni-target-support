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

#include <stdint.h>

#include <iostream>

#include <boost/bind.hpp>
#include <boost/atomic.hpp>
#include <boost/thread/thread.hpp>

#include "../scopeserver/ExtModeMessage.h"
#include "../scopeserver/ExtModeSocketServer.h"
#include "../scopeserver/ExtModeScopeConfig.h"

#include "VeristandDllWrapper.hpp"
#include "VeristandExtModeAdapter.h"
#include "VeristandModel.h"

class VeristandExtModeAdapter_p {
public:
	VeristandExtModeAdapter_p(SharedVeristandModel aModel):
		mModel(aModel),
		mServer(),
		mScopeState(ScopeState_Disabled),
		mScopeMutex(),
		mScopeArmReq(false),
		mScopeResetReq(true),
		mExtModeScopeConfig()
		{
	};

   	~VeristandExtModeAdapter_p(){
   	};

   	bool initialize(size_t aMaxNumOfSignals, size_t aMaxScopeBufferSize);
   	bool start(unsigned int port);
   	void stop();
   	void captureScopeSignals(double aTime);

private:

   	typedef enum {
   		ScopeState_Disabled = 0,
		ScopeState_Armed,
		ScopeState_Triggered,
		ScopeState_Ready
   	} ScopeState_t;

   	void scopeRequestHandler(SharedExtModeMessage &aRequest, SharedExtModeMessage &aResponse);
   	bool getTriggerSign();

   	// scope variables
   	size_t mMaxNumOfSignals;
   	size_t mMaxScopeBufferSize;
   	boost::shared_array<double> mScopeRowBuffer;
   	boost::shared_array<double> mScopeBuffer;
   	boost::shared_array<int32_t> mScopeSignalIndices;

   	size_t mScopeBufferSize;
   	size_t mScopeDecimationPrd;
   	int mNumTimeStepsRequested;
   	size_t mNumSignalsRequested;
   	int32_t mTriggerChannel;
   	double mTriggerLevel;
   	int mTriggerEdge;
   	int mTriggerDelay;

   	int mScopeNumStepsCaptured;
   	int mScopeNumStepsInBuffer;
   	size_t mScopeDecimationCtr;
   	size_t mScopeBufferWriteIndex;
   	int mLastTriggerSign;

   	// order matters
  	SharedVeristandModel mModel;
  	boost::scoped_ptr<ExtModeSocketServer> mServer;
  	boost::atomic<ScopeState_t> mScopeState;
  	mutable boost::mutex mScopeMutex;
  	boost::atomic_bool mScopeArmReq;
  	boost::atomic_bool mScopeResetReq;
   	ExtModeScopeConfig mExtModeScopeConfig;
};

bool VeristandExtModeAdapter_p::initialize(size_t aMaxNumOfSignals, size_t aMaxScopeBufferSize){
	mMaxNumOfSignals = aMaxNumOfSignals;
	mMaxScopeBufferSize = aMaxScopeBufferSize;

	// allocate maximal allowable memory
	mScopeBuffer.reset(new double[aMaxScopeBufferSize]);
	mScopeRowBuffer.reset(new double[aMaxNumOfSignals+2]);
	mScopeSignalIndices.reset(new int32_t[aMaxNumOfSignals+2]);

	return true;
}

bool VeristandExtModeAdapter_p::start(unsigned int port){
	mServer.reset(new ExtModeSocketServer());
	if(!mServer->start(port, boost::bind(&VeristandExtModeAdapter_p::scopeRequestHandler, this,_1, _2))){
		mServer.reset();
		return false;
	}
	return true;
}

void VeristandExtModeAdapter_p::stop(){
	if(mServer){
		mServer->stop();
	}
}

void VeristandExtModeAdapter_p::scopeRequestHandler(SharedExtModeMessage &aRequest, SharedExtModeMessage &aResponse){
	if(aRequest){
		switch(aRequest->getType()){
			case ExtModeMessage::REQUEST_MODELINFO:
			{
				aResponse.reset(new ExtModeMessage());
				aResponse->pushInt(ExtModeMessage::REPLY_MODELINFO);
				aResponse->pushDouble(mModel->getBaseTimeStep());
				std::vector<char> checksum = mModel->getModelChecksum();
				aResponse->pushInt(checksum.size());
				aResponse->pushData(&checksum[0], checksum.size());
				aResponse->pushInt(mModel->getNumSignalsFlattened()); // num  ext mode signals
				aResponse->pushInt(mModel->getNumParametersFlattened()); // num parameters
			}
			break;

		   case ExtModeMessage::REQUEST_TUNE_PARAMS:
			{
				boost::shared_array<char> data;
				aRequest->getData(data);

				int baseIndex = sizeof(int);
				int numParams = *(int *)(&data[baseIndex]);
				if(numParams > mModel->getNumParametersFlattened())
				{
					aResponse.reset(new ExtModeMessage());
					aResponse->pushInt(ExtModeMessage::REPLY_ERROR);
					std::string msg("Excessive number of parameter values supplied.");
					aResponse->pushInt(msg.size());
					aResponse->pushData(msg.c_str(), msg.size());
					break;
				}
				else
				{
					baseIndex += sizeof(int);
					for(int i=0; i<numParams; i++)
					{
						double val = *(double *)(&data[baseIndex]);
						std::cout << "Setting param " << i << " to " << val << std::endl;

						if(!mModel->setParameter(i, val)){
							std::cout << "Unable to write parameter" << std::endl;
						}
						baseIndex += sizeof(double);
					}

					if(!mModel->commitParameters()){
						std::cout << "Unable to commit parameters" << std::endl;
					}

					for(int i=0; i<numParams; i++){
						double val;
						if(!mModel->getParameter(i, val)){
							std::cout << "Unable to read parameter" << std::endl;
						} else {
							std::cout << "Current value " << val << std::endl;
						}
					}
				}
				// this seems to be having no effect...
				aResponse.reset(new ExtModeMessage());
				aResponse->pushInt(ExtModeMessage::REPLY_TUNE_PARAMS);
				aResponse->pushInt(0);
			}
			break;

			case ExtModeMessage::REQUEST_SIGNALDATA:
			{
				ExtModeScopeConfig req;
				req.parse(aRequest);

				// resize request based on target buffer capacity
				if(req.getNumSignals() > mMaxNumOfSignals){
					aResponse.reset(new ExtModeMessage());
					aResponse->pushInt(ExtModeMessage::REPLY_ERROR);
					std::string msg("Excessive number of external mode signals.");
					aResponse->pushInt(msg.size());
					aResponse->pushData(msg.c_str(), msg.size());
					break;
				}

				int32_t maxSamples = mMaxScopeBufferSize / req.getNumSignals();
				if(req.getNumRequestedSamples() > maxSamples){
					req.setNumRequestedSamples(maxSamples);
				}

				if((mScopeState == ScopeState_Disabled) || !mExtModeScopeConfig.equals(req)){
					if(mExtModeScopeConfig.equals(req)){
						// simply rearm
						mScopeArmReq = true;
					} else {
						// new configuration
						{
							boost::mutex::scoped_lock lock(mScopeMutex); // critical section for signal capture
							mScopeResetReq = true; // abort scope operation so that we can modify settings
						}

						mNumTimeStepsRequested = req.getNumRequestedSamples();
						mNumSignalsRequested = req.getNumSignals();
						mScopeSignalIndices[0] = 0;
						for(size_t i=0; i<req.getNumSignals(); i++){
							mScopeSignalIndices[1+i] = req.getSignalId(i);
						}
						mScopeSignalIndices[1+mNumSignalsRequested] = -1;
						mScopeBufferSize = req.getNumRequestedSamples() * req.getNumSignals();

						mTriggerChannel = req.getTriggerChannel();
						mTriggerLevel = req.getTriggerLevel();
						mTriggerEdge = req.getTriggerEdge();
						mTriggerDelay = req.getTriggerDelay()/req.getDecimationPeriod();

						if(mTriggerDelay > mNumTimeStepsRequested){
							mTriggerDelay = mNumTimeStepsRequested;
						} else if(mTriggerDelay <= (-mNumTimeStepsRequested)){
							mTriggerDelay = -(mNumTimeStepsRequested-1);
						}

						mScopeDecimationPrd = req.getDecimationPeriod();

						mExtModeScopeConfig.setTo(req);
						mScopeArmReq = true;
					}
				} else {
					//std::cout << "Scope in state " << mScopeState << std::endl;
				}
			}
			break;

			default:
				break;
		}
	} else {
		// spontaneous transmission?
		if(mScopeState == ScopeState_Ready){
			aResponse.reset(new ExtModeMessage());
			aResponse->pushInt(ExtModeMessage::REPLY_SIGNALDATA);
			aResponse->pushInt(mExtModeScopeConfig.getTransactionId()); // has no effect
			aResponse->pushInt(0); // error code
			aResponse->pushInt(mNumTimeStepsRequested);
			float sampleTime = (float)mModel->getBaseTimeStep() * (float)mExtModeScopeConfig.getDecimationPeriod();
			aResponse->pushFloat(sampleTime);
			aResponse->pushInt(mExtModeScopeConfig.getNumSignals());
			for(size_t i=0; i<mExtModeScopeConfig.getNumSignals(); i++)
			{
				aResponse->pushInt(mExtModeScopeConfig.getSignalId(i));
			}

			size_t index = mScopeBufferWriteIndex;
			for(size_t i=0; i<mScopeBufferSize; i++)
			{
				aResponse->pushFloat(mScopeBuffer[index]);
				index++;
				if(index >= mScopeBufferSize){
					index = 0;
				}
			}
			mScopeResetReq = true; // get ready for next capture
		}
	}
}

bool VeristandExtModeAdapter_p::getTriggerSign(){
	int32_t num = 3;
	int32_t sigs[] = {0, mTriggerChannel, -1};
	double values[3];
	mModel->probeSignals(&sigs[0], 3, &values[0], &num);
	bool sign = (values[2] >= mTriggerLevel);
	if(mTriggerEdge > 0){
		return !sign;
	} else {
		return sign;
	}
}

void VeristandExtModeAdapter_p::captureScopeSignals(double aTime){
//	std::cout << "Step at: " << aTime << std::endl;

	boost::mutex::scoped_lock lock(mScopeMutex); // critical section for signal capture

	if(mScopeResetReq){
		mScopeState = ScopeState_Disabled;
		mScopeResetReq = false;
	}

	switch(mScopeState){
		case ScopeState_Disabled:
		{
			if(mScopeArmReq){
				mScopeArmReq = false;
				mScopeNumStepsCaptured = 0;
				mScopeNumStepsInBuffer = 0;
				mScopeBufferWriteIndex = 0;
				mScopeDecimationCtr = 1; // get first sample immediately

				if(mTriggerChannel < 0){
					// no trigger signal, trigger right away
					mScopeState = ScopeState_Triggered;
				} else {
					mLastTriggerSign = getTriggerSign();
					mScopeState = ScopeState_Armed;
				}
			}
		}
		break;

		case ScopeState_Armed:
		case ScopeState_Triggered:
		{
			mScopeDecimationCtr--;
			if(mScopeDecimationCtr != 0){
				break;
			}
			mScopeDecimationCtr = mScopeDecimationPrd;

			if(mScopeState != ScopeState_Triggered){
				bool triggerSign = getTriggerSign();
		        if(!mLastTriggerSign &&  triggerSign){
					if(mTriggerDelay >= 0){
						// positive trigger delay means we have to delay actual trigger
						mScopeNumStepsCaptured = -mTriggerDelay;
		        			mScopeState = ScopeState_Triggered;
					} else {
						// negative trigger delay means we display data already captured
						if(mScopeNumStepsInBuffer >= (-mTriggerDelay)){
							mScopeNumStepsCaptured = -mTriggerDelay;
			        			mScopeState = ScopeState_Triggered;
						}
					}
		        }
		        	mLastTriggerSign = triggerSign;
			}

			int32_t num = mMaxNumOfSignals+2; // first two entries "book-keeping" and "timestamp"
			mModel->probeSignals(&mScopeSignalIndices[0], mMaxNumOfSignals+2, &mScopeRowBuffer[0], &num);
			std::copy(&mScopeRowBuffer[2], &mScopeRowBuffer[num], &mScopeBuffer[mScopeBufferWriteIndex]);

			mScopeBufferWriteIndex += (num-2);
			if(mScopeBufferWriteIndex >= mScopeBufferSize){
				mScopeBufferWriteIndex = 0;
			}

			if(mScopeNumStepsInBuffer < mNumTimeStepsRequested){
				mScopeNumStepsInBuffer++;
			}

			if(mScopeState == ScopeState_Triggered){
				mScopeNumStepsCaptured++;
				if(mScopeNumStepsCaptured == (int)mNumTimeStepsRequested){
					mScopeState = ScopeState_Ready;
					mServer->requestSend();
				}
			}
		}
		break;

		case ScopeState_Ready:
			break;

		default:
			mScopeState = ScopeState_Disabled;
			break;
	}
}

VeristandExtModeAdapter::VeristandExtModeAdapter(SharedVeristandModel aModel):
	pimpl(new VeristandExtModeAdapter_p(aModel)){
}

VeristandExtModeAdapter::~VeristandExtModeAdapter(){

}

bool VeristandExtModeAdapter::initialize(size_t aMaxNumOfSignals, size_t aMaxScopeBufferSize){
	return pimpl->initialize(aMaxNumOfSignals, aMaxScopeBufferSize);
}

bool VeristandExtModeAdapter::start(unsigned int port){
	return pimpl->start(port);
}

void VeristandExtModeAdapter::stop(){
	pimpl->stop();
}

void VeristandExtModeAdapter::captureScopeSignals(double aTime){
	pimpl->captureScopeSignals(aTime);
}
