  DEFPAGE 0, $D000, $0F00
  DEFPAGE 1..2

  PAGE 0
  CODE @ $D000

  JP MAIN
  JP COMMAND_HANDLER
  JP JUMP_INTEXAMPLE
  jp JUMP_RAMTEST
  dw LOAD_HTP_FILE_API
  dw SAVE_HTP_FILE_API

  CODE @ $D010
CTRL_PORT equ $40
SCREEN_ADDR_START equ $F800

VER_MAJOR    equ '1'
VER_MINOR_D1 equ '0'
VER_MINOR_D2 equ '1'

CMD_MOUNT_SD 		equ  0
CMD_OPEN_DIR 		equ  1
CMD_NEXT_DIRENTRY 	equ  2
CMD_CLOSE_DIR 		equ  3
CMD_OPEN_HTP_FILE 	equ  4
CMD_READ_HTP_BLOCK 	equ  5
CMD_CLOSE_FILE 		equ  6
CMD_GET_CURR_PATH 	equ  7
CMD_SET_CURR_PATH	equ  8
CMD_SET_START_TIMER	equ  9
CMD_STOP_TIMER		equ 10
CMD_ACK_TIMER		equ 11
CMD_OPEN_BIN_FILE_FOR_WRITE equ 15
CMD_WRITE_BIN_BLOCK equ 16
CMD_DELETE			equ 17
CMD_RENAME			equ 18
CMD_SWITCH_PAGE 	equ 19
CMD_CHECK_MOUNTED	equ 20

  
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

SYSVAR_SCREEN_WIDTH equ $400A  ; 1 means 32 chars, 2 means 64 chars
SYSVAR_PRINT_ADDR equ $4014
; SYSVAR_PRINT_ADDR equ $CFFE
SYSVAR_BUFFER_POINTER equ $400B
SYSVAR_MEM_TOP equ $4016
SYSVAR_NEXT_BASIC_LINE equ $402E
SYSVAR_IRQ_VECT EQU $403F
SYSVAR_AUTOSTART EQU $404C

WINDOW_HEIGHT equ 20

KEY_DOWN  equ 1
KEY_UP    equ 2
KEY_LEFT  EQU 3
KEY_RIGHT equ 4
KEY_HOME  equ 5
KEY_END   equ 6
KEY_RET   equ 7
KEY_F1	  equ 8

KEY_COUNT_FIRST equ 30
KEY_COUNT_NEXT  equ 7

  map $6000
NUM_OF_ENTRIES # 2
WINDOW_POS # 2
SELECTED_LINE # 1
CURR_LINE # 1
CURR_ENTRY_ADDR # 2
CURRENT_ENTRY_SCREEN_ADDR # 2
DIR_LEVEL # 1
LAST_KEY # 1
KEY_WAIT_COUNTER # 1
PATH_PRINTED # 1	; 0 - no, 1 - yes
DIRECTORY_ENTRIES # 1
  endmap

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
  
SWITCH_BACK_TO_PAGE0
  push af
  xor a
  ld ($DF00), a
  ld a, CMD_SWITCH_PAGE
  out (CTRL_PORT), A
  call WAIT_PROCESSED
  jr z, .switch_ok
.system_error
  ld de, $D800
  ld hl, STR_ERR_PAGE_CHANGE_FAILED
.print_loop
  call SYS_WAIT_FOR_SYNC
  ld a, (hl)
  or a
  jr z, .print_loop
  ld (de), a
  inc hl
  inc de
  jr .print_loop
.switch_ok
  pop af
  ret

JUMP_PAGED_COMMAND
  ld ($DF00), a
  ld a, CMD_SWITCH_PAGE
  out (CTRL_PORT), A
  call WAIT_PROCESSED
  jr nz, SWITCH_BACK_TO_PAGE0.system_error
  jp (HL)

; PARAM POI
; RETVAL of CALL
; RETVAL of COMMAND_HANDLER.fix_parameters
; RETVAL of the caller
COPY_PARAM_TO_CARTRAM
  ld hl, 6
  add hl, sp
  ld a, (hl)
  inc hl
  ld h, (hl)
  ld l, a
  ld de, $DF00
  ld b, $FE
.copy_p_loop
  ld a, (hl)
  cp $60
  jr nz, .eol_check_done
  xor a
.eol_check_done
  cp '"'
  jr nz, .closing_dq_check_done
  xor a
.closing_dq_check_done
  ld (de), a
  inc hl
  inc de
  or a
  ret z
  djnz .copy_p_loop
  xor a
  ld (de), a
  ret

STRHL_ERR_MOUNT_FAILED	; +
  db "Becsatol", 127, "s nem siker", 125, "lt", ('!' + 128)
STR_ERR_PAGE_CHANGE_FAILED	; +
  db "!! MEMLAPOZ", 64, "SI RENDSZER HIBA!! ", 0

; can print several lines not bothering about the sync, the caller must make sure
; handles only the CR as special character, the others are simply skipped
print_fast_str
  push hl
  ld hl, (SYSVAR_PRINT_ADDR)
  ex de, hl
  pop hl
.print_fast_str_loop
  ld a,(hl)
  or a
  ret z
  cp $10
  jr c, .ctrl_char	; a < $10
  ld (de), a
  inc hl
  inc de
  ld a, (SYSVAR_SCREEN_WIDTH)
  cp 2
  jr nz, .skip_inc_charpos
  inc de
.skip_inc_charpos
  ex de, hl
  ld (SYSVAR_PRINT_ADDR), hl
  ex de, hl
  jr .print_fast_str_loop
.ctrl_char
  cp CHR_CR
  jr nz, .skip_cr
  push hl
  ld a, e
  and $C0
  ld e, a
  ld hl, 64
  add hl, de
  ld (SYSVAR_PRINT_ADDR), hl
  ex de, hl
  pop hl
.skip_cr
  inc hl
  jr .print_fast_str_loop

//no need to be in 0x00 - 0x100  

JUMP_INTEXAMPLE
  ld hl, INTEXAMPLE
  ld a, 1
  jp JUMP_PAGED_COMMAND

JUMP_RAMTEST
  ld hl, RAMTEST
  ld a, 1
  jp JUMP_PAGED_COMMAND

MAIN
  ld bc, DIRECTORY_ENTRIES - NUM_OF_ENTRIES - 1
  ld hl, NUM_OF_ENTRIES
  ld de, NUM_OF_ENTRIES + 1
  xor a
  ld (NUM_OF_ENTRIES), a
  ldir
  
  ld hl, PAGE1_PRINT_MENU
  ld a, 1
  call JUMP_PAGED_COMMAND
;  call PRINT_MENU
  
  ld hl, STR_MOUNT_IN
  call print_status_message
  
  call MOUNT
  
  jr nz, MOUNT_FAILED
  ld hl, STR_MOUNT_OK
  call print_status_message
  
  ld hl, $002f ; "/", nul terminated string
  ld ($DF00), hl
  
  ld hl, STR_OPEN_IN
  call print_status_message
  
  call OPEN_DIR
  jr nz, OPEN_DIR_FAILED
  
  
  ld hl, STR_OPEN_OK
  call print_status_message
  
  ld hl, STR_LOAD_IN
  call print_status_message

  call LOAD_ENTRIES
  jp nz, LOAD_ENTRIES_FAILED
  
  ld hl, STR_LOAD_OK
  call print_status_message

  call CLOSE_DIR
  
  xor a
  ld (PATH_PRINTED), a
  
  call PRINT_CUR_DIR_IN_BOX
  
  call DISPLAY_BOX
  
.keyb_scan_loop
  call READ_KEYBOARD
  call HANDLE_KEY_PRESS
  jr .keyb_scan_loop
  
MOUNT
  ld A, CMD_MOUNT_SD
  out (CTRL_PORT), A
  jp WAIT_PROCESSED
  
MOUNT_FAILED
  ld hl, STR_MOUNT_NOK
  call print_status_message
  ld hl, $f840
  call SYS_UPDATE_PRINT_ADDR
  ret
  
OPEN_DIR
  ld a, CMD_OPEN_DIR
  out (CTRL_PORT), A
  jp WAIT_PROCESSED

OPEN_DIR_FAILED
  ld hl, STR_OPEN_NOK
  call print_status_message
  call wait_some
  ld hl, SCREEN_ADDR_START
  call SYS_UPDATE_PRINT_ADDR
  ret

LOAD_ENTRIES
  ld hl, 0
  ld (NUM_OF_ENTRIES), hl
  ld hl, DIRECTORY_ENTRIES
  ld a, (DIR_LEVEL)
  or a
  call nz, ADD_PARENT_DIR	; call when DIR_LEVEL != 1, in case of root dir, don't add sub-dir
.store_one_entry
  ld a, CMD_NEXT_DIRENTRY
  out (CTRL_PORT), A
  call WAIT_PROCESSED
  ret nz
  ld a, ($DF05)
  or a
  jr z, .end_of_directory
  ld a, ($DF00)	; check type
  and $06 ; SYSTEM or HIDDEN
  jr nz, .store_one_entry	; skip hidden or system files
  push hl
  ex de, hl
  ld hl, $df00
  ld bc, 3
  ldir
  inc hl
  inc hl
  ld b, 13
.copy_file_name
  ld a, (hl)
  ldi
  or a
  jr z, .copy_done
  djnz .copy_file_name
.copy_done
  ld hl, (NUM_OF_ENTRIES)
  inc hl
  ld (NUM_OF_ENTRIES), hl
  pop hl
  ld de, 16
  add hl, de
  jr .store_one_entry
.end_of_directory
  xor a
  ret
  
ADD_PARENT_DIR
  push hl
  ld a, $10 ; dir type
  ld (hl), a
  ld de, 3
  add hl, de
  ld a, '.'
  ld (hl), a
  inc hl
  ld (hl),a
  inc hl
  xor a
  ld (hl), a
  ld hl, NUM_OF_ENTRIES
  inc (hl)	; first item, incrementing from 0, to 1, safe to increment low byte
  pop hl
  ld de, 16
  add hl, de
  ret

