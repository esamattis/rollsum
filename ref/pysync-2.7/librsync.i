/* File : librsync.i
 * $Id: librsync.i 1.6 Thu, 02 May 2002 16:36:42 +1000 abo $
 * Author: Donovan Baarda <abo@minkirri.apana.org.au>
 *
 * swig interface file for the librsync library.
 */

%module librsync
%{
#include "librsync/rsync.h"
#include "librsync/job.h"
#include "librsync/util.h"
%}

/********************general typemaps*****************************/
%include typemaps.i
    
// Grab a Python function object as a Python object.
%typemap(python,in) PyObject *PyFunc {
    if (!PyCallable_Check($source)) {
        PyErr_SetString(PyExc_TypeError, "Need a callable object!");
        return NULL;
    }
    $target = $source;
}

// Type mapping for grabbing a FILE * from Python
%typemap(python,in) FILE * {
    if (!PyFile_Check($source)) {
        PyErr_SetString(PyExc_TypeError, "Need a file!");
        return NULL;
    }
    $target = PyFile_AsFile($source);
}

// Type mapping for "char *buffer, int length" to an input string.
%typemap(python,in) char *buffer {
    if (PyString_AsStringAndSize($source, &$target, buffer_length)==-1) {
        PyErr_SetString(PyExc_TypeError,"not a string type");
        return NULL; 
    }
}
%typemap(python,ignore) int length (int *buffer_length){
    buffer_length=&$target;
}


/***************************general librsync************************/

typedef int size_t;

extern const char rs_librsync_version[];
extern const char rs_licence_string[];

//defaults
#define RS_DEFAULT_STRONG_LEN 8
#define RS_DEFAULT_BLOCK_LEN 2048

//logging levels
typedef enum {
    RS_LOG_EMERG         = 0,
    RS_LOG_ALERT         = 1,
    RS_LOG_CRIT          = 2,
    RS_LOG_ERR           = 3,
    RS_LOG_WARNING       = 4,
    RS_LOG_NOTICE        = 5,
    RS_LOG_INFO          = 6,
    RS_LOG_DEBUG         = 7
} rs_loglevel;
void rs_trace_set_level(rs_loglevel level);

//result codes
typedef enum {
    RS_DONE =		0,
    RS_BLOCKED =	1,
    RS_RUNNING  =       2,
    RS_TEST_SKIPPED =   77,
    RS_IO_ERROR =	100,
    RS_SYNTAX_ERROR =   101,
    RS_MEM_ERROR =	102,
    RS_INPUT_ENDED =	103,
    RS_BAD_MAGIC =      104,
    RS_UNIMPLEMENTED =  105,
    RS_CORRUPT =        106,
    RS_INTERNAL_ERROR = 107,
    RS_PARAM_ERROR =    108
} rs_result;
char *rs_strerror(rs_result r);

//the following are not wrapped, use the base64 module instead.
//void rs_hexify(char *to_buf, void const *from_buf, int from_len);
//size_t rs_unbase64(char *s);
//void rs_base64(unsigned char const *buf, int n, char *out);


/***************************md4 class*******************************/

// Type mapping for rs_strong_sum_t parameters to an output string.
typedef unsigned int rs_weak_sum_t;
typedef unsigned char rs_strong_sum_t[RS_MD4_LENGTH];
%typemap(python,argout) rs_strong_sum_t {
    PyObject *o=PyString_FromStringAndSize($source, RS_MD4_LENGTH);
    $target = l_output_helper($target,o);
}
%typemap(python,ignore) rs_strong_sum_t {
    rs_strong_sum_t temp_sum;
    $target=(unsigned char *)&temp_sum;
}

// md4 class definition
%name(md4) typedef struct rs_mdfour {
    %addmethods {
        rs_mdfour_t() {
            rs_mdfour_t *v;
            v = (rs_mdfour_t *)malloc(sizeof(rs_mdfour_t));
            rs_mdfour_begin(v);
            return v;
        }
        ~rs_mdfour_t() {
            free(self);
        }
        void digest(rs_strong_sum_t sum) {
            rs_mdfour_t temp;
            temp = *self;
            rs_mdfour_result(&temp,sum);
        }
        void update(char *buffer, int length);
    }
} rs_mdfour_t;


