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

#ifndef VERISTAND_DLL_WRAPPER_HPP_
#define VERISTAND_DLL_WRAPPER_HPP_

#include <stdint.h>

#ifdef SCONS_TARGET_WIN
#include <windows.h>
#endif
#ifdef SCONS_TARGET_UNIX
#include <dlfcn.h>
#endif

#include <boost/shared_ptr.hpp>


class VeristandDllWrapper;
typedef boost::shared_ptr<VeristandDllWrapper> SharedVeristandDllWrapper;

class VeristandDllWrapper_p;
class VeristandDllWrapper {

public:
	VeristandDllWrapper(std::string aDllName);
	virtual ~VeristandDllWrapper();

	int loadDll();
	void unloadDll();

	int32_t getModelFrameworkVersion(uint32_t* major, uint32_t* minor, uint32_t* fix, uint32_t* build);
	int32_t modelStart(void);
	int32_t initializeModel(double finaltime, double *outTimeStep, int32_t *num_in, int32_t *num_out, int32_t* num_tasks);
	int32_t postOutputs(double *outData);
	int32_t modelUpdate(void);
	int32_t schedule(double *inData, double *outData, double *outTime, int32_t *dispatchtasks);
	int32_t taskTakeOneStep(int32_t taskid);
	int32_t finalizeModel(void);
	int32_t probeSignals(int32_t *sigindices, int32_t numsigs, double *value, int32_t* num);
	int32_t setScalarParameterInline(uint32_t index,  uint32_t subindex, double paramvalue);
	int32_t setVectorParameter(uint32_t index, const double* paramvalues, uint32_t paramlength);
	int32_t setParameter(int32_t index, int32_t subindex, double val);
	int32_t getParameter(int32_t index, int32_t subindex, double* val);
	int32_t getVectorParameter(uint32_t index, double* paramValues, uint32_t paramLength);
	int32_t getErrorMessageLength(void);
	int32_t modelError(char* errmsg, int32_t* msglen);
	int32_t taskRunTimeInfo(int32_t halt, int32_t* overruns, int32_t *numtasks);
	int32_t getSimState(int32_t* numContStates, char* contStatesNames, double* contStates, int32_t* numDiscStates,
										char* discStatesNames, double* discStates, int32_t* numClockTicks, char* clockTicksNames, int32_t* clockTicks);
	int32_t setSimState(double* contStates, double* discStates, int32_t* clockTicks);
	int32_t getBuildInfo(char* detail, int32_t* len);
	int32_t getModelSpec(char* name, int32_t *namelen, double *baseTimeStep, int32_t *outNumInports,
												int32_t *outNumOutports, int32_t *numtasks);
	int32_t getParameterIndices(int32_t* indices, int32_t* len);
	int32_t getParameterSpec(int32_t* paramidx, char* ID, int32_t* ID_len, char* paramname, int32_t *pnlen,
											  int32_t *datatype, int32_t* dims, int32_t* numdim);
	int32_t getSignalSpec(int32_t* sigidx, char* ID, int32_t* ID_len, char* blkname, int32_t* bnlen, int32_t *portnum,
										   char* signame, int32_t* snlen, int32_t *datatype, int32_t* dims, int32_t* numdim);
	int32_t getTaskSpec(int32_t index, int32_t* tid, double *tstep, double *offset);
	int32_t getExtIOSpec(int32_t index, int32_t *idx, char* name, int32_t* tid, int32_t *type, int32_t *dims, int32_t* numdims);

	// Plexim functions
	int32_t getModelChecksum(char* checksum, int32_t* checksumlen);

private:
	VeristandDllWrapper_p *pimpl;
};

