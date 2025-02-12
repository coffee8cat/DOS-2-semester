.model tiny
.code
org 100h

Start:      cld
            mov bx, 0b800h              ; beginnig of video mem segment
            mov es, bx

            mov cx, 30h                 ; frame length
            mov dx, 10h                 ; frame height

            call CalcFrameStart

            mov ah, 04h                 ; frame color
            mov si, offset Sequence

            push di
            call DrawFrame
            pop di


            add di, 0A0h
            add di, 0A0h
            add di, 0A0h
            add di, 0A0h
            add di, 020h
            mov ah, 03h
            mov si, offset String

            call WriteString

            mov di, offset String
            call Strlen

            mov di, offset AtoiTest
            call atoi10

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
; Writes a string ending with '$' in video mem
; Entry:    ah - color
;           si - pointer to a string
;           di - pointer to video mem for beginning of the string
; Exit:     None
; Destr:    cx, si, di
;=============================================================================================================
WriteString proc

; condition check
            mov cl, 00h

condition:  cmp ds:[si], cl    ; while (ds:[si] != '$')
            je while_end

            lodsb               ; al = ds:[si++]
            stosw               ; es:[di] = ax, di+=2
            jmp condition

while_end:

            ret
            endp

;=============================================================================================================
; Countes length of string ending with '$'
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
;        xor ax, ax
;        xor cx, cx
;        dec di

;test_condition: ; while(ds:[di] != ax) { di++ }
;
;        inc di
;        inc cx
;        cmp ds:[di], al
;        jne test_condition

;        dec cx

        ret
        endp

;=============================================================================================================
; Countes length of string ending with '$'
; Entry:    di - pointer to a string with number
; Exit:     ax - number extracted from string
; Destr:    di, ax, dx
;=============================================================================================================
atoi10  proc

        xor ax, ax
        xor dx, dx
        mov dh, '0'
        mov bl, 0Ah

test_condition2:  ; while (ds:[di] - '0' < 10) { ax = ax * 10 + [di] - '0'}
        mul bl
        add al, dl

        mov dl, ds:[di]
        sub dl, dh

        inc di
        cmp dl, 0Ah
        jb test_condition2

        ret
        endp


AtoiTest:   db '123b'

Sequence:   db '123456789'

String:     db 'Hello there?', 00h, '!!!NOTFORPRINT!!!'


end     Start
