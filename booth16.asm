.MODEL SMALL
.STACK 100h
.DATA
;-----------------------------------------------------
;			  VARIABLES
;-----------------------------------------------------

Intro db 10,13,10,13,'     Booths Algorithm (AH:8-AL:8-AX:16)',10,13,10,13,'     7/7-14-bit Multiplication  Q-Key to exit',10,13,10,13,'                                                      Bit Patterns',10,13,'                                                 ----------------------','$'
Prompt db 10,13,'     Please enter (0..127) >> $'
result db 10,13,'     Result: $'
stepping db 10,13,'     Show Stepping? y/n >> $'
flag db 0
TEN dw 10
temp dw 0
var1 dw 0
var2 dw 0
posval db 0
negval db 0
bit db 0
tempSi dw 0
size dw 4

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

PrintChar MACRO char
	mov ah, 02h
	mov dl, char
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
	mov ah, 0
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
	
	jmp Input
Second:

	call AtoI
	mov ax, temp
	mov ah, 0
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

; print results
	DisplayMessage result
	mov ax, var1
	call ItoA
	PrintChar '*'
	mov ax, var2
	call ItoA
	PrintChar '='
	mov ax, var1
	mul var2
	push ax
	call ItoA

	; printing values
	mov ah, 03h		; move cursor over
	int 10h
	mov ah, 02h
	mov dl, 51
	int 10h
	mov size, 8
	call ItoB

; Start Calculations

	DisplayMessage stepping
	GetChar
	cmp al, 'y'
	je ShowStepping
	cmp al, 'Y'
	je ShowStepping
	jmp EOF
	
ShowStepping:
	call Booth
	
	jmp EOF

;-----------------------------------------------------
;			  PROCEDURES
;-----------------------------------------------------

; value in AX

ItoA PROC
	pop si
	ItoALoop:
		mov dx,0
		div TEN       ;Product in DX+AX
		push dx       ;DX:Remainder
		inc cx
		cmp ax,0
	jne ItoALoop
	
	ItoAPrint:
		pop dx
		add dx, 48
		mov ah, 02h
		int 21h
	loop ItoAPrint
		
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
	pop tempSi
	pop ax
	
	mov cx, size
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

	mov cx, size
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

	push tempSi
	ret

ItoB ENDP

;-----------------------------------------------------

Booth PROC
	pop si

	mov ah, 03h		; move cursor over
	int 10h
	mov ah, 02h
	inc dh			; new line
	mov dl, 51
	int 10h
	
	mov size, 8		; how many binary bits
	mov cx, 8		; counter
	mov bit, 0

	mov ax, var2		; set values of pos & neg
	mov posval, al
	not ax
	inc ax
	mov negval, al

	mov ax, var1		; put ax on top of stack
	push ax
	
	BoothLoop:

	PrintBits:
		pop ax
		push cx			; save registers
		push ax
		push ax			; extra copy for printing

		; printing values
		mov ah, 03h		; move cursor over
		int 10h
		mov ah, 02h
		inc dh			; new line
		mov dl, 51
		int 10h

		call ItoB
		
		mov ah, 02h
		mov dl, bit
		add dl, 48
		int 21h

		pop ax			; restore registers
		pop cx

		cmp bit, 0
		je EvenBit
		jmp OddBit

	EvenBit:
		push ax
		and al, 01h
		cmp al, 0
		jne Add
		jmp ShiftRight

	OddBit:
		push ax
		and al, 01h
		cmp al, 0
		jne Subtract
		jmp ShiftRight
	Add:
		pop ax
		add ah, posval
		push ax

		jmp ShiftRight

	Subtract:
		pop ax
		add ah, negval
		push ax
		jmp ShiftRight

	ShiftRight:
		and al, 1
		mov bit, al

		pop ax			; shift right 1
		shr ax, 1
		push ax
		
		mov dh, ah		; keep MSB
		and dh, 80h
		pop ax
		add ah, dh
		
		push ax
		dec cx
	cmp cx, 0
	jne BoothLoop

	push ax
	; printing values
	mov ah, 03h		; move cursor over
	int 10h
	mov ah, 02h
	inc dh			; new line
	mov dl, 51
	int 10h
	pop ax
	push ax

	call ItoB


	push si
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