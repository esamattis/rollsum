%module rollsum
%{
#include "rollsum.h"
%}

// Type mapping for "char *buffer, int length" to an input string.
%typemap(python,in) char *buf {
    if (PyString_AsStringAndSize($source, &$target, buf_len)==-1) {
        PyErr_SetString(PyExc_TypeError,"not a string type");
        return NULL; 
    }
}
%typemap(python,ignore) int len (int *buf_len){
    buf_len=&$target;
}


#define RS_CHAR_OFFSET 31

%name(rollsum) typedef struct rs_rollsum {
    unsigned long count;
    %addmethods {
        rs_rollsum_t(char *buf=NULL,int len=0) {
            rs_rollsum_t *sum;
            sum=malloc(sizeof(rs_rollsum_t));
            rs_rollsum_init(sum);
            if (buf) {
                rs_rollsum_update(sum,buf,len);
            }
            return sum;
        }
        ~rs_rollsum_t() {
            free(self);
        }
        void update(char *buf,int len);
        void rotate(char out, char in);
        void rollin(char c);
        void rollout(char c);
        unsigned long digest();
    }
} rs_rollsum_t;
