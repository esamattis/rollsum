#!/usr/bin/env python
"""
zlib tests

Performance tests using zlib to compress delta's using various approaches.

     $Id: zlibtest.py 1.2 Thu, 07 Dec 2000 23:38:16 +1100 abo $
Author	: Donovan Baarda <abo@minkirri.apana.org.au>
License	: GPL
Download: ftp://minkirri.apana.org.au/pub/python

Requires: zlib

Usage:
    $ zlibtest.py < somebigfile

Where:
    somebigfile is a large file that can be used to test delta compression
    against.
    
This tests how well different approaches to compressing deltas with zlib work.
"""
import sys,zlib,whrandom

blocksize=8*1024

r=whrandom.whrandom()

data=sys.stdin.read()

z0=zlib.compressobj(9) #compress all
z1=zlib.compressobj(9) #compress deltas
z2=zlib.compressobj(9) #compress deltas with sync
z3=zlib.compressobj(9) #compress deltas with context
c0=''
c1=''
c2=''
c3=''

p=l=d=c=0
while p<len(data):
    # 1 in 4 chance of inserted data
    if r.randint(0,3)==0:
        l=p+r.randint(1,blocksize)
        c0=c0+z0.compress(data[p:l])
        c1=c1+z1.compress(data[p:l])
        c2=c2+z2.compress(data[p:l])+z2.flush(zlib.Z_SYNC_FLUSH)
        c3=c3+z3.compress(data[p:l])+z3.flush(zlib.Z_SYNC_FLUSH)
        d=d+l-p
        c=c+1
        p=l
    # skip matching block
    l=p+blocksize
    c0=c0+z0.compress(data[p:l])
    z3.compress(data[p:l])
    z3.flush(zlib.Z_SYNC_FLUSH)
    p=l
c0=c0+z0.flush()
c1=c1+z1.flush()
c2=c2+z2.flush()
c3=c3+z3.flush()

print "full data         = %d Bytes %d blocks" % (len(data),len(data)/blocksize)
print "delta data        = %d Bytes %d%% %d inserts" % (d,100*d/len(data),c)
print "full    compressed= %d Bytes %d%%" % (len(c0),100*len(c0)/len(data))
print "delta   compressed= %d Bytes %d%%" % (len(c1),100*len(c1)/d)
print "sync    compressed= %d Bytes %d%%" % (len(c2),100*len(c2)/d)
print "context compressed= %d Bytes %d%%" % (len(c3),100*len(c3)/d)
