; Assembly Enigma Machine
section .data
    ; ------------------- Data Section ---------------------
    alpha DB     'ABCDEFGHIJKLMNOPQRSTUVWXYZ'
    ;------------ 5 ROTORS------------------ NOTCH--TURN OVER--
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
    ;Configure an enigma machine
    enimga_refelctor equ refelctor_B
    enigma_rotor_1   equ rotor_III
    enigma_rotor_2   equ rotor_II
    enigma_rotor_3   equ rotor_I

    ;--------- END CONFIG

    getStringMsg DB 'Enter a string : ', '$'
    result DB 'ENIGMA output  : ', '$'
    newline DB 0AH, 0DH, '$'
    farewellMessage DB 0AH, 0DH,'Have a good day !...', 0AH, 0DH, 'Written in x16 Assembly by ZAM',0AH, 0DH, '$'

    bufferSize equ 255
    inputBuffer DB bufferSize
    inputSize   DB 0
                times bufferSize DB '$'

    r1 DW enigma_rotor_1
    r1_offset DW 0
    r1_turnNext DB 0

    r2 DW enigma_rotor_2
    r2_offset DW 0
    r2_turnNext DB 0

    r3 DW enigma_rotor_3
    r3_offset DW 0
    r3_turnNext DB 0

section .text
    ; ------------------- Code Section ---------------------
    ORG 100H        ; COM file's entry point
    CALL main
    exit:
        MOV AH, 09H
        LEA DX, [newline]
        INT 21H
        LEA DX, [farewellMessage]
        INT 21H
        RET
        MOV AX, 4C00H
        INT 21H

    ; ------------------- Procedure Definitions ---------------------

    ; Initializes the game and displays the welcome message
    main:
        ; call simulate_enigma
        CALL getUserInput
        MOV CL, [inputSize]
        LEA BX, [inputBuffer + 2]
        loop_forEachChar:
            CALL simulate_enigma
            INC BX
            DEC CL
            JNZ loop_forEachChar
        MOV AH, 09H
        LEA DX, [result]
        INT 21H
        LEA DX, [inputBuffer + 2]
        INT 21H
        RET

    getUserInput:
            ;get input from user
            MOV AH, 09H
            LEA DX, [getStringMsg]
            INT 21H

            MOV AH, 0AH
            LEA DX, [inputBuffer]
            INT 21H

            MOV AH, 09H
            LEA DX, [newline]
            INT 21H
            RET
    simulate_enigma:
        ; INPUT ADDRESS OF CURRENT CHAR in BX
        PUSH CX
        MOV AL, [BX]
        PUSH BX
        ; Check if the character is an alphabet character
        cmp al, 'A'
        jl not_alpha
        cmp al, 'Z'
        jbe alpha_valid
        cmp al, 'a'
        jl not_alpha
        cmp al, 'z'
        jbe alpha_valid
        jmp not_alpha

        alpha_valid:
        ; CONVERT TO UPPER CASE
        CALL toUpperCase
        PUSH AX ; store AL to STACK

        ;CYCLE ROTOR 1
        LEA SI, [r1]
        CALL cycleRotor

        ; CHECK FOR DOUBLE STEP ON SECOND ROTOR
        LEA SI, [r2]
        MOV DI, [SI]
        MOV BX, [SI + 2]

        MOV AH, [alpha + BX]
        MOV AL, [DI + 26]
        ; IF ROTOR_2 NOTCH IS ACTIVE
        TEST AL, AH
        JNE skip_rotate
            CALL cycleRotor
        skip_rotate:

        ; check all 2 rotors and if turn next is enable advance the next rotor by 1
        MOV CX, 2
        LEA SI, [r1]
        loop_stepRotors:
            MOV AL, [SI + 4]
            CMP AL, 1
            JNE skip_cycleNext
                MOV [SI + 4], BYTE 0
                ADD SI, 5 ; SET NEXT ROTOR ADDRESS
                CALL cycleRotor
            skip_cycleNext:
            DEC CX
            JNZ loop_stepRotors

        POP AX ;get the input stored back
        ; PASS THRU ALL ROTORS FORWARD
        MOV CX, 3
        LEA SI, [r1]
        loop_passRF:
            CALL passRotorForward
            ADD SI, 5 ; NEXT ROT
            DEC CX
            JNZ loop_passRF
        ; PASS THRU REFELECTOR
        CALL passRefelector
        ; PASS THRU ALL ROTROS REVERSE
        MOV CX, 3
        LEA SI, [r3]
        loop_passRR:
            CALL passRotorReverse
            SUB SI, 5 ; NEXT ROT
            DEC CX
            JNZ loop_passRR
        not_alpha:
        POP BX
        MOV [BX], AL
        POP CX
        ; RETURN BX, CX back
        RET

    passRefelector:
        ; INPUT AL plain-text char
        LEA BX, [alpha]
        CALL getIndexofChar
        MOV SI, enimga_refelctor
        MOV AL, [SI + BX]
        RET

    passRotorForward:
        ; INPUT AL plain-text char
        ; INPUT SI rotor address

        MOV BX, alpha
        CALL getIndexofChar

        MOV DI, [SI]
        ADD BX, [SI + 2]
        CALL indexCorrection
        MOV AL, [DI + BX]
        MOV BX, alpha
        CALL getIndexofChar
        ADD BX, 26
        SUB BX, [SI + 2]
        CALL indexCorrection
        MOV AL, [alpha + BX]

        ; RETURN  AL cipher-text char
        RET

    passRotorReverse:
        ; INPUT AL cypher-text char
        ; INPUT SI rotor address
        MOV BX, alpha
        CALL getIndexofChar

        ADD BX, [SI + 2]
        CALL indexCorrection
        MOV AL, [alpha + BX]
        MOV BX, [SI]
        CALL getIndexofChar
        ADD BX, 26
        SUB BX, [SI + 2]
        CALL indexCorrection
        MOV AL, [alpha + BX]
        ; RETURN AL plain-text char
        RET

    cycleRotor:
        ;INPUT SI rotor 
        PUSH AX
        MOV DI, [SI]
        MOV BX, [SI + 2]
        INC BX
        CMP BX, 26
        JL skip
            CALL indexCorrection
        skip:
        MOV [SI + 2], BX
        ; if base[offset] == turnover set r1 rotate next 1
        MOV AH, [alpha + BX]
        MOV AL, [DI + 27]
        CMP AH, AL
        JNE skip1
        MOV [SI + 4], BYTE 1 ; set turn next to 1
        skip1:
        POP AX
        RET

    indexCorrection:
        ; INPUT BX Value
        PUSH DX ; for some reason these need to be ZERO
        MOV DX, 0
        MOV AX, BX
        MOV BX, 26
        CMP AX, 0
        JZ if_zero
        DIV BX
        MOV BX, DX
        JMP return
        if_zero:
        MOV BX, 0
        return:
        POP DX
        RET
        ; RET BX result

    toUpperCase:
        ; INPUT char stored in AL

        ; Check if the character is a lowercase letter
        CMP AL, 'a'
        JL not_lowercase
        CMP AL, 'z'
        JG not_lowercase

        SUB Al, 32
        not_lowercase
        RET
        ; RETURN UPPER CASE CHAR IN AL

    getIndexofChar:
        ; INPUT BX points to string to find index from.
        ; INPUT AL char to be check
        PUSH SI
        MOV SI, 0
        loop_check:
            MOV AH, [BX + SI]
            CMP AH, AL
            JE break
            INC SI
            CMP SI, 26
            JNZ loop_check
        break:
        ; SI contains offset
        MOV BX, SI
        POP SI
        RET
        ; RETURN OFFSET IN BX
