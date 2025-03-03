.model tiny
.code
.386
org 100h
locals @@

Start:          call Main

VideoMemSegment equ     0b800h

FrameColor      equ     03h
FrameLength     equ     09h
FrameHeight     equ     0Fh

DisplayedRegNum equ     0Dh
RegSize         equ     02h

JMP_code        equ     db 0eah

KeyboardPort    equ     60h

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

        push ax
        push bx
        push es

; if (scan_code != scan_code(R)) { jmp to old INT09H handler}
        in al, KeyboardPort             ; load key scan code

        cmp al, R_scan_code
        jne end_INT09H_StandIn


; if (Active == 1) { erase frame, Active = 0} else { Make frame, Active = 1}
        cmp byte ptr Frame_Active, 0b
        je  @@not_Active

; Frame is active, erase frame

        mov bx, VideoMemSegment     ; set es to the beginnig of video mem segment
        mov es, bx

        call EraseFrame

        mov byte ptr Frame_Active, 0b
        jmp end_INT09H_StandIn

@@not_Active:
        mov byte ptr Frame_active, 1b

end_INT09H_StandIn:

        pop es
        pop bx
        pop ax

        JMP_code
old_int9_ofs:   dw 0
old_int9_seg:   dw 0

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

        push ss
        push es
        push ds
        push sp

        push bp
        push di
        push si
        push dx
        push cx
        push bx
        push ax

        cmp byte ptr Frame_Active, 1b
        jne @@end_INT08H_StandIn

        mov bx, sp                      ; restore sp value in stack (sp changed due to several pushes)
        add bx, 0Eh                     ; 2 * num of pushes after 'push sp'
        mov ax, bx
        add ax, 0Eh                     ; 2 * num of pushes before 'push sp' (including ip, cs, flags)
        mov word ptr ss:[bx], ax

        mov bx, VideoMemSegment         ; set es to the beginnig of video mem segment
        mov es, bx

; Displaying registers values------------------------------

        call MakeFrame

        mov bx, offset RegValuesOff
        mov word ptr di, cs:[bx]

        mov bx, sp
        dec bx
        dec bx                          ; to compensate bx+2 before every iteration
        xor cx, cx

        mov ch, DisplayedRegNum
@@for_cond_check:

        cmp cl, ch                      ; for (cl = 0; cl < (ch = DisplayedRegNum); cl++)
        je  @@for_end

        add bx, RegSize                 ; bx += Regsize
        mov ax, word ptr ss:[bx]        ; ax = ss:[bx]
        add di, 0A0h                    ; di += 10

        push bx
        push cx
        call itoa_hex                   ; display ax value in videomem
        pop cx
        pop bx

        inc cl                          ; cl++
        jmp @@for_cond_check

@@for_end:

@@end_INT08H_StandIn:

        pop ax
        pop bx
        pop cx
        pop dx

        pop si
        pop di

        pop bp
        pop ds                          ; do not pop sp!!! - there is stored sp of interrupted function
        pop ds
        pop es
        pop ss

        JMP_code
old_int8_ofs:   dw 0
old_int8_seg:   dw 0

        endp

;=============================================================================================================
; Calculate and save start es:[di] position of frame and register values displaying
; assuming es = B800h (Video Memory Segment)
; Entry:    None
; Exit:     None
; Destr:    ax
;=============================================================================================================
PrepareToDisplay        proc


        mov bx, VideoMemSegment     ; set es to the beginnig of video mem segment
        mov es, bx

        mov cx, FrameLength
        mov dx, FrameHeight

        call CalcFrameStart         ; Position for centered frame

        mov word ptr cs:[offset FrameOff], di

        add di, 0Eh     ; 8 + 6
        mov word ptr cs:[offset RegValuesOff], di

        ret
        endp

FrameOff:       dw 0   ; frame start position in VideoMemSeg
RegValuesOff:   dw 0   ; start position in VideoMemSeg for writing registers values

;=============================================================================================================
; Erase frame displayed on es:[offset FrameOff], filling with '0h', '20h' - space char on black
; Entry:    None
; Exit:     None
; Destr:    ax
;=============================================================================================================
EraseFrame      proc

        mov bx, offset FrameOff
        mov word ptr di, cs:[bx]

        mov si, offset Sequence + 9     ; empty space seq
        xor ah, ah                      ; set background color to black

        mov cx, FrameLength
        mov dx, FrameHeight

        call DrawFrame

        ret
        endp

;=============================================================================================================
; Makes a frame for displaying registers values in video memory or erases it if already displaying
; FrameLength and FrameHeight are set as const
; Position for frame (centered) is calculated before going resident
;
; !!! MAKE SURE THAT REGNAME ENDS WITH DOUBLE '0Dh' !!!
;
; Entry:    None
; Exit:     None
; Destr:    ax
;=============================================================================================================
MakeFrame   proc

        mov bx, VideoMemSegment     ; set es to the beginnig of video mem segment
        mov es, bx

; Drawing Frame--------------------------------------------


        mov bx, offset FrameOff         ; load precalculated frame offset
        mov word ptr di, cs:[bx]
        push di

        mov si, offset Sequence
        mov ah, 03h

        mov cx, FrameLength
        mov dx, FrameHeight

        call DrawFrame

        pop di
