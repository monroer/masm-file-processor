TITLE Intern error-corrector     (proj6_monroer.asm)

; Author: Riley Monroe
; Last Modified: 3/16/2025
; OSU email address: monroer@oregonstate.edu
; Course number/section:   CS271 Section 400
; Project Number:   6              Due Date: 3/16/2025
; Description: This program reads temperature measurements from a file,
;              converts the ASCII values to integers, and prints them in reverse order.
;              The program implements macros for I/O and procedures for parsing
;              and displaying temperatures using string primitives.


INCLUDE Irvine32.inc

; (insert macro definitions here)

; (insert constant definitions here)

TEMPS_PER_DAY = 24
BUFFER_SIZE = 8192
MAX_FILENAME = 128
DELIMITER = ','


; ---------------------------------------------------------------------------------
; Name: mGetString
;
; Displays a prompt and gets user input.
;
; Preconditions: none
;
; Receives:
; promptAddr = address of prompt message
; inputAddr = address to store user input
; maxLength = maximum length of input allowed
; bytesRead = address to store number of bytes read
;
; Returns: inputAddr = user input string
;          bytesRead = number of bytes read
; ---------------------------------------------------------------------------------

mGetString MACRO promptAddr:REQ, inputAddr:REQ, maxLength:REQ, bytesRead:REQ
	push	edx						; save registers
	push	ecx
	push	eax

	mov		edx, promptAddr			; display prompt
	call	WriteString

	mov		edx, inputAddr			; set up for read string
	mov		ecx, maxLength
	call	ReadString

	mov		edi, bytesRead			; store bytes read
	mov		[edi], eax

	pop		eax						; restore registers
	pop		ecx
	pop		edx
ENDM

; ---------------------------------------------------------------------------------
; Name: mDisplayString
;
; Prints a string from a specified memory location.
;
; Preconditions: none
;
; Receives:
; stringAddr = address of string to print
;
; Returns: none
; ---------------------------------------------------------------------------------

mDisplayString MACRO stringAddr:REQ
	push	edx						; save register

	mov		edx, stringAddr			; priont string
	call	WriteString

	pop		edx						; restore register
ENDM

; ---------------------------------------------------------------------------------
; Name: mDisplayChar
;
; Prints an ascii character.
;
; Preconditions: none
;
; Receives:
; char = character to print 
;
; Returns: none
; ---------------------------------------------------------------------------------

mDisplayCharacter MACRO char:REQ
	push	eax						; save register

	mov		al, char				; print character
	call	WriteChar

	pop		eax						; restore register
ENDM


.data

; (insert variable definitions here)

	programTitle	db "Intern error-corrector",13,10,0
	programDesc		db "I'll read and reverse a ','-delimited ascii file storing a series of temperature values and provide the corrected temperature ordering as a printout!",13,10,0
	promptFilename	db "Please enter the filename: ",0
	errorOpenFile	db "Error: Could not open the file.",13,10,0
	errorReadFile	db "Error: Could not read from the file.",13,10,0
	resultMsg		db "Temperature values in reverse order:",13,10,0
	goodbyeMsg		db "Thanks for using the Intern error-corrector. Goodbye!",13,10,0
	
	filename		db MAX_FILENAME DUP(0)
	fileBuffer		db BUFFER_SIZE DUP (0)
	fileHandle		dd ?
	bytesRead		dd ?
	tempCount		dd ?
	temperatures	sdword TEMPS_PER_DAY DUP(0)
	

.code
main PROC

; (insert executable instructions here)

	;display program title and description
	mDisplayString	OFFSET programTitle
	mDisplayString	OFFSET programDesc
	call			CrLf

	; get file name from user
	mGetString		OFFSET promptFilename, OFFSET filename, MAX_FILENAME, OFFSET bytesRead
	call			CrLf

	; open file
	mov				edx, OFFSET filename
	call			OpenInputFile
	mov				fileHandle, eax

	; check if file opened successfully
	cmp				eax, INVALID_HANDLE_VALUE
	jne				_fileOpenSuccess
	mDisplayString	OFFSET errorOpenFile
	jmp				_programExit

_fileOpenSuccess:
	; read file into buffer
	mov				edx, OFFSET fileBuffer
	mov				ecx, BUFFER_SIZE - 1
	call			ReadFromFile
	jnc				_fileReadSuccess

	; handle file read error
	mDisplayString	OFFSET errorReadFile
	push			fileHandle
	call			CloseFile
	jmp				_programExit

_fileReadSuccess:
	; store bytes read
	mov				bytesRead, eax

	; add null terminator to file buffer
	mov				edi, OFFSET fileBuffer
	add				edi, eax
	mov				byte PTR [edi], 0

	; close the file
	push			fileHandle
	call			CloseFile

	; parse temps from file buffer
	push			OFFSET temperatures
	push			OFFSET fileBuffer
	call			ParseTempsFromString

	; display results header
	call			CrLf
	mDisplayString	OFFSET resultMsg

	; write temps in reverse order
	push			OFFSET temperatures
	call			WriteTempsReverse

	;display goodbye message
	call			CrLf
	mDisplayString	OFFSET goodbyeMsg

