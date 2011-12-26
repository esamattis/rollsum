#!/usr/bin/env python

import os,sys,random
from testdata import *

olddata=get_olddata("oldfile.bin",256*KB)
newdata=get_newdata("newfile.bin",olddata)

execute("./pysync.py signature oldfile.bin sigfile.bin")
execute("./pysync.py rdelta sigfile.bin newfile.bin diffile.bin")
execute("./pysync.py patch oldfile.bin diffile.bin updfile.bin")
execute("diff newfile.bin updfile.bin")
execute("./pysync.py xdelta oldfile.bin newfile.bin diffile.bin")
execute("./pysync.py patch oldfile.bin diffile.bin updfile.bin")
execute("diff newfile.bin updfile.bin")