LOAD_ENTRIES_FAILED
  ld hl, STR_LOAD_NOK
  call print_status_message
  ld hl, 0
  add hl, sp
  call OWN_PRINT_DEC
  call wait_some
  
  call CLOSE_DIR
  call WAIT_PROCESSED
  
  ld hl, SCREEN_ADDR_START
  call SYS_UPDATE_PRINT_ADDR
  ret

CLOSE_DIR
  ld a, $03
  out (CTRL_PORT), A
  jp WAIT_PROCESSED

READ_KEYBOARD
  call SCAN_KEYBOARD
  xor a
  cp c
  jr z, .no_key_pressed
  ld a, (LAST_KEY)
  cp c
  jr nz, .new_key_pressed
  ld a, (KEY_WAIT_COUNTER)
  dec a
  ld (KEY_WAIT_COUNTER), a
  or a
  jr nz, .not_yet
  ld a, KEY_COUNT_NEXT
  ld (KEY_WAIT_COUNTER), a
  ret
.not_yet
  ld c, 0
  ret
.new_key_pressed
  ld a, KEY_COUNT_FIRST
  ld (KEY_WAIT_COUNTER), a
  ld a, c
.no_key_pressed
  ld (LAST_KEY), a
  ret

; E800  D0: down, D1: up, D2: right, D3: left
; E801  D0: SPACE, D1: CR
; E802  D1: SH1, D2: SH2
; E803  D2: F1

SCAN_KEYBOARD
  call SYS_WAIT_FOR_SYNC
  ld a, ($E800)
  ld c, KEY_DOWN
  bit 0, a
  ret z
  ld c, KEY_UP
  bit 1, a
  ret z
  ld c, KEY_RIGHT
  bit 2,a
  ret z
  ld c, KEY_LEFT
  bit 3, a
  ret z
  ld c, KEY_RET
  ld a, ($E801)
  bit 1, a
  ret z
  ld a, ($E803)
  ld c, KEY_F1
  bit 2, a
  ret z
  ld c, 0
  ret
  
HANDLE_KEY_PRESS
  xor a
  cp c
  ret z
  ld a,c
  cp KEY_UP
  jp z, PROCESS_KEY_UP
  cp KEY_DOWN
  jp z, PROCESS_KEY_DOWN
  cp KEY_LEFT
  jp z, PROCESS_KEY_LEFT
  cp KEY_RIGHT
  jp z, PROCESS_KEY_RIGHT
  cp KEY_F1
  jr nz, .no_f1_pressed
  ld hl, $F840
  call SYS_UPDATE_PRINT_ADDR
  pop hl ; drop return value from stack
  ret	; return to BASIC
.no_f1_pressed
  cp KEY_RET
  ret nz
  jp PROCESS_KEY_RET
  
PROCESS_KEY_UP:
  call PRINT_CUR_DIR_IN_BOX
  ld a,(SELECTED_LINE)
  or a
  jr z, .on_top_of_box
  add 5
  ld b, a
  ld c, 0
  call SET_POS
  ld a, CHR_GT
  ld hl, (SYSVAR_PRINT_ADDR)
  ld (hl),a
  ld de, 64
  add hl, de
  ld a, CHR_VER_MID
  ld (hl),a
  ld a,(SELECTED_LINE)
  add 5
  ld b, a
  ld c, 22
  call SET_POS
  ld a, CHR_LT
  ld hl, (SYSVAR_PRINT_ADDR)
  ld (hl),a
  ld de, 64
  add hl, de
  ld a, CHR_VER_MID
  ld (hl), a
  ld hl, SELECTED_LINE
  dec (hl)
  ret
.on_top_of_box
  ld hl,(WINDOW_POS)
  ld a,l
  or h
  ret z ; we are at the top of the window (pos: 0)
  call SYS_WAIT_FOR_SYNC
  dec hl
  ld (WINDOW_POS), hl
  
  ld b, 6
  ld c, 0
  call SET_POS
  ld a, CHR_VER_MID
  ld hl, (SYSVAR_PRINT_ADDR)
  ld (hl), a
  ld de, 22
  ld a, (SYSVAR_SCREEN_WIDTH)
  cp 2
  jr nz, .skip_32_chars
  ld e, 44
.skip_32_chars
  add hl, de
  ld a, CHR_VER_MID
  ld (hl), a
  ld hl, SCREEN_ADDR_START
  ld de, (6 + WINDOW_HEIGHT - 2)*64 + 63
  add hl, de
  push hl
  ld de, 64
  add hl, de
  ex de, hl
  pop hl
  ld bc, (WINDOW_HEIGHT - 1)*64
  call SYS_WAIT_FOR_SYNC
  lddr
  ld b,0
  ld c,1
  call PRINT_ENTRIES
  ret
  
PROCESS_KEY_DOWN:
  call PRINT_CUR_DIR_IN_BOX
  ld hl,(WINDOW_POS)
  ld a,(SELECTED_LINE)
  ld e,a
  ld d,0
  add hl,de
  inc hl
  ex de, hl
  ld hl, (NUM_OF_ENTRIES)
  xor a
  sbc hl,de
  ret c
  ld a,h
  or l
  ret z
  ld a,(SELECTED_LINE)
  cp (WINDOW_HEIGHT - 1)
  jr z,.on_botton_of_box
  ld a,(SELECTED_LINE)
  ld (CURR_LINE), a
  add 6
  ld b, a
  ld c, 0
  call SET_POS
  ld hl, (SYSVAR_PRINT_ADDR)
  ld a, CHR_VER_MID
  ld (hl),a
  ld de, 64
  add hl, de
  ld a, CHR_GT
  ld (hl), a
  ld a, (CURR_LINE)
  add 6
  ld b, a
  ld c, 22
  call SET_POS
  ld hl, (SYSVAR_PRINT_ADDR)
  ld a, CHR_VER_MID
  ld (hl),a
  ld de, 64
  add hl, de
  ld a, CHR_LT
  ld (hl), a
  ld hl, SELECTED_LINE
  inc (hl)
  ret
.on_botton_of_box:
  call SYS_WAIT_FOR_SYNC
  ld hl, WINDOW_POS
  inc (hl)
  
  ld hl, SCREEN_ADDR_START
  ld de, (5 + WINDOW_HEIGHT)*64
  add hl, de
  ld a, CHR_VER_MID
  ld (hl), a
  ld de, 22
  add hl, de
  ld a, (SYSVAR_SCREEN_WIDTH)
  cp 2
  jr nz, .skip_32_chars
  add hl, de
.skip_32_chars
  ld a, CHR_VER_MID
  ld (hl), a
; moving the screen 
  ld hl, SCREEN_ADDR_START
  ld de, 6*63
  add hl, de
  push hl
  ld de, 64
  add hl, de
  pop de
  ld bc, (WINDOW_HEIGHT - 1) * 64
  ldir
  
  ld b,(WINDOW_HEIGHT - 1)
  ld c,1
  call PRINT_ENTRIES
  ret
  
PROCESS_KEY_LEFT:
  call PRINT_CUR_DIR_IN_BOX
  ld hl, (WINDOW_POS)
  ld de, WINDOW_HEIGHT
  xor a
  sbc hl, de
  jr c, .less_than_a_page
.print_full_screen
  call SYS_WAIT_FOR_SYNC
  ld (WINDOW_POS), hl
  ld b, 0
  ld c, WINDOW_HEIGHT
  call PRINT_ENTRIES
  ret
.less_than_a_page
  ld hl, (WINDOW_POS)
  ld a,l
  or h
  jr z, .page_up_on_first_page
  ld hl, 0
  jr .print_full_screen
.page_up_on_first_page:
  ld a, (SELECTED_LINE)
  ld (CURR_LINE), a
  add 6
  ld b, a
  ld c, 0
  call SET_POS
  ld hl, (SYSVAR_PRINT_ADDR)
  ld a, CHR_VER_MID
  ld (hl), a
  ld de,22
  add hl,de
  ld a, (SYSVAR_SCREEN_WIDTH)
  cp 2
  jr nz, .skip_32_chars
  add hl, de
.skip_32_chars
  ld a, CHR_VER_MID
  ld (hl), a
  xor a
  ld (SELECTED_LINE), a
  ld b, 0
  ld c, 1
  call PRINT_ENTRIES
  ret

PROCESS_KEY_RIGHT:
  call PRINT_CUR_DIR_IN_BOX
  ld hl, WINDOW_HEIGHT
  ld de, (NUM_OF_ENTRIES)
  xor a
  sbc hl,de
  jr nc,.page_down_one_page_only
  ld hl, (WINDOW_POS)
  ld de, WINDOW_HEIGHT
  add hl, de
  ld de, (NUM_OF_ENTRIES)
  xor a
  sbc hl, de
  jr z, .page_down_this_is_the_last_page
  ld hl, (WINDOW_POS)
  ld de, WINDOW_HEIGHT + WINDOW_HEIGHT
  add  hl, de
  ld de, (NUM_OF_ENTRIES)
  xor a
  sbc hl, de
  jr nc, .page_down_is_almost_ok
  ld hl,(WINDOW_POS)
  ld de, WINDOW_HEIGHT
  add hl, de
  ld (WINDOW_POS), hl
  jr .full_box_vars_set
.page_down_one_page_only
  ld c, 0
  ld a, (SELECTED_LINE)
  add 6
  ld b,a
  call SET_POS
  ld hl, (SYSVAR_PRINT_ADDR)
  ld a, CHR_VER_MID
  ld (hl), a
  ld de, 22
  add hl, de
  ld a, (SYSVAR_SCREEN_WIDTH)
  cp 2
  jr nz, .skip_32_chars
  add hl, de