/***************************stats class*******************************/
typedef struct rs_stats {
    char            *op;
    int             lit_cmds;
    rs_long_t       lit_bytes;
    rs_long_t       lit_cmdbytes;
    rs_long_t       copy_cmds, copy_bytes, copy_cmdbytes;
    rs_long_t       sig_cmds, sig_bytes;
    int             false_matches;
    rs_long_t       sig_blocks;
    size_t          block_len;
    rs_long_t       in_bytes;
    rs_long_t       out_bytes;
    %addmethods {
        rs_stats_t() {
            rs_stats_t *v;
            v = (rs_stats_t *)malloc(sizeof(rs_stats_t));
            return v;
        }
        ~rs_stats_t() {
            free(self);
        }
        char *__str__() {
            static char buf[1024];
            return rs_format_stats(self,buf,sizeof(buf) - 1);
        }
        int log() {
            return rs_log_stats(self);
        }
    }
} rs_stats_t;


/***************************sig class*******************************/
typedef struct rs_signature {
    %addmethods {
        ~rs_signature_t() {
            rs_free_sumset(self);
        }
        void dump() {
            rs_sumset_dump(self);
        }
    }
} rs_signature_t;

//void rs_free_sumset(rs_signature_t *);
//void rs_sumset_dump(rs_signature_t *);
//rs_result rs_build_hash_table(rs_signature_t* sums);


/***************************job class*******************************/
typedef struct rs_job {
    %addmethods {
        ~rs_job_t() {
            rs_job_free(self);
        }

        rs_stats_t *statistics();
        
        PyObject *calc(char *buffer, int length) {
            int outlength=16*1024;
            rs_result err;
            rs_buffers_t buf;
            PyObject *RetVal;
            
            if (!(RetVal = PyString_FromStringAndSize(NULL, outlength))) {
                PyErr_SetString(PyExc_MemoryError,
                                "Can't allocate memory to calc data");
                return NULL;
            }
            buf.avail_in=length;
            buf.next_in=buffer;
            buf.eof_in=!length; //an empty string in indicates EOF
            buf.avail_out = outlength;
            buf.next_out = (unsigned char *)PyString_AsString(RetVal);
            err=rs_job_iter(self,&buf);
            while (err == RS_BLOCKED && (buf.avail_in || buf.eof_in)) {
                if (!buf.avail_out) {
                    if (_PyString_Resize(&RetVal, outlength << 1) == -1) {
                        PyErr_SetString(PyExc_MemoryError,
                                        "Can't allocate memory to compress data");
                        return NULL;
                    }
                    buf.next_out = (unsigned char *)PyString_AsString(RetVal) + outlength;
                    buf.avail_out = outlength;
                    outlength = outlength << 1;
                }
                err=rs_job_iter(self,&buf);
            }
            if (err != RS_BLOCKED && err != RS_DONE) {
                PyErr_Format(PyExc_ValueError, 
                             "Error %i while doing calc: %.200s",err,rs_strerror(err));
                Py_DECREF(RetVal);
                return NULL;
            }
            _PyString_Resize(&RetVal, outlength - buf.avail_out);
            return RetVal;
        }
        
        PyObject *flush() {
            return rs_job_calc(self,"",0);
        }
        
        rs_signature_t *calcsig() {
            rs_result err;
            rs_signature_t *sig;
            
            sig = self->signature;
            err=rs_build_hash_table(sig);
            return sig;
        }
        
    }
} rs_job_t;

// Low level API routines
%name(calcsigobj) rs_job_t *rs_sig_begin(size_t new_block_len=RS_DEFAULT_BLOCK_LEN, size_t strong_sum_len=RS_DEFAULT_STRONG_LEN);
rs_job_t *loadsigobj();
%name(rdeltaobj) rs_job_t *rs_delta_begin(rs_signature_t *);
rs_job_t *patchobj(PyObject *PyFunc, PyObject *PyArgs);

// File level API routines
rs_stats_t *filesig(FILE *old_file, FILE *sig_file,
                    size_t block_len=RS_DEFAULT_BLOCK_LEN, 
                    size_t strong_sum_len=RS_DEFAULT_STRONG_LEN);

rs_stats_t *filerdelta(FILE *sig_file, FILE *new_file, FILE *delta_file);

