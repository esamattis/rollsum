
/* MD5 module */

/* This module provides an interface to the RSA Data Security,
   Inc. MD5 Message-Digest Algorithm, described in RFC 1321.
   It requires the files md5c.c and rollsum.h (which are slightly changed
   from the versions in the RFC to avoid the "global.h" file.) */


/* MD5 objects */

#include "Python.h"
#include "rollsum.h"

typedef struct {
	PyObject_HEAD
        rs_rollsum_t	sum;		/* the context holder */
} rollsumobject;

staticforward PyTypeObject Rollsumtype;

#define is_rollsumobject(v)		((v)->ob_type == &Rollsumtype)

static rollsumobject *
newrollsumobject(void)
{
	rollsumobject *sump;

	sump = PyObject_New(rollsumobject, &Rollsumtype);
	if (sump == NULL)
		return NULL;

	MD5Init(&sump->sum);	/* actual initialisation */
	return sump;
}


/* MD5 methods */

static void
rollsum_dealloc(rollsumobject *sump)
{
	PyObject_Del(sump);
}


/* MD5 methods-as-attributes */

static PyObject *
rollsum_update(rollsumobject *self, PyObject *args)
{
	unsigned char *cp;
	int len;

	if (!PyArg_Parse(args, "s#", &cp, &len))
		return NULL;

	MD5Update(&self->sum, cp, len);

	Py_INCREF(Py_None);
	return Py_None;
}

static char update_doc [] =
"update (arg)\n\
\n\
Update the sum object with the string arg. Repeated calls are\n\
equivalent to a single call with the concatenation of all the\n\
arguments.";


static PyObject *
rollsum_digest(rollsumobject *self, PyObject *args)
{
 	rs_rollsum_t mdContext;
	unsigned char aDigest[16];

	if (!PyArg_NoArgs(args))
		return NULL;

	/* make a temporary copy, and perform the final */
	mdContext = self->sum;
	MD5Final(aDigest, &mdContext);

	return PyString_FromStringAndSize((char *)aDigest, 16);
}

static char digest_doc [] =
"digest() -> string\n\
\n\
Return the digest of the strings passed to the update() method so\n\
far. This is an 16-byte string which may contain non-ASCII characters,\n\
including null bytes.";


static PyObject *
rollsum_hexdigest(rollsumobject *self, PyObject *args)
{
 	rs_rollsum_t mdContext;
	unsigned char digest[16];
	unsigned char hexdigest[32];
	int i, j;

	if (!PyArg_NoArgs(args))
		return NULL;

	/* make a temporary copy, and perform the final */
	mdContext = self->sum;
	MD5Final(digest, &mdContext);

	/* Make hex version of the digest */
	for(i=j=0; i<16; i++) {
		char c;
		c = (digest[i] >> 4) & 0xf;
		c = (c>9) ? c+'a'-10 : c + '0';
		hexdigest[j++] = c;
		c = (digest[i] & 0xf);
		c = (c>9) ? c+'a'-10 : c + '0';
		hexdigest[j++] = c;
	}
	return PyString_FromStringAndSize((char*)hexdigest, 32);
}


static char hexdigest_doc [] =
"hexdigest() -> string\n\
\n\
Like digest(), but returns the digest as a string of hexadecimal digits.";


static PyObject *
rollsum_copy(rollsumobject *self, PyObject *args)
{
	rollsumobject *sump;

	if (!PyArg_NoArgs(args))
		return NULL;

	if ((sump = newrollsumobject()) == NULL)
		return NULL;

	sump->sum = self->sum;

	return (PyObject *)sump;
}

static char copy_doc [] =
"copy() -> sum object\n\
\n\
Return a copy (``clone'') of the sum object.";


