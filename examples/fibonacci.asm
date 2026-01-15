; Fibonacci sequence calculator
; Calculates first 10 Fibonacci numbers and stores them in memory

START:
    LOADI R1, 0        ; F(0) = 0
    LOADI R2, 1        ; F(1) = 1
    LOADI R3, 0        ; Counter
    LOADI R4, 10       ; Limit (10 numbers)
    LOADI R5, 0        ; Memory address counter
    
    ; Store F(0)
    STORE R1, [0]
    
    ; Store F(1)
    ADD R5, R5, 1
    STORE R2, [1]
    
LOOP:
    ; Calculate next Fibonacci number: F(n) = F(n-1) + F(n-2)
    ADD R6, R1, R2     ; R6 = F(n-1) + F(n-2)
    
    ; Store result
    ADD R5, R5, 1
    STORE R6, [R5]
    
    ; Update for next iteration
    MOV R1, R2         ; F(n-2) = F(n-1)
    MOV R2, R6         ; F(n-1) = F(n)
    
    ; Increment counter
    ADD R3, R3, 1
    
    ; Check if done
    CMP R3, R4
    JNZ LOOP           ; Continue if counter < limit
    
    HALT