_programExit:
	exit

	Invoke ExitProcess,0	; exit to operating system
main ENDP

; (insert additional procedures here)


; ---------------------------------------------------------------------------------
; Name: ParseTempsFromString
;
; Converts string temperature values to numeric values using string primitives.
;
; Preconditions: fileBuffer contains ASCII temperature values separated by DELIMITER
;
; Postconditions: none
;
; Receives:
; [ebp+12] = reference to fileBuffer
; [ebp+8] = reference to temperature array
;
; Returns: temperature array filled with converted values
; ---------------------------------------------------------------------------------

ParseTempsFromString PROC
	LOCAL currentTemp:sdword
	LOCAL isNegative:byte

	push		ebp
	mov			ebp, esp
	pushad								; save all registers

	; set up source and destination pointers
	mov			esi, [ebp+12]			; fileBuffer source
	mov			edi, [ebp+8]			; temperature array destination
	xor			ecx, ecx

_parseNextTemp:
	;check if reached max number of temps
	cmp			ecx, TEMPS_PER_DAY
	jae			_doneParsing

	; initialize for new temp
	mov			currentTemp, 0			; reset current temp value
	mov			isNegative, 0			; reset negative flag

	lodsb

	; skip leading whitespace and check for end of file
	cmp			al, ' '					; check for space
	je			_parseNextTemp			
	cmp			al, 9					; chekc for tab
	je			_parseNextTemp			
	cmp			al, 13					; check for carriage return
	je			_parseNextTemp			
	cmp			al, 10					; check for line feed
	je			_parseNextTemp			
	
	; check fior end of string
	cmp			al, 0
	je			_doneParsing

	
	; check for negative sign
	cmp 		al, '-'					; see if negative
	jne			_notNegative			; if not check if digit
	mov			isNegative, 1			; set neg flag
	lodsb

_notNegative:
	;process digits

_digitLoop:
	cmp			al, '0'
	jb			_notDigit
	cmp			al, '9'
	ja			_notDigit

	;convert ascii to numeric value
	sub			al, '0'					; convert ascii to numeric
	movzx		eax, al					; zero eztend al to eax

	; multiply current value by 10 and add new digit
	mov			ebx, currentTemp
	imul		ebx, 10
	add			ebx, eax
	mov			currentTemp, ebx

	; get next char
	lodsb
	jmp			_digitLoop

_notDigit:
	;apply sign in neg
	cmp			isNegative, 0
	je			_storeTemp
	neg			currentTemp

_storeTemp:
	;store temp in array
	mov			eax, currentTemp
	mov			[edi], eax
	add			edi, TYPE sdword		; move to next array element
	inc			ecx

	; check if current char is delimiter
	cmp			al, DELIMITER
	jne			_parseNextTemp		; if not delimiter, may be end of data

	; check if end of string
	cmp			al, 0				; check for end of string
	je			_doneParsing

	jmp			_skipToDelimiter


_skipToDelimiter:
	; skip to next delimiter or end of file
	lodsb
	cmp			al, 0					; check for end of file
	je			_doneParsing			; if end of file, done
	cmp			al ,DELIMITER			;check for delimiter
	jne			_skipToDelimiter		; if not delimiter, go past

	jmp			_parseNextTemp			; continue skipping

_doneParsing:
	popad								; restore all registers
	pop			ebp
	ret			8						; clean up stack (2 * 4 bytes)

ParseTempsFromString ENDP


; ---------------------------------------------------------------------------------
; Name: WriteTempsReverse
;
; Prints the temperature values in reverse order.
;
; Preconditions: Temperature array contains valid temperature values
;
; Postconditions: none
;
; Receives:
; [ebp+8] = reference to temperature array
;
; Returns: none
; ---------------------------------------------------------------------------------

WriteTempsReverse PROC
	push		ebp
	mov			ebp, esp
	pushad								; save all registers

	; start from end of array
	mov			esi, [ebp+8]			; get address of temp array
	mov			ecx, TEMPS_PER_DAY		; set counter
	mov			eax, TYPE sdword		; size of each element
	mul			ecx						; calculate total array size
	dec			ecx						; adjust counter for 0 based indexing
	add			esi, eax				; point to end of array
	sub			esi, TYPE sdword		; point to last element

	; print temps in reverse order
_printReverse:
	; print current temp
	mov			eax, [esi]
	call		WriteInt

	; check if more temps
	dec			ecx
	jl			_DoneWriting

	; print delimiter and continue
	mDisplayCharacter DELIMITER
	sub			esi, TYPE sdword		; move to previous element
	jmp			_printReverse

_doneWriting:
	call		CrLf

	popad								; restore all regiosters
	pop			ebp
	ret			4						; clean up stack (1 * 4 bytes)

WriteTempsReverse ENDP


END main