.skip_32_chars
  ld a, CHR_VER_MID
  ld (hl), a
  ld a,(NUM_OF_ENTRIES)
  dec a
  ld (SELECTED_LINE), a
  ld (CURR_LINE), a
  ld b, a
  ld c, 1
  call SYS_WAIT_FOR_SYNC
  call PRINT_ENTRIES
  ret
.page_down_this_is_the_last_page
  ld a,(SELECTED_LINE)
  ld b, a
  ld a, WINDOW_HEIGHT - 1
  ld (SELECTED_LINE), a
  ld c, 1
  call PRINT_ENTRIES
  ld a,(SELECTED_LINE)
  ld b,a
  ld c,1
  call PRINT_ENTRIES
  ret
.page_down_is_almost_ok
  ld hl, (NUM_OF_ENTRIES)
  ld de, WINDOW_HEIGHT
  xor a
  sbc hl, de
  ld (WINDOW_POS), hl
.full_box_vars_set
  ld b, 0
  ld c, WINDOW_HEIGHT
  call PRINT_ENTRIES
  ret

PROCESS_KEY_RET
  ld a, (SELECTED_LINE)
  ld hl, (WINDOW_POS)
  ld e, a
  ld d, 0
  add hl, de
  ld b, 4
.mul_16_loop
  sla l
  rl h
  djnz .mul_16_loop
  ld de, DIRECTORY_ENTRIES
  add hl, de
  ld a, (hl)
  and $10
  jp nz, .directory_selected 	; parent- or subdir
  push hl
  ld de, 3-1	; skip type+size (3 bytes) -1 becuse of inc HL below
  add hl, de
  ld b, 12		; 12 char long file name - starting at 4th character
  xor a
.search_str_end_loop
  inc hl
  cp (hl)
  jr z, .name_end_found
  djnz .search_str_end_loop
  inc hl		; couldn't find trailing 0, let's pretend we have one after the 12 chars long filename...
.name_end_found
  xor a
  ld de, 4		; we're at trailing 0
  sbc hl, de
  ld de, STR_HTP_EXTENSION
  ld b, 4
.check_extension_loop
  ld a, (de)
  cp (hl)
  jr nz, .extension_check_failed
  inc hl
  inc de
  djnz .check_extension_loop
  pop hl
  ld de, 3
  add hl, de
  ld de, $DF00
  ld bc, 12
  ldir
  xor a
  ld (de), a
  ld hl, (SYSVAR_MEM_TOP)
  push hl
  call LOAD_HTP_FILE
  pop hl
  ld (SYSVAR_MEM_TOP), hl
  jr nz, .load_failed
  pop hl ; drop return address from stack
  call SYS_PRG_LOAD_INIT
  ld hl, $F800
  call SYS_UPDATE_PRINT_ADDR
  ld hl, STRHL_LOADED
  ld c, $0d
  call SYS_PRINT_STRING	; call for 'normal' printout because of weird autostarts that sits on CHR_OUT/IN vectors
  ld a,1
  ld (SYSVAR_AUTOSTART), a
  xor a
  jp SYS_AUTOSTART_ENTRY
;  jp $0079
;  ret	; return to BASIC
.load_failed
  ret
  
.extension_check_failed
  pop hl
  ld hl, STR_ERR_EXT_ERROR
  call print_status_message
  ret
  
.directory_selected
  ld de, 3
  add hl, de
  push hl
  ld de, STR_PARENT_DIR
  ld b, 3
.parent_dir_check_loop
  ld a,(de)
  cp (hl)
  inc hl
  inc de
  jr nz, .going_down
  djnz .parent_dir_check_loop
  ;; going_up
  ld hl, DIR_LEVEL
  xor a
  cp (hl)
  jr z, .skip_inc ; already on root level - shall not happen!
  dec (hl)
  jr .skip_inc
.going_down
  ld hl, DIR_LEVEL
  inc (hl)
  
.skip_inc
  pop hl
  ld de, $DF00
  ld bc, 13
  ldir

  call OPEN_DIR
  jr z, .open_dir_ok
  ld hl, $f800
  ld (SYSVAR_PRINT_ADDR), hl
  call print_fast_hex_byte
  ld a,':'
  call print_fast_char
  ld hl, $df00
  call print_fast_str
  ld a,':'
  call print_fast_char
  pop hl	; exiting, removing callee address
  jp OPEN_DIR_FAILED

.open_dir_ok
  call LOAD_ENTRIES
  jr z, .load_entries_ok
  pop hl  ; exiting, removing callee address
  jp LOAD_ENTRIES_FAILED
  
.load_entries_ok
  ld hl, STR_LOAD_OK
  call print_status_message

  call CLOSE_DIR
  
  call CLEAR_SELECTION
  
  ld hl, 0
  ld (WINDOW_POS), hl
  xor a
  ld (SELECTED_LINE), a
  ld (CURR_LINE), a
  
  call DISPLAY_BOX
  
  xor a
  ld (PATH_PRINTED), a
  call PRINT_CUR_DIR_IN_BOX

  ret

VAR_BYTES_LEFT  equ 0
VAR_DESTINATION equ 2
VAR_BLOCK_IDX   equ 4
VAR_CHECKSUM    equ 6
VAR_LOGTARGET   equ 8

LOAD_HTP_FILE_API
  ld de, $DF00
.copy_filename_loop
  ld a, (hl)
  ld (de), a
  inc hl
  inc de
  or a
  jr nz, .copy_filename_loop
  ld a, $02
  jr LOAD_HTP_FILE + 1

LOAD_HTP_FILE
  xor a
  push af		; log target: 0: menu (positioned own print routine), 1: console (CLI - OS print routine), 2: none (API)
  ld a, $04	; open file
.load_next_block
  out (CTRL_PORT), a
  call WAIT_PROCESSED
  jr z, .open_ok
  cp $B0
  jp z, .leading_0_error
  cp $B1
  jp z, .internal_out_of_mem
  cp $B2
  jp z, .file_error
  cp $B3
  jp z, .checksum_mismatch
  ld ($DF00), a
  jp .not_found

.open_ok  
  ld hl, $DF06
  ld d, (hl)
  ld e, 0
  push de		; loaded CRC in reg D, calculated CRC in E (initially it is 0)
  
  ld hl, $DF04
  ld e, (hl)
  inc hl
  ld d, (hl)
  push de		; actual block (E), max block (D), last block if E==D
  
  ld hl, $DF00	; Destination to load
  ld e, (hl)
  inc hl
  ld d, (hl)
  push de		; destination to load
  inc hl		; DF002 - size of payload
  ld e, (hl)
  inc hl
  ld d, (hl)
  push de		; remaining size of block
  
.load_one_round
  ld a, $05		; Transfer min 1, max 256 bytes of payload to $DF00-$DFFF
  out (CTRL_PORT), a
  call WAIT_PROCESSED
  jp nz, .load_failed
  ld hl, VAR_BYTES_LEFT
  add hl, sp
  ld c, (hl)
  inc hl
  ld b, (hl)
  ld hl, 256
  xor a
  sbc hl, bc
  jr nc,.copy_last_round	; <= 256 bytes in payload
  ld hl, VAR_CHECKSUM
  add hl, sp
  ld a, (hl)				; so far calculated checkSum in A
  ld hl, VAR_DESTINATION
  add hl, sp
  ld e, (hl)
  inc hl
  ld d, (hl)				; destination pointer in DE
  ld bc, $0100
  ld hl, $df00
.copy_loop_long
  add a, (hl)				; 7 - checkSum
  ldi		    			; 16 - transfer, adjust HL, DE, BC
  jp pe, .copy_loop_long 	; 10
  ld hl, VAR_CHECKSUM
  add hl, sp
  ld (hl), a				; store checkSum
  ld hl, VAR_DESTINATION
  add hl, sp
  ld (hl), e				; store destination pointer
  inc hl
  ld (hl), d
  ld hl, VAR_BYTES_LEFT		; decrement remaining size of payload
  add hl, sp
  ld a, (hl)
  inc hl
  ld d, (hl)
  dec d
  ld (hl), d				; decreased size of payload by 256 bytes (hi byte - 1)
  or d						; remaining size of payload is 0?
  jr z, .no_more_bytes_left	; the payload % 256 is 0, no more bytes in block
  jr .load_one_round
.copy_last_round			; BC already contains the remaining size of payload
  ld hl, VAR_CHECKSUM
  add hl, sp
  ld a, (hl)
  ld hl, VAR_DESTINATION
  add hl, sp
  ld e, (hl)
  inc hl
  ld d, (hl)
  ld hl, $df00
.copy_loop_short
  add a, (hl)
  ldi
  jp pe, .copy_loop_short
  ld hl, VAR_CHECKSUM
  add hl, sp
  ld (hl), a
.no_more_bytes_left
  ld hl, VAR_CHECKSUM	; in case the execution arrives from .copy_loop_long...
  add hl, sp
  ld a, (hl)	; calculated checkSum in A
  inc hl
  ld d, (hl)	; loaded checkSum in D
  cp d
  jr nz, .checksum_failed
  ld hl, VAR_BLOCK_IDX
  add hl, sp
  ld a, (hl)
  inc hl
  cp (hl)	; comparing the current and the last block index
  pop hl
  pop hl
  pop hl
  pop hl
  ld a, $05 ; in case not the last block, A must be $05 - transfer next 256 bytes to HL.
  jp nz, .load_next_block
.file_load_finished_free_stack
.file_load_finished_stack_done
;  ld hl, STR_FILE_LOADED
;  call print_status_message
  ld a, $06			; close file
  out (CTRL_PORT), a
  call WAIT_PROCESSED
;  ld hl, STR_FILE_CLOSED
;  call print_status_message
  pop af ; log target flag
  xor a ; set flag Z
  ret
