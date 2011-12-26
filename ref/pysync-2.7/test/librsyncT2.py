#!/usr/bin/env python

import os,sys,librsync
from testdata import *

old="oldfile.bin"
new="newfile.bin"
sig="sigfileT.bin"
dif="diffileT.bin"
upd="updfileT.bin"

olddata=get_olddata(old,256*KB)
newdata=get_newdata(new,olddata)
        
librsync.rs_trace_set_level(librsync.RS_LOG_DEBUG)

s=librsync.filesig(open(old,'rb'),open(sig,'wb'),1024)
print s

s=librsync.filerdelta(open(sig,'rb'),open(new,'rb'),open(dif,'wb'))
print s

s=librsync.filepatch(open(old,'rb'),open(dif,'rb'),open(upd,'wb'))
print s