#ifdef SCONS_TARGET_WIN
inline static void CORE_dispError(DWORD dw){
	LPVOID lpMsgBuf;

	FormatMessage(
			FORMAT_MESSAGE_ALLOCATE_BUFFER |
			FORMAT_MESSAGE_FROM_SYSTEM |
			FORMAT_MESSAGE_IGNORE_INSERTS,
			NULL,
			dw,
			MAKELANGID(LANG_NEUTRAL, SUBLANG_DEFAULT),
			(LPTSTR) &lpMsgBuf,
			0, NULL );

	printf("Error: %s \n", lpMsgBuf);
}
#endif

class VeristandDllWrapper_p {
	typedef int32_t (*DllGetModelFrameworkVersionFcn)(uint32_t* major, uint32_t* minor, uint32_t* fix, uint32_t* build);
	typedef int32_t (*DllModelStartFcn)(void);
	typedef int32_t (*DllInitializeModelFcn)(double finaltime, double *outTimeStep, int32_t *num_in, int32_t *num_out, int32_t* num_tasks);
	typedef int32_t (*DllPostOutputsFcn)(double *outData);
	typedef int32_t (*DllModelUpdateFcn)(void);
	typedef int32_t (*DllScheduleFcn)(double *inData, double *outData, double *outTime, int32_t *dispatchtasks);
	typedef int32_t (*DllTaskTakeOneStepFcn)(int32_t taskid);
	typedef int32_t (*DllFinalizeModelFcn)(void);
	typedef int32_t (*DllProbeSignalsFcn)(int32_t *sigindices, int32_t numsigs, double *value, int32_t* num);
	typedef int32_t (*DllSetScalarParameterInlineFcn)(uint32_t index,  uint32_t subindex, double paramvalue);
	typedef int32_t (*DllSetVectorParameterFcn)(uint32_t index, const double* paramvalues, uint32_t paramlength);
	typedef int32_t (*DllSetParameterFcn)(int32_t index, int32_t subindex, double val);
	typedef int32_t (*DllGetParameterFcn)(int32_t index, int32_t subindex, double* val);
	typedef int32_t (*DllGetVectorParameterFcn)(uint32_t index, double* paramValues, uint32_t paramLength);
	typedef int32_t (*DllGetErrorMessageLengthFcn)(void);
	typedef int32_t (*DllModelErrorFcn)(char* errmsg, int32_t* msglen);
	typedef int32_t (*DllTaskRunTimeInfoFcn)(int32_t halt, int32_t* overruns, int32_t *numtasks);
	typedef int32_t (*DllGetSimStateFcn)(int32_t* numContStates, char* contStatesNames, double* contStates, int32_t* numDiscStates,
									char* discStatesNames, double* discStates, int32_t* numClockTicks, char* clockTicksNames, int32_t* clockTicks);
	typedef int32_t (*DllSetSimStateFcn)(double* contStates, double* discStates, int32_t* clockTicks);
	typedef int32_t (*DllGetBuildInfoFcn)(char* detail, int32_t* len);
	typedef int32_t (*DllGetModelSpecFcn)(char* name, int32_t *namelen, double *baseTimeStep, int32_t *outNumInports,
											int32_t *outNumOutports, int32_t *numtasks);
	typedef int32_t (*DllGetParameterIndicesFcn)(int32_t* indices, int32_t* len);
	typedef int32_t (*DllGetParameterSpecFcn)(int32_t* paramidx, char* ID, int32_t* ID_len, char* paramname, int32_t *pnlen,
										  int32_t *datatype, int32_t* dims, int32_t* numdim);
	typedef int32_t (*DllGetSignalSpecFcn)(int32_t* sigidx, char* ID, int32_t* ID_len, char* blkname, int32_t* bnlen, int32_t *portnum,
									   char* signame, int32_t* snlen, int32_t *datatype, int32_t* dims, int32_t* numdim);
	typedef int32_t (*DllGetTaskSpecFcn)(int32_t index, int32_t* tid, double *tstep, double *offset);
	typedef int32_t (*DllGetExtIOSpecFcn)(int32_t index, int32_t *idx, char* name, int32_t* tid, int32_t *type, int32_t *dims, int32_t* numdims);

