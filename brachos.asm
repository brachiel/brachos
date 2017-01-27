; vim: tabstop=4 sw=4 expandtab filetype=nasm :
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

WelcomeMessage db 'Welcome to brachOS. Booting from low level 16 bit...', clrf, 0x00
CommandList db 'Enter a command. 2=boot second stage, r=reboot, p=print hello message, c=clear screen', clrf, '# ', 0x00

DriveNumber db 0x00

; print the string sitting in si and append 0d0a
fs_print:
    lodsb           ; Load string
    or al, al
    jz .print_complete
    mov ah, 0x0e
    int 0x10        ; BIOS interrupt 10 - Print character to screen via video memory
    jmp fs_print
.print_complete:
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
    je .command_reboot
    cmp al, 'p'
    je .command_print_hello
    cmp al, 'c'
    je .command_clear_screen
    cmp al, '2'
    je .command_load_second_stage
    call fs_print_newline
    jmp fs_wait_and_handle_command     ; not a correct command. Ask again.
.command_reboot:
    call fs_reboot
.command_print_hello:
    call fs_print_newline
    call fs_print_newline
    mov si, WelcomeMessage
    call fs_print_ln
    jmp fs_wait_and_handle_command
.command_clear_screen:
    call fs_clear_screen
    jmp fs_wait_and_handle_command
.command_load_second_stage:
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
    pusha                              ; save all
    mov si, 0x02                       ; number of tries
.top:
    mov ah, 0x02                       ; read sectors from drive
    int 0x13
    jnc .end                           ; exit if successful
    dec si                             ; decrement remaining steps
    jc  .end                           ; exit if maximum tries reached
    xor ah, ah                         ; reset disk system
    int 0x13
    jnc .top
.end:
    popa
    ret


fs_execute_second_stage:
    mov al, 0x01    ; one sector
    mov cx, 0x0002  ; cylinder 0, sector 2
    mov bx, 0x7e00  ; right after bootloader
    mov dl, [DriveNumber]
    xor dh, dh      ; head 0
    call fs_read_sectors_16
    jnc .success
    jmp fs_halt
.success:
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

    mov byte [DriveNumber], dl
    xor bx, bx

    ; Setup stack segments
    mov ax, cs
    mov ds, ax
    mov es, ax
    mov ss, ax

    ; Set up stack just below A000:000
    mov bp, 0x9000         ; Stack base pointer
    mov sp, 0xffff         ; Stack pointer

    sti                    ; Enable interrupts

    call fs_clear_screen

    ; Print Welcome
    mov si, WelcomeMessage
    call fs_print_ln

    call fs_print_newline
    call fs_print_newline

    call fs_wait_and_handle_command

    times 510 - ($-$$) db 0         ; Fill the rest of the boot loader with 0
    dw 0xAA55       ; Boot signature


;;;;;;;; SECTOR 2 ;;;;;;;;

jmp ss_main

SecondStageMessage db 'Welcome to the second stage', 0x00

ss_main:
    mov si, SecondStageMessage
    call fs_print_ln

    call fs_wait_for_keypress

    call fs_reboot
    
    times 512 - ($-$$) db 0         ; Fill the rest of sector 2 with 0

