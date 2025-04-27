; pt3 player for HomeLab3 + The Cart
;

CMD_OPEN_DIR 		equ  1
CMD_NEXT_DIRENTRY 	equ  2
CMD_CLOSE_DIR 		equ  3
CMD_OPEN_HTP_FILE 	equ  4
CMD_READ_HTP_BLOCK 	equ  5
CMD_CLOSE_FILE 		equ  6
CMD_OPEN_BIN_FILE_FOR_READ 		equ  12
CMD_READ_BIN_FILE   equ  13

CTRL_PORT equ $40
SCREEN_ADDR_START equ $F800

CHR_BELL equ 05
CHR_INS  equ 06
CHR_DEL  equ 07
CHR_DWN  equ 08
CHR_UP   equ 09
CHR_LFT  equ 10
CHR_RGH  equ 11
CHR_CLS  equ 12
CHR_CR   equ 13
CHR_TAB  equ 14
CHR_HOME equ 15
CHR_LT   equ $3c ; <
CHR_GT   equ $3e ; >

CHR_TOP_LEFT	equ 142
CHR_TOP_RIGHT 	equ 143
CHR_BOT_LEFT 	equ 144
CHR_BOT_RIGHT 	equ 145
CHR_HOR_MID     EQU 146
CHR_VER_MID     EQU 147
CHR_CROSS     	EQU 148
CHR_VER_LEFT_MID EQU 158
CHR_VER_RIGHT_MID EQU 159
CHR_HOR_TOP_MID EQU 190
CHR_HOR_BOT_MID EQU 191
CHR_TILDE EQU 187

SYS_WAIT_FOR_SYNC     EQU $00F6
SYS_PRINT_STRING      equ $018F
SYS_PRINT_HEX_BYTE    equ $01A5
SYS_UPDATE_PRINT_ADDR equ $0277
SYS_PRG_LOAD_INIT     equ $0D63
SYS_AUTOSTART_ENTRY   equ $179D
SYS_READ_ONE_LINE     equ $0546

SYSVAR_SCREEN_WIDTH equ $400A  ; 1 means 32 chars, 2 means 64 chars
SYSVAR_PRINT_ADDR equ $4014
SYSVAR_BUFFER_POINTER equ $400B
SYSVAR_MEM_TOP equ $4016
SYSVAR_NEXT_BASIC_LINE equ $402E
SYSVAR_IRQ_VECT EQU $403F
SYSVAR_AUTOSTART EQU $404C

CARTRAM equ $DF00

  org $4100
  
  ld hl, $035c
  ld ($4002), hl
  ld hl, $0283
  ld ($4004), hl
  pop hl

START_AGAIN  
  ld a, $0c
  rst $28

  call PRINT_SCREEN
  ld hl, HLSTR_READING_LIST
  call PRINT_MESSAGE
  call PRINT_PTxFILES
  ret nz
  call GET_FILENAME
  ld a, (CARTRAM)
  or a
  ret z
  CALL SET_PT_VERSION
  call LOAD_FILE
  jr nz, SPACEPRESS
  call TIDY_BOX_UP
  call PT_INIT
  call PT_PLAY
  call MUTE
  jr START_AGAIN
  
SPACEPRESS
  call $00F6
  ld a, ($e801)
  bit 0, a
  jr nz, SPACEPRESS
  jr START_AGAIN
  
TIDY_BOX_UP
  xor a
  rst $28
  ld hl, $f841
  call SYS_UPDATE_PRINT_ADDR
  ld a, $20
  call DRAW_LINE
  xor a
  rst $28
  ld hl, $f875
  call SYS_UPDATE_PRINT_ADDR
  ld hl, HLSTR_BACK
  call SYS_PRINT_STRING
  ret

PRINT_SCREEN
  ld a, CHR_TOP_LEFT
  RST $28
  ld a, CHR_HOR_MID
  call DRAW_LINE
  ld a, CHR_TOP_RIGHT
  rst $28
  ld a, CHR_VER_MID
  rst $28
  xor a
  rst $28
  ld hl, $f87f
  call SYS_UPDATE_PRINT_ADDR
  ld a, CHR_VER_MID
  rst $28
  ld a, CHR_BOT_LEFT
  rst $28
  ld a, CHR_HOR_MID
  call DRAW_LINE
  ld a, CHR_BOT_RIGHT
  rst $28
  ld a, $0d
  rst $28
  ld hl, $f800 + (31*64) + 1
  call SYS_UPDATE_PRINT_ADDR
  ld hl, HLSTR_POWEREDBY
  ld c, 0
  call SYS_PRINT_STRING
  ret

DRAW_LINE
  ld b, 62
