.model tiny
.code
.386
org 100h
locals @@

Start:
        call Authorization

EOP:
        mov ah, 4ch				; DOS Fn 4ch = exit(al)
        int 21h					; DOS Fn 21h = system(ah)

BuffSize        equ     10h
CanarySize      equ     04h

;======================================================================================================
; Authorization function will pass user if password is correct
; Entry: None
; Exit:  None
; Dstr:  ax, bx, cx, dx, si
;======================================================================================================
Authorization   proc

@@while_start:

        mov si, offset StringOff
        mov cs:[si], offset Signing_Message
        call PrintString

        call getns

        mov si, offset Authorization_flag
        mov byte ptr bl, cs:[si]
        xor bh, bh
        cmp bl, bh
        jne @@while_end

        mov si, offset StringOff
        mov cs:[si], offset Wrong_Password_Message
        call PrintString

        jmp @@while_start

@@while_end:

        mov si, offset StringOff
        mov cs:[si], offset Access_Message

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
; Get a line from standart input no longer than 18 symbols (excluding '0Dh') ending with '0Dh'.
; Reading will be stopped after 18th symbol
; Entry: None
; Exit:  None
; Dstr:  ax, bx, cx, si
;======================================================================================================
getns   proc

        call SetTimerVulnerability

        mov bx, sp
        dec bx                          ; otherwise ret adress will be overwritten
        sub sp, Buffsize

        mov ah, BuffSize
        xor al, al

@@for_cond_check:
        cmp ah, al
        je @@for_end

        mov ss:[bx], al                 ; set to 0 all buffer
        dec bx
        dec ah

        jmp @@for_cond_check
@@for_end:

        call Set_Canary_Prot

        mov bx, sp

        mov ch, 0Dh + BuffSize + 2
        mov cl, 0Dh                 ; enter char - end of input

@@loop_cond_check:

        cmp ch, cl                  ; if (ch == cl) {break;}
        je @@loop_end               ; meaning that Buffsize + 2 iterations proceeded

        mov ah, 01h                 ; getchar() => al
        int 21h

        cmp al, cl                  ; if (al == '0Dh') { break; }
        je @@loop_end

        mov ss:[bx], al             ; write al to buffer
        inc bx

        dec ch                      ; dec iteration counter
        jmp @@loop_cond_check

@@loop_end:

        call Check_Canary_Prot

        xor cl, cl
        mov si, offset Canary_Prot_Dstr
        cmp byte ptr cs:[si], cl
        jne  EOP

        mov cx, ss
        mov es, cx
        mov di, sp
        mov si, offset time
        mov cx, 0005h
        rep cmpsb                                       ; while(ds:[di++] == es:[si++] && cx--) {}
        je @@Access_granted

        call DJB2_hash
        mov si, offset Password_hash
        cmp word ptr bx, cs:[si]                        ; check password hash
        jne @@Access_denied

@@Access_granted:

        mov si, offset Authorization_flag
        xor cl, cl
        inc cl
        mov cs:[si], cl                                 ; set Authorization flag to 1

@@Access_denied:
        add sp, Buffsize

        ret
        endp

Signing_Message         db 'Enter Password: ', 0Dh
Wrong_Password_Message  db 'Wrong Password! Access denied', 0Ah, 0Dh
Access_Message          db 'Welcome, tryhard! May the force be with you...', 0Ah, 0Dh

Password_hash           db 62h, 0Dh     ; skywalker
Authorization_flag      db 0

;======================================================================================================
; Set Canary protection on the last 4 bytes in buffer of previous stack frame
; Therefore calling function must reserve Buffsize bytes before Setting Canary Protection
; Entry: None
; Exit:  None
; Dstr: ax, bx, cl, si
;======================================================================================================
Set_Canary_Prot  proc

        ; 2 bytes are already in stack frame of this func as return adress
        ; 2 + Buffsize is alredy a ret adress of previous func
        ; bx == sp will be used as a cond for the end of setting canary
        mov bx, sp
        add bx, 2 + Buffsize - 1

        xor ax, ax
        mov ah, CanarySize

        mov si, offset Canary
        add si, CanarySize  - 1         ; Writing Canary backwards

        ; for (ah = CanarySize; ah > 0; ah--) { ss[bx--] = cs[si--]; }
@@for_cond_check:
        cmp ah, al
        je @@for_end

        mov cl, cs:[si]
        mov ss:[bx], cl
        dec bx
        dec si
        dec ah

        jmp @@for_cond_check

@@for_end:

        ret
        endp

Canary  db 'yoda'

;======================================================================================================
; Check Canary protection on the last 4 bytes in buffer of previous stack frame
; Therefore calling function must reserve Buffsize bytes before Setting Canary Protection
; Entry: None
; Exit:  None
; Dstr: ax, bx, cl, si
;======================================================================================================
Check_Canary_Prot  proc

        ; 2 bytes are already in stack frame of this func as return adress
        ; 2 + Buffsize is alredy a ret adress of previous func
        ; bx == sp will be used as a cond for the end of setting canary
        mov bx, sp
        add bx, 2 + Buffsize - 1

        xor ax, ax
        mov ah, CanarySize

        mov si, offset Canary
        add si, CanarySize  - 1         ; Writing Canary backwards

        ; for (ah = CanarySize; ah > 0; ah--)
        ; {
        ;     if (ss[bx--] != cs[si--]) { Canary_Prot_Dstr = 1; break; }
        ; }
@@for_cond_check:
        cmp ah, al
        je @@for_end

        mov cl, cs:[si]
        cmp ss:[bx], cl
        jne @@Canary_Prot_Dstr

        dec bx
        dec si
        dec ah

        jmp @@for_cond_check

@@Canary_Prot_Dstr:
        mov si, offset Canary_Prot_Dstr
        mov byte ptr cs:[si], 1

@@for_end:

        ret
        endp

Canary_Prot_Dstr        db 0

;======================================================================================================
; 16 bit djb2 hash of buffer of previous func
; Entry: None
; Exit:  bx - hash calculated
; Dstr: ax, bx, cx, si
;======================================================================================================
DJB2_hash       proc

        mov si, sp
        add si, 2

        xor al, al
        mov ah, BuffSize - CanarySize           ; max expected length of string
        mov bx, 1505h                           ; initial const for hash

; while (ah-- > al) { bx = bx * 33 + ss:[si++]}
@@cond_check:

        cmp ah, al
        je @@while_end

        xor ch, ch
        mov cl, ss:[si]                         ; cx = ss:[si]
        add cx, bx
        shl bx, 5
        add bx, cx

        inc si
        dec ah
        jmp @@cond_check

@@while_end:

        mov si, offset hash_sum                 ; saving hash sum
        mov cs:[si], bx

        ret
        endp

hash_sum        dw 0

;======================================================================================================
; Allows to pass authorization by entering time at the moment
; Entry: None
; Exit:  bx - hash calculated
; Dstr: ax, cx, dx, si
;======================================================================================================
SetTimerVulnerability   proc

        mov ah, 02h
        int 1ah

        mov si, offset time

        mov ax, cx
        shr ax, 4
        shr al, 4
        add ax, 3030h           ; al + '0', ah + '0'

        mov cs:[si], ah
        inc si
        mov cs:[si], al
        inc si

        mov cs:[si], ':'
        inc si

        mov ax, cx
        shl ax, 4
        shl ah, 4
        shr ah, 4
        shr al, 4
        add ax, 3030h           ; al + '0', ah + '0'

        mov cs:[si], ah
        inc si
        mov cs:[si], al

        ret
        endp

time    db 0, 0, 0, 0, 0

end     Start