	typedef 	int32_t (*DllGetModelChecksumFnc)(char* checksum, int32_t* checksumlen);
public:
	VeristandDllWrapper_p(std::string aDllName);
	virtual ~VeristandDllWrapper_p();

	int loadDll();
	void unloadDll();

	inline DllGetModelFrameworkVersionFcn getGetModelFrameworkVersionFcn() const { return mDllGetModelFrameworkVersionFcn; }
	inline DllModelStartFcn getModelStartFcn() const { return mDllModelStartFcn; }
	inline DllInitializeModelFcn getInitializeModelFcn() const { return mDllInitializeModelFcn; }
//	inline DllPostOutputsFcn getPostOutputsFcn() const { return mDllPostOutputsFcn; }
	inline DllModelUpdateFcn getModelUpdateFcn() const { return mDllModelUpdateFcn; }
	inline DllScheduleFcn getScheduleFcn() const { return mDllScheduleFcn; }
//	inline DllTaskTakeOneStepFcn getTaskTakeOneStepFcn() const { return mDllTaskTakeOneStepFcn; }
	inline DllFinalizeModelFcn getFinalizeModelFcn() const { return mDllFinalizeModelFcn; }
	inline DllProbeSignalsFcn getProbeSignalsFcn() const { return mDllProbeSignalsFcn; }
	inline DllSetScalarParameterInlineFcn getSetScalarParameterInlineFcn() const { return mDllSetScalarParameterInlineFcn; }
	inline DllSetVectorParameterFcn getSetVectorParameterFcn() const { return mDllSetVectorParameterFcn; }
	inline DllSetParameterFcn getSetParameterFcn() const { return mDllSetParameterFcn; }
	inline DllGetParameterFcn getGetParameterFcn() const { return mDllGetParameterFcn; }
	inline DllGetVectorParameterFcn getGetVectorParameterFcn() const { return mDllGetVectorParameterFcn; }
	inline DllGetErrorMessageLengthFcn getGetErrorMessageLengthFcn() const { return mDllGetErrorMessageLengthFcn; }
	inline DllModelErrorFcn getModelErrorFcn() const { return mDllModelErrorFcn; }
//	inline DllTaskRunTimeInfoFcn getTaskRunTimeInfoFcn() const { return mDllTaskRunTimeInfoFcn; }
	inline DllGetSimStateFcn getGetSimStateFcn() const { return mDllGetSimStateFcn; }
	inline DllSetSimStateFcn getSetSimStateFcn() const { return mDllSetSimStateFcn; }
	inline DllGetBuildInfoFcn getGetBuildInfoFcn() const { return mDllGetBuildInfoFcn; }
	inline DllGetModelSpecFcn getGetModelSpecFcn() const { return mDllGetModelSpecFcn; }
	inline DllGetParameterIndicesFcn getGetParameterIndicesFcn() const { return mDllGetParameterIndicesFcn; }
	inline DllGetParameterSpecFcn getGetParameterSpecFcn() const { return mDllGetParameterSpecFcn; }
	inline DllGetSignalSpecFcn getGetSignalSpecFcn() const { return mDllGetSignalSpecFcn; }
//	inline DllGetTaskSpecFcn getGetTaskSpecFcn() const { return mDllGetTaskSpecFcn; }
	inline DllGetExtIOSpecFcn getGetExtIOSpecFcn() const { return mDllGetExtIOSpecFcn; }

	inline DllGetModelChecksumFnc getGetModelChecksumFnc() const { return mDllGetModelChecksumFnc; }

private:
	int allPointersAreNonNull();

	void* mHandle;
	std::string mDllName;