.loop_line
  push af
  push bc
  rst $28
  pop bc
  pop af
  djnz .loop_line
  ret

PRINT_MESSAGE
  push hl
  xor a
  rst $28
  ld hl, $F841
  call SYS_UPDATE_PRINT_ADDR
  pop hl
  ld c, 0
  call SYS_PRINT_STRING
  ret


PRINT_PTxFILES
  ld hl, $F940
  call SYS_UPDATE_PRINT_ADDR
  xor a
  ld ($DF00), a
  ld a, CMD_OPEN_DIR
  out (CTRL_PORT), a
  call WAIT_PROCESSED
  jr nz, .open_dir_failed
.read_direntry_loop
  ld a, CMD_NEXT_DIRENTRY
  out (CTRL_PORT), a
  call WAIT_PROCESSED
  jr nz, .io_error
  ld a, ($DF05)
  or a
  jr z, .end_of_dir
  call .check_ptx_extension
  jr nz,.read_direntry_loop
  ld hl, $DF05
.print_name_loop
  ld a, (hl)
  rst $28
  inc hl
  or a
  jr nz, .print_name_loop
  ld hl, (SYSVAR_PRINT_ADDR)
  ld a, l
  and a, $F0
  ld l, a
  ld de, $0010
  add hl, de
  call SYS_UPDATE_PRINT_ADDR
  jr .read_direntry_loop
  
.check_ptx_extension
  ld hl, $DF05
  ld de, .STR_PTx_EXT
.check_loop
  ld a, (de)
  cp (hl)
  jr z, .ext_eq
  ld de, .STR_PTx_EXT
.check_cont
  inc hl
  ld a, (hl)
  or a
  jr nz, .check_loop
  inc a
  ret
.ext_eq
  inc de
  ld a, (de)
  or a
  jr nz, .check_cont
  ret

.end_of_dir
  ld a, CMD_CLOSE_DIR
  out (CTRL_PORT), a
  call WAIT_PROCESSED
  xor a
  ret
  
.open_dir_failed
  ld hl, HLSTR_ERR_OPEN_DIR
  call PRINT_MESSAGE
  xor a
  inc a
  ret
  
.io_error
  ld hl, HLSTR_ERR_IO_ERR
  call PRINT_MESSAGE
  ld a, CMD_CLOSE_DIR
  out (CTRL_PORT), a
  call WAIT_PROCESSED
  xor a
  inc a
  ret

.STR_PTx_EXT
  db ".PT", 0
  
WAIT_PROCESSED
  push bc
  push de
  ld b, $20
.check_ack
  in a, (CTRL_PORT)
  cp $7F
  jr z, .ack
  djnz .check_ack
  jr .nok
.ack
  ld de, $0000
  ld b, $40
.loop_wait_processed
  in a,(CTRL_PORT)
  ld c, a
  nop
  cp $FF
  jr nz, .result_arrived
  dec de
  ld a, d
  or e
  jr nz, .loop_wait_processed
  djnz .loop_wait_processed
  ld a, c
  or a
  jr .nok
.result_arrived
  and $80
  ld a, c
  jr nz,.nok
.nok
  pop de
  pop bc
  ret
  
GET_FILENAME
  ld hl, $F841
  call SYS_UPDATE_PRINT_ADDR
  ld a, $20
  call DRAW_LINE
  xor a
  rst $28
  ld hl, HLSTR_FN_INPUT_QUESTION
  call PRINT_MESSAGE
  call INPUT_TILL_CR
  ret
    
LOAD_FILE
  ld a, CMD_OPEN_BIN_FILE_FOR_READ
  out (CTRL_PORT), a
  call WAIT_PROCESSED
  jr nz, .file_open_err
  ld de, MDLADDR
  ld b, 0
.file_load_loop
  ld a, CMD_READ_BIN_FILE
  out (CTRL_PORT), a
  call WAIT_PROCESSED
  jr nz, .file_finished
  ld a, ($DF00)
  ld c, a
  ld hl, $DF01
  ldir
  ld a, ($DF00)
  cp $ff
  jr z, .file_load_loop
.file_finished
  ld a, CMD_CLOSE_FILE
  out (CTRL_PORT), a
  call WAIT_PROCESSED
  xor a
  ret
.file_open_err
  push af
  ld hl, HLSTR_ERR_FILE_NOT_FOUND
  call PRINT_MESSAGE
  pop af
  call SYS_PRINT_HEX_BYTE
  xor a
  rst $28
  
  xor a
  inc a
  ret

PT_INIT
  LD A, (PT_VERSION)
  cp '2'
  ld a, 2
  jr z, .version_set
  LD A, 0
.version_set
  LD (START+10),A
  ld hl, MDLADDR
  JP INIT
  
