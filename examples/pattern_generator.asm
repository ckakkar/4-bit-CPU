; Pattern generator
; Generates interesting number patterns
; Pattern 1: Powers of 2 (2^0, 2^1, 2^2, ...)
; Pattern 2: Triangular numbers (1, 3, 6, 10, 15, ...)
; Pattern 3: Square numbers (1, 4, 9, 16, 25, ...)

START:
    ; Pattern 1: Powers of 2
    LOADI R1, 0x30     ; Memory address for powers of 2
    LOADI R2, 1        ; Current power (2^0 = 1)
    LOADI R3, 0        ; Exponent counter
    LOADI R4, 8        ; Max exponent
    
POWERS_LOOP:
    STORE R2, [R1]     ; Store current power
    ADD R1, R1, 1      ; Increment address
    SHL R2, R2, 1      ; R2 = R2 * 2 (shift left = multiply by 2)
    ADD R3, R3, 1      ; Increment counter
    CMP R3, R4
    JNZ POWERS_LOOP
    
    ; Pattern 2: Triangular numbers
    ; T(n) = n * (n+1) / 2
    LOADI R1, 0x40     ; Memory address for triangular numbers
    LOADI R2, 1        ; n = 1
    LOADI R3, 10       ; Max n
    LOADI R4, 0        ; Previous triangular number
    
TRIANGULAR_LOOP:
    ADD R5, R4, R2     ; T(n) = T(n-1) + n
    STORE R5, [R1]     ; Store triangular number
    ADD R1, R1, 1      ; Increment address
    MOV R4, R5         ; Save for next iteration
    ADD R2, R2, 1      ; n = n + 1
    CMP R2, R3
    JNZ TRIANGULAR_LOOP
    
    ; Pattern 3: Square numbers
    ; n^2 for n = 1 to 10
    LOADI R1, 0x50     ; Memory address for squares
    LOADI R2, 1        ; n = 1
    LOADI R3, 10       ; Max n
    
SQUARES_LOOP:
    MUL R4, R2, R2     ; R4 = n * n
    STORE R4, [R1]     ; Store square
    ADD R1, R1, 1      ; Increment address
    ADD R2, R2, 1      ; n = n + 1
    CMP R2, R3
    JNZ SQUARES_LOOP
    
    HALT

; Results:
; Powers of 2 (0x30-0x37): 1, 2, 4, 8, 16, 32, 64, 128
; Triangular (0x40-0x49): 1, 3, 6, 10, 15, 21, 28, 36, 45, 55
; Squares (0x50-0x59): 1, 4, 9, 16, 25, 36, 49, 64, 81, 100
