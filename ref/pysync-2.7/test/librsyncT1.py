#!/usr/bin/env python

import os,sys,random,librsync
from testdata import *

def fcopy(pos,len,file):
    file.seek(pos)
    return file.read(len)

def scopy(pos,len,str):
    return str[pos:pos+len]

olddata=get_olddata("oldfile.bin",256*KB)
newdata=get_newdata("newfile.bin",olddata)

librsync.rs_trace_set_level(librsync.RS_LOG_DEBUG)

c=librsync.calcsigobj(1024)
sigdata=c.calc(olddata)+c.flush()
print c.statistics()
open("sigfile.bin",'wb').write(sigdata)

c=librsync.loadsigobj()
c.calc(sigdata)+c.flush()
sighash=c.calcsig()
print c.statistics()

c=librsync.rdeltaobj(sighash)
difdata=c.calc(newdata)+c.flush()
print c.statistics()
open("diffile.bin",'wb').write(difdata)

c=librsync.patchobj(scopy,olddata)
upddata=c.calc(difdata)+calc.flush()
print c.statistics()
open("updfile.bin",'wb').write(updata)
