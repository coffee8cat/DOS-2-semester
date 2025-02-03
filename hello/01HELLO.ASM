.model tiny
.code
org 100h

Start: 		mov ah, 09h		; DOS Fn 09h = puts(dx)
		mov dx, offset Meow	; dx = &Meow
		int 21h			; DOS Fn 21h = system(ah)

		mov ah, 4ch		; DOS Fn 4ch = exit(al)
		int 21h			; DOS Fn 21h = system(ah)

Meow:		db 'MEOW$' 		; Meow = "MEOW$"

end		Start