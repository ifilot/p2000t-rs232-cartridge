;-------------------------------------------------------------------------------
; This code is based on the source code as developed by
; dionoid(https://github.com/dionoid) as found via the link below:
; https://github.com/p2000t/software/blob/master/utilities/pc2p2000t/pc2p2000t.z80.asm
;-------------------------------------------------------------------------------
basic_start_addr:    EQU    $6547

    org $4ec7

pageaddr:
    DB $9f,$df,$ff ; set page address positions (upper byte)

; exactly 27 bytes of data should be placed here such that the starting
; instruction is at $4eee; this allows for an easy BASIC command of
; `20 DEF USR1=&H4EEE`

    ; dummy data (36 bytes)
    DB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
    DB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
    DB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00

start:
    ld hl,.line1
    ld de,$5000+20*$50
    call printstring
    ld hl,.line2
    ld de,$5000+21*$50
    call printstring
    jp read_program

.line1: DB "P2000T READY TO COPY FILE OVER RS232",255
.line2: DB "BAUD=9600, PARITY=N, DATA=8, STOP=1",255

;-------------------------------------------------------------------------------
; reads a byte from the serial port (9600 baud) and returns in A
;-------------------------------------------------------------------------------
read_byte:
    push bc
check_start_bit:
    in a,($20)
    and $01                 ; check if bit D0 is 0
    jr nz, check_start_bit
    ld b, $15
delay_on_start_bit:
    djnz delay_on_start_bit
    ld b, $08

read_next_bit:
    in a,($20)

    ; 58 clocks without extra delay
    ; 1.2 * 1041.67 = 1250. Need delay in B: 
    ; 2400 baud: (1250 - 58) / 13 = 91,7 + 1 = 93 (&h5D)

    ; 4800 baud: 1.2 * 520.84 = 625
    ; delay in B: (625 - 58) / 13 = 43,62 + 1 = 45 (&h2D)

    ; 9600 baud: 1.2 * 260.42 = 312.5
    ; delay in B: (312.5 - 58) / 13 = 19.6 + 1 = 21 (&h15)

    rra                     ; bit 0 into carry
    rr c
    push bc
    ld b, $10
delay_bit:
    djnz delay_bit
    pop bc
    djnz read_next_bit

    ; 72 clocks without extra delay. So delay in B: 
    ; 2400 baud: (1041.67 - 72) / 13 = 74.6 + 1 = 76 (&h4C)
    ; 4800 baud: (520.84 - 72) / 13 = 34.53 + 1 = 35 (&h23)
    ; 9600 baud: (260.42 - 72) / 13 = 14.49 + 1 = 16 (&h10)

    ld a,c
    pop bc
    ret

;-------------------------------------------------------------------------------
; read a program over the RS232 port
;-------------------------------------------------------------------------------
read_program:               ; start the program
    di                      ; disable interrupts

read_header:                ; read 256-byte header into top of memory
    call setpage
    ld l,0
    ld b,0
read_header_loop:
    call read_byte
    ld (hl),a
    inc hl
    djnz read_header_loop

    ;read the blocks and put into basic memory
    push bc
    call setpage
    pop bc
    ld l,$4f                ; set pointer to address containing number of blocks
    ld c, (hl)              ; load number of blocks into c
    ld hl, basic_start_addr   ; ?read pointer from $625c?
    jr read_block           ; first header already read, so skip
ignore_header:
    ld b, $00               ; ignore later 256-byte headers
ignore_header_loop:
    call read_byte
    djnz ignore_header_loop
read_block:
    ld de, $400
read_block_loop:
    call read_byte
    ld (hl),a
    inc hl
    dec de
    ld a,d
    or e
    jr nz, read_block_loop
    dec c
    jr nz, ignore_header

    ld de, basic_start_addr ; set de to start of basic program
    call setpage            ; set page in h
    ld l,$34
    ld c,(hl)               ; load lower byte program length
    inc hl                  ; increment pointer
    ld b,(hl)               ; lower upper byte program length
    ld a,b                  ; copy b->a->h
    ld h,a
    ld a,c                  ; copy c->a->l
    ld l,a
    add hl,de
    ld ($6405), hl          ; set basic pointers to var space
    ld ($6407), hl
    ld ($6409), hl

    ; reset the pointers to end of memory for BASIC
    ld a, ($63b9)
    add a, 2
    ld ($63b9), a
    ld ($6259), a

    ; succes: play beep
    ld a,$07
    call $104a

    ei                      ; enable interrupts
    ret

;-------------------------------------------------------------------------------
; set the page to which the header data is written in h
; output: hl - start of buffer area
;   uses: a,bc
;-------------------------------------------------------------------------------
setpage:
    ld bc,pageaddr         ; set pointer to page addresses
    ld a,($605c)           ; read RAM value, 1->16kb,2->32kb,3->48kb
    dec a                  ; decrement such that index starts at 0
    add a,c                ; add lower byte of page addr to it
    ld c,a                 ; update lower byte page address pointer
    ld a,(bc)              ; load page byte into a
    ld h,a                 ; set upper byte into h
    ld l,$00               ; set lower byte to 0
    ret

;-------------------------------------------------------------------------------
; print string to screen
; input: hl - string pointer
;        de - screen address
; output: de - exit video address
; uses: a
;-------------------------------------------------------------------------------
printstring:
    ld a,(hl)
    cp 255
    ret z
    ld (de),a
    inc de
    inc hl
    jp printstring