.model tiny
.code
.386
org 100h
locals @@

Start:
        call Authorization

        mov ah, 4ch				; DOS Fn 4ch = exit(al)
        int 21h					; DOS Fn 21h = system(ah)

;======================================================================================================
;
; Entry: None
; Exit:  None
; Dstr:  ax, dx, si
;======================================================================================================
Authorization   proc

@@while_start:


        mov bx, offset StringOff
        mov cs:[bx], offset Signing_Message
        call PrintString

        call getns

        mov bx, offset Authorization_flag
        mov byte ptr bl, cs:[bx]
        xor bh, bh
        cmp bl, bh
        jne @@while_end

        mov bx, offset StringOff
        mov cs:[bx], offset Wrong_Password_Message
        call PrintString

        jmp @@while_start

@@while_end:

        mov bx, offset StringOff
        mov cs:[bx], offset Access_Message

        call PrintString

        ret
        endp

;======================================================================================================
; Prints a string ending with '0Dh' to standart output
; Entry: None
; Exit:  None
; Dstr:  ax, dx, si
;======================================================================================================
PrintString   proc

        mov ah, 06h             ; DOS Fn 06h = Console I/O(dl)
        mov word ptr si, StringOff
        mov dh, 0Dh

@@loop_cond_check:

        mov dl, cs:[si]

        cmp dl, dh              ; if (dl == '0Dh') { break; }
        je @@loop_end

        int 21h                 ; send dl to Console Output
        inc si

        jmp @@loop_cond_check

@@loop_end:

        ret
        endp

StringOff   dw 0

;======================================================================================================
; Get a line from standart input no longer than 16 symbols (excluding '0Dh') ending with '0Dh'
; Entry: None
; Exit:  None
; Dstr:  ax, cl, si
;======================================================================================================
getns   proc

        push sp
        sub sp, 10h

        mov bx, sp

        mov ch, 1Eh     ; 13 + 17
        mov cl, 0Dh                 ; enter char - end of input

@@loop_cond_check:

        cmp al, cl                  ; if (al == '0Dh') { break; }
        je @@loop_end

        cmp ch, cl                  ; if (ch == cl) {break;}
        je @@loop_end               ; meaning that 17 iterations proceeded

        mov ah, 01h                 ; getchar() => al
        int 21h

        mov ss:[bx], al             ; write al to buffer
        inc bx

        dec ch                      ; dec iteration counter
        jmp @@loop_cond_check

@@loop_end:

        add sp, 10h
        pop sp

        mov bx, offset Authorization_flag
        mov cs:[bx], 1
        ; call check Canary protection

        ret
        endp

Signing_Message         db 'Enter Password: ', 0Dh
Wrong_Password_Message  db 'Wrong Password! Access denied', 0Ah, 0Dh
Access_Message          db 'Welcome, tryhard! May the force be with you...', 0Ah, 0Dh

Authorization_flag      db 0

end     Start