static PyMethodDef rollsum_methods[] = {
	{"update",    (PyCFunction)rollsum_update,    METH_OLDARGS, update_doc},
	{"digest",    (PyCFunction)rollsum_digest,    METH_OLDARGS, digest_doc},
	{"hexdigest", (PyCFunction)rollsum_hexdigest, METH_OLDARGS, hexdigest_doc},
	{"copy",      (PyCFunction)rollsum_copy,      METH_OLDARGS, copy_doc},
	{NULL, NULL}			     /* sentinel */
};

static PyObject *
rollsum_getattr(rollsumobject *self, char *name)
{
	return Py_FindMethod(rollsum_methods, (PyObject *)self, name);
}

static char module_doc [] =

"This module implements the interface to RSA's MD5 message digest\n\
algorithm (see also Internet RFC 1321). Its use is quite\n\
straightforward: use the new() to create an sum object. You can now\n\
feed this object with arbitrary strings using the update() method, and\n\
at any point you can ask it for the digest (a strong kind of 128-bit\n\
checksum, a.k.a. ``fingerprint'') of the concatenation of the strings\n\
fed to it so far using the digest() method.\n\
\n\
Functions:\n\
\n\
new([arg]) -- return a new sum object, initialized with arg if provided\n\
md5([arg]) -- DEPRECATED, same as new, but for compatibility\n\
\n\
Special Objects:\n\
\n\
Rollsumtype -- type object for md5 objects\n\
";

static char md5type_doc [] =
"An md5 represents the object used to calculate the MD5 checksum of a\n\
string of information.\n\
\n\
Methods:\n\
\n\
update() -- updates the current digest with an additional string\n\
digest() -- return the current digest value\n\
copy() -- return a copy of the current md5 object\n\
";

statichere PyTypeObject Rollsumtype = {
	PyObject_HEAD_INIT(NULL)
	0,			  /*ob_size*/
	"md5",			  /*tp_name*/
	sizeof(rollsumobject),	  /*tp_size*/
	0,			  /*tp_itemsize*/
	/* methods */
	(destructor)rollsum_dealloc,  /*tp_dealloc*/
	0,			  /*tp_print*/
	(getattrfunc)rollsum_getattr, /*tp_getattr*/
	0,			  /*tp_setattr*/
	0,			  /*tp_compare*/
	0,			  /*tp_repr*/
        0,			  /*tp_as_number*/
	0,                        /*tp_as_sequence*/
	0,			  /*tp_as_mapping*/
	0, 			  /*tp_hash*/
	0,			  /*tp_call*/
	0,			  /*tp_str*/
	0,			  /*tp_getattro*/
	0,			  /*tp_setattro*/
	0,	                  /*tp_as_buffer*/
	0,			  /*tp_xxx4*/
	md5type_doc,		  /*tp_doc*/
};


/* MD5 functions */

static PyObject *
rollsum_new(PyObject *self, PyObject *args)
{
	rollsumobject *sump;
	unsigned char *cp = NULL;
	int len = 0;

	if (!PyArg_ParseTuple(args, "|s#:new", &cp, &len))
		return NULL;

	if ((sump = newrollsumobject()) == NULL)
		return NULL;

	if (cp)
		MD5Update(&sump->sum, cp, len);

	return (PyObject *)sump;
}

static char new_doc [] =
"new([arg]) -> sum object\n\
\n\
Return a new sum object. If arg is present, the method call update(arg)\n\
is made.";


/* List of functions exported by this module */

static PyMethodDef rollsum_functions[] = {
	{"new",		(PyCFunction)MD5_new, METH_VARARGS, new_doc},
	{"md5",		(PyCFunction)MD5_new, METH_VARARGS, new_doc}, /* Backward compatibility */
	{NULL,		NULL}	/* Sentinel */
};


/* Initialize this module. */

DL_EXPORT(void)
initmd5(void)
{
	PyObject *m, *d;

        Rollsumtype.ob_type = &PyType_Type;
	m = Py_InitModule3("md5", rollsum_functions, module_doc);
	d = PyModule_GetDict(m);
	PyDict_SetItemString(d, "Rollsumtype", (PyObject *)&Rollsumtype);
	/* No need to check the error here, the caller will do that */
}
