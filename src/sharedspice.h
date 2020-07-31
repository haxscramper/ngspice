/*! header file for shared ngspice */
/*! Copyright 2013 Holger Vogt */
/*! Modified BSD license */

#include <stdbool.h>

// clang-format off

/*!
  \file sharedspice.h

Interface between a calling program (caller) and ngspice.dll (ngspice.so)

`** ngSpice_Init(SendChar*, SendStat*, ControlledExit*, SendData*,
SendInitData*, BGThreadRunning*, void)`

After caller has loaded ngspice.dll,
the simulator has to be initialized by calling `ngSpice_Init()`. Address
pointers of several callback functions defined in the caller are sent to
ngspice.dll.

Callback funtion typedefs
- `SendChar` typedef of callback function for reading printf, fprintf, fputs
- `SendStat` typedef of callback function for reading status string and precent value
- `ControlledExit` typedef of callback function for tranferring a signal upon ngspice controlled_exit to caller. May be used by caller to detach ngspice.dll.
- `SendData` typedef of callback function for sending an array of structs containing data values of all vectors in the current plot (simulation output)
- `SendInitData` typedef of callback function for sending an array of structs containing info on all vectors in the current plot (immediately before simulation starts)
- `BGThreadRunning` typedef of callback function for sending a boolean signal (true if thread is running)

The void pointer may contain the object address of the calling
function ('self' or 'this' pointer), so that the answer may be directed
to a calling object. Callback functions are defined in the global section.

**

`ngSpice_Command(char*)`

Send a valid command (see the control or interactive commands) from caller
to ngspice.dll. Will be executed immediately (as if in interactive mode).
Some commands are rejected (e.g. 'plot', because there is no graphics
interface). Command 'quit' will remove internal data, and then send a
notice to caller via ngexit().

**

`ngGet_Vec_Info(char*)`

receives the name of a vector (may be in the form 'vectorname' or
<plotname>.vectorname) and returns a pointer to a vector_info struct.
The caller may then directly assess the vector data (but probably should
not modify them).

**

`ngSpice_Circ(char**)`

sends an array of null-terminated char* to ngspice.dll. Each char* contains
a single line of a circuit (each line like in an input file **.sp). The
last entry to char** has to be NULL. Upon receiving the arry, ngspice.dll
will immediately parse the input and set up the circuit structure (as if
received the circuit from a file by the 'source' command.

**

`char* ngSpice_CurPlot();`

returns to the caller a pointer to the name of the current plot

**

`char** ngSpice_AllPlots()`

returns to the caller a pointer to an array of all plots (by their
typename)

**

`char** ngSpice_AllVecs(char*);`

returns to the caller a pointer to an array of vector names in the plot
named by the string in the argument.

**

Additional basics:

No memory mallocing and freeing across the interface:
- Memory allocated in ngspice.dll has to be freed in ngspice.dll.
- Memory allocated in the calling program has to be freed only there.

ngspice.dll should never call `exit()` directly, but handle either the
'quit' request to the caller or an request for exiting upon error,
done by callback function `ngexit()`.
*/

// clang-format on

#ifndef NGSPICE_DLL_H
#    define NGSPICE_DLL_H

