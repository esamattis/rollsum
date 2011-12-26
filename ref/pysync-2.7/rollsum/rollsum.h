/*= -*- c-basic-offset: 4; indent-tabs-mode: nil; -*-
 *
 * rollsum -- the rsync rolling checksum
 * $Id: rollsum.h 1.3 Wed, 01 May 2002 13:15:09 +1000 abo $
 * 
 * Author: Donovan Baarda <abo@minkirri.apana.org.au>, based on work,
 * Copyright (C) 2000, 2001 by Martin Pool <mbp@samba.org>
 * 
 * This program is free software; you can redistribute it and/or modify
 * it under the terms of the GNU Lesser General Public License as published by
 * the Free Software Foundation; either version 2.1 of the License, or
 * (at your option) any later version.
 * 
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU Lesser General Public License for more details.
 * 
 * You should have received a copy of the GNU Lesser General Public License
 * along with this program; if not, write to the Free Software
 * Foundation, Inc., 675 Mass Ave, Cambridge, MA 02139, USA.
 */

/* We should make this something other than zero to improve the
 * checksum algorithm: tridge suggests a prime number. */
#define RS_CHAR_OFFSET 31

typedef struct rs_rollsum {
    unsigned long count;
    unsigned long s1;
    unsigned long s2;
} rs_rollsum_t;

void rs_rollsum_update(rs_rollsum_t *sum,const char *buf,int len);

void rs_rollsum_init(rs_rollsum_t *sum);
void rs_rollsum_rotate(rs_rollsum_t *sum,char out, char in);
void rs_rollsum_rollin(rs_rollsum_t *sum,char c);
void rs_rollsum_rollout(rs_rollsum_t *sum,char c);
unsigned long rs_rollsum_digest(rs_rollsum_t *sum);

/* Macro versions incase they make any difference.
#define rs_rollsum_init(sum) { \
    sum->count=sum->s1=sum->s2=0; \
}

#define rs_rollsum_rotate(sum,out,in) { \
    sum->s1 += in - out; \
    sum->s2 += sum->s1 - sum->count*(out+RS_CHAR_OFFSET); \
}

#define rs_rollsum_rollin(sum,c) { \
    sum->s1 += (c + RS_CHAR_OFFSET); \
    sum->s2 += sum->s1; \
    sum->count++; \
}

#define rs_rollsum_rollout(sum,c) { \
    sum->s1 -= (c+RS_CHAR_OFFSET); \
    sum->s2 -= sum->count*(c+RS_CHAR_OFFSET); \
    sum->count--; \
}

#define rs_rollsum_digest(sum) ((sum->s2 << 16) | (sum->s1 & 0xffff))

*/


