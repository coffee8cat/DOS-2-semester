.model tiny
.code
org 100h
locals @@

Start:
        cld
        mov bx, VideoMemSegment     ; set es to the beginnig of video mem segment
        mov es, bx

        mov di, CMD_args_start      ; pointer to command line arguments

        call SkipSpaces

        call atoi10                 ; read frame length
        mov cx, ax

        call SkipSpaces

        call atoi10                 ; read frame height
        mov dx, ax

        call SkipSpaces

        push dx
        call atoi10
        pop dx

        mov ah, al

        call SkipSpaces

        push dx
        call atoi10
        push ax

        mov dl, 9
        mul dl

        mov si, offset Sequence
        add si, ax

        pop ax
        pop dx

        call CalcFrameStart

        mov ah, 04h                 ; frame color

        push di
        call DrawFrame
        pop di


        ;add di, 0A0h
        ;add di, 0A0h
        ;add di, 0A0h
        ;add di, 0A0h
        ;add di, 020h
        ;mov ah, 03h
        ;mov si, offset String

        ;call WriteString

        ;mov di, offset String
        ;call Strlen

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

        call DrawLine
        add si, 03h

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
; Moves di until ds:[di] is a non-space character
; Entry:    di - pointer to video mem for beginning of the string
; Exit:     None
; Destr:    di, al
;=============================================================================================================
SkipSpaces   proc

        mov al, ' '
        dec di

test_condition_SkipSpace:
        inc di
        cmp ds:[di], al
        je test_condition_SkipSpace

        ret
        endp

;=============================================================================================================
; Writes a string ending with '$' in video mem
; Entry:    ah - color
;           si - pointer to a string
;           di - pointer to video mem for beginning of the string
; Exit:     None
; Destr:    cx, si, di
;=============================================================================================================
WriteString proc

        mov cl, 00h

test_condition_WriteString:
        cmp ds:[si], cl    ; while (ds:[si] != '$')
        je while_end

        lodsb               ; al = ds:[si++]
        stosw               ; es:[di] = ax, di+=2
        jmp test_condition_WriteString

while_end:

        ret
        endp

;=============================================================================================================
; Counts length of null terminated string
; Entry:    di - pointer to a string
; Exit:     cx - length of the string
; Destr:    al, si, cx
;=============================================================================================================
Strlen  proc

        push es
        mov ax, ds
        mov es, ax

        xor ax, ax
        cld
        mov cx, -1

        repne scasb
        neg cx
        dec cx

        pop es

        ret
        endp

;=============================================================================================================
; Reads 10-based number from 0 to 255 from a string and saves to al
; Entry:    di - pointer to a string with number
; Exit:     al - number extracted from string
; Destr:    di, ax, dx, bl
;=============================================================================================================
atoi10  proc

        xor ax, ax
        xor dx, dx
        mov dh, '0'
        mov bl, 0Ah     ; 0Ah - radix of 10 digit system

test_condition_atoi10:        ; while (ds:[di] - '0' < 10) { ax = ax * 10 + [di] - '0'}
        mul bl
        add al, dl

        mov dl, ds:[di]
        sub dl, dh

        inc di
        cmp dl, 0Ah             ; ?  0 <= dl < 10
        jb test_condition_atoi10

        ret
        endp

;=============================================================================================================
; Reads 16-based number from 0 to 255 from a string and saves to al
; Entry:    di - pointer to a string with number
; Exit:     ax - number extracted from string
; Destr:    di, ax, dx
;=============================================================================================================
atoi16  proc

        xor ax, ax
        xor dx, dx
        mov dh, '0'

test_condition_atoi16:  ; while (ds:[di] - '0' < 10) { ax = ax * 10 + [di] - '0'}
        shl al, 4
        add al, dl

        mov dl, ds:[di]
        sub dl, dh

        inc di
        cmp dl, 10h             ; 10h - radix of 16 digit system
        jb test_condition_atoi16

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

String:     db 'Hello there?', 00h, '!!!NOTFORPRINT!!!'


end     Start
