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

#include <iostream>

#include "VeristandModel.h"

VeristandModel::VeristandModel(SharedVeristandDllWrapper aDllWrapper):
	mDllWrapper(aDllWrapper),
	mParameterIndexLookup(),
	mParameterSubindexLookup(){
}

VeristandModel::~VeristandModel(){
}

bool VeristandModel::initialize(){
	{
		uint32_t major, minor, fix, build;
		mDllWrapper->getModelFrameworkVersion(&major, &minor, &fix, &build);
		std::cout << "Version " << major << "-" << minor << "-" << fix << "-" << build << std::endl;

	}
	{
		std::vector<char> name;
		int32_t len = -1;
		mDllWrapper->getModelSpec(0, &len, 0, 0, 0, 0);
		name.resize(len);
		mDllWrapper->getModelSpec(&name[0], &len, &mBaseTimeStep, 0, 0, 0);
		mModelName = std::string(name.begin(), name.end());
		std::cout << "Model name: " << mModelName << std::endl;
	}
	{
		int32_t checksumLen = -1;
		mDllWrapper->getModelChecksum(0, &checksumLen);
		mModelChecksum.resize(checksumLen);
		mDllWrapper->getModelChecksum(&mModelChecksum[0], &checksumLen);
		std::string s(mModelChecksum.begin(), mModelChecksum.end());
		std::cout << "Model checksum: " << s << std::endl;
	}
	{
		std::vector<char> detail;
		int32_t len = -1;
		mDllWrapper->getBuildInfo(0, &len);
		detail.resize(len+1);
		mDllWrapper->getBuildInfo(&detail[0], &len);
		mBuildInfo = std::string(detail.begin(), detail.end());
		std::cout << "Build info: " <<  mBuildInfo << std::endl;
	}
	{
		int32_t indices[100];
		int32_t len = sizeof(indices)/sizeof(int32_t);
		mDllWrapper->getParameterIndices(&indices[0], &len);

		mNumFlattenedParameters = 0;
		for(int i=0; i<len; i++){
			int32_t paramidx = indices[i];
			int32_t dims[100];
			int32_t numdim = -1;

			mDllWrapper->getParameterSpec(&paramidx, 0, 0, 0, 0 ,0, 0, &numdim); // first query size of dimension
			mDllWrapper->getParameterSpec(&paramidx, 0, 0, 0, 0 ,0, &dims[0], &numdim); // first query size of dimension

			int flattenedDim = 1;
			for(int j=0; j<numdim; j++){
				flattenedDim *= dims[j];
			}

			for(int j=0; j<flattenedDim; j++){
				mParameterIndexLookup.insert(std::pair<int32_t, int32_t>(mNumFlattenedParameters, paramidx));
				mParameterSubindexLookup.insert(std::pair<int32_t, int32_t>(mNumFlattenedParameters, j));
				mNumFlattenedParameters++;
			}
		}
		std::cout << "Num flattened parameters: " << mNumFlattenedParameters << std::endl;
	}

#if 0
	{
		int32_t indices[100];
		int32_t len = sizeof(indices)/sizeof(int32_t);

		mDllWrapper->getParameterIndices(&indices[0], &len);

		for(int i=0; i<len; i++){
			int32_t paramidx = indices[i];
			//char* ID;
			int32_t ID_len = 0;
			char paramname[1000];
			int32_t pnlen = sizeof(paramname)-1;
			int32_t datatype;
			int32_t dims[100];
			int32_t numdim = -1;

			mDllWrapper->getParameterSpec(&paramidx, 0, 0, 0, 0 ,0, 0, &numdim); // first query size of dimension
			mDllWrapper->getParameterSpec(&paramidx, 0, &ID_len, &paramname[0], &pnlen, &datatype, &dims[0], &numdim);

			paramname[pnlen] = '\0';
			std::cout << "Parameter index (" << paramidx  << "): " << std::string(paramname) << " = [";
			int flattenedDim = 1;
			for(int j=0; j<numdim; j++){
				flattenedDim *= dims[j];
			}
			for(int j=0; j<flattenedDim; j++){
				double val;
				mDllWrapper->getParameter(paramidx, j, &val);
				std::cout << val;
				if(j < flattenedDim-1){
					std::cout << ", ";
				}
			}
			std::cout << "]" << std::endl;
		}
	}
#endif

	{
		int32_t sigidx = -1;
		mNumFlattenedSignals = mDllWrapper->getSignalSpec(&sigidx, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0);
		std::cout << "Num flattened signals: " << mNumFlattenedSignals << std::endl;
	}

#if 0
	{
		int32_t sigidx = -1;
		//char* ID;
		int32_t ID_len = 0;
		char blkname[1000];
		int32_t bnlen = sizeof(blkname)-1;
		int32_t portnum;
		char signame[1000];
		int32_t snlen = sizeof(signame)-1;
		int32_t datatype;
		int32_t dims[100];
		int32_t numdim = sizeof(dims)/sizeof(int32_t);

		int32_t len = mDllWrapper->getSignalSpec(&sigidx, 0, &ID_len, &blkname[0], &bnlen, &portnum, &signame[0], &snlen, &datatype, &dims[0], &numdim);

		mNumFlattenedParameters = 0;
		for(int i=0; i<len; i++){
			sigidx = i;
			ID_len = 0;
			bnlen = sizeof(blkname)-1;
			snlen = sizeof(signame)-1;
			numdim = -1;
			mDllWrapper->getSignalSpec(&sigidx, 0, 0, 0, 0, 0, 0, 0, 0, 0, &numdim);
			mDllWrapper->getSignalSpec(&sigidx, 0, &ID_len, &blkname[0], &bnlen, &portnum, &signame[0], &snlen, &datatype, &dims[0], &numdim);
			blkname[bnlen] = '\0';
			signame[snlen] = '\0';

			std::cout << "Signal index (" << i  << "): " << std::string(signame) << " in block " << std::string(blkname) << " = [";

			int flattenedDim = 1;
			for(int j=0; j<numdim; j++){
				flattenedDim *= dims[j];
			}
			for(int j=0; j<flattenedDim; j++){
				std::cout << "x";
				if(j < flattenedDim-1){
					std::cout << ", ";
				}
			}
			std::cout << "]" << std::endl;

		}
	}
#endif
	{
		mNumFlattenedInputs = 0;
		mNumFlattenedOutputs = 0;

		int32_t numPorts = mDllWrapper->getExtIOSpec(-1, 0, 0, 0, 0, 0, 0);
		for(int32_t i=0; i<numPorts; i++){
			int32_t dims[100];
			int32_t numdim = -1;
			int32_t type;

			mDllWrapper->getExtIOSpec(i, 0, 0, 0, 0, 0, &numdim);
			mDllWrapper->getExtIOSpec(i, 0, 0, 0, &type, &dims[0], &numdim);

			int flattenedDim = 1;
			for(int j=0; j<numdim; j++){
				flattenedDim *= dims[j];
			}
			if(type == 0){
				mNumFlattenedInputs += flattenedDim;
			} else {
				mNumFlattenedOutputs += flattenedDim;
			}
		}
	}

	return true;
}