#    ifdef __cplusplus
extern "C" {
#    endif

#    if defined(__MINGW32__) || defined(_MSC_VER) || defined(__CYGWIN__)
#        ifdef SHARED_MODULE
#            define IMPEXP __declspec(dllexport)
#        else
#            define IMPEXP __declspec(dllimport)
#        endif
#    else
/*! use with gcc flag -fvisibility=hidden */
#        if __GNUC__ >= 4
#            define IMPEXP __attribute__((visibility("default")))
#            define IMPEXPLOCAL __attribute__((visibility("hidden")))
#        else
#            define IMPEXP
#            define IMPEXP_LOCAL
#        endif
#    endif

/*! required only if header is used by the caller,
   is already defined in ngspice.dll */
#    ifndef ngspice_NGSPICE_H
/*! Complex numbers. */
struct ngcomplex {
    double cx_real; ///< Real part
    double cx_imag; ///< Complex part
};

typedef struct ngcomplex ngcomplex_t;
#    endif

/*! vector info obtained from any vector in ngspice.dll. Allows direct
   access to the ngspice internal vector structure, as defined in
   include/ngspice/devc.h .*/
typedef struct vector_info {
    char*        v_name;     ///< Same as so_vname. */
    int          v_type;     ///< Same as so_vtype. */
    short        v_flags;    ///< Flags (a combination of VF_*). */
    double*      v_realdata; ///< Real data. */
    ngcomplex_t* v_compdata; ///< Complex data. */
    int          v_length;   ///< Length of the vector. */
} vector_info, *pvector_info;

typedef struct vecvalues {
    char*  name;       ///< name of a specific vector */
    double creal;      ///< actual data value */
    double cimag;      ///< actual data value */
    bool   is_scale;   ///< if 'name' is the scale vector */
    bool   is_complex; ///< if the data are complex numbers */
} vecvalues, *pvecvalues;

typedef struct vecvaluesall {
    int veccount; ///< number of vectors in plot
    /// Number of actual set of vectors. i.e. the number of accepted
    /// data points. \note: not a 0-based index. To get access to
    /// vector in `vecsa` use `v->vecindex - 1`
    int         vecindex;
    pvecvalues* vecsa; ///< values of actual set of vectors, indexed
                       /// from 0 to veccount - 1
} vecvaluesall, *pvecvaluesall;

/*! info for a specific vector */
typedef struct vecinfo {
    int number;    ///< number of vector, as postion in the linked
                   /// list of vectors, starts with 0 */
    char* vecname; ///< name of the actual vector */
    bool  is_real; ///< TRUE if the actual vector has real data */
    void* pdvec;   ///< a void pointer to struct dvec *d, the actual vector
                   ///< */
    void* pdvecscale; ///< a void pointer to struct dvec *ds, the
                      /// scale vector */
} vecinfo, *pvecinfo;

/*! info for the current plot */
typedef struct vecinfoall {
    /// Name of the simulation (?)
    char* name;
    /// Title of the circuit being simulated (first line in the netlist)
    char* title;
    /// Datetime of simulation start
    char* date;
    /// DOC ??
    char* type;
    /// Number of vectors in simulation
    int veccount;

    /*! the data as an array of vecinfo with length equal to the number of
     * vectors in the plot */
    pvecinfo* vecs;

} vecinfoall, *pvecinfoall;


/*!
  sending output from stdout, stderr to caller

  \note This is a typedef for callback function that should be passed as
  argument to `ngSpice_Init()`

  - `char*` string to be sent to caller output
  - `int`   identification number of calling ngspice shared lib
  - `void*` return pointer received from caller, e.g. pointer to
    object having sent the request

  Possible implemenetation

  \code{.cpp}
  int ng_getchar(char* outputreturn, int ident, void* userdata) {
    printf("@ %s\n", outputreturn);
    return 0;
  }
  \endcode
*/
typedef int(SendChar)(char*, int, void*);

/*!

  \brief sending simulation status to caller

  When processing netlist or running simulation this function is used
  to report progress.

  \note This is a typedef for callback function that should be passed as
  argument to `ngSpice_Init()`


  - `char*` simulation status and value (in percent) to be sent to caller
  - `int` identification number of calling ngspice shared lib
  - `void*` return pointer received from caller

  Possible implemenetation:

  \code{.cpp}
  int ng_getstat(char* outputreturn, int ident, void* userdata) {
      printf("# %s\n", outputreturn);
      return 0;
  }
  \endcode

*/

typedef int(SendStat)(char*, int, void*);

/*! asking for controlled exit */
/*!


  \note This is a typedef for callback function that should be passed as
  argument to `ngSpice_Init()`


   - `int`   exit status
   - `bool` if true: immediate unloading dll, if false: just set flag,
   unload is done when function has returned bool if true: exit upon
   'quit', if false: exit due to ngspice.dll error int identification
   number of calling ngspice shared lib void* return pointer received
   from caller
*/
typedef int(ControlledExit)(int, bool, bool, int, void*);


/*! send back actual vector data */
/*!


  \note This is a typedef for callback function that should be passed as
  argument to `ngSpice_Init()`

  After simulation completes new vector this function is invoked.

   \param vecvaluesall* pointer to array of structs containing actual
  values from all vectors. Information about current state of the
  simulation (which vectors are completed) can be accessed from it.

   \param int number of structs (one per vector)

   \param int identification number of calling ngspice shared lib

   \param void* return pointer received from caller

   aaa  bbb

   Possible implementation

   \code{.cpp}
   int ng_data(
       pvecvaluesall vdata, int numvecs, int ident, void* userdata) {
       printf(
           "Completed [%d/%d] (%s)\n",
           vdata->vecindex,                        // New vec number
           vdata->veccount,                        // Total count
           vdata->vecsa[vdata->vecindex - 1]->name // Name of the new vector
       );
       return 0;
   }
   \endcode

   Output generated during simulation

   \code{.txt}
     Completed [1/5] (v1#branch)
     Completed [2/5] (v2#branch)
     Completed [3/5] (V(2))
     Completed [4/5] (V(1))
     Completed [5/5] (v-sweep)
   \endcode
*/
typedef int(SendData)(pvecvaluesall, int, int, void*);


/*!
  \brief send back initailization vector data

  Called before simulation start


  \note This is a typedef for callback function that should be passed as
  argument to `ngSpice_Init()`

   - `vecinfoall*` pointer to array of structs containing data from all
     vectors right after initialization
   - `int`         identification number of calling ngspice shared lib
   - `void*`       return pointer received from caller

   Possible implementation

   \code{.cpp}
   int ng_initdata(pvecinfoall intdata, int ident, void* userdata) {
     puts("Pre-simulation callback");
     for (int i = 0; i < intdata->veccount; i++) {
       printf("  Vector: %s\n", intdata->vecs[i]->vecname);
     }
     return 0;
   }
   \endcode

*/
typedef int(SendInitData)(pvecinfoall, int, void*);


/*! indicate if background thread is running */
/*!


  \note This is a typedef for callback function that should be passed as
  argument to `ngSpice_Init()`

   - `bool`        true if background thread is running
   - `int`         identification number of calling ngspice shared lib
   - `void*`       return pointer received from caller
*/
typedef int(BGThreadRunning)(bool, int, void*);

/*! ask for VSRC EXTERNAL value */
/*!

  \note This is a typedef for callback function that should be passed
  as argument to `ngSpice_Init_Sync()`

   - `double*`     return voltage value
   - `double`      actual time
   - `char*`       node name
   - `int`         identification number of calling ngspice shared lib
   - `void*`       return pointer received from caller
*/
typedef int(GetVSRCData)(double*, double, char*, int, void*);

/*! ask for ISRC EXTERNAL value */
/*!


  \note This is a typedef for callback function that should be passed as
  argument to `ngSpice_Init_Sync()`

   - `double*`     return current value
   - `double`      actual time
   - `char*`       node name
   - `int`         identification number of calling ngspice shared lib
   - `void*`       return pointer received from caller
*/
typedef int(GetISRCData)(double*, double, char*, int, void*);

/*! ask for new delta time depending on synchronization requirements */
/*!


  \note This is a typedef for callback function that should be passed
  as argument to `ngSpice_Init_Sync()`


  - `double`      actual time (ckt->CKTtime)
  - `double*`     delta time (ckt->CKTdelta)
  - `double`      old delta time (olddelta)
  - `int`         redostep (as set by ngspice)
  - `int`         identification number of calling ngspice shared lib
  - `int`         location of call for synchronization in dctran.c
  - `void*`       return pointer received from caller
*/
typedef int(GetSyncData)(double, double*, double, int, int, int, void*);


/// ngspice initialization
IMPEXP
int ngSpice_Init(
    /// pointer to callback function for reading printf, fprintf
    SendChar* printfcn,
    /// pointer to callback function for the status string and percent
    SendStat* statfcn,
    /// pointer to callback function for setting a 'quit' signal in caller
    /// value
    ControlledExit* ngexit,
    /// pointer to callback function for returning data values of all
    SendData* sdata,
    /// pointer to callback function for returning information of all
    /// output vectors just initialized current output vectors
    SendInitData* sinitdata,
    /// pointer to callback function indicating if workrt thread is running
    BGThreadRunning* bgtrun,
    /// pointer to user-defined data, will not be modified, but handed
    /// over back to caller during Callback, e.g. address of calling
    /// object
    void* userData);

/// initialization of synchronizing functions
IMPEXP
int ngSpice_Init_Sync(
    /// pointer to callback function for retrieving a voltage source value
    /// from caller
    GetVSRCData* vsrcdat,
    /// pointer to callback function for retrieving a current source value
    /// from caller
    GetISRCData* isrcdat,
    /// pointer to callback function for synchronization
    GetSyncData* syncdat,
    /// pointer to integer unique to this shared library (defaults to 0)
    int* ident,
    /// pointer to user-defined data, will not be modified, but handed
    /// over back to caller during Callback, e.g. address of calling
    /// object. If NULL is sent here, userdata info from ngSpice_Init()
    /// will be kept, otherwise userdata will be overridden by new value
    /// from here.
    void* userData);

/*!
  \brief Execute ngspice command

  Caller may send ngspice commands to ngspice.dll. Commands are executed
  immediately

*/
IMPEXP
int ngSpice_Command(char* command);


/*!

  \brief get info about a vector

  \arg vecname Name of the vector in form of `plotname.vectorname`

 */
IMPEXP
pvector_info ngGet_Vec_Info(char* vecname);


/*! send a circuit to ngspice.dll
   The circuit description is a dynamic array
   of char*. Each char* corresponds to a single circuit
   line. The last entry of the array has to be a NULL */
IMPEXP
int ngSpice_Circ(char** circarray);


/*!
  \brief Get name of the curent plots

  After new command is finished it's results are collected into a
  'plot' - a group of vectors generated by any analysis. Two `dc`
  commands used one after another will generate plots `dc1` and `dc2`
  respectively.

  \returns a pointer to the name of the current plot

 */
IMPEXP
char* ngSpice_CurPlot(void);


/*!
  \brief Get name of all points

  \returns pointer to an array of all plots created so far by ngspice.dll

*/
IMPEXP
char** ngSpice_AllPlots(void);


/*!
  \brief Get names of all vectors in plot

  \returns a pointer to an null-terminated array of vector names in
  the plot named by plotname

*/
IMPEXP
char** ngSpice_AllVecs(char* plotname);

/*! returns TRUE if ngspice is running in a second (background) thread */
IMPEXP
bool ngSpice_running(void);

/*! set a breakpoint in ngspice */
IMPEXP
bool ngSpice_SetBkpt(double time);


#    ifdef __cplusplus
}
#    endif

#endif
