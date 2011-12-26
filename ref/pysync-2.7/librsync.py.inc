if __name__ == "__main__":
    import os
    from sys import argv,stdin,stdout,stderr,exit

    def openarg(argno,mode='rb'):
        if (len(argv) <= argno) or (argv[argno] == '-'): 
            if 'r' in mode: return stdin
            return stdout
        return open(argv[argno],mode)
        
    if len(argv)>=2 and argv[1]=="signature":
        oldfile,sigfile=openarg(2,'rb'),openarg(3,'wb')
        stats=filesig(oldfile,sigfile,1024)
        stderr.write(str(stats))
    elif len(argv)>=3 and argv[1]=="rdelta":
        sigfile,newfile,diffile=openarg(2,'rb'),openarg(3,'rb'),openarg(4,'wb')
        stats=filerdelta(sigfile,newfile,diffile)
        stderr.write(str(stats))
    elif len(argv)>=3 and argv[1]=="patch":
        oldfile,diffile,newfile=openarg(2,'rb'),openarg(3,'rb'),openarg(4,'wb')
        stats=filepatch(oldfile,diffile,newfile)
        stderr.write(str(stats))
    else:
        print """
Usage:
    %s signature [<oldfile> [<sigfile>]]
    	... generates signature file <sigfile> from <oldfile>
    
    %s rdelta <sigfile> [<newfile> [<diffile>]]
        ... generates delta file <diffile> for <newfile> from <sigfile>
        
    %s patch <oldfile> [<diffile> [<newfile>]]
        ... applies delta file <diffile> to <oldfile> to generate <newfile>
        
Where file parameters ommitted or specified as '-' indicate standard 
input or output as appropriate.
""" % ((os.path.basename(argv[0]),) * 3)
        exit(1)