; Write registers names------------------------------------

        ; di will be shifted to the begining of the first string for first WriteString
        add di, 08h
        mov si, offset RegName

@@loop:
        add di, 09Ah            ; considering length_of_strings = 3, di_shift = 160 - 3 * 2
        call WriteString

        cmp cs:[si], cl         ; after WriteString 0Dh stored in cl
        jne @@loop              ; writing strings until '0Dh', '0Dh' is met

        ret
        endp

Sequence:   db  0c9h, 0cdh, 0bbh, 0bah, 020h, 0bah, 0c8h, 0cdh, 0bch    ; double line box
            db  020h, 020h, 020h, 020h, 020h, 020h, 020h, 020h, 020h    ; empty black space

RegName:    db  'ax:', 0Dh, 'bx:', 0Dh, 'cx:', 0Dh, 'dx:', 0Dh, 'si:', 0Dh
            db  'di:', 0Dh, 'bp:', 0Dh, 'sp:', 0Dh, 'ds:', 0Dh, 'es:', 0Dh
            db  'ss:', 0Dh, 'ip:', 0Dh, 'cs:', 0Dh, 0Dh ; !!! MAKE SURE IT ENDS WITH DOUBLE 'ODh' !!!

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

        ; di = (80 - cx / 2 + 160 * (14 - dx / 2)) / 2 * 2
        shr ax, 1

        mov di, 0050h
        sub di, cx

        sub ax, 0Eh
        neg ax
        shl ax, 5

        mov cx, 05h
        mul cx

        add di, ax

        shr di, 1               ; round to a multiple of 2 (for video memory)
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
; Destr:    al, dx, si, di
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
        lodsb           ; reading first byte of sequence to al
        stosw           ; writing to video mem

        lodsb           ; reading second byte
        rep stosw       ; writing (cx - 2) times to video mem

        lodsb           ; reading first byte of sequence to al
        stosw           ; writing to video mem

        pop cx          ; save cx

        shl cx, 1       ; shift di to the beginning of the next string
        add di, 0A0h
        sub di, cx
        shr cx, 1

        pop si          ; save si

        ret
        endp

;=============================================================================================================
; Writes a string ending with '\r' in video mem (could be set in cl - look in func)
; Entry:    ah - color
;           si - pointer to a string
;           di - pointer to video mem for beginning of the string
; Exit:     None
; Destr:    cx, si, di
;=============================================================================================================
WriteString proc

        push ds
        mov bx, cs
        mov ds, bx

        mov cl, 0Dh             ; TERMINATING SYMBOL

@@test_condition:
        cmp cs:[si], cl         ; while (ds:[si] != cl)
        je while_end

        lodsb                   ; al = ds:[si++]
        stosw                   ; es:[di] = ax, di+=2
        jmp @@test_condition

while_end:

        inc si
        pop ds

        ret
        endp

;=============================================================================================================
; Reads 16-based number from 0 to 255 from a string and saves to al
; Entry:    di - pointer to a string to write a number
;           ax - value to translate
; Exit:     None
; Destr:    di, si, ax, bx, cx
;=============================================================================================================
itoa_hex    proc

        push di

        ; bx = ax // 16
        ; for (i =0; i < 4; i++) { es:[di] = ax % 16, ax = ax // 16}

        xor cx, cx
        mov ch, RegSize * 2
        mov si, offset HexASCII

@@for_cond_check:

        cmp cl, ch
        je  @@for_end

        mov bx, ax
        shr bx, 4
        shl bx, 4

        push si

        add si, ax
        sub si, bx

        sub ax, bx
        mov byte ptr al, cs:[si]
        mov byte ptr es:[di], al
        dec di
        dec di
        pop si

        mov ax, bx
        shr ax, 4
        inc cl
        jmp @@for_cond_check

@@for_end:

        pop di

        ret
        endp


HexASCII:   db '0', '1', '2', '3', '4', '5', '6', '7'
            db '8', '9', 'A', 'B', 'C', 'D', 'E', 'F'

EOP:    db 0

;======================================================================================================
Main    proc


; Rewriting INT09H in Table of Interruptions-----------------------------------------------------------

    ; set es[bx] to a INT09H pointer
        xor ax, ax
        mov es, ax
        mov cx, 1234h
        mov dx, 5678h
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

        ;int 09h
; Rewriting INT08H in Table of Interruptions-----------------------------------------------------------

    ; set es[bx] to a INT08H pointer
        xor ax, ax
        mov es, ax
        mov bx, 08h * 04h

    ; Save old handler of INT08H
        mov ax, es:[bx]
        mov word ptr old_int8_ofs, ax
        mov ax, es:[bx+2]
        mov word ptr old_int8_seg, ax

    ; write new handler for INT08H
    ; Forbid interrupts to avoid trying to handle interruption with wrong function address
        cli
        mov es:[bx], offset INT08H_StandIn
        push cs
        pop ax
        mov es:[bx+2], ax
        sti

        call PrepareToDisplay

; Terminate and Stay Resident--------------------------------------------------------------------------
        mov ax, 3100h           ; TSR
        mov dx, offset EOP      ; programm size in paragraphs (16 byte)
        shr dx, 4
        inc dx
        int 21h

        endp

end     Start
