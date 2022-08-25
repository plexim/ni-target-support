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

#ifndef VERISTAND_MODEL_H_
#define VERISTAND_MODEL_H_

#include <vector>
#include <map>

#include <boost/noncopyable.hpp>
#include <boost/shared_ptr.hpp>

#include "VeristandDllWrapper.hpp"

class VeristandModel;
typedef boost::shared_ptr<VeristandModel> SharedVeristandModel;

class VeristandModel : private boost::noncopyable {
public:
	VeristandModel(SharedVeristandDllWrapper aDllWrapper);
	virtual ~VeristandModel();

	bool initialize();

	int32_t probeSignals(int32_t *sigindices, int32_t numsigs, double *value, int32_t* num){
		return mDllWrapper->probeSignals(sigindices, numsigs, value, num);
	}

	bool getParameter(int32_t aFlattenedIndex, double &aValue);

	bool setParameter(int32_t aFlattenedIndex, double aValue);

	bool commitParameters();

   	std::string getBuildInfo(){
   		return mBuildInfo;
   	}
   	std::string getModelName(){
   		return mModelName;
   	}
   	double getBaseTimeStep(){
   		return mBaseTimeStep;
   	}

    	int32_t getNumParametersFlattened(){
    		return mNumFlattenedParameters;
    	}

   	int32_t getNumSignalsFlattened(){
   		return mNumFlattenedSignals;
   	}

   	std::vector<char> getModelChecksum(){
   		return mModelChecksum;
   	}

   	size_t getNumInputsFlattened(){
   		return mNumFlattenedInputs;
   	}

   	size_t getNumOutputsFlattened(){
   		return mNumFlattenedOutputs;
   	}

private:
   	std::string mBuildInfo;
   	std::string mModelName;
   	double mBaseTimeStep;
    	int32_t mNumFlattenedParameters;
   	int32_t mNumFlattenedSignals;
   	std::vector<char> mModelChecksum;
	size_t mNumFlattenedInputs;
	size_t mNumFlattenedOutputs;

	// order matters
	SharedVeristandDllWrapper mDllWrapper;
	std::map<int32_t, int32_t> mParameterIndexLookup;
	std::map<int32_t, int32_t> mParameterSubindexLookup;
};

#endif // VERISTAND_MODEL_H_
