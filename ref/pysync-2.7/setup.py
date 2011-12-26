#!/usr/bin/env python
from distutils.core import setup, Extension
from glob import glob


librsync_sources= """base64.c buf.c checksum.c command.c delta.c 
emit.c fileutil.c hex.c job.c mdfour.c mksum.c msg.c netint.c 
patch.c prototab.c readsums.c scoop.c search.c stats.c stream.c 
sumset.c trace.c tube.c util.c version.c whole.c""".split()
librsync_sources=map(lambda x: "librsync/"+x,librsync_sources)

md4_ext=Extension("md4", ['md4sum/md4module.c','md4sum/md4c.c'])
librsync_ext=Extension(
    "librsyncc",
    ['librsync_wrap.c']+librsync_sources,
    include_dirs=["librsync"])

setup(
    # $Format: "    name=\"$Project$\","$
    name="pysync",
    # $Format: "    version=\"$ProjectVersion$\","$
    version="2.7",
    # $Format: "    description=\"$ProjectDescription$\","$
    description="A Python implementation of the rsync algorithm",
    # $Format: "    author=\"$ProjectAuthorName$\","$
    author="Donovan Baarda",
    # $Format: "    author_email=\"$ProjectAuthorEmail$\","$
    author_email="abo@minkirri.apana.org.au",
    # $Format: "    url=\"$ProjectUrl$\","$
    url="http://freshmeat.net/projects/pysync/",
    py_modules=['pysync','adler32','librsync'],
    ext_modules=[md4_ext,librsync_ext])