	DllGetModelFrameworkVersionFcn mDllGetModelFrameworkVersionFcn;
	DllModelStartFcn mDllModelStartFcn;
	DllInitializeModelFcn mDllInitializeModelFcn;
//	DllPostOutputsFcn mDllPostOutputsFcn;
	DllModelUpdateFcn mDllModelUpdateFcn;
	DllScheduleFcn mDllScheduleFcn;
//	DllTaskTakeOneStepFcn mDllTaskTakeOneStepFcn;
	DllFinalizeModelFcn mDllFinalizeModelFcn;
	DllProbeSignalsFcn mDllProbeSignalsFcn;
	DllSetScalarParameterInlineFcn mDllSetScalarParameterInlineFcn;
	DllSetVectorParameterFcn mDllSetVectorParameterFcn;
	DllSetParameterFcn mDllSetParameterFcn;
	DllGetParameterFcn mDllGetParameterFcn;
	DllGetVectorParameterFcn mDllGetVectorParameterFcn;
	DllGetErrorMessageLengthFcn mDllGetErrorMessageLengthFcn;
	DllModelErrorFcn mDllModelErrorFcn;
//	DllTaskRunTimeInfoFcn mDllTaskRunTimeInfoFcn;
	DllGetSimStateFcn mDllGetSimStateFcn;
	DllSetSimStateFcn mDllSetSimStateFcn;
	DllGetBuildInfoFcn mDllGetBuildInfoFcn;
	DllGetModelSpecFcn mDllGetModelSpecFcn;
	DllGetParameterIndicesFcn mDllGetParameterIndicesFcn;
	DllGetParameterSpecFcn mDllGetParameterSpecFcn;
	DllGetSignalSpecFcn mDllGetSignalSpecFcn;
//	DllGetTaskSpecFcn mDllGetTaskSpecFcn;
	DllGetExtIOSpecFcn mDllGetExtIOSpecFcn;

	DllGetModelChecksumFnc mDllGetModelChecksumFnc;
};

inline VeristandDllWrapper_p::VeristandDllWrapper_p(std::string aDllName):
		mHandle(NULL), mDllName(aDllName) {
}

inline VeristandDllWrapper_p::~VeristandDllWrapper_p(){
	unloadDll();
}

#ifdef SCONS_TARGET_WIN
inline void VeristandDllWrapper_p::unloadDll(){
	if (mHandle)
	{
		FreeLibrary((HMODULE)mHandle);
		mHandle = NULL;
	}
}