rs_stats_t *filepatch(FILE *basis_file, FILE *delta_file, FILE *new_file);


//put main testcode at end of Python shadow module.
%pragma(python) include="librsync.py.inc"

    
// Extra implemented functions
%{
typedef struct py_copy_cb_arg_s {
    PyObject *pyfunc;
    PyObject *pyargs;
} py_copy_cb_arg_t;

rs_result py_copy_cb(void *arg, off_t pos, size_t *len, void **buf)
{
    PyObject *pyargs, *arglist;
    PyObject *result;
    char *data;
    size_t size;

    arglist = Py_BuildValue("(l,l)",pos,*len);    // Build argument list
    pyargs = PySequence_Concat(arglist,((py_copy_cb_arg_t *)arg)->pyargs);
    Py_DECREF(arglist);				// Trash arglist
    result = PyEval_CallObject(((py_copy_cb_arg_t *)arg)->pyfunc,pyargs);// Call Python
    Py_DECREF(pyargs);                            // Trash pyargs
    if (result) {
        PyString_AsStringAndSize(result,&data,&size);
        printf("got result\n");
        memcpy(*buf,data,size);
        Py_XDECREF(result);
        if (*len == size) {
            return RS_DONE;
        } else {
            *len=size;
            return RS_INPUT_ENDED;     /* TODO: raise an exception? */
        }
    } else {
        *len=0;
        return RS_IO_ERROR;
    }
}

rs_job_t *patchobj(PyObject *PyFunc, PyObject *PyArgs) {
    py_copy_cb_arg_t *arg;

    printf("preparing patchobj\n");
    rs_trace_set_level(8);
    rs_trace_to(rs_trace_stderr);
    arg=(py_copy_cb_arg_t *)rs_alloc(sizeof(py_copy_cb_arg_t),"py_copy_cb_arg_t");
    arg->pyfunc=PyFunc;
    arg->pyargs=PyArgs;
    Py_INCREF(PyFunc);
    Py_INCREF(PyArgs);
    return rs_patch_begin(py_copy_cb,arg);
}

rs_job_t *loadsigobj() {
    rs_signature_t *temp;

    return rs_loadsig_begin(&temp);
}

    
// File API routines    
rs_stats_t *filesig(FILE *old_file, FILE *sig_file, 
                     size_t block_len, size_t strong_sum_len) {
    rs_stats_t *ret;
    rs_result err;
    
    ret=(rs_stats_t *)rs_alloc(sizeof(rs_stats_t),"rs_stats_t");
    err=rs_sig_file(old_file,sig_file,block_len,strong_sum_len,ret);
    if (err != RS_DONE) {
        PyErr_Format(PyExc_ValueError, 
                     "Error %i doing sig_file: %.200s",err,rs_strerror(err));
        return NULL;
    }
    return ret;
}
    
rs_stats_t *filerdelta(FILE *sig_file, FILE *new_file, FILE *delta_file) {
    rs_stats_t *ret;
    rs_result err;
    rs_signature_t *sig;
    
    ret=(rs_stats_t *)rs_alloc(sizeof(rs_stats_t),"rs_stats_t");
    if ((err=rs_loadsig_file(sig_file,&sig,ret)) == RS_DONE) {
        err=rs_build_hash_table(sig);
    }
    if (err != RS_DONE) {
        PyErr_Format(PyExc_ValueError, 
                     "Error %i loading sig_file: %.200s",err,rs_strerror(err));
        return NULL;
    }
    err=rs_delta_file(sig, new_file, delta_file, ret);
    if (err != RS_DONE) {
        PyErr_Format(PyExc_ValueError, 
                     "Error %i doing delta_file: %.200s",err,rs_strerror(err));
        return NULL;
    }
    return ret;
}

rs_stats_t *filepatch(FILE *basis_file, FILE *delta_file, FILE *new_file) {
    rs_stats_t *ret;
    rs_result err;
    
    ret=(rs_stats_t *)rs_alloc(sizeof(rs_stats_t),"rs_stats_t");
    err=rs_patch_file(basis_file,delta_file,new_file,ret);
    if (err != RS_DONE) {
        PyErr_Format(PyExc_ValueError, 
                     "Error %i doing sig_file: %.200s",err,rs_strerror(err));
        return NULL;
    }
    return ret;
}

%}

