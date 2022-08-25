/* Include headers */
#include "ni_modelframework.h"
#include "|>BASE_NAME<|_ni.h"

#include <stddef.h>
#include <float.h>
#include <math.h>

/* User defined datatypes and constants */
/*  PLECS Coder Data Type Order 		*/
/*  0       1          2         3           4          5           6          7       8         9        */
/* "bool", "uint8_t", "int8_t", "uint16_t", "int16_t", "uint32_t", "int32_t", "float", "double", "double" */

/* Instantiate IO and Signals - defined in |>BASE_NAME<|.h */
Inports rtInport;
Outports rtOutport;
Signals rtSignal;

/* INPUT: ptr, base address of where value should be set.
   INPUT: subindex, offset into ptr where value should be set.
   INPUT: value, the value to be set
   INPUT: type, the user defined type of the parameter being set, as defined in
  		  rtParamAttributes
   RETURN: status, NI_ERROR on error, NI_OK otherwise */

int32_t USER_SetValueByDataType(void* ptr, int32_t subindex, double value, int32_t type)
{
	switch (type) {
    		case 1:
    			((bool *)ptr)[subindex] = (bool)value;
    			return NI_OK;	
    		case 2:
    			((uint8_t*)ptr)[subindex] = (uint8_t)value;
    			return NI_OK;	
    		case 3:
    			((int8_t*)ptr)[subindex] = (int8_t)value;
    			return NI_OK;	
    		case 4:
    			((uint16_t *)ptr)[subindex] = (uint16_t)value;
    			return NI_OK;	
    		case 5:
    			((int16_t*)ptr)[subindex] = (int16_t)value;
    			return NI_OK;	
    		case 6:
    			((uint32_t*)ptr)[subindex] = (uint32_t)value;
    			return NI_OK;	
    		case 7:
    			((int32_t*)ptr)[subindex] = (int32_t)value;
    			return NI_OK;	
    		case 8:
    			((float *)ptr)[subindex] = (float)value;
    			return NI_OK;	
    		case 9:
    			((double *)ptr)[subindex] = (double)value;
    			return NI_OK;
    		case 10: /* TODO: Target specific float - remove? */
    			((double *)ptr)[subindex] = (double)value;
    			return NI_OK;			
	}
  	return NI_ERROR;
}

/* INPUT: ptr, base address of value to be retrieved.
   INPUT: subindex, offset into ptr where value should be retrieved.
   INPUT: type, the user defined type of the parameter or signal being 
  		  retrieved, as defined in rtParamAttributes or rtSignalAttributes
   RETURN: value of user-defined type cast to a double */

double USER_GetValueByDataType(void* ptr, int32_t subindex, int32_t type)
{
	switch (type) {

	case 1:
		return (double)(((bool *)ptr)[subindex]);
	case 2:
		return (double)(((uint8_t *)ptr)[subindex]);
	case 3:
		return (double)(((int8_t *)ptr)[subindex]);
	case 4:
		return (double)(((uint16_t *)ptr)[subindex]);
	case 5:
		return (double)(((int16_t *)ptr)[subindex]);
	case 6:
		return (double)(((uint32_t *)ptr)[subindex]);
	case 7:
		return (double)(((int32_t*)ptr)[subindex]);
	case 8:
		return (double)(((float *)ptr)[subindex]);
	case 9:
		return (double)(((double *)ptr)[subindex]);
	case 10: /* TODO: Target specific float - remove? */
		return (double)(((double *)ptr)[subindex]);
  	}
  	{	/* return NaN, ok for vxworks and pharlap */
	  	uint32_t nan[2] = {0xFFFFFFFF, 0xFFFFFFFF};
		return *(double*)nan;
	}
}

/*
// When a model has parameters of the form: "modelname/parameter", these model parameters are considered global parameters (target scoped) in NI VeriStand
// When a model has parameters of the form: "modelname/block/paramter" these model parameters are NOT considered global parameters (model scoped) in NI VeriStand
typedef struct {
  int32_t idx;			// not used
  char* paramname;	// name of the parameter, e.g., "Amplitude"
  uintptr_t addr;// offset of the parameter in the Parameters struct
  int32_t datatype;		// integer describing a user defined datatype. must have a corresponding entry in GetValueByDataType and SetValueByDataType
  int32_t width;		// size of parameter
  int32_t numofdims; 	// number of dimensions
  int32_t dimListOffset;// offset into dimensions array
  int32_t IsComplex;	// not used
} NI_Parameter;
*/



/* Define parameter attributes */
int32_t ParameterSize DataSection(".NIVS.paramlistsize") = |>PARAM_LIST_SIZE<|;

NI_Parameter rtParamAttribs[] DataSection(".NIVS.paramlist") = {|>PARAM_LIST<|};

int32_t ParamDimList[] DataSection(".NIVS.paramdimlist") = {|>PARAM_DIM_LIST<|};

/* Initialize parameters */
Parameters initParams DataSection(".NIVS.defaultparams") = {|>DEFAULT_PARAMS<|};

