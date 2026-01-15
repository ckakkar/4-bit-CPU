; Tribonacci sequence generator
; Similar to Fibonacci but each number is sum of previous 3
; T(0) = 0, T(1) = 0, T(2) = 1
; T(n) = T(n-1) + T(n-2) + T(n-3)
; Generates first 15 Tribonacci numbers

START:
    LOADI R1, 0        ; T(0) = 0
    LOADI R2, 0        ; T(1) = 0
    LOADI R3, 1        ; T(2) = 1
    LOADI R4, 0x70     ; Memory address
    LOADI R5, 0        ; Counter
    LOADI R6, 15       ; Number of terms to generate
    
    ; Store first three terms
    STORE R1, [R4]     ; T(0) = 0
    ADD R4, R4, 1
    STORE R2, [R4]     ; T(1) = 0
    ADD R4, R4, 1
    STORE R3, [R4]     ; T(2) = 1
    ADD R4, R4, 1
    LOADI R5, 3        ; Counter = 3 (already stored 3 terms)
    
TRIBONACCI_LOOP:
    ; Calculate next term: T(n) = T(n-1) + T(n-2) + T(n-3)
    ADD R7, R1, R2     ; R7 = T(n-3) + T(n-2)
    ADD R7, R7, R3     ; R7 = T(n-3) + T(n-2) + T(n-1)
    
    ; Store result
    STORE R7, [R4]
    ADD R4, R4, 1
    
    ; Update for next iteration
    MOV R1, R2         ; T(n-3) = T(n-2)
    MOV R2, R3         ; T(n-2) = T(n-1)
    MOV R3, R7         ; T(n-1) = T(n)
    
    ; Increment counter
    ADD R5, R5, 1
    CMP R5, R6
    JNZ TRIBONACCI_LOOP
    
    HALT

; Tribonacci sequence (0x70-0x7E):
; 0, 0, 1, 1, 2, 4, 7, 13, 24, 44, 81, 149, 274, 504, 927
; Note: Some values may overflow 8-bit range
