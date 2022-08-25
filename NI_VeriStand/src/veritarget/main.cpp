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

#include <stdio.h>
#include <stdlib.h>
#include <iostream>

#include <signal.h>

#ifdef SCONS_TARGET_UNIX
#include <unistd.h>
#endif

#include <boost/scoped_ptr.hpp>
#include <boost/thread.hpp>
#include <boost/asio.hpp>
#include <boost/asio/deadline_timer.hpp>
#include <boost/asio/signal_set.hpp>


#include "VeristandDllWrapper.hpp"
#include "VeristandExtModeAdapter.h"
#include "VeristandModel.h"

#ifndef BASE_NAME
#error BASE_NAME undefined.
#endif

#define xstr(x) #x
#define str(x) xstr(x)
#define sub(x) x

#ifdef __cplusplus
extern "C" {
#endif
#include str(sub(BASE_NAME)_vdaq.h)
#include "NIDAQmx.h"
#ifdef __cplusplus
}
#endif

#if defined(SCONS_TARGET_MAC)
#define	MODEL_DLL str(sub(BASE_NAME).dylib)
#elif defined(SCONS_TARGET_WIN)
#define	MODEL_DLL str(sub(BASE_NAME).dll)
#elif defined(SCONS_TARGET_LINUX)
#define	MODEL_DLL str(sub(BASE_NAME).so)
#else
#error Unsupported platform.
#endif

bool KeepAlive;

#ifdef SCONS_TARGET_UNIX
void AbortHandler(int s){
	if(s == 2){
		std::cout  << std::endl << "Gracefully exiting..." << std::endl;
		KeepAlive = false;
	} else {
		printf("Caught signal %d\n",s);
	}
}
#endif

#ifdef SCONS_TARGET_WIN
BOOL WINAPI AbortHandler(DWORD dwType)
{
	switch(dwType) {
	case CTRL_C_EVENT:
		std::cout  << std::endl << "Gracefully exiting..." << std::endl;
		KeepAlive = false;
		break;
	case CTRL_BREAK_EVENT:
	default:
		;;
	}
	return TRUE;
}
#endif

boost::asio::io_context IoService;
boost::asio::deadline_timer StepTimer(IoService);
boost::thread BackgroundThread;

SharedVeristandDllWrapper ModelDllWrapper;
boost::scoped_ptr<VeristandExtModeAdapter> Adapter;
std::vector<double> Inputs;
std::vector<double> Outputs;
double BaseTimeStep;

//Configure for HW Timed Execution
#if (defined(SCONS_TARGET_LINUX) && (USE_SOFTWARE_TIMER==0))
// Function called every hardware interrupt
int32_t MySignalCallback(void* taskHandle, int32_t signalID, void *callbackData)
{
	if(KeepAlive){
		double t;
		int32_t dispatchTasks;

		UpdateIO(&Inputs[0],&Outputs[0]);
		ModelDllWrapper->schedule(&Inputs[0], &Outputs[0], &t, &dispatchTasks);
		Adapter->captureScopeSignals(t);
	    ModelDllWrapper->modelUpdate();
		//std::cout << "Running my signal callback Code." << std::endl;
	}
	return 0;
}


void SignalWaitHanlder( const boost::system::error_code &ec , int signal_number )
{
	if(ec){
		std::cout << "Error Code." << std::endl;
	}
}
//Configure for SW Timed Execution with Hardware
#elif  (defined(SCONS_TARGET_LINUX) && (USE_SOFTWARE_TIMER==1))
void Step(const boost::system::error_code &ec){
	if(!ec){
		if(KeepAlive){

			double t;
			int32_t dispatchTasks;
			UpdateIO(&Inputs[0],&Outputs[0]);
			ModelDllWrapper->schedule(&Inputs[0], &Outputs[0], &t, &dispatchTasks);
			Adapter->captureScopeSignals(t);
		    ModelDllWrapper->modelUpdate();

			StepTimer.expires_from_now(boost::posix_time::microseconds((uint32_t)(BaseTimeStep*1e6)));
			StepTimer.async_wait(Step);
		}
	}
}

