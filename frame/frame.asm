.model tiny
.code
org 100h

Start:      mov bx, 0b800h              ; beginnig of video mem segment
            mov es, bx

            mov ah, 04h                 ; frame color
            mov di, 0200h               ; frame start position in video mem
            mov si, offset Sequence
            mov cx, 10h                 ; frame length
            mov dx, 06h                 ; frame height

            call DrawFrame

            mov ah, 4ch				; DOS Fn 4ch = exit(al)
            int 21h					; DOS Fn 21h = system(ah)

;=============================================================================================================
; Draws a frame in video mem described with 9 bytes
; Entry:    ah - color
;           si - pointer to 9 byte sequence
;           cx - length of the frame
;           dx - height of the frame
; Exit:     None
; Destr:    al, si, dx, di
;=============================================================================================================
DrawFrame   proc

            call DrawLine
            add si, 03h

            dec dx
            dec dx
height:
            call DrawLine
            dec dx
            cmp dx, 0h
            ja height

            add si, 03h

            call DrawLine
            add si, 03h

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

Sequence: db '123456789'

end     Start
