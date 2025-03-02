.model tiny
.code
.386
org 100h
locals @@

Start:
        call Authorization

        mov ah, 4ch				; DOS Fn 4ch = exit(al)
        int 21h					; DOS Fn 21h = system(ah)

BuffSize        equ     10h
CanarySize      equ     04h

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

        sub sp, Buffsize

        call Set_Canary_Protect

        mov bx, sp

        mov ch, 0Dh + BuffSize + 2
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

        add sp, Buffsize

        mov bx, offset Authorization_flag
        mov cs:[bx], 1
        ; call check Canary protection

        ret
        endp

Signing_Message         db 'Enter Password: ', 0Dh
Wrong_Password_Message  db 'Wrong Password! Access denied', 0Ah, 0Dh
Access_Message          db 'Welcome, tryhard! May the force be with you...', 0Ah, 0Dh

Authorization_flag      db 0

;======================================================================================================
; Set Canary protection on the last 4 bytes in buffer of previous stack frame
; Therefore calling function must reserve Buffsize bytes before Setting Canary Protection
; Entry: None
; Exit:  None
; Dstr: bx, cl, si
;======================================================================================================
Set_Canary_Protect  proc

        ; save ret adress for this func, otherwise it will be overwritten as placed in mem under sp
        mov bx, sp
        mov word ptr cx, ss:[bx]
        mov word ptr cs:[offset Ret_Ad_saved], cx

        ; 2 bytes are already in stack frame of this func as return adress
        ; 2 + Buffsize is alredy a ret adress of previous func
        ; bx == sp will be used as a cond for the end of setting canary
        add sp, 2 + Buffsize - 1 - CanarySize
        add bx, 2 + Buffsize - 1

        mov si, offset Canary
        add si, CanarySize  - 1         ; Writing Canary backwards

@@for_cond_check:
        cmp bx, sp
        je @@for_end

        mov cl, cs:[si]
        mov ss:[bx], cl                 ; while (bx != sp) { ss[bx--] = cs[si--]; }
        dec bx
        dec si

        jmp @@for_cond_check

@@for_end:
        ; restore sp
        sub sp, 2 + Buffsize - 1 - CanarySize
        sub bx, 2 + Buffsize - 1 - CanarySize

        ; restore ret adress
        mov word ptr si, offset Ret_Ad_saved
        mov word ptr cx, cs:[si]
        mov word ptr ss:[bx], cx

        ret
        endp

Ret_Ad_saved    dw 0
Canary          db 'jinn'

end     Start