inline int VeristandDllWrapper_p::loadDll(){
	std::cout << "Loading " << mDllName << std::endl;
	mHandle = LoadLibrary(mDllName.c_str());
	if (!mHandle){
		printf("CORE LoadLibrary failed with error: %d \n", GetLastError());
		CORE_dispError(GetLastError());
		return(-1);
	} else {
		mDllGetModelFrameworkVersionFcn = (DllGetModelFrameworkVersionFcn)GetProcAddress((HMODULE)mHandle, "NIRT_GetModelFrameworkVersion");
		mDllModelStartFcn = (DllModelStartFcn)GetProcAddress((HMODULE)mHandle, "NIRT_ModelStart");
		mDllInitializeModelFcn = (DllInitializeModelFcn)GetProcAddress((HMODULE)mHandle, "NIRT_InitializeModel");
//		mDllPostOutputsFcn = (DllPostOutputsFcn)GetProcAddress((HMODULE)mHandle, "NIRT_PostOutputs");
		mDllModelUpdateFcn = (DllModelUpdateFcn)GetProcAddress((HMODULE)mHandle, "NIRT_ModelUpdate");
		mDllScheduleFcn = (DllScheduleFcn)GetProcAddress((HMODULE)mHandle, "NIRT_Schedule");
//		mDllTaskTakeOneStepFcn = (DllTaskTakeOneStepFcn)GetProcAddress((HMODULE)mHandle, "NIRT_TaskTakeOneStep");
		mDllFinalizeModelFcn = (DllFinalizeModelFcn)GetProcAddress((HMODULE)mHandle, "NIRT_FinalizeModel");
		mDllProbeSignalsFcn = (DllProbeSignalsFcn)GetProcAddress((HMODULE)mHandle, "NIRT_ProbeSignals");
		mDllSetScalarParameterInlineFcn = (DllSetScalarParameterInlineFcn)GetProcAddress((HMODULE)mHandle, "NIRT_SetScalarParameterInline");

		mDllSetVectorParameterFcn = (DllSetVectorParameterFcn)GetProcAddress((HMODULE)mHandle, "NIRT_SetVectorParameter");
		mDllSetParameterFcn = (DllSetParameterFcn)GetProcAddress((HMODULE)mHandle, "NIRT_SetParameter");
		mDllGetParameterFcn = (DllGetParameterFcn)GetProcAddress((HMODULE)mHandle, "NIRT_GetParameter");
		mDllGetVectorParameterFcn = (DllGetVectorParameterFcn)GetProcAddress((HMODULE)mHandle, "NIRT_GetVectorParameter");
		mDllGetErrorMessageLengthFcn = (DllGetErrorMessageLengthFcn)GetProcAddress((HMODULE)mHandle, "NIRT_GetErrorMessageLength");
		mDllModelErrorFcn = (DllModelErrorFcn)GetProcAddress((HMODULE)mHandle, "NIRT_ModelError");
//		mDllTaskRunTimeInfoFcn = (DllTaskRunTimeInfoFcn)GetProcAddress((HMODULE)mHandle, "NIRT_TaskRunTimeInfo");
		mDllGetSimStateFcn = (DllGetSimStateFcn)GetProcAddress((HMODULE)mHandle, "NIRT_GetSimState");
		mDllSetSimStateFcn = (DllSetSimStateFcn)GetProcAddress((HMODULE)mHandle, "NIRT_SetSimState");
		mDllGetBuildInfoFcn = (DllGetBuildInfoFcn)GetProcAddress((HMODULE)mHandle, "NIRT_GetBuildInfo");
		mDllGetModelSpecFcn = (DllGetModelSpecFcn)GetProcAddress((HMODULE)mHandle, "NIRT_GetModelSpec");
		mDllGetParameterIndicesFcn = (DllGetParameterIndicesFcn)GetProcAddress((HMODULE)mHandle, "NIRT_GetParameterIndices");
		mDllGetParameterSpecFcn = (DllGetParameterSpecFcn)GetProcAddress((HMODULE)mHandle, "NIRT_GetParameterSpec");
		mDllGetSignalSpecFcn = (DllGetSignalSpecFcn)GetProcAddress((HMODULE)mHandle, "NIRT_GetSignalSpec");
//		mDllGetTaskSpecFcn = (DllGetTaskSpecFcn)GetProcAddress((HMODULE)mHandle, "NIRT_GetTaskSpec");
		mDllGetExtIOSpecFcn = (DllGetExtIOSpecFcn)GetProcAddress((HMODULE)mHandle, "NIRT_GetExtIOSpec");

		mDllGetModelChecksumFnc = (DllGetModelChecksumFnc)GetProcAddress((HMODULE)mHandle, "PLX_GetModelChecksum");

		if(!allPointersAreNonNull()){
			printf("Unable to obtain function handles. Error: %d \n", GetLastError());
			CORE_dispError(GetLastError());
			return(-2);
		}
	}
	return(0);
}
#endif
#ifdef SCONS_TARGET_UNIX
inline void VeristandDllWrapper_p::unloadDll(){
	if (mHandle)
	{
		dlclose(mHandle);
		mHandle = NULL;
	}
}

