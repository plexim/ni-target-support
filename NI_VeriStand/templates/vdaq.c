#include "|>BASE_NAME<|.h"
#include "|>BASE_NAME<|_vdaq.h"

//Static IO definitions
#define RTLATE_ERROR_OR_WARN 1 //  0 = err. 1 = warn.
#define RT_TIMEOUT 1.0

//Static task handles
|>TASK_HANDLE_LIST<|

//Structure defining global IO for each task.
typedef struct {|>IO_DATA_FORMAT<|} IODataFormat;
static IODataFormat ioSignals;

//Hardware signals for task control
char startTriggerName[256];		//Name for common trigger among different tasks
char sampleClockName[256];		//Name for common clock among different tasks

int32 DAQmxErrChk(int32 err)
{
	static	char	errBuff[2048]={'\0'};

	if DAQmxFailed(err)
	{
		DAQmxGetExtendedErrorInfo(errBuff,2048);
		|>CLEAR_TASKS<|
		printf("DAQmx Error: %s\n",errBuff);
	}
	return 0;
}

int32 ValidateHardwareConfiguration(void)
{

	/*********************************************/
	// Test to get names of slots for IO - for future use  with coder
	/*********************************************/
    char  devNames[256]={'\0'};
    char  testDevName[256]={'\0'};
    DAQmxErrChk (DAQmxGetSysDevNames(&devNames[0], 256));
    DAQmxErrChk (DAQmxGetDevProductType("PXI1Slot2", &testDevName[0], 256));
    printf("Devices: %s\n",devNames);
    printf("Product: %s\n",testDevName);

    return 0;
}

int32 SetupIO(void)
{

	/*********************************************/
	// Setup IO and Sample timing
	/*********************************************/
    printf("Creating tasks...\n");
	|>CREATE_TASKS<|

	// Analog Input.
    printf("Creating analog inputs...\n");
	|>DAQ_CREATE_AI_CHANS<|

	// Analog Output.
    printf("Creating analog outputs...\n");
	|>DAQ_CREATE_AO_CHANS<|

	// Digital Input.  Create Task -> Create Virtual Channel -> Assign Clock -> Align DO clock with AI clock
    printf("Creating digital inputs...\n");
	|>DAQ_CREATE_DI_CHANS<|

	// Digital Output.  Create Task -> Create Virtual Channel -> Assign Clock -> Align DO clock with AI clock
    printf("Creating digital outputs...\n");
	|>DAQ_CREATE_DO_CHANS<|

	// Counter Input.
    printf("Creating counter inputs...\n");
	|>DAQ_CREATE_CI_CHANS<|

	// Counter Output.
    printf("Creating counter outputs...\n");
	|>DAQ_CREATE_CO_CHANS<|

	// Configure Task Timings
    printf("Configuring task timing...\n");
	|>CONFIG_TASK_TIMING<|

	return 0;
}

// Task timing in Hardware Triggered Single Point using Signal Events
int32 SetupTask(DAQmxSignalEventCallbackPtr SignalCallback)
{
	//Setup Task Handler - For every event, call the SignalCallback function.
    printf("Setting up tasks...\n");
	|>SETUP_TASKS<|

	//Convert real-time errors to warnings
	|>RTLATE_TASKS<|

	// DAQmx Start Code
    printf("Starting tasks...\n");
	|>START_TASKS<|

	return 0;
}

int32 UpdateIO(double *inData, double *outData)
{

	|>MAP_DAQ_WRITE_TO_MODEL<|

	|>MAP_DAQ_READ_TO_MODEL<|

	return 0;
}

int32 CleanupTask(void)
{
	printf("Cleanup Task\n");
	//Restore terminal connections
	|>CLEANUP_TERMINAL_CONNECTIONS<|

	return 0;
}

// Function called in the event the trigger is abnormally interrupted
int32 CVICALLBACK DoneCallback(TaskHandle taskHandle, int32 status, void *callbackData)
{
	printf("Done callback \n");

	// Check to see if an error stopped the task.
	DAQmxErrChk (status);

	return 0;
}

// Clear tasks at errors or end
TaskHandle StopAndClearTask(TaskHandle taskHandle) {
    if( taskHandle )  {
	   DAQmxStopTask(taskHandle);
	   DAQmxClearTask(taskHandle);
    }
    return 0;
}


int32 GetTerminalNameWithDevPrefix(TaskHandle taskHandle, const char terminalName[], char triggerName[])
{
	char	device[256];
	int32	productCategory;
	uInt32	numDevices,i=1;

	DAQmxErrChk (DAQmxGetTaskNumDevices(taskHandle,&numDevices));
	while( i<=numDevices ) {
		DAQmxErrChk (DAQmxGetNthTaskDevice(taskHandle,i++,device,256));
		DAQmxErrChk (DAQmxGetDevProductCategory(device,&productCategory));
		if( productCategory!=DAQmx_Val_CSeriesModule && productCategory!=DAQmx_Val_SCXIModule ) {
			*triggerName++ = '/';
			strcat(strcat(strcpy(triggerName,device),"/"),terminalName);
			break;
		}
	}
	return 0;
}