/*
   This data structure is used to retrieve the size, width, and datatype of the default parameters.
      
   ParamSizeWidth Parameters_sizes[] DataSection(".NIVS.defaultparamsizes") = {
    { sizeof(initParams), 0, 0},  The first element in this array uses only the first field in the typedef.  It is used to specify the size of the default parameters structure.
    { sizeof(double), 1, 0 }, Subsequent elements in the array use all 3 fields, they are: the size (num of bytes per element), the width (num of elements) (2x2 array would have 4 elements), and the datatype of each parameter (which is handled by Get/SetValueByType)
   };  
*/
ParamSizeWidth Parameters_sizes[] DataSection(".NIVS.defaultparamsizes") = {|>DEFAULT_PARAM_SIZES<|};

/*
typedef struct {
  int32_t    idx;		// not used
  char*  blockname; // name of the block where the signals originates, e.g., "sinewave/sine"
  int32_t    portno;	// the port number of the block
  char* signalname; // name of the signal, e.g., "Sinewave + In1"
  uintptr_t addr;// address of the storage for the signal
  uintptr_t baseaddr;		// not used
  int32_t	 datatype;	// integer describing a user defined datatype. must have a corresponding entry in GetValueByDataType
  int32_t width;		// size of signal
  int32_t numofdims; 	// number of dimensions
  int32_t dimListOffset;// offset into dimensions array
  int32_t IsComplex;	// not used
} NI_Signal;
*/

/* Define signal attributes */
int32_t SignalSize DataSection(".NIVS.siglistsize") = |>SIG_LIST_SIZE<|;
/* must be careful to not get a pointer into .rela.NIVS.siglist */
/* the addr field for these signals is populated in USER_Initialize */
NI_Signal rtSignalAttribs[] DataSection(".NIVS.siglist") = { |>SIG_LIST<|};

int32_t SigDimList[] DataSection(".NIVS.sigdimlist") = { |>SIG_DIM_LIST<|};

/*
typedef struct {
  int32_t	idx;	// not used
  char*	name;	// name of the external IO, e.g., "In1"
  int32_t	TID;	// = 0
  int32_t   type; 	// Ext Input: 0, Ext Output: 1
  int32_t  width; 	// not used
  int32_t	dimX;	// 1st dimension size
  int32_t	dimY; 	// 2nd dimension size
} NI_ExternalIO;
*/

/* Define I/O attributes */
int32_t ExtIOSize DataSection(".NIVS.extlistsize") = |>EXT_LIST_SIZE<|;
int32_t InportSize = |>INPORT_SIZE<|;
int32_t OutportSize = |>OUTPORT_SIZE<|;
NI_ExternalIO rtIOAttribs[] DataSection(".NIVS.extlist") = { |>EXT_LIST<|};

/* Model name and build information */
const char * USER_ModelName DataSection(".NIVS.compiledmodelname") = "|>BASE_NAME<|";
const char * USER_Builder DataSection(".NIVS.builder") = "|>BUILDER_NAME<|";

/* baserate is the rate at which the model runs */
double USER_BaseRate = |>SAMPLE_TIME<|;

/*
typedef struct {
  int32_t    tid;		// = 0
  double tstep;		
  double offset;
  int32_t priority;
} NI_Task;
*/
NI_Task rtTaskAttribs DataSection(".NIVS.tasklist") = { 0 /* must be 0 */, |>SAMPLE_TIME<| /* must be equal to baserate */, 0, 0 };

/* RETURN: status, NI_ERROR on error, NI_OK otherwise */
int32_t USER_Initialize() {

	|>USER_PRE_INITIALIZE<|

	|>BASE_NAME<|_initialize(0.0);

	return NI_OK;
}

/* INPUT: *inData, pointer to inport data at the current timestamp, to be 
  	      consumed by the function
   OUTPUT: *outData, pointer to outport data at current time + baserate, to be
  	       produced by the function
   INPUT: timestamp, current simulation time */
int32_t USER_TakeOneStep(double *inData, double *outData, double timestamp) 
{
	if (inData){	|>MAP_INDATA_INPORT<|	}

	|>BASE_NAME<|_step();

	if (outData){	|>MAP_OUTDATA_OUTPORT<|	}
	
	return NI_OK;
}

/* RETURN: status, NI_ERROR on error, NI_OK otherwise */
int32_t USER_Finalize() {
	|>BASE_NAME<|_terminate();
	return NI_OK;
}

/* Non-supported API */

extern struct { 
	int32_t stopExecutionFlag;
	const char *errmsg;
	void* flip;
	uint32_t inCriticalSection;
	int32_t SetParamTxStatus;
	double timestamp;
} NIRT_system;

DLL_EXPORT int32_t NIRT_GetSimState(int32_t* numContStates, char* contStatesNames, double* contStates, int32_t* numDiscStates, char* discStatesNames, double* discStates, int32_t* numClockTicks, char* clockTicksNames, int32_t* clockTicks) 
{
	if (numContStates && numDiscStates && numClockTicks) {
		if (*numContStates < 0 || *numDiscStates < 0 || *numClockTicks < 0) {
			*numContStates = 0;
			*numDiscStates = 0;
			*numClockTicks = 1;
			return NI_OK;
		}
	}
	
	if (clockTicks && clockTicksNames) {
		clockTicks[0] = NIRT_system.timestamp;
		strcpy(clockTicksNames, "clockTick0");
	}	
	return NI_OK;
}

DLL_EXPORT int32_t NIRT_SetSimState(double* contStates, double* discStates, int32_t* clockTicks)
{
	if (clockTicks) {
		NIRT_system.timestamp = clockTicks[0];
	}	
	return NI_OK;
}

int32_t USER_ModelStart() {
	return NI_OK;
}
