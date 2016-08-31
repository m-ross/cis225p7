TITLE	lab07
; Programmer:	Marcus Ross
; Due:		16 April, 2014
; Description:	This program takes input from the keyboard in the form of a string of characters no greater than 32 characters in length and analyzes the brackets therein to report whether any brackets are unpaired.

		.MODEL SMALL
		.386
		.STACK 128
;==========================
		.DATA
head		DB	'Expression Evaluator', 0ah, 0dh, '64 characters maximum', 0ah, 0dh, 'Leave blank and press enter to exit', 0ah, 0dh, 24h
prompt	DB	'Enter text to evaluate: ', 24h
input		DB	40h, 41h DUP(0)	; 40h = 64 bytes of input; 41h DUP(0) to hold: 1st byte = number of bytes inputted + 63 chars + 1 CR
newLine	DB	0ah, 0dh, 24h	; CR, LF, $
roundCt	DB	0			; keep count of round brackets
squareCt	DB	0			; keep count of square brackets
curlyCt	DB	0			; keep count of curly brackets
msgStart	DB	'Unmatched ', 24h
roundO	DB	'open round', 24h
squareO	DB	'open square', 24h
curlyO	DB	'open curly', 24h
roundC	DB	'closed round', 24h
squareC	DB	'closed square', 24h
curlyC	DB	'closed curly', 24h
msgEnd	DB	' bracket.', 0ah, 0dh, 24h
validMsg	DB	'Expression is valid.', 0ah, 0dh, 24h
valid		DB	0			; value remaining at 0 means expression was valid
;==========================
		.CODE
Main		PROC	NEAR
		mov	ax, @data		; init data
		mov	ds, ax		; segment register

		call	dispHead		; display header

begin:	call	getInput		; get string from keyboard
		cmp	[input + 2], 0dh	; check first char of input
		je	exit			; goto end if input = carriage return
		call	evalInput		; evaluate input
		jmp	begin			; loop

exit:		mov	ax, 4c00h		; return code 0
		int	21h
Main		ENDP
;==========================
dispErr	MACRO	bracket
		mov	dx, OFFSET msgStart
		mov	ah, 09h
		int	21h		; display start of message
		mov	dx, OFFSET bracket
		int	21h		; display name of bracket
		mov	dx, OFFSET msgEnd
		int	21h		; display end of message
		inc	valid
		ENDM
;==========================
disphead	PROC	NEAR
		mov	dx, OFFSET head
		mov	ah, 09h
		int	21h		; display header
		ret
		ENDP
;==========================
getInput	PROC	NEAR
		mov	dx, OFFSET prompt
		mov	ah, 09h
		int	21h		; display prompt
		mov	dx, OFFSET input
		mov	ah, 0ah
		int	21h		; get string of chars and put at OFFSET input
		mov	dx, OFFSET newLine
		mov	ah, 09h
		int	21h		; display new line
		ret
		ENDP
;==========================
evalInput	PROC	NEAR
		mov	bx, 2h		; offset of first char in input

loop1:	mov	al, [input + bx]	; prep char @ +bx for comparing
		cmp	al, '('		; check if char is '('
		je	rO			; if true, skip other checks
		cmp	al, '['		; check if char is '['
		je	sO			; if true, skip other checks
		cmp	al, '{'		; check if char is '{'
		je	cO			; if true, skip other checks
		cmp	al, ')'		; check if char is ')'
		je	rC			; if true, skip other checks
		cmp	al, ']'		; check if char is ']'
		je	sC			; if true, skip other checks
		cmp	al, '}'		; check if char is '}'
		je	cC			; if true, skip other check
		cmp	al, 0dh		; check if char is carriage return
		je	done			; if true, done looping b/c at last char
		jmp	loop1end		; if not bracket or CR, goto end of loop

rO:		inc	roundCt		; increment round brackets count
		jmp	isOpen

sO:		inc	squareCt		; increment square brackets count
		jmp	isOpen

cO:		inc	curlyCt		; increment curly brackets count
		jmp	isOpen

rC:		cmp	sp, 3eh		; check if any brackets are on stack
		je	rC3			; if not, skip ahead to display error
		pop	ax			; pop open bracket to see if it matches round
		cmp	al, '('
		jne	rC1			; if not '(', skip ahead
		dec	roundCt
		jmp	loop1end
rC1:		cmp	al, '['
		jne	rC2
		dec	squareCt		; if '[', display error and dec counter
		dispErr squareO
		jmp	rC3
rC2:		cmp	al, '{'
		jne	loop1end
		dec	curlyCt		; if '{', display error and dec counter
		dispErr curlyO
rC3:		dispErr roundC		; display error b/c matching round brackets were not found
		mov	roundCt, 0		
		jmp	loop1end

sC:		cmp	sp, 7eh		; check if any brackets are on stack
		je	sC3			; if not, skip ahead to display error
		pop	ax			; pop open bracket to see if it matches round
		cmp	al, '['
		jne	sC1			; if not '[', skip ahead
		dec	squareCt
		jmp	loop1end
sC1:		cmp	al, '('
		jne	sC2
		dec	roundCt		; if '(', display error and dec counter
		dispErr roundO
		jmp	sC3
sC2:		cmp	al, '{'
		jne	loop1end
		dec	curlyCt		; if '{', display error and dec counter
		dispErr curlyO
sC3:		dispErr squareC		; display error b/c matching square brackets were not found
		mov	squareCt, 0
		jmp	loop1end

cC:		cmp	sp, 7eh		; check if any brackets are on stack
		je	cC3			; if not, skip ahead to display error
		pop	ax			; pop open bracket to see if it matches round
		cmp	al, '{'
		jne	cC1			; if not '{', skip ahead
		dec	curlyCt
		jmp	loop1end
cC1:		cmp	al, '('
		jne	cC2
		dec	roundCt		; if '(', display error and dec counter
		dispErr roundO
		jmp	cC3
cC2:		cmp	al, '['
		jne	loop1end
		dec	squareCt		; if '[', display error and dec counter
		dispErr squareO
cC3:		dispErr curlyC		; display error b/c matching curly brackets were not found
		mov	curlyCt, 0
		jmp	loop1end

isOpen:	xor	ah, ah		; ax = al
		push	ax			; push open bracket

loop1end:	inc	bx			; increment offset for next char
		jmp	loop1			; begin loop

done:		cmp	sp, 7eh		; check if any brackets are on stack
		je	checkValid		; if not, done evaluating
		pop	ax			; pop one bracket at a time to display errors

		cmp	al, '('
		jne	done1
		dispErr roundO		; display error for each open round bracket still on stack
		jmp	done
done1:	cmp	al, '['
		jne	done2
		dispErr squareO		; display error for each open square bracket still on stack
		jmp	done
done2:	cmp	al, '{'
		jne	done
		dispErr curlyO		; display error for each open curly bracket still on stack
		jmp	done

checkValid:	cmp	valid, 0		; if valid = 0, no error messages were displayed
		jne	notValid
		mov	dx, OFFSET validMsg
		mov	ah, 09h
		int	21h

notValid:	mov	valid, 0		; reset valid for next run
		mov	dx, OFFSET newLine
		mov	ah, 09h
		int	21h			; display new line
		ret
		ENDP
;==========================
	END	Main