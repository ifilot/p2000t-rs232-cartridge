# -*- coding: utf-8 -*-

import numpy as np
import os
import subprocess
import hashlib

# set root path
ROOT = os.path.dirname(__file__)
START = 0x3EC7 # start position on ROM

def main():
    print('Building ROM...\n')

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
    rom[START:START+len(ollie)] = ollie
    print("Inserting code; using %i / %i bytes of free space" % 
          (len(ollie),0x4000-START))
    
    # verify that the byte at 0x3EEE corresponds to the opt code for ld hl
    print('Checking opt code at 0x3EEE=0x%02X ?= 0x21 (%s)' % 
        (rom[0x3EEE], 'true' if rom[0x3EEE]==0x21 else 'false'))
    assert(rom[0x3EEE]==0x21)

    # store file
    filename = os.path.join(ROOT, 'BASIC-MODIFIED.bin')
    f = open(filename, 'wb')
    f.write(rom)
    f.close()

    # generate checksum
    print()
    print('Done writing modified ROM.')
    print('Checksum: %s' % hashlib.md5(open(filename, 'rb').read()).hexdigest())
    
if __name__ == '__main__':
    main()