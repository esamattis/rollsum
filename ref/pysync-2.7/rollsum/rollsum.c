/* rollsum.c -- compute the rsync rolling checksum of a data stream
 */

/* @(#) $Id: rollsum.c 1.3 Wed, 01 May 2002 13:15:09 +1000 abo $ */

#include "rollsum.h"

#define DO1(buf,i)  {s1 += buf[i]; s2 += s1;}
#define DO2(buf,i)  DO1(buf,i); DO1(buf,i+1);
#define DO4(buf,i)  DO2(buf,i); DO2(buf,i+2);
#define DO8(buf,i)  DO4(buf,i); DO4(buf,i+4);
#define DO16(buf)   DO8(buf,0); DO8(buf,8);
#define OF16(off)  {s1 += 16*off; s2 += 136*off;}

void rs_rollsum_update(rs_rollsum_t *sum,const char *buf,int len) {
    /* ANSI C says no overflow for unsigned */
    unsigned long s1 = sum->s1;
    unsigned long s2 = sum->s2;

    sum->count+=len;                   /* increment sum count */
    while (len >= 16) {
        DO16(buf);
        OF16(RS_CHAR_OFFSET);
        buf += 16;
        len -= 16;
    }
    while (len != 0) {
        s1 += (*buf++ + RS_CHAR_OFFSET);
        s2 += s1;
        len--;
    }
    sum->s1=s1;
    sum->s2=s2;
}

void rs_rollsum_init(rs_rollsum_t *sum) {
    sum->count=sum->s1=sum->s2=0;
}

void rs_rollsum_rotate(rs_rollsum_t *sum,char out, char in) {
    sum->s1 += in - out;
    sum->s2 += sum->s1 - sum->count*(out+RS_CHAR_OFFSET);
}

void rs_rollsum_rollin(rs_rollsum_t *sum,char c){
    sum->s1 += (c + RS_CHAR_OFFSET);
    sum->s2 += sum->s1;
    sum->count++;
}

void rs_rollsum_rollout(rs_rollsum_t *sum,char c) {
    c+=RS_CHAR_OFFSET;
    sum->s1 -= c;
    sum->s2 -= sum->count*c;
    sum->count--;            
}

unsigned long rs_rollsum_digest(rs_rollsum_t *sum) {
    return (sum->s2 << 16) | (sum->s1 & 0xffff);
}
