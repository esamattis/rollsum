/* MD4.H - header file for MD4C.C
 * $Id: md4.h 1.2 Sat, 27 Apr 2002 17:54:33 +1000 abo $
 */

/* Copyright (C) 1991-2, RSA Data Security, Inc. Created 1991. All
   rights reserved.

   License to copy and use this software is granted provided that it
   is identified as the "RSA Data Security, Inc. MD4 Message-Digest
   Algorithm" in all material mentioning or referencing this software
   or this function.
   License is also granted to make and use derivative works provided
   that such works are identified as "derived from the RSA Data
   Security, Inc. MD4 Message-Digest Algorithm" in all material
   mentioning or referencing the derived work.

   RSA Data Security, Inc. makes no representations concerning either
   the merchantability of this software or the suitability of this
   software for any particular purpose. It is provided "as is"
   without express or implied warranty of any kind.

   These notices must be retained in any copies of any part of this
   documentation and/or software.
 */

#ifndef _MD4_H_
#define _MD4_H_

#ifdef _WIN32
/* windows doesn't define these in sys/types.h */
typedef unsigned char u_int8_t;
typedef unsigned short int u_int16_t;
typedef unsigned int u_int32_t;
#define __BEGIN_DECLS 
#define __END_DECLS 
#else
#include <sys/cdefs.h>
#endif

#define MD4_HASHBYTES  16

/* MD4 context. */
typedef struct MD4Context {
  u_int32_t state[4];	/* state (ABCD) */
  u_int32_t count[2];	/* number of bits, modulo 2^64 (lsb first) */
  unsigned char buffer[64];	/* input buffer */
} MD4_CTX;


__BEGIN_DECLS
void   MD4Init(MD4_CTX *);
void   MD4Update(MD4_CTX *, const unsigned char *, unsigned int);
void   MD4Final(unsigned char [MD4_HASHBYTES], MD4_CTX *);
char * MD4End(MD4_CTX *, char *);
char * MD4File(const char *, char *);
char * MD4Data(const unsigned char *, unsigned int, char *);
__END_DECLS

#endif /* _MD4_H_ */