PT_PLAY
  CALL PLAY
  ld a, (PRINT_AY_REGISTERS)
  or a
  jr z, .skip_print_ayregs
  ld hl, AYREGS
  ld bc, 13
  ld de, $F841
  ldir
  ld a, (CurPos)
  call .print_hex
.skip_print_ayregs
  call $00f6
  ld a, ($E803)
  bit 2, a
  jr nz, PT_PLAY
  ret

.print_hex
  push af
  rlca        
  rlca        
  rlca        
  rlca        
  call .print_nibble
  pop  af     
.print_nibble
  and  0Fh    	; 15
  cp   0Ah    	; 10
  jr   c, .digit_ok
  add  a,07h  	; 7
.digit_ok:
  add  a,30h  	; 48, '0'
  ld (de), a
  inc de
  ret
  
PT_VERSION
  db 00
  
PRINT_AY_REGISTERS
  db 1

INPUTSCREEN_ADDR_START
	dw 0000
INPUTSCREEN_ADDR_END
	dw 0000
LAST_CHAR
	db 00
CHAR_CNT
    db 00
	

CHAR_CNT_CONST equ $0c
INPUT_TILL_CR
  ld hl, (SYSVAR_PRINT_ADDR)
  ld (INPUTSCREEN_ADDR_START), hl
  xor a
  ld (LAST_CHAR), a
  ld a, CHAR_CNT_CONST
  ld (CHAR_CNT), a
  ld a, $86
  rst $28
  ld a, CHR_LFT
  rst $28
.input_loop
  rst $18
  ld hl, LAST_CHAR
  cp (hl)
  jr nz, .process_key
  ld hl, CHAR_CNT
  dec (hl)
  ld a, (hl)
  or a
  jr nz, .input_loop
  jr .last_char_stored
.process_key
  ld (LAST_CHAR), a
.last_char_stored
  ld a, CHAR_CNT_CONST
  ld (CHAR_CNT), a
  ld a, (LAST_CHAR)
  or a
  jr z, .input_loop
  cp $0d
  jr z, .done
  cp $0a
  jr z, .back
  cp $20
  jr c, .input_loop
  push hl
  ld c, a
  ld de, $f87E
  ld hl, (SYSVAR_PRINT_ADDR)
  xor a
  sbc hl, de
  ld a, c
  pop hl
  jr z, .input_loop
  jr .print_char_and_cursor
.back
  ld de, (SYSVAR_PRINT_ADDR)
  ld hl, (INPUTSCREEN_ADDR_START)
  xor a
  sbc hl, de
  jr z, .input_loop
  ld a, $20
  rst $28
  ld a, $0a
  rst $28
.print_char_and_cursor
  rst $28
  ld a, $86
  rst $28
  ld a, $0a
  rst $28
  jr .input_loop
.done
  xor a
  ld bc, (SYSVAR_PRINT_ADDR)
  ld hl, (INPUTSCREEN_ADDR_START)
  ld de, CARTRAM
.copy_loop
  xor a
  push hl
  sbc hl, bc
  pop hl
  jr z, .end_loop
  ld a, (hl)
  ld (de), a
  inc hl
  inc de
  jr .copy_loop
.end_loop
  ld (de), a
  ld a, $20
  rst $28
  xor a
  rst $28
  ret
  
SET_PT_VERSION
  ld hl, CARTRAM
.find_last_char
  ld a, (hl)
  or a
  jr z, .end
  ld b, a
  inc hl
  jr .find_last_char
.end
  ld a, b
  ld (PT_VERSION), A
  ret


HLSTR_ERR_FILE_NOT_FOUND
  db "Hiba a f", 127, "jl megnyit", 127, "sakor !   (SPACE", (')' + 128)
HLSTR_FN_INPUT_QUESTION
  db "Lej", 127, "tszand", 126, " file neve?     ", 10, 10, 10, 10, 10, (' ' + 128)
HLSTR_ERR_IO_ERR
  db "Hiba a k", 124, "nyvt", 127, "r olvas", 127, "sa sor", 127, "n", ('!' + 128)
HLSTR_BACK
  db "Vissza: F", ('1' + 128)
  


HLSTR_ERR_OPEN_DIR
  db "Hiba a k", 124, "nyvt", 127, "r megnyit", 127, "sa sor", 127, "n!", 13, (13 + 128)
HLSTR_READING_LIST
  db ".PTx file-lista beolvas", 127, "sa..", ('.' + 128)

HLSTR_POWEREDBY
  db "Powered by Universal PT2 and 3 player by S.V.Bulba (2004-2007", (")" + 128)

include HL3PTxPlay.asm

ENDADDR