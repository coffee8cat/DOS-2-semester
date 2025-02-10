.model tiny
.code
org 100h

Start:      mov bx, 0b800h              ; beginnig of video mem segment
            mov es, bx
            mov di, 0200h
            mov si, offset Sequence

            mov cx, 10h
            mov ah, 04h                 ; line color
            call DrawLine

            mov cx, 10h
            shl cx, 1
            add di, 0A0h
            sub di, cx
            shr cx, 1
            call DrawLine

            mov cx, 10h
            shl cx, 1
            add di, 0A0h
            sub di, cx
            shr cx, 1
            call DrawLine

            mov ah, 4ch				; DOS Fn 4ch = exit(al)
            int 21h					; DOS Fn 21h = system(ah)
;=============================================================================================================
; Draws line described with 3 bytes in video mem
; 1 time first byte, (cx-2) times - second byte and then third byte
; 121 (cx = 6) => 122221
; Entry:    ah - color
;           si - pointer to 3 byte sequence
;           cx - length of the frame
; Exit:     None
; Destr:    si, cx
;=============================================================================================================
DrawLine    proc

            dec cx
            dec cx

            lodsb       ; reading first byte of sequance to al
            stosw       ; writing to video mem

            lodsb       ; reading second byte
            rep stosw   ; writing (cx - 2) times to video mem

            lodsb       ; reading first byte of sequance to al
            stosw       ; writing to video mem

            ret
            endp

Sequence: db '123456789'

end     Start
