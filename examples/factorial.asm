; Factorial calculator
; Calculates n! (n factorial) for n = 0 to 7
; Stores results in memory starting at address 0x20

START:
    LOADI R1, 0        ; n = 0 (current number)
    LOADI R2, 7        ; max_n = 7 (maximum to calculate)
    LOADI R3, 0x20     ; Memory address for results
    LOADI R4, 1        ; factorial = 1 (0! = 1)
    
    ; Store 0! = 1
    STORE R4, [R3]
    ADD R3, R3, 1      ; Increment address
    
LOOP:
    ; Calculate n! = n * (n-1)!
    ; R4 currently holds (n-1)!
    ADD R1, R1, 1      ; n = n + 1
    MUL R4, R1, R4     ; factorial = n * factorial
    ; Note: MUL stores lower 8 bits in R4, upper 8 bits in R5
    
    ; Store result
    STORE R4, [R3]
    ADD R3, R3, 1      ; Increment address
    
    ; Check if done
    CMP R1, R2
    JNZ LOOP           ; Continue if n < max_n
    
    HALT

; Results stored in memory:
; 0x20: 1  (0! = 1)
; 0x21: 1  (1! = 1)
; 0x22: 2  (2! = 2)
; 0x23: 6  (3! = 6)
; 0x24: 24 (4! = 24)
; 0x25: 120 (5! = 120, but 8-bit = 120)
; 0x26: 208 (6! = 720, but 8-bit = 208 due to overflow)
; 0x27: 80  (7! = 5040, but 8-bit = 80 due to overflow)
