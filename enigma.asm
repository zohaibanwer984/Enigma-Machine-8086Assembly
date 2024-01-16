; Enigma Machine Simulation
; Written in NASM Assembly For 8086
; BY @zohaibanwer984

section .data
    ; ------------------- Data Section ---------------------

    ;------------ 5 ROTORS--------------------NOTCH--TURN OVER--
    ; BASE       'ABCDEFGHIJKLMNOPQRSTUVWXYZ'
    rotor_I   DB 'EKMFLGDQVZNTOWYHXUSPAIBRCJ', 'Q', 'R'
    rotor_II  DB 'AJDKSIRUXBLHWTMCQGZNPYFVOE', 'E', 'F'
    rotor_III DB 'BDFHJLCPRTXVZNYEIWGAKMUSQO', 'V', 'W'
    rotor_IV  DB 'ESOVPZJAYQUIRHXLNFTGKDCMWB', 'J', 'K'
    rotor_V   DB 'VZBRGITYUPSDNHLXAWMJQOFECK', 'Z', 'A'
    ;------ reflectors 
    ; BASE         'ABCDEFGHIJKLMNOPQRSTUVWXYZ'
    refelctor_A DB 'EJMZALYXVBWFCRQUONTSPIKHGD'
    refelctor_B DB 'YRUHQSLDPXNGOKMIEBFZCWVJAT'
    refelctor_C DB 'FVPJIAOYEDRZXWGCTKUQSBNMHL'

    ;--------- CONFIG

    ; Configure enigma machine reflector
    enimga_refelctor equ refelctor_B
    ; Configure enigma machine rotors
    enigma_rotor_1   equ rotor_III
    enigma_rotor_2   equ rotor_II
    enigma_rotor_3   equ rotor_I
    ; Configure rotor intial offset
    rotor_1_offset equ 0
    rotor_2_offset equ 0
    rotor_3_offset equ 0

    ;--------- END CONFIG

    ; Alphabet string
    alpha DB     'ABCDEFGHIJKLMNOPQRSTUVWXYZ'

    ; Messages and Prompts
    getStringMsg DB 'Enter a string : ', '$'
    result DB 'ENIGMA output  : ', '$'
    newline DB 0AH, 0DH, '$'
    farewellMessage DB 0AH, 0DH,'Have a good day !...', 0AH, 0DH, 'Written in x16 Assembly by ZAM',0AH, 0DH, '$'

    ; Buffer for store User input
    bufferSize equ 255
    inputBuffer DB bufferSize
    inputSize   DB 0
                times bufferSize DB '$'

    ; Enigma Rotor Pointers
    r1 DW enigma_rotor_1 ; Rotor 1
    r1_offset DW rotor_1_offset
    r1_turnNext DB 0

    r2 DW enigma_rotor_2 ; Rotor 2
    r2_offset DW rotor_2_offset
    r2_turnNext DB 0

    r3 DW enigma_rotor_3 ; Rotor 3
    r3_offset DW rotor_3_offset
    r3_turnNext DB 0