.load_failed
  ld hl, VAR_LOGTARGET+1
  add hl, sp
  ld a, (hl)
  or a
  jr z, .log_failed_to_menu
  cp $01
  jr nz, .error_exit_with_close
  ld hl, STR_ERR_LOAD_ERROR
  call SYS_PRINT_STRING
  jr .error_exit_with_close
.log_failed_to_menu
  ld hl, STR_ERR_LOAD_ERROR
  call print_status_message
.error_exit_with_close
  pop hl		; free variables
  pop hl
  pop hl
  pop hl
  ld a, $06			; close file
  out (CTRL_PORT), a
  call WAIT_PROCESSED
.error_exit
  pop af	 ; free log target flag
  xor a
  inc a
  ret
  
.not_found
.internal_out_of_mem
  ld de, STR_ERR_NOT_FOUND
  jr .print_error_message
.leading_0_error
  ld de, STR_ERR_INV_LEAD_0
  jr .print_error_message
.file_error
  ld de, STR_ERR_INV_HTP
  jr .print_error_message
.checksum_mismatch
  ld de, STR_ERR_CHECKSUM_ON_LOAD
  jr .print_error_message

.print_error_message
  ld hl, 1
  add hl, sp
  ld a, (hl)
  or a
  jr z, .log_nf_to_menu
  cp $01
  jr nz, .error_exit
  ex de, hl
  ld c, 13
  call SYS_PRINT_STRING
  jr .error_exit
.log_nf_to_menu
  ex de, hl
  call print_status_message
  jr .error_exit

.checksum_failed
  ld b, a
  ld hl, VAR_LOGTARGET+1
  add hl, sp
  ld a, (hl)
  or a
  ld a, b
  jr z, .log_cf_to_menu
  cp $01
  jr nz, .error_exit_with_close
  ld e, a
  push de
  ld hl, STR_ERR_CHECKSUM
  call SYS_PRINT_STRING
  pop de
  push de
  ld a, d
  call SYS_PRINT_HEX_BYTE
  ld a, '-'
  RST $28
  pop de
  ld a, e
  call SYS_PRINT_HEX_BYTE
  ld a, ')'
  rst $28
  jr .error_exit_with_close
.log_cf_to_menu
  ld e, a
  push de
  ld hl, STR_ERR_CHECKSUM
  call print_status_message
  pop de
  push de
  ld a, d
  call print_fast_hex_byte
  ld a, '-'
  call print_fast_char
  pop de
  ld a, e
  call print_fast_hex_byte
  ld a, ')'
  call print_fast_char
  jp .error_exit_with_close

wait_some
  push af
  push bc
  push hl
  ld b, $18
  ld hl, 0
.loop
  nop
  dec hl
  ld a,h
  or l
  jr nz,.loop 
  djnz .loop
  pop hl
  pop bc
  pop af
  ret

print_str
  ld a, (hl)
  or a
  ret z
  push hl
  rst $28
  pop hl
  inc hl
  jr print_str
  ret


print_fast_char
  push hl
  ld hl, (SYSVAR_PRINT_ADDR)
  ld (hl), a
  inc hl
  ld a, (SYSVAR_SCREEN_WIDTH)
  cp 2
  jr nz, .skip_inc_charpos
  inc hl
.skip_inc_charpos
  ld (SYSVAR_PRINT_ADDR), hl
  pop hl
  ret
  
print_fast_hex_byte:
  push af
  rra
  rra
  rra
  rra
  and $0f
  call .print_fast_hex_nibble
  pop af
  and $0f
.print_fast_hex_nibble
  cp $0A
  jr nc, .gte10
  add a, '0'
  jr .print_nibble
.gte10
  add a, 'A'
  sub $0A
.print_nibble
  jr print_fast_char

print_status_message
  xor a
  ld (PATH_PRINTED), a
  ld bc, $1b01
  call SET_POS
  jp print_fast_str
  
PRINT_CUR_DIR_IN_BOX
  ld a, (PATH_PRINTED)
  or a
  ret nz
  ld bc, $1b01
  call SET_POS
  ld a, CMD_GET_CURR_PATH
  out (CTRL_PORT), A
  call WAIT_PROCESSED
  ret nz
  ld b, 21
  ld hl, $DF00
.print_path_loop
  ld a, (hl)
  or a
  jr z, .end_of_path
  call print_fast_char
  inc hl
  djnz .print_path_loop
  jr .exit_from_print_path
.end_of_path
  ld a, $20
  call print_fast_char
  djnz .end_of_path
.exit_from_print_path
  ld a, 1
  ld (PATH_PRINTED), a
  ret
  
  

INCLUDE "menu.asm"

CMD_PARAM_SAVE_START_ADDR equ $DFF1
CMD_PARAM_SAVE_END_ADDR equ $DFF3
CMD_PARAM_CMD_ID equ $DFF0
ID_PAGE0 equ 0
ID_PAGE1 equ 1
ID_PAGE2 equ 2

CLI_CMD_SAVE_ID 	equ 0
CLI_CMD_LOAD_ID 	equ 1
CLI_CMD_MOUNT_ID 	equ 2
CLI_CMD_DIR_ID 		equ 3
CLI_CMD_PWD_ID 		equ 4
CLI_CMD_CD_ID 		equ 5
CLI_CMD_DEL_ID 		equ 6
CLI_CMD_HELP_ID 	equ 7
CLI_CMD_BASICDEMO_ID equ 8
CLI_CMD_RENAME		equ 9

CMD_JUMP_LIST
  dw COMMAND_HANDLER.save_from_basic ; dummy address	- 0
  db ID_PAGE0, 0
  dw LOAD_HANDLER	; 1
  db ID_PAGE0, 0
  dw PAGE1_MOUNT	; 2
  db ID_PAGE1, 0
  dw PAGE1_DIRECTORY_LIST ; 3
  db ID_PAGE1, 0
  dw PAGE1_GET_DIR	; 4
  db ID_PAGE1, 0
  dw PAGE1_CHANGE_DIR	; 5
  db ID_PAGE1, 0
  dw PAGE1_DELETE_FILE	; 6
  db ID_PAGE1, 0
  dw PAGE1_HELP	; 7
  db ID_PAGE1, 1	; no need SD card
  dw PAGE2_LOAD_BASIC_DEMO ; 8
  db ID_PAGE2, 1	; no need SD card
  dw PAGE1_RENAME_FILE
  db ID_PAGE1, 0

LOAD_HANDLER
  call COPY_PARAM_TO_CARTRAM
  
  ld hl, ($4018)
  push hl
  ld hl, $0000
  ld ($4018), hl
  
  ld hl, (SYSVAR_MEM_TOP)
  push hl
  
  ld a, $1 ; print to console
  call LOAD_HTP_FILE + 1
  
  pop hl
  ld (SYSVAR_MEM_TOP), hl
  
  pop de
  ld hl, ($4018)
  
  jr nz, .failed_to_load
  
  ld a, l
  or h
  jr z, .not_loaded_to_basic_area
  ld de, SYS_AUTOSTART_ENTRY
  ld hl, 2
  add hl, sp
  ld (hl), e
  inc hl
  ld (hl), d
  xor a	; set Z, load OK
  ret
.not_loaded_to_basic_area
  xor a	; set Z, load OK
.failed_to_load
  ex de, hl
  ld ($4018),hl
  ret

COMMAND_HANDLER
  call PARSE_AND_STORE_PARAMS
  jr nz, .fix_parameters
  ld a, (CMD_PARAM_CMD_ID)
  or a
  jr z, .save_from_basic
  sla a
  sla a
  ld e, a
  ld d, 0
  ld hl, CMD_JUMP_LIST
  add hl, de
  ld de, 3
  add hl, de
  ld a, (hl)
  or a
  jr nz, .mount_done
  ld a, CMD_CHECK_MOUNTED
  out (CTRL_PORT), a
  call WAIT_PROCESSED
  jr nz, .exit_mount_failed
  ld a, ($DF00)
  or a
  jr nz, .mount_done
  ld a, CMD_MOUNT_SD
  out (CTRL_PORT), a
  call WAIT_PROCESSED
  jr z, .mount_done
.exit_mount_failed
  ld hl, STRHL_ERR_MOUNT_FAILED
  ld c, 13
  call SYS_PRINT_STRING
  xor a
  inc a
  jr .fix_parameters
.mount_done
  xor a
  sbc hl, de
  ld e, (hl)
  inc hl
  ld d, (hl)
  inc hl
  ld a, (hl)
  ex de, hl
  ld de, .fix_parameters ; return address
  push de
  jp JUMP_PAGED_COMMAND

.save_from_basic
  ld hl, (CMD_PARAM_SAVE_START_ADDR)
  ex de, hl
  ld hl, (CMD_PARAM_SAVE_END_ADDR)
  push hl
  pop bc
  xor a
  sbc hl, de
  jp z, PARSE_AND_STORE_PARAMS.invalid_params
  ld hl, 2
  add hl, sp
  ld a, (hl)
  inc hl
  ld h, (hl)
  ld l, a			; call $D003,"S filename" ; HL points to filename
  ld a, 1 ; logs to console
  call SAVE_HTP_FILE_API + 1

.fix_parameters
  pop bc	; return address
  pop hl	; pointer of parameters
  ld d, $60	; in case of failed CMD parse, we drop the whole line
  jr nz, .end_of_line_loop
  ld d, ':'
.end_of_line_loop
  ld a, (hl)
  cp $60
  jr z, .end_of_line
  cp d
  jr z, .end_of_line
  inc hl
  jr .end_of_line_loop
.end_of_line
  push hl
  push bc
  xor a
  ret
  

