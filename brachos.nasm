; http://fisnikhasani.com/building-your-own-bootloader/
bits 16             ; 16 bit real mode
org 0x7c00          ; BIOS boot origin

jmp main

; VARS

Message db "Welcome to Wanja OS; booting from low level 16 bit...", 0x00
AnyKey db "Press any key to reboot...", 0x00

; print the string sitting in si and append 0d0a
print_ln:
    lodsb           ; Load string
    or al, al
    jz complete
    mov ah, 0x0e
    int 0x10        ; BIOS interrupt 10 - Print character to screen via video memory
    jmp print_ln
complete:
    call print_newline


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


wait_for_keypress:
    mov ah, 0
    int 0x16        ; BIOS service
    ret


reboot:
    mov si, AnyKey
    call print_ln

    call wait_for_keypress

    ; Send us to end of memory, causing a reboot
    db 0x0ea
    dw 0x0000
    dw 0xffff

main:
    cli             ; Clear interrupts

    ; Setup stack segments
    mov ax, cs
    mov ds, ax
    mov es, ax
    mov ss, ax
    sti             ; Enable interrupts

    ; Print Welcome
    mov si, Message
    call print_ln

    call print_newline
    call print_newline

    call reboot

    times 510 - ($-$$) db 0         ; Fill the rest of the boot loader with 0
    dw 0xAA55       ; Boot signature