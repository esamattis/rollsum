#!/usr/bin/env python
"""
rollsum hash function

A fast and simple 32bit hash function that supports rapid calculation of a
'rolling' window, where a checksum for data[i+1:j+1]) can be rapidly
calculated from the checksum for data[i:j] with data[i] and data[j+1]. This
means the checksums for a fixed sized window can be calculated for every byte
offset by 'rolling" the window through the data.

     $Id: rollsumT1.py 1.2 Wed, 01 May 2002 12:13:23 +1000 abo $
Author	: Donovan Baarda <abo@minkirri.apana.org.au>
License	: GPL
Download: ftp://minkirri.apana.org.au/pub/python

Requires:

Usage:
    import rollsum
    
    sig=rollsum.rollsum()	# create new adler32 object
    sig.update(datastring)	# update adler32 object with datastring
    sig.rotate(byteout,bytein)	# rotate byteout out and bytein into adler32
    sig.rollin(bytein)          # roll in a single byte
    sig.rollout(byteout)        # roll out a single byte
    csum=sig.digest()		# get adler32 digest

Where:
    this all looks suspiciously like the same API for md5sum...
    

This algorithm is taken straight from librsync which uses the same
algo as rsync.

"""

from random import randint
from time import clock
from rollsum import rollsum

# generate 8K random data
data=''
for i in range(8*1024):
    data=data+chr(randint(0,255))

# time digest
t=clock()
for i in range(80*1024):
    v=rollsum(data).digest()
t=clock()-t
print "80K x digest of 8K data gave %s in %8.4f seconds" % (hex(v),t)

# time rotation
a=rollsum(data)
t=clock()
for i in 10*data:
    a.rotate(i,i)
    v=a.digest()
t=clock()-t
print "80K x rotate of 8K data gave %s in %8.4f seconds" % (hex(v),t)
