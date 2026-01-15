; Collatz Conjecture sequence generator
; For any number n:
;   - If n is even: n = n / 2
;   - If n is odd: n = 3*n + 1
; The sequence always reaches 1 (conjecture, not proven)
; Generates sequence for a given starting number

START:
    LOADI R1, 7        ; Starting number (try different values!)
    LOADI R2, 0xC0     ; Memory address for sequence
    LOADI R3, 0        ; Step counter
    LOADI R4, 50       ; Max steps (safety limit)
    LOADI R5, 2        ; For division by 2
    LOADI R6, 3        ; For multiplication by 3
    
    ; Store starting number
    STORE R1, [R2]
    ADD R2, R2, 1
    ADD R3, R3, 1
    
COLLATZ_LOOP:
    ; Check if n == 1 (sequence complete)
    CMP R1, 1
    JZ DONE
    
    ; Check if n is even (n % 2 == 0)
    ; We can check by: if (n & 1) == 0, then even
    LOADI R7, 1
    AND R7, R1, R7     ; R7 = n & 1
    CMP R7, 0
    JZ EVEN
    
    ; n is odd: n = 3*n + 1
    MUL R1, R1, R6     ; n = n * 3
    ADD R1, R1, 1      ; n = n + 1
    JMP STORE_RESULT
    
EVEN:
    ; n is even: n = n / 2
    DIV R1, R1, R5     ; n = n / 2 (quotient)
    ; Note: For even numbers, remainder is always 0
    
STORE_RESULT:
    STORE R1, [R2]     ; Store current value
    ADD R2, R2, 1      ; Increment address
    ADD R3, R3, 1      ; Increment step counter
    
    ; Safety check
    CMP R3, R4
    JZ DONE            ; Stop if too many steps
    
    JMP COLLATZ_LOOP
    
DONE:
    HALT

; Example sequences:
; Starting with 7: 7, 22, 11, 34, 17, 52, 26, 13, 40, 20, 10, 5, 16, 8, 4, 2, 1
; Starting with 6: 6, 3, 10, 5, 16, 8, 4, 2, 1
; Starting with 5: 5, 16, 8, 4, 2, 1