inline int VeristandDllWrapper_p::loadDll(){
	std::cout << "Loading " << mDllName << std::endl;
	mHandle = dlopen(mDllName.c_str(), RTLD_LAZY);
	if (!mHandle){
		printf("CORE LoadLibrary failed with error: %s \n", dlerror());
		return(-1);
	} else {
		mDllGetModelFrameworkVersionFcn = (DllGetModelFrameworkVersionFcn)dlsym(mHandle, "NIRT_GetModelFrameworkVersion");
		mDllModelStartFcn = (DllModelStartFcn)dlsym(mHandle, "NIRT_ModelStart");
		mDllInitializeModelFcn = (DllInitializeModelFcn)dlsym(mHandle, "NIRT_InitializeModel");
//		mDllPostOutputsFcn = (DllPostOutputsFcn)dlsym(mHandle, "NIRT_PostOutputs");
		mDllModelUpdateFcn = (DllModelUpdateFcn)dlsym(mHandle, "NIRT_ModelUpdate");
		mDllScheduleFcn = (DllScheduleFcn)dlsym(mHandle, "NIRT_Schedule");
//		mDllTaskTakeOneStepFcn = (DllTaskTakeOneStepFcn)dlsym(mHandle, "NIRT_TaskTakeOneStep");
		mDllFinalizeModelFcn = (DllFinalizeModelFcn)dlsym(mHandle, "NIRT_FinalizeModel");
		mDllProbeSignalsFcn = (DllProbeSignalsFcn)dlsym(mHandle, "NIRT_ProbeSignals");
		mDllSetScalarParameterInlineFcn = (DllSetScalarParameterInlineFcn)dlsym(mHandle, "NIRT_SetScalarParameterInline");

		mDllSetVectorParameterFcn = (DllSetVectorParameterFcn)dlsym(mHandle, "NIRT_SetVectorParameter");
		mDllSetParameterFcn = (DllSetParameterFcn)dlsym(mHandle, "NIRT_SetParameter");
		mDllGetParameterFcn = (DllGetParameterFcn)dlsym(mHandle, "NIRT_GetParameter");
		mDllGetVectorParameterFcn = (DllGetVectorParameterFcn)dlsym(mHandle, "NIRT_GetVectorParameter");
		mDllGetErrorMessageLengthFcn = (DllGetErrorMessageLengthFcn)dlsym(mHandle, "NIRT_GetErrorMessageLength");
		mDllModelErrorFcn = (DllModelErrorFcn)dlsym(mHandle, "NIRT_ModelError");
//		mDllTaskRunTimeInfoFcn = (DllTaskRunTimeInfoFcn)dlsym(mHandle, "NIRT_TaskRunTimeInfo");
		mDllGetSimStateFcn = (DllGetSimStateFcn)dlsym(mHandle, "NIRT_GetSimState");
		mDllSetSimStateFcn = (DllSetSimStateFcn)dlsym(mHandle, "NIRT_SetSimState");
		mDllGetBuildInfoFcn = (DllGetBuildInfoFcn)dlsym(mHandle, "NIRT_GetBuildInfo");
		mDllGetModelSpecFcn = (DllGetModelSpecFcn)dlsym(mHandle, "NIRT_GetModelSpec");
		mDllGetParameterIndicesFcn = (DllGetParameterIndicesFcn)dlsym(mHandle, "NIRT_GetParameterIndices");
		mDllGetParameterSpecFcn = (DllGetParameterSpecFcn)dlsym(mHandle, "NIRT_GetParameterSpec");
		mDllGetSignalSpecFcn = (DllGetSignalSpecFcn)dlsym(mHandle, "NIRT_GetSignalSpec");
//		mDllGetTaskSpecFcn = (DllGetTaskSpecFcn)dlsym(mHandle, "NIRT_GetTaskSpec");
		mDllGetExtIOSpecFcn = (DllGetExtIOSpecFcn)dlsym(mHandle, "NIRT_GetExtIOSpec");

		mDllGetModelChecksumFnc = (DllGetModelChecksumFnc)dlsym(mHandle, "PLX_GetModelChecksum");

		if(!allPointersAreNonNull()){
			printf("Unable to obtain function handles. Error: %s \n", dlerror());

			return(-2);
		}
	}
	return(0);
}
#endif

