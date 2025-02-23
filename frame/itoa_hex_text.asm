.model tiny
.code
.386
org 100h
locals @@

Start:

RegSize equ 02h

        mov bx, VideoMemSegment
        mov es, bx

        mov di, 80 * 2 * 5 + 80

        mov ax, 1234h
        call itoa_hex
        int 21h

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

VideoMemSegment equ     0b800h

end Start
