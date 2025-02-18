.model tiny
.code
org 100h
locals @@

Start:
        mov bx, VideoMemSegment     ; set es to the beginnig of video mem segment
        mov es, bx

        mov si, CMD_args_start      ; pointer to command line arguments

        call SkipSpaces

        call atoi10                 ; read frame length
        mov cx, ax

        call SkipSpaces

        call atoi10                 ; read frame height
        mov dx, ax

        call SkipSpaces

        push dx
        call atoi16                 ; read frame color
        pop dx

        mov ah, al
        push ax

        call SkipSpaces

        push dx
        call atoi10                 ; get sequence start position

        mov dl, 9
        mul dl

        mov bx, si
; Custom sequence if ax == 0
; Condition
        cmp ax, 0h
        ja  @@not_custom_sequence

        call SkipSpaces
        add bx, 09h                 ; move bx to position after sequence in command line args
        jmp @@endif

@@not_custom_sequence:
        mov si, offset Sequence
        add si, ax

@@endif:

; Making a frame --------------------------
        pop dx

        call CalcFrameStart
        pop ax

        push di
        call DrawFrame
        pop di

        push ax
; -----------------------------------------

; Prepare for writing a string ------------

        mov si, bx              ; restore si
        call SkipSpaces

        push di

        mov di, si

        push cx
        call Strlen
        mov bx, cx

        pop cx
        pop di

        call CalcStringStart

        pop ax
        call WriteString

        mov ah, 4ch				; DOS Fn 4ch = exit(al)
        int 21h					; DOS Fn 21h = system(ah)

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

        mov di, 50h
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
; Calculates the start position for a string in video mem
; Entry:    cx - length of the frame
;           dx - height of the frame
;           bx - length of the string
; Exit:     di - pointer to a start position
; Destr:    ax, bx, cx, dx
;=============================================================================================================
CalcStringStart  proc

        ; di += (cx - bx) / 2 + 160 * (dx / 2)
        shr dx, 1
        mov ax, dx
        shl ax, 5

        sub cx, bx

        mov dx, 0005h
        mul dx

        add ax, cx
        shr ax, 1
        shl ax, 1

        add di, ax

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

;=============================================================================================================
; Moves si until ds:[si] is a non-space character
; Entry:    si - pointer to video mem for beginning of the string
; Exit:     None
; Destr:    si, al
;=============================================================================================================
SkipSpaces   proc

        mov al, ' '
        dec si

@@test_condition:               ; while(ds:[si] != ' ') { si++ }
        inc si
        cmp ds:[si], al
        je @@test_condition

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

        mov cl, 0Dh             ; TERMINATING SYMBOL

@@test_condition:
        cmp ds:[si], cl         ; while (ds:[si] != cl)
        je while_end

        lodsb                   ; al = ds:[si++]
        stosw                   ; es:[di] = ax, di+=2
        jmp @@test_condition

while_end:

        ret
        endp

;=============================================================================================================
; Counts length of '\r' terminated string
; Entry:    di - pointer to a string
; Exit:     cx - length of the string
; Destr:    al, di, cx
;=============================================================================================================
Strlen  proc

        push es
        mov ax, ds
        mov es, ax

        mov ax, 0Dh     ; end of string
        mov cx, -1

        cld
        repne scasb
        neg cx
        dec cx

        pop es

        ret
        endp

;=============================================================================================================
; Reads 10-based number from 0 to 255 from a string and saves to al
; Entry:    si - pointer to a string with number
; Exit:     al - number extracted from string
; Destr:    si, ax, dx, bl
;=============================================================================================================
atoi_dec        proc

        xor ax, ax
        xor dx, dx
        mov dh, '0'
        mov bl, 0Ah     ; 0Ah - radix of 10 digit system

@@test_condition:       ; while (ds:[si] - '0' < 10) { ax = ax * 10 + ds:[si] - '0'}
        mul bl
        add al, dl

        mov dl, ds:[si]
        sub dl, dh              ; dl = dl - '0'; ASCII to actual digits

        inc si
        cmp dl, 0Ah             ; ?  0 <= dl < 10
        jb @@test_condition

        ret
        endp

;=============================================================================================================
; Reads 16-based number from 0 to 255 from a string and saves to al
; Entry:    si - pointer to a string with number
; Exit:     ax - number extracted from string
; Destr:    si, ax, dx
;=============================================================================================================
atoi_hex        proc

        xor ax, ax
        xor dx, dx
        mov dh, '0'

@@test_condition:  ; while (ds:[si] - '0' < 10) { ax = ax * 16 + [si] - '0'}
        shl al, 4
        add al, dl

        mov dl, ds:[si]
        cmp dl, 'A'
        jb  @@lower_than_A

        sub dl, 'A' - '0'       ; in the end dl = dl - 'A' + 10d
        add dl, 0Ah

@@lower_than_A:
        sub dl, dh              ; dl = dl - '0'; ASCII to actual digits

        inc si
        cmp dl, 10h             ; 10h - radix of 16 digit system
        jb @@test_condition

        ret
        endp

CMD_args_start  equ     0081h
VideoMemSegment equ     0b800h

AtoiTest:   db '12b'

Sequence:   db  031h, 032h, 033h, 034h, 035h, 036h, 037h, 038h, 039h    ; 123456789 - test sequence
            db  0dah, 0c4h, 0bfh, 0b3h, 020h, 0b3h, 0c0h, 0c4h, 0d9h    ; single line box
            db  0c9h, 0cdh, 0bbh, 0bah, 020h, 0bah, 0c8h, 0cdh, 0bch    ; double line box
            db  003h, 003h, 003h, 003h, 020h, 003h, 003h, 003h, 003h    ; valentine frame
            db  006h, 006h, 006h, 005h, 0b0h, 006h, 005h, 005h, 005h    ; spades frame with shade filling
            db  02bh, 02dh, 02bh, 049h, 020h, 049h, 05ch, 05fh, 02fh    ; '+-+I I\_/'

String:     db 'Hello there?', 0Dh, '!!!NOTFORPRINT!!!'


end     Start
