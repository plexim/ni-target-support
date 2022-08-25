#ifndef VERISTANDDAQ_H_
#define VERISTANDDAQ_H_
#include <stdio.h>
#include <stdint.h>
#include <string.h>
#include <math.h>

#include "NIDAQmx.h"

#define USE_SOFTWARE_TIMER |>SOFTWARE_TIMER_FLAG<| // 0 = HW. 1=SW timing

int32 DAQmxErrChk(int32 err);
int32 ValidateHardwareConfiguration(void);
int32 SetupIO(void);
int32 SetupTask(DAQmxSignalEventCallbackPtr SignalCallback);
int32 UpdateIO(double *inData, double *outData);
int32 CVICALLBACK DoneCallback(TaskHandle taskHandle, int32 status, void *callbackData);
TaskHandle StopAndClearTask(TaskHandle taskHandle);
int32 GetTerminalNameWithDevPrefix(TaskHandle taskHandle, const char terminalName[], char triggerName[]);
int32 CleanupTask(void);

#endif