section .text
    ; ------------------- Code Section ---------------------
    ORG 100H        ; COM file's entry point
    CALL main       ; Call main procedure
    exit:
        ; Print farewell
        MOV AH, 09H
        LEA DX, [newline]
        INT 21H
        LEA DX, [farewellMessage]
        INT 21H
        ; return to DOS
        MOV AX, 4C00H
        INT 21H

    ; ------------------- Procedure Definitions ---------------------
    main:
        ; Handles user input pass process through enigma
        ; print the result back

        ; Get User input
        CALL getUserInput
        ; Loop thur Each character in buffer
        MOV CL, [inputSize]
        LEA BX, [inputBuffer + 2]
        loop_forEachChar:
            CALL simulate_enigma
            INC BX
            DEC CL
            JNZ loop_forEachChar
        ; Prints the result
        MOV AH, 09H
        LEA DX, [result]
        INT 21H
        LEA DX, [inputBuffer + 2]
        INT 21H
        RET

    getUserInput:
        ; Get User Input and stores in input buffer

        ; Prints input prompt
        MOV AH, 09H
        LEA DX, [getStringMsg]
        INT 21H
        ; DOS Operation to get string input
        MOV AH, 0AH
        LEA DX, [inputBuffer]
        INT 21H
        ; Prints newline
        MOV AH, 09H
        LEA DX, [newline]
        INT 21H
        RET

    simulate_enigma:
        ; Gets char pass through the enigma and stores the result
        ; INPUT  : Address of current char in BX register
        ; RETURN : None

        PUSH CX       ; Push CX to stack to reserve counter used by main
        MOV AL, [BX]  ; Load the char to AL
        PUSH BX       ; Push address of current char on stack
        ; Check if the character is an alphabet character
        CMP AL, 'A'
        JL not_alpha    ; If not a valid skip
        CMP AL, 'Z'
        JBE alpha_valid ; If valid continue
        CMP AL, 'a'
        JL not_alpha
        CMP AL, 'z'
        JBE alpha_valid
        not_alpha:
            JMP skip_toResult
        alpha_valid:
        ; Convert input to upper case
        CALL toUpperCase
        PUSH AX     ; Store AL to STACK
        ; Cycle first rotor once
        LEA SI, [r1]
        CALL cycleRotor
        ; Check if second rotor need to rotor
        LEA SI, [r2]         ; Load second rotor pointer address
        MOV DI, [SI]         ; Load second rotor address
        MOV BX, [SI + 2]     ; Load offset value in BX
        MOV AH, [alpha + BX] ; Load char from alpha[offset]
        MOV AL, [DI + 26]    ; Load notch char of rotor
        CMP AL, AH           ; Check if notch is active
        JNE skip_rotate
            CALL cycleRotor  ; Cycle second rotor
        skip_rotate:
        ; Check first two rotors and if turn next is enable advance the next rotor by 1
        MOV CX, 2
        LEA SI, [r1]
        loop_stepRotors:
            MOV AL, [SI + 4]          ; Load rotor nextTurn flag
            TEST AL, 1                ; Check flag
            JNE skip_cycleNext        ; Skip if flag not active
                MOV [SI + 4], BYTE 0  ; Clear flag 
                ADD SI, 255           ; Set next rotor pointer in SI
                CALL cycleRotor       ; Cycle the next rotor
            skip_cycleNext:
            DEC CX
            JNZ loop_stepRotors
        ; Get stored input back from stack to AL
        POP AX
        ; Loop all each rotor and pass the input
        MOV CX, 3
        LEA SI, [r1]              ; Load first rotor pointer
        MOV BH, 0                 ; Clear BH cause BX is needed
        MOV BL, AL                ; Copy the char to BL
        SUB BL, 41H               ; Substract ASCII value of 'A' to get index of char in BX
        loop_passRF:
            CALL passRotorForward ; Pass the char
            ADD SI, 5             ; Load next rotor pointer in SI
            DEC CX
            JNZ loop_passRF       ; Repeat until CX is zero
        MOV AL, [alpha + BX]      ; Convert the index back to char
        ; Now pass the char through refelector
        CALL passRefelector
        ; Loop back through all each rotor in reverse order and pass the char
        MOV CX, 3
        LEA SI, [r3]              ; Load last rotor pointer
        MOV BH, 0                 ; Clear BH cause BX is needed
        MOV BL, AL                ; Copy the char to BL
        SUB BL, 41H               ; Substract ASCII value of 'A' to get index of char index in BX
        loop_passRR:
            CALL passRotorReverse ; Pass the char
            SUB SI, 5             ; Load next rotor pointer in SI
            DEC CX
            JNZ loop_passRR       ; Repeat until CX is zero
        MOV AL, [alpha + BX]      ; Convert the index back to char
        skip_toResult:
        ; Stores the processed char back to its destination 
        POP BX         ; Restore the current char address into BX
        MOV [BX], AL   ; Update the char
        POP CX         ; Retorse the CX from Stack
        RET

    passRefelector:
        ; Pass the char through selected Refelector
        ; INPUT  : Input char in AL
        ; RETURN : Resultant char in AL

        MOV BH, 0                  ; Clear BH cause BX is needed
        MOV BL, AL                 ; Copy the char to BL
        SUB BL, 41H                ; Substract ASCII value of 'A' to get index of char in BX
        MOV SI, enimga_refelctor   ; Load the refelector address in SI
        MOV AL, [SI + BX]          ; Get the char from refelector[index]
        RET

    passRotorForward:
        ; Pass the char left to right through selected rotor
        ; INPUT  : Index value in BX & rotor address pointer in SI
        ; RETURN : New index value in BX

        MOV DI, [SI]             ; Load the cipher string address into DI
        ADD BX, [SI + 2]         ; Add rotor offset into index
        CALL indexCorrection     ; Index % 26
        MOV BL, [DI + BX]        ; Load char from cipher[index]
        SUB BL, 41H              ; substract ASCII value of 'A' to get index in BX
        MOV BH, 0                ; clear BH cause BX is needed
        ADD BX, 26               ; Add index + 26
        SUB BX, [SI + 2]         ; Substract offset from index
        CALL indexCorrection     ; Index % 26
        RET

    passRotorReverse:
        ; Pass the char right to left through selected rotor
        ; INPUT  : Index value in BX & rotor address pointer in SI
        ; RETURN : New index value in BX

        ADD BX, [SI + 2]         ; Add rotor offset into index
        CALL indexCorrection     ; Index % 26
        MOV AL, [alpha + BX]     ; Load char from alpha[index]
        MOV BX, [SI]             ; Load cipher string address into BX
        CALL getIndexofChar      ; Convert char to index in BX
        ADD BX, 26               ; Add index + 26
        SUB BX, [SI + 2]         ; Substract offset from index
        CALL indexCorrection     ; Index % 26
        RET

    cycleRotor:
        ; Rotate the current rotor on step if notch is active set turnNext flag
        ; INPUT : Rotor pointer in SI
        ; RETURN : None

        PUSH AX                 ; Reserve AX to stack
        MOV DI, [SI]            ; Load rotor address into DI
        MOV BX, [SI + 2]        ; Load offset value into BX
        INC BX                  ; Increament offset
        CALL indexCorrection    ; Offset % 26
        MOV [SI + 2], BX        ; Store the offset
        MOV AH, [alpha + BX]    ; Load char from alpha[offset] in AH
        MOV AL, [DI + 27]       ; Load char from rotor notch in AL
        CMP AH, AL              ; Check if both char are equal
        JNE skip_increment      ; If not equl skip next instruction
        MOV [SI + 4], BYTE 1    ; Set turnNext flag to 1
        skip_increment:
        POP AX                  ; Restore AX from stack
        RET

    indexCorrection:
        ; Do modulus by 26 on BX
        ; INPUT  : Value in BX
        ; RETURN : Resultant value in BX

        PUSH DX      ; Reserve DX to stack
        MOV DX, 0    ; Clear DX before operation
        MOV AX, BX   ; Store the value in AX
        MOV BX, 26   ; Load 26 in BX
        CMP AX, 0    ; Check if value is zero 
        JZ if_zero   ; Skip division if zero
        DIV BX       ; Divide the value by 26
        MOV BX, DX   ; Store remainder in BX
        JMP return   ; Jump to return
        if_zero:
        MOV BX, 0    ; Set value to 0
        return:
        POP DX       ; Restore DX from stack
        RET

    toUpperCase:
        ; Convert char to uppercase in AL
        ; INPUT  : char stored in AL
        ; RETURN : uppercase char in AL

        ; Check if the character is a lowercase letter
        CMP AL, 'a'
        JL not_lowercase
        CMP AL, 'z'
        JG not_lowercase
        SUB Al, 32
        not_lowercase
        RET

    getIndexofChar:
        ; Gets index value of char in given string
        ; INPUT   : Address of string in BX & char in AL
        ; RETURNS : Index value in BX

        PUSH SI                 ; Reserve SI to stack
        ;loop through each char in string
        MOV SI, 0               ; Clear the SI
        loop_check:
            MOV AH, [BX + SI]   ; Load char from string[offset] in AL
            CMP AH, AL          ; Compare input char and string char
            JE break            ; Break loop if equal
            INC SI              ; Increament offset
            CMP SI, 26          ; Check if offset
            JL loop_check       ; Loop until offset is less then 26
        break:
        MOV BX, SI              ; store index value in BX
        POP SI                  ; restore SI from stack
        RET
