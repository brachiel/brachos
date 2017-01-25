; vim: tabstop=4 sw=4 expandtab :
;
; (c)  2017  Fisnik Hasani  http://fisnikhasani.com/building-your-own-bootloader/
; (c)  2017  brachiel       http://github.com/brachiel
;
;    This program is free software: you can redistribute it and/or modify
;    it under the terms of the GNU General Public License as published by
;    the Free Software Foundation, either version 3 of the License, or
;    (at your option) any later version.
;
;    This program is distributed in the hope that it will be useful,
;    but WITHOUT ANY WARRANTY; without even the implied warranty of
;    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
;    GNU General Public License for more details.
;
;    You should have received a copy of the GNU General Public License
;    along with this program.  If not, see <http://www.gnu.org/licenses/>.
;

bits 16             ; 16 bit real mode
org 0x7c00          ; BIOS boot origin

jmp fs_main

; VARS

%define clrf    0x0d, 0x0a

WelcomeMessage db 'Welcome to brachOS. Booting from low level 16 bit...', clrf, clrf, 0x00
CommandList db 'Enter a command. 2=boot second stage, r=reboot, p=print hello message, c=clear screen', clrf, '# ', 0x00

DriveNumber db 0x00

; print the string sitting in si and append 0d0a
fs_print:
    lodsb           ; Load string
    or al, al
    jz fs_print_complete
    mov ah, 0x0e
    int 0x10        ; BIOS interrupt 10 - Print character to screen via video memory
    jmp fs_print
fs_print_complete:
    ret


fs_print_ln:
    call fs_print
    call fs_print_newline
    ret


; prints 0d 0a
fs_print_newline:
    mov al, 0       ; 0x00 terminator
    stosb            ; store string

    ; Add newline
    mov ah, 0x0e
    mov al, 0x0d
    int 0x10
    mov al, 0x0a
    int 0x10

    ret


; get current video mode and set it again; this will clear the screen
fs_clear_screen:
    mov ah, 0x0f
    int 0x10
    ; al contains video mode
    ; ah = number of character columns
    ; bh = active page
    mov ah, 0
    ; al = video mode
    int 0x10
    ret


fs_wait_for_keypress:
    mov ah, 0
    int 0x16        ; BIOS service
    ; pressed key is in al
    ret


fs_wait_and_handle_command:
    mov si, CommandList
    call fs_print

    call fs_wait_for_keypress

    cmp al, 'r'
    je fs_command_reboot
    cmp al, 'p'
    je fs_command_print_hello
    cmp al, 'c'
    je fs_command_clear_screen
    cmp al, '2'
    je fs_load_second_stage
    call fs_print_newline
    jmp fs_wait_and_handle_command     ; not a correct command. Ask again.
fs_command_reboot:
    call fs_reboot
fs_command_print_hello:
    call fs_print_newline
    call fs_print_newline
    mov si, WelcomeMessage
    call fs_print_ln
    jmp fs_wait_and_handle_command
fs_command_clear_screen:
    call fs_clear_screen
    jmp fs_wait_and_handle_command
fs_load_second_stage:
    call fs_execute_second_stage
    
    

; Read sectors using BIOS interrupts
; input:
; dl  -  drive number
; al  -  number of sectors to read
; ch  -  cylinder[7:0]
; cl  -  sector (1-63), cylinder[9:8]
; dh  -  head
; es:bx - destination
fs_read_sectors_16:
;    pusha                              ; save all
    mov si, 0x02                       ; number of tries
fs_read_sectors_16__top:
    mov ah, 0x02                       ; read sectors from drive
    int 0x13
    jnc fs_read_sectors_16__end        ; exit if successful
    dec si                             ; decrement remaining steps
    jc  fs_read_sectors_16__end        ; exit if maximum tries reached
    xor ah, ah                         ; reset disk system
    int 0x13
    jnc fs_read_sectors_16__top
fs_read_sectors_16__end:
;    popa
    ret


fs_execute_second_stage:
    mov al, 0x01    ; one sector
    mov cx, 0x0002  ; cylinder 0, sector 2
    mov bx, 0x7e00  ; right after bootloader
    mov dl, [DriveNumber]
    xor dh, dh      ; head 0
    call fs_read_sectors_16
    jnc fs_read_second_stage__success
    jmp fs_halt
fs_read_second_stage__success:
    jmp 0x7e00      ; successfully read sector 2. Start execution there.
    


fs_reboot:
    ; Jump to end of memory, causing a reboot
    jmp word 0xffff:0000

fs_halt:
    cli
    hlt
    jmp fs_halt

fs_main:
    cli             ; Clear interrupts

    mov byte [DriveNumber], dl  ; BIOS stores the device number for us

    ; Setup stack segments
    mov ax, cs
    mov ds, ax
    mov es, ax
    mov ss, ax

    mov sp, stack_high ; setting up small stack
    sti             ; Enable interrupts

    call fs_clear_screen

    ; Print Welcome
    mov si, WelcomeMessage
    call fs_print_ln

    call fs_print_newline
    call fs_print_newline

    call fs_wait_and_handle_command

stack_low:
    times 509 - ($-$$) db 0         ; Fill the rest of the boot loader with 0
stack_high:
    db 0
    dw 0xAA55       ; Boot signature


;;;;;;;; SECTOR 2 ;;;;;;;;

jmp ss_main

SecondStageMessage db 'Welcome to the second stage', 0x00

ss_main:
    mov si, SecondStageMessage
    call fs_print_ln

    call fs_wait_for_keypress

    call fs_reboot
    
    times 1024 - ($-$$) db 0         ; Fill the rest of sector 2 with 0
