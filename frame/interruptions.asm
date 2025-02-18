.model tiny
.code
org 100h
locals @@

Start:

; Rewriting INT09H in Table of Interruptions-----------------------------------------------------------

    ; set es[bx] to a INT09H pointer
        xor ax, ax
        mov es, ax
        mov bx, 09h * 04h

    ; Save old handler of INT09H
        mov ax, es:[bx]
        mov word ptr old_int9_ofs, ax
        mov ax, es:[bx+2]
        mov word ptr old_int9_seg, ax

    ; write new handler for INT09H
    ; Forbid interrupts to avoid trying to handle interruption with wrong function address
        cli
        mov es:[bx], offset INT09H_StandIn
        push cs
        pop ax
        mov es:[bx+2], ax
        sti

; Terminate and Stay Resident--------------------------------------------------------------------------
        mov ax, 3100h           ; TSR
        mov dx, offset EOP      ; programm size in paragraphs (16 byte)
        shr dx, 4
        inc dx
        inc dx
        int 21h

;=============================================================================================================
; Called from INT09H, draws frame to display registers values (frame active) if interruption
; caused by pressing [R]. Erases frame on second press of [R].
; At the end of function jumps to original INT09H handler
; Entry:    None
; Exit:     None
; Destr:    al
;=============================================================================================================
INT09H_StandIn  proc

R_scan_code equ 013h

        push bx
        push es
        push ax

        mov bx, VideoMemSegment     ; set es to the beginnig of video mem segment
        mov es, bx
        mov ah, 04h
        mov bx, 5*80*2


; if (scan_code != scan_code(R)) { jmp to old INT09H handler}
        in al, 60h      ; load key scan code
        mov es:[bx], ax

        cmp al, R_scan_code
        jne @@end_INT09H_StandIn

; if (Active == 1) { erase frame, Active = 0} else { Make frame, Active = 1}
        cmp byte ptr Frame_Active, 0b
        je  @@not_Active

        ; erase frame
        mov bx, VideoMemSegment     ; set es to the beginnig of video mem segment
        mov es, bx

        mov cx, 09h
        mov dx, 06h

        call CalcFrameStart

        push di
        add di, (50h + 04h) * 02h
        mov word ptr FrameValuesOff, di
        pop di

        mov si, offset Sequence + 9
        mov ah, 04h

        call DrawFrame

        add di, 0A1h


        mov byte ptr Frame_Active, 0b
        jmp @@end_INT09H_StandIn

@@not_Active:
        ; make frame
        mov bx, VideoMemSegment     ; set es to the beginnig of video mem segment
        mov es, bx

        mov cx, 09h
        mov dx, 06h

        call CalcFrameStart

        mov si, offset Sequence
        mov ah, 04h

        call DrawFrame

        mov byte ptr Frame_active, 1b

@@end_INT09H_StandIn:

        pop ax
        pop es
        pop bx

                db 0eah     ; jmp code
old_int9_ofs:   dw 0
old_int9_seg:   dw 0

FrameValuesOff: db 0h, 0h   ; start position in VideoMemSeg for writing registers values

Frame_Active:   db 0
        endp
;=============================================================================================================
; Called from INT08H, displays registers values if frame is active.
; At the end of function jumps to original INT08H handler
; Entry:    None
; Exit:     None
; Destr:    al
;=============================================================================================================
INT08H_StandIn  proc

        cmp byte ptr Frame_Active, 1b
        jne @@end_INT08H_StandIn

        ; display registers


@@end_INT08H_StandIn:

                db 0eah     ; jmp code
old_int8_ofs:   dw 0
old_int8_seg:   dw 0

        endp


;=============================================================================================================
; Calculates the start position for a frame in video mem
; Entry:    cx - length of the frame
;           dx - height of the frame
; Exit:     di - pointer to a start position
; Destr:    ax
;=============================================================================================================
CalcFrameStart  proc

        push cx
        push dx
        mov ax, dx

        ; 80 - cx / 2 + 160 * (14 - h / 2)
        shr ax, 1

        mov di, 0050h
        sub di, cx

        sub ax, 0Eh
        neg ax
        shl ax, 5

        mov cx, 05h
        mul cx

        add di, ax

        shr di, 1
        shl di, 1

        pop dx
        pop cx

        ret
        endp


;=============================================================================================================
; Draws a frame in video mem described with 9 bytes
; Entry:    ah - color
;           si - pointer to 9 byte sequence
;           cx - length of the frame
;           dx - height of the frame
; Exit:     None
; Destr:    al, si, di
;=============================================================================================================
DrawFrame   proc

        push dx
        push ds
        mov bx, cs
        mov ds, bx

        call DrawLine
        add si, 03h             ; move to the next subsequence

        dec dl
        dec dl
height:
        call DrawLine
        dec dl
        cmp dl, 0h
        ja height

        add si, 03h

        call DrawLine
        add si, 03h

        pop ds
        pop dx

        ret
        endp

;=============================================================================================================
; Draws line described with 3 bytes in video mem
; 1 time first byte, (cx-2) times - second byte and then third byte
; 121 (cx = 6) => 122221
; Entry:    ah - color
;           si - pointer to 3 byte sequence
;           cx - length of the frame
; Exit:     None
; Destr:    al, di
;=============================================================================================================
DrawLine    proc

        push si         ; save si
        push cx         ; save cx

        dec cx
        dec cx

        cld
        lodsb           ; reading first byte of sequance to al
        stosw           ; writing to video mem

        lodsb           ; reading second byte
        rep stosw       ; writing (cx - 2) times to video mem

        lodsb           ; reading first byte of sequance to al
        stosw           ; writing to video mem

        pop cx          ; save cx

        shl cx, 1       ; shift di to the beginning of the next string
        add di, 0A0h
        sub di, cx
        shr cx, 1

        pop si          ; save si

        ret
        endp

VideoMemSegment equ     0b800h

Sequence:   db  0dah, 0c4h, 0bfh, 0b3h, 020h, 0b3h, 0c0h, 0c4h, 0d9h    ; single line box
            db  02bh, 02dh, 02bh, 049h, 020h, 049h, 05ch, 05fh, 02fh    ; '+-+I I\_/'

EOP:    db 0
end     Start