inline int VeristandDllWrapper_p::allPointersAreNonNull() {
	return(
		(mDllGetModelFrameworkVersionFcn != NULL) &&
		(mDllModelStartFcn != NULL) &&
		(mDllInitializeModelFcn != NULL) &&
//		(mDllPostOutputsFcn != NULL) &&
		(mDllModelUpdateFcn != NULL) &&
		(mDllScheduleFcn != NULL) &&
//		(mDllTaskTakeOneStepFcn != NULL) &&
		(mDllFinalizeModelFcn != NULL) &&
		(mDllProbeSignalsFcn != NULL) &&
		(mDllSetScalarParameterInlineFcn != NULL) &&
		(mDllSetVectorParameterFcn != NULL) &&
		(mDllSetParameterFcn != NULL) &&
		(mDllGetParameterFcn != NULL) &&
		(mDllGetVectorParameterFcn != NULL) &&
		(mDllGetErrorMessageLengthFcn != NULL) &&
		(mDllModelErrorFcn != NULL) &&
//		(mDllTaskRunTimeInfoFcn != NULL) &&
		(mDllGetSimStateFcn != NULL) &&
		(mDllSetSimStateFcn != NULL) &&
		(mDllGetBuildInfoFcn != NULL) &&
		(mDllGetModelSpecFcn != NULL) &&
		(mDllGetParameterIndicesFcn != NULL) &&
		(mDllGetParameterSpecFcn != NULL) &&
		(mDllGetSignalSpecFcn != NULL) &&
//		(mDllGetTaskSpecFcn != NULL) &&
		(mDllGetExtIOSpecFcn != NULL) &&
		(mDllGetModelChecksumFnc != NULL)
	);
}

inline VeristandDllWrapper::VeristandDllWrapper(std::string aDllName) {
	pimpl = new VeristandDllWrapper_p(aDllName);
}

inline VeristandDllWrapper::~VeristandDllWrapper(){
	delete pimpl;
}

inline void VeristandDllWrapper::unloadDll(){
	pimpl->unloadDll();
}

inline int VeristandDllWrapper::loadDll(){
	return pimpl->loadDll();
}

inline int32_t VeristandDllWrapper::getModelFrameworkVersion(uint32_t* major, uint32_t* minor, uint32_t* fix, uint32_t* build){
	return pimpl->getGetModelFrameworkVersionFcn()(major, minor, fix,build);;
}

inline int32_t VeristandDllWrapper::modelStart(void){
	return pimpl->getModelStartFcn()();
}

inline int32_t VeristandDllWrapper::initializeModel(double finaltime, double *outTimeStep, int32_t *num_in, int32_t *num_out, int32_t* num_tasks){
	return pimpl->getInitializeModelFcn()(finaltime, outTimeStep, num_in, num_out, num_tasks);
}

inline int32_t VeristandDllWrapper::postOutputs(double *outData){
	return 0;
}

inline int32_t VeristandDllWrapper::modelUpdate(void){
	return pimpl->getModelUpdateFcn()();
}

inline int32_t VeristandDllWrapper::schedule(double *inData, double *outData, double *outTime, int32_t *dispatchtasks){
	return pimpl->getScheduleFcn()(inData, outData, outTime, dispatchtasks);
}

inline int32_t VeristandDllWrapper::taskTakeOneStep(int32_t taskid){
	return 0;
}

inline int32_t VeristandDllWrapper::finalizeModel(void){
	return pimpl->getFinalizeModelFcn()();
}

inline int32_t VeristandDllWrapper::probeSignals(int32_t *sigindices, int32_t numsigs, double *value, int32_t* num){
	return pimpl->getProbeSignalsFcn()(sigindices, numsigs, value, num);
}

