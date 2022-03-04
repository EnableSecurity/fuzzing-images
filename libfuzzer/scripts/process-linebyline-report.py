import sys, os

globaldata={}

def parse(p):
    newfile=True
    currentfile=''
    for l in open(p, 'rt').read().split('\n'):
        if newfile:
            if l.endswith(':'):
                sourcefile = l[:-1]
                if sourcefile[0] == '/':
                    sourcefile=sourcefile[1:]
                currentfile = sourcefile
                if sourcefile not in globaldata:
                    globaldata[sourcefile] = []
                newfile=False
        else:
            if l.strip() == '':
                newfile=True
            else:
                lp = l.split('|', 3)
                try:
                    linenumber=int(lp[0].strip())
                    count='0'
                    if lp[1].strip()!='':
                        count=lp[1].strip()
                    code=lp[2]
                    if len(globaldata[currentfile])<linenumber:
                        globaldata[currentfile].append([linenumber, code, count])
                    else:
                        globaldata[currentfile][linenumber-1].append(count)
                except:
                    # skip exceptions such as "Unexecuted instantiation"
                    pass



if __name__ == '__main__':
    if len(sys.argv)<3:
        print('Usage: python3 process-linebyline-report.py <reportpath> <outputpath>, aborting')
        sys.exit()

    sourcedir=sys.argv[1]
    if not os.path.exists(sourcedir):
        print('path not found, aborting')
        sys.exit()

    if not os.path.exists(os.path.join(sourcedir, 'snapshots.txt')):
        print('missing snapshots.txt, aborting')
        sys.exit()

    for d in open(os.path.join(sourcedir, 'snapshots.txt'), 'rt').read().split('\n'):
        d=d.strip()
        if d=='':
            break
        
        parse(os.path.join(sourcedir, 'run.%s.linebyline-report.txt' % d))

    outdir=sys.argv[2]

    pathfilter=''
    if len(sys.argv)>3:
        pathfilter=sys.argv[3]

    if not os.path.exists(outdir):
        os.makedirs(outdir)
    nocoverage = open(os.path.join(outdir, 'nocoverage.txt'), 'wt')
    for sourcefile in globaldata:
        sourcedir, sourcefilename = os.path.split(sourcefile)
        reportoutdir = os.path.join(outdir, sourcedir)

        doit=pathfilter==''
        if pathfilter!='':
            if pathfilter in sourcefile:
                doit=True

        if doit:
            if not os.path.exists(reportoutdir):
                os.makedirs(reportoutdir)
            src = ''
            allzero = True
            for l in globaldata[sourcefile]:
                for cnt in l[2:]:
                    if cnt.strip()!='0':
                        allzero = False
                    src += ' %8s |' % cnt
                    # fout.write(' %8s |' % cnt)
                src += ' '
                # fout.write(' ')
                src += l[1]
                # fout.write(l[1])
                src += '\n'
                # fout.write('\n')
            if allzero:
                nocoverage.write('no coverage in %s' % sourcefile)
                nocoverage.write('\n')
            else:
                with open(os.path.join(reportoutdir, sourcefilename), 'wt') as fout:
                    fout.write(src)
    nocoverage.close()