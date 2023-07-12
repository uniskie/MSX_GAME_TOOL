#!env python
import sys
import array
import os
#import Enum

# for Python 3.4.5
# 
# extract files in MSX Ys2 Disks
#

infilename = 'YSⅡprogram.DSK' # sys.argv[1]
if (len(sys.argv) > 1):
    if (len(sys.argv[1]) > 0):
        infilename = sys.argv[1]
        print(sys.argv[1])
outdir = os.path.splitext(os.path.basename(infilename))[0] + os.path.sep # sys.argv[2]
if (len(sys.argv) > 2):
    if (len(sys.argv[2]) > 0):
        outdir = sys.argv[2]
        print(sys.argv[2])
outfilename = outdir
print(outdir)
print(os.getcwd())
#i=input()

os.makedirs(outdir, exist_ok=True)


sector_size = 512
entry_size = 16

infile = open(infilename, 'rb')
data = infile.read()
print('in_file size = ' + str(len(data)))

listfile = open( outfilename + '_list.txt', mode='w' )
listfile.write( infilename + '\n' )
listfile.write('filename ( start sector, sector count )\n')
listfile.write('-------------------------------------------\n')
is_loop = True
f = sector_size
dirpos = 0

file_head = 0
file_end = 0

file_no = 0
custom_no = 0

while is_loop:
    diros = f

    dir_entry = bytearray()
    dir_entry[:] = data[f:f+entry_size]
    #print( dir_entry[0])

    if (dir_entry[0] < 128) :
        outname = dir_entry[0:6].decode('sjis', 'replace')
        file_head = int.from_bytes(dir_entry[12:14], byteorder='little')
        file_end  = int.from_bytes(dir_entry[14:16], byteorder='little')
        print(outname + ' (' + format(file_head, '4d') + ', ' + format(file_end - file_head + 1, '4d')+ ')')

        listfile.write(outname + ' (' + format(file_head, '4d') + ', ' + format(file_end - file_head + 1, '4d')+ ')\n')
        
        outdata = bytearray()
        outdata[:] = data[ file_head * sector_size : file_end * sector_size ]
        outfile = open( outfilename + outname + '.bin', 'wb')
        outfile.write(outdata)
        outfile.close()

    file_no = file_no + 1

    f = f + entry_size
    if (f >= sector_size * (1 + 4) ):
        break

listfile.close()
                 
infile.close()

print('-- end -- hit enter key') 
i=input()

