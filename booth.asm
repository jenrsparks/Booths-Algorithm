.MODEL SMALL
.STACK 100h
.DATA
;-----------------------------------------------------
;			  VARIABLES
;-----------------------------------------------------

Intro db 10,13,10,13,'     Booths Algorithm (AX:16-DX:16-AX/DX:32)',10,13,10,13,'     14/14-27-bit Multiplication  Q-Key to exit',10,13,10,13,'                                                      Bit Patterns',10,13,'                                                 ----------------------','$'
Prompt db 10,13,'     Please enter (0..9999) >> $'
flag db 0
TEN dw 10
temp dw 0
var1 dw 0
var2 dw 0
posval dw 0
negval dw 0
bit dw 0

;-----------------------------------------------------
;			END VARIABLES
;-----------------------------------------------------

;-----------------------------------------------------
;			  MACROS
;-----------------------------------------------------

GetChar MACRO
	mov ax, 0
	mov ah, 08h
	int 21h
ENDM

;-----------------------------------------------------

DisplayChar MACRO
	mov ah, 02h
	add dl, 48
	int 21h
ENDM

;-----------------------------------------------------

DisplayMessage MACRO ms
	mov ah, 09h
	mov dx, OFFSET ms
	int 21h
ENDM

;-----------------------------------------------------
;			END MACROS
;-----------------------------------------------------

.CODE

;-----------------------------------------------------
;			  MAIN
;-----------------------------------------------------

Start:

	mov ax, @data
	mov ds,ax

	mov ah,00h   ;Clear screen
	mov al,02h
	int 10h

	DisplayMessage Intro
Input:
	DisplayMessage Prompt
	mov cx, 0
Values:
	GetChar
	cmp al, 13		; Enter key pressed
	je Check
	inc cx
	mov ah, 0		; decontaminate ax
	push ax
	mov dx, ax		; print character
	sub dx, 48
	DisplayChar

	cmp cx, 4
	jl Values
Check:	
	cmp flag, 0
	jne Second
	
First:
	call AtoI
	mov ax, temp
	mov var1, ax
	push var1
	
	; move cursor over
	mov ah, 03h
	int 10h
	mov ah, 02h
	mov dl, 51
	int 10h
	
	mov flag, 1
	call ItoB
	
	mov ah, 02h
	mov dl, 13
	int 21h
		
	jmp Input
Second:

	call AtoI
	mov ax, temp
	mov var2, ax
	push var2

	; move cursor over
	mov ah, 03h
	int 10h
	mov ah, 02h
	mov dl, 51
	int 10h

	call ItoB

	mov ah, 02h
	mov dl, 13
	int 21h

; Start Calculations

;	call Booth

	jmp EOF

;-----------------------------------------------------
;			  PROCEDURES
;-----------------------------------------------------

ItoA PROC
	pop si
	ItoALoop:
		mov dx,0
		div TEN       ;Product in DX+AX
		push dx       ;DX:Remainder
		inc cx
		cmp ax,0
	jne ItoALoop
	push si
	ret
ItoA ENDP

;-----------------------------------------------------

AtoI PROC
	pop si
	mov temp, 0
	mov bx, 1
	AtoILoop:
		pop ax
		sub ax, 48
		mul bx
		add temp, ax
		
		; mul dx by 10
		mov ax, 10
		mul bx
		mov bx, ax

		loop AtoILoop
	push si
	ret
AtoI ENDP

;-----------------------------------------------------

;	Make sure original value is on the top of
;	the stack, ie, the integer, not character

ItoB PROC
	pop si
	pop ax
	
	mov cx, 16
	mov dx, 01h		; dx = 1
	Bin:
		mov dx, 01h
		push ax
		and ax, dx	; ax = current bit
		pop dx		; save number from stack
		push ax
		mov ax, dx	; restore ax
		shr ax, 1	; go to next bit
	loop Bin

	mov cx, 16
	mov bx, 0
PrintB:
	pop dx
	inc bx
	DisplayChar
	cmp bx, 4
	jne PrintBNext
	mov bx, 0
	mov dl, ' '
	sub dl, 48
	DisplayChar
PrintBNext:
loop PrintB

	push si
	ret

ItoB ENDP

;-----------------------------------------------------

Booth PROC

	Booth:					; loop through size of places
		pop ax					; n2
		pop posval				; n1

		mov dx, posval		; value of first number
		not dx				; 2's comp of num1
		add dx, 1
		mov negval, dx

		cmp bit, 0
		je sec1a
		jmp sec1b

		sec1a:
			mov bx, 01h
			and ax, bx
			cmp ax, 1		; tests for 10 => (ax)1(bit)0
			je subnum			; 10
			jmp shr1		; 00



		sec1b:
			mov bx, 01h
			and ax, bx
			cmp ax, 0		; tests for 01 => (ax)0(bit)1
			je addnum		; 01
			jmp shr1		; 11
		; loop through size of places		

		subnum:
			; add num2 (2's comp of num1)
			jmp shr1

		addnum:
			; add num1
			jmp shr1		; not neccessary if it's directly above

		shr1:
			shr ax, 1

		shr2:
			shr ax, 1
			or ax, 8000h

		shrd1:
			shr ax, 1

		shrd2:
			shr ax, 1
			or dx, 8000h

		shr3:
			mov bx, 01h		; getting last bit
			push dx
			and dx, bx

			cmp dx, 0
			je shr1			; good to go; don't need to change a thing
			jmp shr2		; change first bit to 1

		sec2:
			mov [bit], ax	; move value of ax into bit variable

		msb:				; checking most significant bit
			and dx, 8000h
			cmp dx, 0
			jne shrd2
			jmp shrd1

		negmsb:
			add ax, 8000h	; make msb a negative / 1
Booth ENDP

;-----------------------------------------------------
;			END PROCEDURES
;-----------------------------------------------------

EOF:
	mov ah, 4ch
	int 21h
	END Start

;-----------------------------------------------------
;			END MAIN
;-----------------------------------------------------