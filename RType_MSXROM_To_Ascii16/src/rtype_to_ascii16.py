#!env python
import sys
import array
import os
#import Enum

# for Python 3.4.5
# 
# Change R-Type Bank to ASCII16
#

infilename = 'RTYPE.ROM' # sys.argv[1]
if (len(sys.argv) > 1):
    if (len(sys.argv[1]) > 0):
        infilename = sys.argv[1]
        print(sys.argv[1])
outfilename = os.path.splitext(os.path.basename(infilename))[0] + '_ASCII16.ROM' # sys.argv[2]
if (len(sys.argv) > 2):
    if (len(sys.argv[2]) > 0):
        outfilename = sys.argv[2]
        print(sys.argv[2])
print(outfilename)
print(os.getcwd())
#i=input()

bank_list = [0x3c000, \
             0x00000, 0x04000, 0x08000, 0x0c000, \
             0x10000, 0x14000, 0x18000, 0x1c000, \
             0x20000, 0x24000, 0x28000, 0x2c000, \
             0x30000, 0x34000, 0x38000, 0x5c000, \
             0x40000, 0x44000, 0x48000, 0x4c000, \
             0x50000, 0x54000, 0x58000,  \
             0x7c000, \
             0x60000, 0x64000, 0x68000, 0x6c000, \
             0x70000, 0x74000, 0x78000 \
             ]
bank_size = 0x4000
rom_size = 0x60000

## read file

infile = open(infilename, 'rb')
data = infile.read()
infile.close()
print('in_file size = ' + str(len(data)))

## set outdata

outdata = bytearray()
outdata[:] = data[:]
#outdata[:] = data[0:rom_size]
print('out_file size = ' + str(len(outdata)))

# Modify Bank
print('#Modify Bank')
s = 0
for i in bank_list:
    if (s + bank_size) >= len(outdata):
        break
    outdata[s:s+bank_size] = data[i:i+bank_size]
    print(hex(s) + ' = ' + hex(i))
    s = s + bank_size

# Change LD (7000H),A -> CALL [PUSH AF:INC A:LD (7000H),A:POP AF:RET]
print('# Change LD (7000H),A -> CALL [PUSH AF:INC A:LD (7000H),A:POP AF:RET]')

# Search for all "320070" and change to "CD0440" in first bank.
print('#Search for all "320070" and change to "CD0440" in first bank.')
s=0
f = b'\x32\x00\x70'
r = b'\xCD\x04\x40'
while s>-1:
    s = outdata.find(f)
##    if s>=bank_size:
##        break
    if s>-1:
        outdata[s:s+len(r)] = r[:]
        print(hex(s))

# Search for all "4142104000000000000000" and change to "41421040F53C320070F1C9".
print('#Search for all "4142104000000000000000" and change to "41421040F53C320070F1C9".')
s = 0
f = b'\x41\x42\x10\x40\x00\x00\x00\x00\x00\x00\x00'
r = b'\x41\x42\x10\x40\xF5\x3C\x32\x00\x70\xF1\xC9'
while s>-1:
    s = outdata.find(f)
    if s>-1:
        outdata[s:s+len(r)] = r[:]
        print(hex(s))

# write outfile

outfile = open( outfilename, 'wb')
outfile.write(outdata)
outfile.close()

# end

print('-- end -- hit enter key') 
i=input()