//Configure for SW Timed Execution on Target Machine (no DAQ libs)
#else
void Step(const boost::system::error_code &ec){
	if(!ec){
		if(KeepAlive){

			double t;
			int32_t dispatchTasks;
			ModelDllWrapper->schedule(&Inputs[0], &Outputs[0], &t, &dispatchTasks);
			Adapter->captureScopeSignals(t);
		    ModelDllWrapper->modelUpdate();

			StepTimer.expires_from_now(boost::posix_time::microseconds((uint32_t)(BaseTimeStep*1e6)));
			StepTimer.async_wait(Step);
		}
	}
}
#endif


int main(int argc, char* argv[]){
	std::cout << "Starting Veristand Model Test." << std::endl;

#ifdef SCONS_TARGET_UNIX
	struct sigaction sigIntHandler;

	sigIntHandler.sa_handler = AbortHandler;
	sigemptyset(&sigIntHandler.sa_mask);
	sigIntHandler.sa_flags = 0;

	sigaction(SIGINT, &sigIntHandler, NULL);
#endif

#ifdef SCONS_TARGET_WIN
	SetConsoleCtrlHandler((PHANDLER_ROUTINE)AbortHandler, TRUE);
#endif

	ModelDllWrapper.reset(new VeristandDllWrapper(MODEL_DLL));
	if(ModelDllWrapper->loadDll() != 0){
		std::cout << "Unable to load model DLL." << std::endl;
		return EXIT_FAILURE;
	}

	SharedVeristandModel model(new VeristandModel(ModelDllWrapper));
	if(!model->initialize()){
		std::cout << "Unable to deterine model configuiration." << std::endl;
		return EXIT_FAILURE;
	}

	Adapter.reset(new VeristandExtModeAdapter(model));
	if(!Adapter->initialize(100, 100000)){
		std::cout << "Unable to initialize adapter." << std::endl;
		return EXIT_FAILURE;
	}

	if(!Adapter->start(9999)){
		std::cout << "Unable to start adapter." << std::endl;
		return EXIT_FAILURE;
	}

	{
		double finaltime = 1.0;
		int32_t num_in;
		int32_t num_out;
		int32_t num_tasks;

		ModelDllWrapper->initializeModel(finaltime, &BaseTimeStep, &num_in, &num_out, &num_tasks);
		std::cout << "Stepsize: " << BaseTimeStep << std::endl;
		std::cout << "Number of model inputs: " << num_in << std::endl;
		std::cout << "Number of model outputs: " << num_out << std::endl;
		std::cout << "Number of model tasks: " << num_tasks << std::endl;

		Inputs.clear();
		Inputs.resize(model->getNumInputsFlattened(), 0.0);
		Outputs.resize(model->getNumOutputsFlattened());

		std::cout << "Number of flattened inputs: " << model->getNumInputsFlattened() << std::endl;
		std::cout << "Number of flattened outputs: " << model->getNumOutputsFlattened() << std::endl;
	}

	KeepAlive = true; // run model until KeepAlive == false

	std::cout << "Not skipping" << std::endl;
	ValidateHardwareConfiguration();
	/* Allocate and initialize IO vectors*/
	SetupIO();

	//TODO: Return here and see if better implementation (remove setup SW timed task?)
	#if (defined(SCONS_TARGET_LINUX) && (USE_SOFTWARE_TIMER==0))	/* DAQmx hardware specific code*/
	/* Define callback for DAQ interrupts */
	SetupTask(MySignalCallback);
	#elif (defined(SCONS_TARGET_LINUX) && (USE_SOFTWARE_TIMER==1))
	/* Start Tasks */
	SetupTask(NULL);
	#endif

	std::cout << "Press Ctrl-C to abort." << std::endl;

	ModelDllWrapper->modelStart();

	/* One step to initialize model outputs at first time-step*/
	double t0;
	int32_t task0;
	ModelDllWrapper->schedule(&Inputs[0], &Outputs[0], &t0, &task0);
	Adapter->captureScopeSignals(t0);
    ModelDllWrapper->modelUpdate();

	#if (defined(SCONS_TARGET_LINUX) && (USE_SOFTWARE_TIMER==0))
	boost::asio::signal_set signals(IoService, SIGINT );
	signals.async_wait( SignalWaitHanlder );
	#else
	StepTimer.expires_from_now(boost::posix_time::milliseconds(0)*60000);
	StepTimer.async_wait(Step);
	#endif

	boost::thread t(boost::bind(&boost::asio::io_context::run, &IoService));
	t.join();

	Adapter->stop();

	std::cout << "Ending Veristand Model Test." << std::endl;

	CleanupTask();

	return EXIT_SUCCESS;
}
