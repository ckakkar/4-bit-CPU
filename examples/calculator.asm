; Simple calculator
; Performs basic arithmetic operations
; Operations: ADD, SUB, MUL, DIV
; Stores results in memory

START:
    ; Example: Calculate (10 + 5) * 3 - 2
    
    ; Step 1: 10 + 5 = 15
    LOADI R1, 10
    LOADI R2, 5
    ADD R3, R1, R2     ; R3 = 15
    STORE R3, [0x60]   ; Store intermediate result
    
    ; Step 2: 15 * 3 = 45
    LOADI R4, 3
    MUL R5, R3, R4     ; R5 = 45 (lower 8 bits)
    STORE R5, [0x61]   ; Store result
    
    ; Step 3: 45 - 2 = 43
    LOADI R6, 2
    SUB R7, R5, R6     ; R7 = 43
    STORE R7, [0x62]   ; Store final result
    
    ; Example 2: Division
    ; Calculate 20 / 4 = 5
    LOADI R1, 20
    LOADI R2, 4
    DIV R3, R1, R2     ; R3 = 5 (quotient), R4 = 0 (remainder)
    STORE R3, [0x63]   ; Store quotient
    STORE R4, [0x64]   ; Store remainder
    
    ; Example 3: Complex expression
    ; Calculate (8 * 7) + (12 / 3) = 56 + 4 = 60
    LOADI R1, 8
    LOADI R2, 7
    MUL R3, R1, R2     ; R3 = 56
    
    LOADI R1, 12
    LOADI R2, 3
    DIV R4, R1, R2     ; R4 = 4 (quotient)
    
    ADD R5, R3, R4     ; R5 = 60
    STORE R5, [0x65]   ; Store result
    
    HALT

; Memory results:
; 0x60: 15  (10 + 5)
; 0x61: 45  (15 * 3)
; 0x62: 43  (45 - 2)
; 0x63: 5   (20 / 4 quotient)
; 0x64: 0   (20 / 4 remainder)
; 0x65: 60  ((8*7) + (12/3))
