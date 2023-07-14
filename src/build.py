# -*- coding: utf-8 -*-

import numpy as np
import os
import subprocess

# set root path
ROOT = os.path.dirname(__file__)

def main():
    # open standard BASIC rom
    f = open(os.path.join(ROOT, 'BASICROM.BIN'), 'rb')
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
        print('BASIC ROM v1.1 checksum passed')
    
    # insert new instructions at $4EC7 in memory / $3EE0 on ROM chip
    f = open(os.path.join(ROOT, 'ollie.bin'), 'rb')
    ollie = bytearray(f.read())
    f.close()
    rom[0x3EC7:0x3EC7+len(ollie)] = ollie
    print("Inserting code; using %i / %i bytes of free space" % 
          (len(ollie),0x4000-0x3EC7))
    
    f = open(os.path.join(ROOT, 'BASIC-MODIFIED.bin'), 'wb')
    f.write(rom)
    f.close()
    
if __name__ == '__main__':
    main()