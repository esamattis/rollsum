
/* MD4 module */

/* This module provides an interface to the RSA Data Security,
   Inc. MD4 Message-Digest Algorithm, described in RFC 1321.
   It requires the files md4c.c and md4.h (which are slightly changed
   from the versions in the RFC to avoid the "global.h" file.) */


/* MD4 objects */

#include "Python.h"
#include "md4.h"

typedef struct {
	PyObject_HEAD
        MD4_CTX	md4;		/* the context holder */
} md4object;

staticforward PyTypeObject MD4type;

#define is_md4object(v)		((v)->ob_type == &MD4type)

static md4object *
newmd4object(void)
{
	md4object *md4p;

	md4p = PyObject_New(md4object, &MD4type);
	if (md4p == NULL)
		return NULL;

	MD4Init(&md4p->md4);	/* actual initialisation */
	return md4p;
}


/* MD4 methods */

static void
md4_dealloc(md4object *md4p)
{
	PyObject_Del(md4p);
}


/* MD4 methods-as-attributes */

static PyObject *
md4_update(md4object *self, PyObject *args)
{
	unsigned char *cp;
	int len;

	if (!PyArg_Parse(args, "s#", &cp, &len))
		return NULL;

	MD4Update(&self->md4, cp, len);

	Py_INCREF(Py_None);
	return Py_None;
}

static char update_doc [] =
"update (arg)\n\
\n\
Update the md4 object with the string arg. Repeated calls are\n\
equivalent to a single call with the concatenation of all the\n\
arguments.";


static PyObject *
md4_digest(md4object *self, PyObject *args)
{
 	MD4_CTX mdContext;
	unsigned char aDigest[16];

	if (!PyArg_NoArgs(args))
		return NULL;

	/* make a temporary copy, and perform the final */
	mdContext = self->md4;
	MD4Final(aDigest, &mdContext);

	return PyString_FromStringAndSize((char *)aDigest, 16);
}

static char digest_doc [] =
"digest() -> string\n\
\n\
Return the digest of the strings passed to the update() method so\n\
far. This is an 16-byte string which may contain non-ASCII characters,\n\
including null bytes.";


static PyObject *
md4_hexdigest(md4object *self, PyObject *args)
{
 	MD4_CTX mdContext;
	unsigned char digest[16];
	unsigned char hexdigest[32];
	int i, j;

	if (!PyArg_NoArgs(args))
		return NULL;

	/* make a temporary copy, and perform the final */
	mdContext = self->md4;
	MD4Final(digest, &mdContext);

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
md4_copy(md4object *self, PyObject *args)
{
	md4object *md4p;

	if (!PyArg_NoArgs(args))
		return NULL;

	if ((md4p = newmd4object()) == NULL)
		return NULL;

	md4p->md4 = self->md4;

	return (PyObject *)md4p;
}

static char copy_doc [] =
"copy() -> md4 object\n\
\n\
Return a copy (``clone'') of the md4 object.";


static PyMethodDef md4_methods[] = {
	{"update",    (PyCFunction)md4_update,    METH_OLDARGS, update_doc},
	{"digest",    (PyCFunction)md4_digest,    METH_OLDARGS, digest_doc},
	{"hexdigest", (PyCFunction)md4_hexdigest, METH_OLDARGS, hexdigest_doc},
	{"copy",      (PyCFunction)md4_copy,      METH_OLDARGS, copy_doc},
	{NULL, NULL}			     /* sentinel */
};

static PyObject *
md4_getattr(md4object *self, char *name)
{
	return Py_FindMethod(md4_methods, (PyObject *)self, name);
}

static char module_doc [] =

"This module implements the interface to RSA's MD4 message digest\n\
algorithm (see also Internet RFC 1321). Its use is quite\n\
straightforward: use the new() to create an md4 object. You can now\n\
feed this object with arbitrary strings using the update() method, and\n\
at any point you can ask it for the digest (a strong kind of 128-bit\n\
checksum, a.k.a. ``fingerprint'') of the concatenation of the strings\n\
fed to it so far using the digest() method.\n\
\n\
Functions:\n\
\n\
new([arg]) -- return a new md4 object, initialized with arg if provided\n\
md4([arg]) -- DEPRECATED, same as new, but for compatibility\n\
\n\
Special Objects:\n\
\n\
MD4Type -- type object for md4 objects\n\
";

static char md4type_doc [] =
"An md4 represents the object used to calculate the MD4 checksum of a\n\
string of information.\n\
\n\
Methods:\n\
\n\
update() -- updates the current digest with an additional string\n\
digest() -- return the current digest value\n\
copy() -- return a copy of the current md4 object\n\
";

statichere PyTypeObject MD4type = {
	PyObject_HEAD_INIT(NULL)
	0,			  /*ob_size*/
	"md4",			  /*tp_name*/
	sizeof(md4object),	  /*tp_size*/
	0,			  /*tp_itemsize*/
	/* methods */
	(destructor)md4_dealloc,  /*tp_dealloc*/
	0,			  /*tp_print*/
	(getattrfunc)md4_getattr, /*tp_getattr*/
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
	md4type_doc,		  /*tp_doc*/
};


/* MD4 functions */

static PyObject *
MD4_new(PyObject *self, PyObject *args)
{
	md4object *md4p;
	unsigned char *cp = NULL;
	int len = 0;

	if (!PyArg_ParseTuple(args, "|s#:new", &cp, &len))
		return NULL;

	if ((md4p = newmd4object()) == NULL)
		return NULL;

	if (cp)
		MD4Update(&md4p->md4, cp, len);

	return (PyObject *)md4p;
}

static char new_doc [] =
"new([arg]) -> md4 object\n\
\n\
Return a new md4 object. If arg is present, the method call update(arg)\n\
is made.";


/* List of functions exported by this module */

static PyMethodDef md4_functions[] = {
	{"new",		(PyCFunction)MD4_new, METH_VARARGS, new_doc},
	{"md4",		(PyCFunction)MD4_new, METH_VARARGS, new_doc}, /* Backward compatibility */
	{NULL,		NULL}	/* Sentinel */
};


/* Initialize this module. */

DL_EXPORT(void)
initmd4(void)
{
	PyObject *m, *d;

        MD4type.ob_type = &PyType_Type;
	m = Py_InitModule3("md4", md4_functions, module_doc);
	d = PyModule_GetDict(m);
	PyDict_SetItemString(d, "MD4Type", (PyObject *)&MD4type);
	/* No need to check the error here, the caller will do that */
}