inline int32_t VeristandDllWrapper::setScalarParameterInline(uint32_t index,  uint32_t subindex, double paramvalue){
	return 0;
}

inline int32_t VeristandDllWrapper::setVectorParameter(uint32_t index, const double* paramvalues, uint32_t paramlength){
	return 0;
}

inline int32_t VeristandDllWrapper::setParameter(int32_t index, int32_t subindex, double val){
	return pimpl->getSetParameterFcn()(index, subindex, val);
}

inline int32_t VeristandDllWrapper::getParameter(int32_t index, int32_t subindex, double* val){
	return pimpl->getGetParameterFcn()(index, subindex, val);
}

inline int32_t VeristandDllWrapper::getVectorParameter(uint32_t index, double* paramValues, uint32_t paramLength){
	return 0;
}

inline int32_t VeristandDllWrapper::getErrorMessageLength(void){
	return 0;
}

inline int32_t VeristandDllWrapper::modelError(char* errmsg, int32_t* msglen){
	return 0;
}

inline int32_t VeristandDllWrapper::taskRunTimeInfo(int32_t halt, int32_t* overruns, int32_t *numtasks){
	return 0;
}

inline int32_t VeristandDllWrapper::getSimState(int32_t* numContStates, char* contStatesNames, double* contStates, int32_t* numDiscStates,
									char* discStatesNames, double* discStates, int32_t* numClockTicks, char* clockTicksNames, int32_t* clockTicks){
	return 0;
}

inline int32_t VeristandDllWrapper::setSimState(double* contStates, double* discStates, int32_t* clockTicks){
	return 0;
}

inline int32_t VeristandDllWrapper::getBuildInfo(char* detail, int32_t* len){
	return pimpl->getGetBuildInfoFcn()(detail, len);
}

inline int32_t VeristandDllWrapper::getModelSpec(char* name, int32_t *namelen, double *baseTimeStep, int32_t *outNumInports,
											int32_t *outNumOutports, int32_t *numtasks){
	return pimpl->getGetModelSpecFcn()(name, namelen, baseTimeStep, outNumInports, outNumOutports, numtasks);
}

inline int32_t VeristandDllWrapper::getParameterIndices(int32_t* indices, int32_t* len){
	return pimpl->getGetParameterIndicesFcn()(indices, len);
}

inline int32_t VeristandDllWrapper::getParameterSpec(int32_t* paramidx, char* ID, int32_t* ID_len, char* paramname, int32_t *pnlen,
										  int32_t *datatype, int32_t* dims, int32_t* numdim){
	return pimpl->getGetParameterSpecFcn()(paramidx, ID, ID_len, paramname, pnlen, datatype, dims, numdim);
}

inline int32_t VeristandDllWrapper::getSignalSpec(int32_t* sigidx, char* ID, int32_t* ID_len, char* blkname, int32_t* bnlen, int32_t *portnum,
									   char* signame, int32_t* snlen, int32_t *datatype, int32_t* dims, int32_t* numdim){
	return pimpl->getGetSignalSpecFcn()(sigidx, ID, ID_len, blkname, bnlen, portnum, signame, snlen, datatype, dims, numdim);
}

inline int32_t VeristandDllWrapper::getTaskSpec(int32_t index, int32_t* tid, double *tstep, double *offset){
	return 0;
}

inline int32_t VeristandDllWrapper::getExtIOSpec(int32_t index, int32_t *idx, char* name, int32_t* tid, int32_t *type, int32_t *dims, int32_t* numdims){
	return pimpl->getGetExtIOSpecFcn()(index, idx, name, tid, type, dims, numdims);
}

inline int32_t VeristandDllWrapper::getModelChecksum(char* checksum, int32_t* checksumlen){
	return pimpl->getGetModelChecksumFnc()(checksum, checksumlen);
}


#endif /* VERISTAND_DLL_WRAPPER_HPP_ */
