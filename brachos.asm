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

jmp main

; VARS

%define clrf    0x0d, 0x0a

WelcomeMessage db 'Welcome to brachOS. Booting from low level 16 bit...', clrf, clrf, \
           '    brachos  Copyright (C) 2017  brachiel', clrf, \
           'This program comes with ABSOLUTELY NO WARRANTY', clrf, \
           'This is free software, and you are welcome to redistribute it', clrf, \
           'under certain conditions.', clrf, 0x00
CommandList db 'Enter a command. r=reboot, p=print hello message, c=clear screen', clrf, '# ', 0x00

; print the string sitting in si and append 0d0a
print:
    lodsb           ; Load string
    or al, al
    jz complete
    mov ah, 0x0e
    int 0x10        ; BIOS interrupt 10 - Print character to screen via video memory
    jmp print
complete:
    ret


print_ln:
    call print
    call print_newline
    ret


; prints 0d 0a
print_newline:
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
clear_screen:
    mov ah, 0x0f
    int 0x10
    ; al contains video mode
    ; ah = number of character columns
    ; bh = active page
    mov ah, 0
    ; al = video mode
    int 0x10
    ret


wait_for_keypress:
    mov ah, 0
    int 0x16        ; BIOS service
    ; pressed key is in al
    ret


wait_and_handle_command:
    mov si, CommandList
    call print

    call wait_for_keypress

    cmp al, 'r'
    je command_reboot
    cmp al, 'p'
    je command_print_hello
    cmp al, 'c'
    je command_clear_screen
    call print_newline
    jmp wait_and_handle_command     ; not a correct command. Ask again.
command_reboot:
    call reboot
command_print_hello:
    call print_newline
    call print_newline
    mov si, WelcomeMessage
    call print_ln
    jmp wait_and_handle_command
command_clear_screen:
    call clear_screen
    jmp wait_and_handle_command


reboot:
    ; Jump to end of memory, causing a reboot
    jmp word 0xffff:0000


main:
    cli             ; Clear interrupts

    ; Setup stack segments
    mov ax, cs
    mov ds, ax
    mov es, ax
    mov ss, ax
    sti             ; Enable interrupts

    call clear_screen

    ; Print Welcome
    mov si, WelcomeMessage
    call print_ln

    call print_newline
    call print_newline

    call wait_and_handle_command

    times 510 - ($-$$) db 0         ; Fill the rest of the boot loader with 0
    dw 0xAA55       ; Boot signature
