"""
Adler32 hash function

A fast and simple 32bit hash function that supports rapid calculation of a
'rolling' window, where a checksum for data[i+1:j+1]) can be rapidly
calculated from the checksum for data[i:j] with data[i] and data[j+1]. This
means the checksums for a fixed sized window can be calculated for every byte
offset by 'rolling" the window through the data.

     $Id: adler32.py 1.7 Thu, 01 Mar 2001 21:39:22 +1100 abo $
Author	: Donovan Baarda <abo@minkirri.apana.org.au>
License	: GPL
Download: ftp://minkirri.apana.org.au/pub/python

Requires: zlib

Usage:
    import adler32
    
    sig=adler32.new()		# create new adler32 object
    sig.update(datastring)	# update adler32 object with datastring
    sig.rotate(byteout,bytein)	# rotate byteout out and bytein into adler32
    csum=sig.digest()		# get adler32 digest

Where:
    this all looks suspiciously like the same API for md5sum...
    

This algorithm is taken straight from the adler32.c found in zlib. Note that
this is different from the rolling checksums implemented in xdelta and rsync.
xdelta uses a random array to index the input data before feeding it to the
adler checksum. rsync seems to use a fixed offset during the calculation.
Neither rsync or xdelta mod by a prime, instead they mod by 2^16 (ie, mask
against 0xffff).

I'm not sure how much benefit mod'ing against a prime is for this hash. It
certainly adds overhead and AFAIKT it actualy reduces the hash range. I've
chosen to implement the pure adler32 for academic reasons.

TODO: 
I've seen this algo implemented without the prime called a "fletcher" checksum.
Mathamatical historians are welcome to correct me on this.
It might pay to implement a fletcher checksum to see how much the prime hurts
performance.

"""
_BASE=65521      # largest prime smaller than 65536
_NMAX=5552       # largest n such that 255n(n+1)/2 + (n+1)(BASE-1) <= 2^32-1
_OFFS=1          # default initial s1 offset

### slow version in pure python for reference
##class adler32:
##    def __init__(self,data=''):
##        self.count, self.s2, self.s1 = 0, 0, _OFFS
##        self.update(data)
##    def update(self,data):
##        i=0
##        while i<len(data):
##            for b in data[i:i+_NMAX]:
##                self.s1=self.s1+ord(b)
##                self.s2=self.s2+self.s1
##            self.s1=self.s1 % _BASE
##            self.s2=self.s2 % _BASE
##            i=i+_NMAX
##        self.count=self.count+len(data)
##    def rotate(self,x1,xn):
##        x1,xn=ord(x1),ord(xn)
##        self.s1=(self.s1-x1+xn) % _BASE
##        self.s2=(self.s2-self.count*x1 + self.s1 - _OFFS) % _BASE
##    def digest(self):
##        return (self.s2 << 16) | self.s1

# fast version using adler32 in zlib
import zlib
class adler32:
    def __init__(self,data=''):
        value = zlib.adler32(data,_OFFS)
        self.s2, self.s1 = (value >> 16) & 0xffff, value & 0xffff
        self.count=len(data)
    def update(self,data):
        value = zlib.adler32(data, (self.s2<<16) | self.s1)
        self.s2, self.s1 = (value >> 16) & 0xffff, value & 0xffff
        self.count = self.count+len(data)
    def rotate(self,x1,xn):
        x1,xn=ord(x1),ord(xn)
        self.s1=(self.s1 - x1 + xn) % _BASE
        self.s2=(self.s2 - self.count*x1 + self.s1 - _OFFS) % _BASE
    def digest(self):
        return (self.s2<<16) | self.s1
    def copy(self):
        n=adler32()
        n.count,n.s1,n.s2=self.count,self.s1,self.s2
        return n

new=adler32

if __name__=='__main__':
    from random import randint
    from time import clock

    # generate 8K random data
    data=''
    for i in range(8*1024):
        data=data+chr(randint(0,255))

    # time digest
    t=clock()
    for i in range(80*1024):
        v=adler32(data).digest()
    t=clock()-t
    print "80K x digest of 8K data gave %s in %8.4f seconds" % (hex(v),t)

    # time rotation
    a=adler32(data)
    t=clock()
    for i in 10*data:
        a.rotate(i,i)
        v=a.digest()
    t=clock()-t
    print "80K x rotate of 8K data gave %s in %8.4f seconds" % (hex(v),t)
