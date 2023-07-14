# -*- coding: utf-8 -*-

import numpy as np
import os
import subprocess

# set the path to the assembler
tniasm = os.path.join('d:/', 'tniasm', 'tniasm.exe')

# set root path
ROOT = os.path.dirname(__file__)

def main():
    # compile assembly
    #compile_asm(os.path.join(ROOT, 'stan.asm')) 
    compile_asm(os.path.join(ROOT, 'ollie.asm'))

    # open standard BASIC rom
    f = open('BASICROM.bin', 'rb')
    rom = bytearray(f.read())
    f.close()
    
    # load checksum parameters
    llb = rom[0x0001] # low byte length
    lhb = rom[0x0002] # high byte length
    nbytes = (lhb * 256 + llb)
    
    # calculate checksum
    checksum = np.uint16(0)
    for i in range(0x0005, 0x0005 + nbytes):
        checksum += rom[i]
    checksum &= 0xFFFF
    
    # verify whether checksum passes and we are dealing with the
    # BASIC ROM v1.1
    if rom[0x0003] == checksum & 0xFF and rom[0x0004] == (checksum >> 8):
        print('Checksum passed')
    
    # insert new instructions at $4EE0 in memory / $3EE0 on ROM chip
    f = open(os.path.join(ROOT, 'ollie.bin'), 'rb')
    ollie = bytearray(f.read())
    f.close()
    rom[0x3F00:0x3F00+len(ollie)] = ollie
    print("Inserting ollie code; using %i / %i bytes of free space" % 
          (len(ollie),0x4000-0x3F00))
    
    f = open('BASIC-MODIFIED.bin', 'wb')
    f.write(rom)
    f.close()
    
def compile_asm(filename):
    print('Compiling: %s' % filename)
    output = filename.replace('.asm','.bin')
    out = subprocess.check_output([tniasm, filename, output], cwd=ROOT)
    print('\n'.join(out.decode().split('\r\n')))
    
if __name__ == '__main__':
    main()