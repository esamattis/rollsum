## adler32e.pyx
# rolling adler32 implementation as a pyrex python extension module
#

def update(self,data):
    cdef unsigned long _BASE,_NMAX
    _BASE=65521      # largest prime smaller than 65536
    _NMAX=5552       # largest n such that 255n(n+1)/2 + (n+1)(BASE-1) <= 2^32-1
    cdef unsigned long count,s1,s2
    cdef unsigned long l,i,k
    cdef char *d
    count,s1,s2=self.count,self.s1,self.s2
    d,l=data,len(data)
    i=0
    while i<l:
        k=i+_NMAX
        if k>l: k=l
        while i < k:
            s1=s1+<unsigned char>d[i]
            s2=s2+s1
            i=i+1
        s1=s1 % _BASE
        s2=s2 % _BASE
    self.s1,self.s2,self.count=s1,s2,count+l


def rotate(self, unsigned long x1, unsigned long xn):
    cdef unsigned long count,s1,s2
    count,s1,s2=self.count,self.s1,self.s2
    self.s1=(s1 - x1 + xn) % 65521
    self.s2=(s2 - count*x1 + s1 - 1) % 65521


def digest(self):
    cdef unsigned long s1,s2
    s1,s2=self.s1,self.s2
    return (s2<<16) | s1