;;  hl is the pointer of a zero (or " or $60) terminated string: filename
;;  de contains the start address of the save
;;  bc contains the end address of the save, exclusively
SAVE_HTP_PARAM_PRINT_LOG equ 6 ; (0->no, otherwise yes)
SAVE_HTP_PARAM_END_POS equ 4
SAVE_HTP_PARAM_CURR_POS equ 2
SAVE_HTP_PARAM_FNAME equ 0
SAVE_HTP_FILE_API
  xor a		; no log to console
  push af
  push bc	; end position
  push de   ; start position
  push hl   ; file name
  ld de, $DF00
  ld b, $08
  ld a, (hl)
  cp '+'
  jr nz, .copy_filename_loop
  inc b
.copy_filename_loop
  ld a, (hl)
  cp $60
  jr z, .filename_copied
  cp '"'
  jr z, .filename_copied
  or a
  jr z, .filename_copied
  cp ' '
  jr nz, .copy_char
  ld a, '_'
.copy_char
  ld (de), a
  inc hl
  inc de
  djnz .copy_filename_loop
.filename_copied
  ld hl, STR_HTP_EXTENSION
  ld bc, 5
  ldir
  ld a, CMD_OPEN_BIN_FILE_FOR_WRITE
  out (CTRL_PORT), a
  call WAIT_PROCESSED
  jp nz, .fopen_failed

; .htp file:
; 0-$ff: $00
; $0100 - $A5
; $0101 - fileName,$00, <loadAdd>, <blockSize>
; <block>
; <checkSum> - the low 8 bit of the sum of bytes in block
; $00
              
; 255 pcs of $00
  ld a, $ff
  ld hl, $DF00
  ld (hl), a
  inc a
  inc hl
  ld (hl), a
  ld de, $DF02
  ld bc, $00FE
  ldir
  ld a, CMD_WRITE_BIN_BLOCK
  OUT (CTRL_PORT), a
  call WAIT_PROCESSED
  jp nz, .write_failed
  
; 0x00
; 0xA5
  ld a, $A5
  ld ($DF02), a ; DF01 contains 0x00, the last one of the 256 zeroes, length is now 2
  
; fileName, and size of filewrite
  ld hl, SAVE_HTP_PARAM_FNAME
  add hl, sp
  ld a, (hl)
  inc hl
  ld h, (hl)
  ld l, a
  ld b, $20
  ld de, $DF03
  ld a, (hl)
  cp '+'
  jr nz, .plus_skipped
  inc hl
.plus_skipped
.bname_loop
  ld a, (hl)
  or a
  jr z, .end_of_block_name
  cp $60
  jr z, .end_of_block_name
  cp '"'
  jr z, .end_of_block_name
  ld (de), a
  inc hl
  inc de
  djnz .bname_loop
.end_of_block_name
  inc de	; skip one zero byte as termination
  ld a, 3 ; <startAdd 2bytes>, <blockSize 2bytes>, -1 because of blocklen byte at $df00
  add e	  ; E pointed to filenamestr termination 0x00
  ld ($DF00), a

; startAddress
  ld hl, SAVE_HTP_PARAM_CURR_POS
  add hl, sp
  ld c, (hl)
  inc hl
  ld b, (hl)
  push bc
  dec hl
  ldi
  ldi
; length
  ld a, (hl)
  inc hl
  ld h, (hl)
  ld l, a	; end address in HL
  pop bc	; start address in BC
  xor a
  sbc hl, bc ; length in HL
  ex de, hl  ; length in DE, buf pos in HL
  ld (hl), e
  inc hl
  ld (hl), d
  
; we're done with the header  
  ld a, CMD_WRITE_BIN_BLOCK
  OUT (CTRL_PORT), a
  call WAIT_PROCESSED
  jp nz, .write_failed
  
;
; header written
;
;
; Block writes from here
  ld de, $df01 ; copy here
  ld hl, SAVE_HTP_PARAM_CURR_POS
  add hl, sp
  ld a, (hl)
  inc hl
  ld h, (hl)
  ld l, a	; start address in HL
  ld c, 0	; checkSum
.data_write_loop
  ld a, (hl)
  ld (de), a
  add c
  ld c, a
  inc hl
  inc de
  xor a
  cp e	; is DE == E0000? 
  call z, .write_full_block ; if yes, let's write out the full block!
			; let's check if we're at the end of file data
  ex de, hl ; de contains the source of file data
  push hl   ; hl contains the target in file-write buffer (DF01-DFFF)
  ld hl, SAVE_HTP_PARAM_END_POS + 2	; because of the push one line above...
  add hl, sp
  ld a, (hl)
  inc hl
  ld h, (hl)
  ld l, a
  xor a
  sbc hl, de
  pop hl
  ex de, hl ; hl contains the source of file data, de contains the target in file-write buffer
  jr z, .write_fraction_block
  jr .data_write_loop
.write_full_block	; a is 0xff
  dec A
  ld ($df00), A
  ld a, CMD_WRITE_BIN_BLOCK
  OUT (CTRL_PORT), A
  CALL WAIT_PROCESSED
  jr nz, .write_failed
  ld DE, $DF01
  ret
.write_fraction_block
  ld A, E
  dec A
  jr z, .end_of_block_writes	; the end of file-data matched with end of file-block
  ld ($df00), a					; otherwise...
  ld a, CMD_WRITE_BIN_BLOCK
  OUT (CTRL_PORT), a
  CALL WAIT_PROCESSED
  jr nz, .write_failed

; Write out the trailing data: checksum and block closing 00
.end_of_block_writes
  ld a, 2
  ld ($DF00), a
  ld a, c		; checksum
  ld ($DF01), a
  xor a
  ld ($DF02), a
  ld a, CMD_WRITE_BIN_BLOCK
  OUT (CTRL_PORT), a
  CALL WAIT_PROCESSED
  jr nz, .write_failed
  
.close_file
  ld a, CMD_CLOSE_FILE
  OUT (CTRL_PORT), A
  CALL WAIT_PROCESSED
  ld hl, STRHL_SAVED
  ld c, $0d
  call SYS_PRINT_STRING
  xor a ; z flag is set
.fix_parameter	; in case of CALL the stack contains the param pointed, and the return value (not where it was called). 
  pop hl	; drop params (filename, start addr, end addr)
  pop hl
  pop hl
  pop hl
  ret
  
.fopen_failed
  ld hl, SAVE_HTP_PARAM_PRINT_LOG+1 ;
  add hl, sp
  ld a, (hl)
  or a
  jr z, .print_skipped_fopen_failed
  ld hl, STRHL_ERR_FILE_OPEN_FOR_WRITE
  ld c, $0D
  call SYS_PRINT_STRING
.print_skipped_fopen_failed
  xor a		; z flag is reset
  inc a
  jr .fix_parameter
  
.write_failed
  ld hl, SAVE_HTP_PARAM_PRINT_LOG+1
  add hl, sp
  ld a, (hl)
  or a
  jr z, .print_skipped_write_failed
  ld hl, STRHL_ERR_FILE_WRITE
  ld c, $0D
  call SYS_PRINT_STRING
.print_skipped_write_failed
  xor a		; z flag is reset
  inc a
  jr .fix_parameter
  

PARSE_AND_STORE_PARAMS
  ld hl, $4016	; default values for start and end address
  ld (CMD_PARAM_SAVE_START_ADDR), hl
  ld hl, ($4018)
  ld (CMD_PARAM_SAVE_END_ADDR), hl
  ld HL, $0004
  add hl, sp
  ld a, (HL)
  inc hl
  ld h, (hl)
  ld l, a
  ld a, (hl)
  cp $60
  jr z, .cmd_help
  cp ","
  jr nz, .no_command
  inc hl
  ld a, (hl)
  cp '"'
  jr z, .cmd_starts
.no_command
  ld hl, STRHL_ERR_MISSING_FILENAME
  ld c, $0D
  call SYS_PRINT_STRING
  xor a
  inc a
  ret
.cmd_mount
  ld a, CLI_CMD_MOUNT_ID
  ld (CMD_PARAM_CMD_ID), a
  xor a
  ret
.cmd_list_dir
  ld a, CLI_CMD_DIR_ID
  ld (CMD_PARAM_CMD_ID), a
  xor a
  ret
.cmd_get_dir
  ld a, CLI_CMD_PWD_ID
  ld (CMD_PARAM_CMD_ID), a
  xor a
  ret
.cmd_help
  ld a, CLI_CMD_HELP_ID
  ld (CMD_PARAM_CMD_ID), a
  xor a
  ret
.cmd_starts
  inc hl
  ld a, (hl)
  ld c, a
  cp "$"
  jr z, .cmd_list_dir
  cp "H"
  jr z, .cmd_help
  cp "M"	; mount
  jr z, .cmd_mount
  cp "I"	; mount
  jr z, .cmd_mount
  cp "P"	; pwd
  jr z, .cmd_get_dir
  inc hl
  ld a, (hl)
  cp $20
  jr nz,.invalid_command
  
  ld b, 6
  ex de, hl
  ld hl, .CLI_CMD_MAPS
.cli_find_cmd_loop
  ld a, c
  cp (hl)
  inc hl
  ld a, (hl)
  inc hl
  jr z, .cli_cmd_found
  djnz .cli_find_cmd_loop
 
.invalid_command
  ld hl, STRHL_INVALID_CMD
  ld c, $0D
  call SYS_PRINT_STRING
  xor a
  inc a	; nz
  ret
.CLI_CMD_MAPS
  db 'S', CLI_CMD_SAVE_ID, 'C', CLI_CMD_CD_ID, 'D', CLI_CMD_DEL_ID, 'L', CLI_CMD_LOAD_ID, 'B', CLI_CMD_BASICDEMO_ID, 'R', CLI_CMD_RENAME
.cmd_save_file
.cmd_change_dir
.cmd_delete
.cmd_load
.cmd_basic_demo
.cli_cmd_found
;  ex de, hl
;  inc hl; HL points right after the command, the filename
;  ex de, hl	; DE points
  ld (CMD_PARAM_CMD_ID), a
.skip_spaces
  inc de	; DE points to the filename
  ld a, (de)
  cp $20
  jr z, .skip_spaces
  
  ld HL, $0004
  add HL, SP
  ld (hl), e
  inc hl
  ld (hl), d	; let's store as if the basic str parameter would start with the filename
  ex de, hl

.fake_filename_copy_loop
  ld a, (hl)
  cp $60
  jp z, .end_of_params
  cp '"'
  jr z, .end_of_filename
  inc hl
  jr .fake_filename_copy_loop
.end_of_filename
  inc hl
  ld a, (hl)
  cp $60
  jp z, .end_of_params
  ld a, (CMD_PARAM_CMD_ID)
  cp CLI_CMD_SAVE_ID
  jr nz, .invalid_params
  ld a, (hl)
  cp ','
  jr nz, .invalid_params
  inc hl
  ld a,(hl)
  cp $e2 ; hex num is coming
  jr nz, .start_addr_is_dec
  inc hl
  call .parse_hex
  jr nz, .invalid_params
  jr .start_addr_ok
.invalid_params
  ld hl, STRHL_ERR_IN_PARAMS
  ld c, $0D
  call SYS_PRINT_STRING
  xor a
  inc a	; nz
  ret
.start_addr_is_dec
  call .parse_dec
  jr nz, .invalid_params
.start_addr_ok
  ex de, hl
  ld (CMD_PARAM_SAVE_START_ADDR), hl
  ex de, hl
  ld a, (hl)
  cp $60
  ret z
  cp ','
  jr nz, .invalid_params
  inc hl
  ld a, (hl)
  cp $e2
  jr nz, .length_is_dec
  inc hl
  call .parse_hex
  jr nz, .invalid_params
  jr .params_parsed
.length_is_dec
  call .parse_dec
  jr nz, .invalid_params
.params_parsed
  ex de, hl
  ld (CMD_PARAM_SAVE_END_ADDR), hl
  ex de, hl
  xor a
  ret
  
.parse_hex
  ld de, $0000
  ld b, 4
.parse_hex_loop
  ld a, (hl)
  cp $60
  ret z
  cp ','
  ret z
  cp '0'
  ret c ; z flag will not be high - error
  cp '9'+1
  jr nc, .hex_alphanum
  sub '0'
  jr .add_to_retval
.hex_alphanum
  cp 'A'
  ret c ; z flag will not high
  cp 'F'+1
  jr nc, .invalid_params
  sub 'A'
  add 10
.add_to_retval
  sla e
  rl d
  sla e
  rl d
  sla e
  rl d
  sla e
  rl d
  add a, e
  ld e, a
  inc hl
  djnz .parse_hex_loop
  xor a
  ret
  
.parse_dec
  ld de, $0000
  ld b, 5
.parse_dec_loop
  ld a, (hl)
  cp $60
  ret z
  cp ','
  ret z
  cp '0'
  ret c
  cp '9' + 1
  ret nc
  call .multiply_de_by10
  sub '0'
  add a, e
  ld e, a
  ld a, $00
  adc d
  ld d, a
  ret c
  inc hl
  djnz .parse_dec_loop
  xor a
  ret 

.multiply_de_by10
  push hl
  push de
  sla e
  rl d
  sla e
  rl d
  sla e
  rl d
  ex de, hl
  pop de
  add hl, de
  add hl, de
  ex de, hl
  pop hl
  ret 

.end_of_params
  xor a
  ret


; á - 127  
; é - 123
; í - 168	; >128
; ó - 126
; ö - 124
; ő - 188	; >128
; ú - 181	; >128
; ü - 125
; ű - 182	; >128


;STR_INIT_FAILED:
;  db "Init failed..", 0x00
;STR_INIT_OK:
;  db "Init OK!", 0x00
;STR_SEARCHING:
;  db "Searching for ", 0x00
;STR_LOAD_NOT_FOUND:
;  db "not found\n", 0x00
;STR_LOAD_ERROR:
;  db "Load error!\n", 0x00
; STR_LOAD_INV_HDR
;   db " invalid block header\n", 0x00
;STR_LOADING:
;  db "Loading block: ",0x00
;STR_DOTDOTDOT:
;  db " ...  ",0x00
;STR_DONE:
;  db "done",0x00
;STR_FILE_LOADED:
;  db "File bet", 124, "ltve.", 0
;STR_FILE_CLOSED:
;  db "Lez", 127, "rva, indulhat", 0

STR_MOUNT_IN
  db "Becsatol",127,"s ...", 0
STR_MOUNT_OK
  db "Becsatol",127,"s OK ", 0
STR_MOUNT_NOK
  db "Becsatol",127,"s NOK", 0

STR_OPEN_IN
  db "Megnyit", 127, "s ...", 0
STR_OPEN_OK
  db "Megnyit", 127, "s  OK", 0
STR_OPEN_NOK
  db "Megnyit", 127, "s NOK", 0
STR_LOAD_IN
  db "Lista bet", 124, "lt", 123, "se...  ", 0
STR_LOAD_OK
  db "Lista bet", 124, "lt", 123, "se OK  ", 0
STR_LOAD_NOK
  db "Lista bet", 124, "lt", 123, "se NOK ", 0
STR_ERR_EXT_ERROR
  db "Kiterjeszt", 123, "si hiba", 0
STR_ERR_NOT_FOUND
  db "F", 127, "jl nem tal", 127, "lhat", 126, 0, 128
STR_ERR_INV_LEAD_0
  db "HTP fejl", 123, "c hiba: leading zeroes", 0, 128
STR_ERR_LOAD_ERROR
  db "HTP f", 127, "jl bet", 124, "lt", 123, "si hiba" , 0, 128
STR_ERR_INV_HTP
  db "HTP f", 127, "jl struktur", 127, "lis hiba!", 0, 128
STR_ERR_CHECKSUM_ON_LOAD
  db "Hib", 127, "s checksum!", 0, 128
STR_ERR_CHECKSUM
  db "Chksum hiba (", 0, 128
STR_PARENT_DIR
  db "..", 0
STR_HTP_EXTENSION
  db ".HTP", 0
  
;STRHL_OK
;  db $0C, "O", ('k' + 128)
STRHL_LOADED
  db $0C, "Program bet", 124, "ltve", ("!" + 128)
STRHL_ERR_MISSING_FILENAME
  db "Nincs, vagy hib", 127,"s filen", 123, "v", ('!' + 128)
STRHL_ERR_FILE_OPEN_FOR_WRITE
  db "A file-t nem lehet ir", 127, "sra megnyitni. Lehet, hogy m", 127, "r l", 123, "tezik", ('?' + 128)
STRHL_ERR_FILE_WRITE
  db "Hiba file ir", 127, "s k", 124, "zben", ('!' + 128)
STRHL_SAVED
  db "File sikeresen mentve", ('!' + 128)
STRHL_ERR_IN_PARAMS
  db "Hib", 127, "s param", 123, "ter", ('!' + 128)
STRHL_INVALID_CMD
  db "Hib", 127, "s parancs", ('!' + 128)

  
END_POS_MARKER_PAGE0
  ds $DF00 - END_POS_MARKER_PAGE0

  PAGE 1
  code @ $d100
  
INTEXAMPLE:
  di
  xor a
  ld ($DFF0), a
  ld l, low IRQ_VECT
  ld h, high IRQ_VECT
  ld (SYSVAR_IRQ_VECT), hl
  ld hl, 250		; 25ms
  ld ($DF00), hl
  call SYS_WAIT_FOR_SYNC
  ld a, $09
  out (CTRL_PORT), a
  call WAIT_PROCESSED
  ret nz
  ei
  ret

IRQ_VECT:
  call .irq_workload
  pop hl
  ld ($D000), a
  ei
  ret
  
.irq_workload2
  ld hl, $f800
  inc (hl)
  ret

.irq_workload
  push af
  push de

  ld a, ($DFF0)
  ld hl, STR_IRQ_EXAMPLE
  ld e, a
  ld d, 0
  add hl, de
  ld a,(hl)
  or a
  jr z, .end_of_string
  ld hl, $F800
  add hl, de
  ld a, (hl)
  cp $20
  jr z, .print_character
  or a
  jr z, .print_character
  ld a,$20
  ld (hl), a
  jr .irq_done
.print_character
  push hl
  ld hl, STR_IRQ_EXAMPLE
  add hl, de
  pop de
  ld a,(hl)
  ld (de), a
.irq_done
  ld hl, $DFF0
  inc (hl)
.quit_workload
  pop de
  pop af
  ret
.end_of_string
  xor a
  ld ($DFF0), a
  jr .quit_workload

RAMTEST
  ld hl, 0
  ld ($5100), hl ; last err: cart ram
  ld ($5102), hl ; last err: sys ram
  ld ($5104), hl ; error counter
  ld hl, $DF00
  ld de, $6000
  ld bc, $0100
  ldir
.test_full_loop
  ld hl, 0
  ld ($5106), hl ; screen counter
.one_screen_loop
  ld de,$F800
  add hl, de
  ld a, '+'
  ld (hl), a
  call .test_256_bytes
  ld de, $f800
  ld hl, ($5106)
  jr nz, .mark_error
  ld a, '.'
  jr .screen_char_loaded
.mark_error
  ld bc, ($5104)
  inc bc
  ld ($5104), bc
  ld a, '*'
.screen_char_loaded
  add hl, de
  call SYS_WAIT_FOR_SYNC
  ld (hl), a
  ld hl, ($5106)
  inc hl
  ld ($5106), hl
  ld a, $08
  cp h
  jr nz, .one_screen_loop
  jp .test_full_loop

.test_256_bytes
  ld hl, $6000
  ld de, $df00
  ld b, 00
.test_loop
  ld a,(de)
  cp (hl)
  jr nz, .failed_compare
  ex de, hl
  ld a,(de)
  cp (hl)
  ex de, hl
  jr nz, .failed_compare
  inc hl
  inc de
  djnz .test_loop
  ret
.failed_compare
  ld ($5100), de
  ld ($5102), hl
  ret
  
PAGE1_DIRECTORY_LIST
  ld a, $0C
  rst $28
  ld c, $20
  call print_current_dir
  jp nz, SWITCH_BACK_TO_PAGE0
  
  ld hl, STRHL_DIR_CONTENT_TEXT
  call SYS_PRINT_STRING

  ld a, CMD_OPEN_DIR
  out (CTRL_PORT), A
  call WAIT_PROCESSED
  jr nz, .dopen_failed
  ld a, $0d
  rst $28
.print_dir_loop
  ld a, CMD_NEXT_DIRENTRY
  OUT (CTRL_PORT), A
  call WAIT_PROCESSED
  jr nz, .read_dir_failed
  
  ld hl, $DF05
  ld a, (hl)
  or a
  jr z, .end_of_directory
.loop_filename_print
  ld a, (hl)
  or a
  jr z, .name_done
  rst $28
  inc hl
  jr .loop_filename_print
.name_done
  ld a, $20
  RST $28
  ld a, (SYSVAR_BUFFER_POINTER)
  cp $70
  jr c, .name_done
  ld a, ($df00)
  and a,$10
  jr nz, .print_dir_str
  ld a, ($df03)
  ld hl, $df04
  or (hl)
  jr z, .print_file_size
  ld hl, STRHL_GT_64K
  ld c, $0D
  call SYS_PRINT_STRING
  jr .entry_printed
.print_file_size
  ld hl, $df01
  ld e, (hl)
  inc hl
  ld d, (hl)
  ex de, hl
  call PRINT_DEC_PAGE1
  ld a, $0D
  rst $28
  jr .entry_printed
.print_dir_str
  ld hl, STRHL_DIR
  ld c, $0D
  call SYS_PRINT_STRING
.entry_printed
  ld b, 25
.delay_print_dir_loop
  call SYS_WAIT_FOR_SYNC
  ld a, ($E803)
  bit 2, a
  jr nz, .keep_going
  bit 1, a
  jr z, .end_of_directory
  djnz .delay_print_dir_loop
.keep_going
  jr .print_dir_loop
.dopen_failed
  xor a
  inc a
  jp SWITCH_BACK_TO_PAGE0
.read_dir_failed
  ld a, CMD_CLOSE_DIR
  out (CTRL_PORT), A
  call WAIT_PROCESSED
  xor a
  inc a
  jp SWITCH_BACK_TO_PAGE0
.end_of_directory
  ld a, CMD_CLOSE_DIR
  out (CTRL_PORT), A
  call WAIT_PROCESSED
  xor a
  jp SWITCH_BACK_TO_PAGE0

PRINT_DEC_PAGE1:
  PUSH    hl 
  ld      a, ' '
  or      a	; clear C
  LD      bc,10000 
  SBC     HL,BC 
  POP     HL 
  JR      nc,PRINT_DEC_PAGE1.print_dec_5
  rst     $28 ; print space

  PUSH    hl 
  ld      a, ' '
  or      a
  LD      bc,1000 
  SBC     HL,BC 
  POP     HL 
  JR      nc,PRINT_DEC_PAGE1.print_dec_4 
  rst     $28 ; print space

  PUSH    hl 
  ld      a, ' '
  or      a
  LD      bc,100 
  SBC     HL,BC 
  POP     HL 
  JR      nc,.print_dec_3
  rst     $28

  PUSH    hl 
  ld      a, ' '
  or      a
  LD      bc,10 
  SBC     HL,BC 
  POP     HL 
  JR      nc,.print_dec_2
  rst     $28
  JR      .print_dec_1 

.print_dec_5:    
  LD      bc,$D8F0 ; -10000
  CALL    .num1
.print_dec_4:    
  LD      bc,$FC18 ; -1000
  CALL    .num1
.print_dec_3:    
  LD      bc,-100 
  CALL    .num1
.print_dec_2:    
  LD      bc,-10 
  CALL    .num1 
.print_dec_1:    
  LD      bc,-1 
.num1:                
  LD      a,'0' - 1
.num2:                
  INC     a 
  ADD     hl,bc 
  JR      c,.num2
  SBC     hl,bc 
  rst     $28
  RET
			
PAGE1_MOUNT
  ld A, CMD_MOUNT_SD
  out (CTRL_PORT), A
  call WAIT_PROCESSED
  jr z, .mount_ok
  ld hl, STRHL_ERR_MOUNT_FAILED
  ld c, $0D
  call SYS_PRINT_STRING
  xor a
  inc a
  jp SWITCH_BACK_TO_PAGE0
.mount_ok
  ld hl, STRHL_MOUNT_OK
  ld c, 13
  call SYS_PRINT_STRING
  xor a
  jp SWITCH_BACK_TO_PAGE0

print_current_dir:
  ld a, CMD_GET_CURR_PATH
  out (CTRL_PORT), A
  call WAIT_PROCESSED
  jr z, .print_path
  ld hl, STRHL_ERR_GET_CURR_PATH_FAILED
  call SYS_PRINT_STRING
  xor a
  inc a
  ret
.print_path
  ld hl, $DF00
  ld b, $ff
.print_path_loop
  ld a, (hl)
  or a
  jr z, .path_done
  rst $28
  inc hl
  djnz .print_path_loop
  xor a
  rst $28
.path_done
  xor a
  ret
  
PAGE1_GET_DIR
  ld hl, STRHL_CUR_DIR
  ld c, 0
  call SYS_PRINT_STRING
  ld c, 13
  call print_current_dir
  jp SWITCH_BACK_TO_PAGE0
  
PAGE1_CHANGE_DIR
  call COPY_PARAM_TO_CARTRAM
  ld hl, $df00
  ld a, (hl)
  cp '/'
  jr z, .syntax_check_passed
  cp '.'
  jr nz, .syntax_check_failed
  inc hl
  ld a, (hl)
  cp '.'
  jr nz, .syntax_check_failed
  inc hl
  ld a, (hl)
  or a
  jr z, .syntax_check_passed
.syntax_check_failed
  ld hl, STRHL_NO_RELATIVE_PATH_ALLOWED
  ld c, $0d
  call SYS_PRINT_STRING
  xor a
  inc a
  jp SWITCH_BACK_TO_PAGE0
.syntax_check_passed
  ld a, CMD_SET_CURR_PATH
  out (CTRL_PORT), A
  call WAIT_PROCESSED
  jr nz, .cd_failed
  ld hl, STRHL_CD_OK
  ld c, $0d
  call SYS_PRINT_STRING
  xor a
  jp SWITCH_BACK_TO_PAGE0
.cd_failed
  ld hl, STRHL_CD_NOK
  ld c, $0d
  call SYS_PRINT_STRING
  xor a
  inc a
  jp SWITCH_BACK_TO_PAGE0
  
PAGE1_DELETE_FILE
  call COPY_PARAM_TO_CARTRAM
  ld a, CMD_DELETE
  out (CTRL_PORT), a
  call WAIT_PROCESSED
  jr nz, .del_failed
  ld hl, STRHL_DEL_OK
  ld c, $0d
  call SYS_PRINT_STRING
  xor a
  jp SWITCH_BACK_TO_PAGE0
.del_failed
  ld hl, STRHL_DEL_NOK
  ld c, $0d
  call SYS_PRINT_STRING
  xor a
  inc a
  jp SWITCH_BACK_TO_PAGE0
  
PAGE1_RENAME_FILE
  call COPY_PARAM_TO_CARTRAM
  ld b, $FE
  ld hl, $DF00
.replace_space_loop
  ld a, (hl)
  or a
  jr z, .end_of_loop
  cp $20
  jr nz, .space_checked
  xor a
  ld (hl), a
.space_checked
  inc hl
  djnz .replace_space_loop
  xor a
  ld (hl), a

.end_of_loop
  ld a, CMD_RENAME
  out (CTRL_PORT), a
  call WAIT_PROCESSED
  jr nz, .ren_failed
  ld hl, STRHL_RENAME_OK
  ld c, $0d
  call SYS_PRINT_STRING
  xor a
  jp SWITCH_BACK_TO_PAGE0
.ren_failed
  ld hl, STRHL_RENAME_NOK
  ld c, $0d
  call SYS_PRINT_STRING
  xor a
  inc a
  jp SWITCH_BACK_TO_PAGE0
  
  
PAGE1_HELP
  ld hl, STR_HELP_TXT
  ld c, 13
  call PRINT_ZT_STRING
  xor a
  jp SWITCH_BACK_TO_PAGE0

PRINT_ZT_STRING
  ld a, (hl)
  or a 
  jr z, .done_str
  rst $28
  inc hl
  jr PRINT_ZT_STRING
.done_str
  ld a, c
  rst $28
  ret

STR_IRQ_EXAMPLE
  db "IRQ example on The Cart", 0

STRHL_DIR
  db "<DIR", (">"+128)
STRHL_MOUNT_OK
  db "SD k", 127, "rtya inicializ", 127, "lva", ("."+128)
STRHL_GT_64K
  db ">64k", ("B" + 128)
STRHL_CUR_DIR:
  db "Jelenlegi k", 124, "nyvt", 127, "r:", (" " + 128)
STRHL_ERR_GET_CURR_PATH_FAILED
  db 13, "K", 124, "nyvt", 127, "r lek", 123, "rdez", 123, "s hiba", ("!" + 128)
STRHL_CD_OK
  db "K", 124, "nyvt", 127, "r v", 127, "lt", 127, "s sikeres", ('.' + 128)
STRHL_CD_NOK
  db "Sikertelen k", 124, "nyvt", 127, "r v", 127, "lt", 127, "s", ('!' + 128)
STRHL_DEL_OK
  db "T", 124, "rl", 123, "s sikeres", ('.' + 128)
STRHL_DEL_NOK
  db "Sikertelen t", 124, "rl", 123, "s", ('!' + 128)
STRHL_RENAME_OK
  db "F", 127, "jl ", 127, "tnevez", 123, "se sikeres", ('.' + 128)
STRHL_RENAME_NOK
  db "Sikertelen f", 127, "jl ", 127, "tnevez", 123, "s", ('!' + 128)
  
STRHL_NO_RELATIVE_PATH_ALLOWED
  db "Relativ el", 123, "r", 123, "si utvonal nem enged", 123, "lyezett", ("!" + 128)  

STR_HELP_TXT
  db 12, "Ez itt a HomeLab3-The Cart k", 127, "rtya parancs", 123, "rtelmez", 188, " le", 169, "r", 127, "sa v",VER_MAJOR, ".", VER_MINOR_D1, VER_MINOR_D2,  13, 13,\
		"A parancsot mindig a", 13,\
		"  CALL $D003,",'"',"<P>( <file>)", '"', "(,<startc", 169, "m>,<v", 123, "gc", 169, "m>)", 13,\
		"form", 127, "ban kell megadni, ahol <P> a parancs, a () k", 124, "z", 124, "tti", 13,\
		"kifejez", 123, "sek opcion", 127, "lisak.", 13,13,13,\
		"A lehets", 123, "ges <P> parancsok:", 13,13,\
		" I vagy M - az SD k", 127, "rtya inicializ", 127, "l", 127, "sa", 13,\
		" P - az aktu", 127, "lis k", 124, "nyvt", 127, "r lek", 123, "rdez", 123, "se", 13,\
		" $ - az aktu", 127, "lis k", 124, "nyvt", 127, "r kilist", 127, "z", 127, "sa", 13,\
		" H - ez a HELP (vagy a $D003 param", 123, "ter n", 123, "lk", 125, "l)", 13,\
		" D <file> - file vagy ", 125, "res k", 124, "nyvt", 127, "r t", 124, "rl", 123, "se", 13,\
		" R <file1> <file2> - <file1> ", 127, "tnevez", 123, "se <file2>-re", 13,\
		" C <path> - k", 124, "nyvt", 127, "r v", 127, "lt", 127, "s", 13,\
		" L <file> - file bet", 124, "lt", 123, "se", 13,\
		" B <sorsz", 127, "m> - BASIC p", 123, "ldaprogram (1-3) bet", 124, "lt", 123, "se", 13,\
		" S <file> - HTP file ment", 123, "se.", 13,13,\
		" Ment", 123, "skor ha a file neve + jellel kezd", 188, "dik, akkor a fel", 125, "l", 169, "r", 127, "s", 13, " enged", 123, "lyezett.", 13,\
		" Start- ", 123, "s v", 123, "gc", 169, "m csak az S (SAVE) parancsn", 127, "l adhat", 126, " meg!", 13,\
		" A start- ", 123, "s a v", 123, "gc", 169, "m megadhat", 126, " decim", 127, "lis(4096) ", 123, "s hex($CAFE)" , 13,\
		" form", 127, "ban is!" , 13,\
		" A file nevet az S parancsn", 127, "l .HTP n", 123, "lk", 125, "l kell megadni!", 0

STRHL_DIR_CONTENT_TEXT
  db "  k", 124, "nyvt", 127, "r tartalma:", (13 + 128)

PAGE1_PRINT_MENU
  ld a, CHR_CLS
  RST $28
  
  call SYS_WAIT_FOR_SYNC	; wait for sync
  ld hl, STR_SCREEN_HEADER_PAGE1
  call print_fast_str
  
  ld hl, STR_BOX_HDR_PAGE1
  call print_fast_str
  
  ld b, WINDOW_HEIGHT
.print_empty_box_lines_loop
  push bc
  ld hl, STR_BOX_EMPTY_LINES_PAGE1
  call print_fast_str
  pop bc
  djnz .print_empty_box_lines_loop

  ld hl, STR_BOX_FOOTER_PAGE1
  call print_fast_str
  
  ld hl, STR_SCREEN_FOOTER_PAGE1
  call print_fast_str
  
  ld hl, $F800
  call SYS_UPDATE_PRINT_ADDR
  JP SWITCH_BACK_TO_PAGE0

; SD kártya olvasó modul, 2024.07
;   v0.01       készítette: Sanyi  
; 
; +-------------+-------+
; +  Név        + Méret +
; +-------------+-------+
; +
;   ...  20 üres sor ...
; +-------------+-------+
; +                     +
; +---------------------+
; 
; Kijelölés mozgatása nyilakkal
; Kiválasztás ENTER    kilépés F1

; é-123, ö-124, ü-125, ó-126, á-127, í-169, ő-188, ű-189
; 

STR_SCREEN_HEADER_PAGE1:
  db "SD k", 127, "rtya olvas", 126," modul, 2025.01", 13
  ; Attilának elküldve: v0.04, v0.05a, v0.07, v0.09 (10), v0.10
  db "  v", VER_MAJOR, ".", VER_MINOR_D1, VER_MINOR_D2, "      K", 123, "sz", 169, "tette: Sanyi", 13, 13, 0

STR_BOX_HDR_PAGE1:
  db CHR_TOP_LEFT
  DS 13, CHR_HOR_MID
  db CHR_HOR_TOP_MID
  ds 7, CHR_HOR_MID
  db CHR_TOP_RIGHT, 13
  
  db CHR_VER_MID, "     N", 123 , "v     ", CHR_VER_MID, " M", 123, "ret ", CHR_VER_MID, 13
  
  db CHR_VER_LEFT_MID
  DS 13, CHR_HOR_MID
  db CHR_CROSS
  ds 7, CHR_HOR_MID
  db CHR_VER_RIGHT_MID, 13, 0

STR_BOX_EMPTY_LINES_PAGE1
  db CHR_VER_MID, "             ", CHR_VER_MID, "       ", CHR_VER_MID, 13, 0
  
STR_BOX_FOOTER_PAGE1
  db CHR_VER_LEFT_MID
  DS 13, CHR_HOR_MID
  db CHR_HOR_BOT_MID
  ds 7, CHR_HOR_MID
  db CHR_VER_RIGHT_MID, 13
  db CHR_VER_MID
  ds  21, 32
  db CHR_VER_MID, 13
  db CHR_BOT_LEFT
  DS 21, CHR_HOR_MID
  db CHR_BOT_RIGHT, 13, 13, 0

STR_SCREEN_FOOTER_PAGE1
  db "Kijel", 124, "l", 123, "s mozgat", 127, "sa nyilakkal", 13
  db "Kiv", 127, "laszt", 127, "s ENTER    kil", 123, "p", 123, "s F1", 0

END_POS_MARKER_PAGE1
  ds $DF00 - END_POS_MARKER_PAGE1

  PAGE 2
  code @ $d100
PAGE2_LOAD_BASIC_DEMO
  call COPY_PARAM_TO_CARTRAM
  ld a, ($DF00)
  cp '1'
  jr nc, .param_high_enough
.invalid_parameter
  ld hl, STR_INVALID_BASIC_PRG
  ld c, $0d
  call PRINT_ZT_STRING_PAGE2
  xor a
  inc a
  JP SWITCH_BACK_TO_PAGE0
.param_high_enough
  cp '3' + 1
  jr nc, .invalid_parameter
  ld hl, (SYSVAR_MEM_TOP)
  push hl
  sub '1'
  sla a
  ld e, a
  ld d, 0
  ld hl, PAGE2_PRG_POIS
  add hl, de
  ld e, (hl)	; de start addr
  inc hl
  ld d, (hl)
  inc hl
  ld c, (hl)	; bc end addr
  inc hl
  ld b, (hl)
  dec bc	; block end: 0x00

  ex de, hl		; hl: start addr
.loop_find_start_add
  ld a, (hl)	
  inc hl
  or a
  jr nz, .loop_find_start_add
  ld de, 4
  add hl, de	; skip start add and len
  ex de, hl		; de start of payload
  ld l, c	
  ld h, b		; hl: end address
  xor a
  sbc hl, de
  ld c, l
  ld b, h		; bc = end - start = length
  ex de, hl		; hl = start payload
  ld de, $4016	; de = copy target = 4016 is the start of save addr
  ldir
  pop hl
  ld (SYSVAR_MEM_TOP),hl

  ld hl, 2
  add hl, sp
  ld de, $179D
  ld (hl), e
  inc hl
  ld (hl), d
  
  ld hl, STRHL_BASIC_DEMO_LOADED
  ld c, $0d
  call SYS_PRINT_STRING
  xor a
  JP SWITCH_BACK_TO_PAGE0

PRINT_ZT_STRING_PAGE2
  ld a, (hl)
  or a 
  jr z, .done_str
  rst $28
  inc hl
  jr PRINT_ZT_STRING_PAGE2
.done_str
  ld a, c
  rst $28
  ret  
  
STR_INVALID_BASIC_PRG
  db "Nem j", 126, " program azonos", 169, "t", 126, "!", 13,\
    " 1 - K", 127, "rtya ", 123, "szlel", 123, "se" , 13,\
	" 2 - Joystick lek", 123, "rdez", 123, "se", 13,\
	" 3 - AY-3-8910 haszn", 127, "lata - polif", 126, "nikus zongora", 0
STRHL_BASIC_DEMO_LOADED
  db "Program bet", 124, "ltve", ('!' + 128)

PAGE2_PRG_POIS
  dw PAGE2_PROG0
  dw PAGE2_PROG1
  dw PAGE2_PROG2
  dw END_POS_MARKER_PAGE2
PAGE2_PROG0
  incbin "detect.htp", 0x100
PAGE2_PROG1
  incbin "JOY-TEST.htp", 0x100
PAGE2_PROG2
  incbin "AY3-TEST.htp", 0x100

END_POS_MARKER_PAGE2
  ds $DF00 - END_POS_MARKER_PAGE2