bool VeristandModel::getParameter(int32_t aFlattenedIndex, double &aValue){
	std::map<int32_t, int32_t>::const_iterator index = mParameterIndexLookup.find(aFlattenedIndex);
	std::map<int32_t, int32_t>::const_iterator subindex = mParameterSubindexLookup.find(aFlattenedIndex);

	if((index == mParameterIndexLookup.end()) || (subindex == mParameterSubindexLookup.end())){
		std::cout << "Unable to determine parameter indices." << std::endl;
		return false;
	}

	std::cout << index->second << "/" << subindex->second << std::endl;
	return (mDllWrapper->getParameter(index->second, subindex->second, &aValue) == 0);
}

bool VeristandModel::setParameter(int32_t aFlattenedIndex, double aValue){
	std::map<int32_t, int32_t>::const_iterator index = mParameterIndexLookup.find(aFlattenedIndex);
	std::map<int32_t, int32_t>::const_iterator subindex = mParameterSubindexLookup.find(aFlattenedIndex);

	if((index == mParameterIndexLookup.end()) || (subindex == mParameterSubindexLookup.end())){
		std::cout << "Unable to determine parameter indices." << std::endl;
		return false;
	}

	std::cout << index->second << "/" << subindex->second << std::endl;
	return (mDllWrapper->setParameter(index->second, subindex->second, aValue) == 0);
}

bool VeristandModel::commitParameters(){
	return (mDllWrapper->setParameter(-1, 0, 0) == 0);
}
