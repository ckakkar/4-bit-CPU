; Sieve of Eratosthenes - Prime number finder
; Finds all primes from 2 to 63
; Marks non-primes as 0, primes as 1 in memory

START:
    ; Initialize array (addresses 0x10-0x4F for numbers 0-63)
    LOADI R1, 0x10     ; Memory base address
    LOADI R2, 64       ; Array size
    LOADI R3, 0        ; Counter
    
INIT_LOOP:
    ; Initialize all to 1 (assume prime)
    LOADI R4, 1
    STORE R4, [R1]
    ADD R1, R1, 1
    ADD R3, R3, 1
    CMP R3, R2
    JNZ INIT_LOOP
    
    ; Mark 0 and 1 as non-prime
    LOADI R1, 0x10
    LOADI R4, 0
    STORE R4, [R1]     ; Mark 0 as non-prime
    ADD R1, R1, 1
    STORE R4, [R1]     ; Mark 1 as non-prime
    
    ; Start sieve algorithm
    LOADI R1, 2        ; i = 2 (first prime)
    LOADI R2, 8        ; sqrt(64) = 8 (max to check)
    
SIEVE_LOOP:
    ; Check if i is prime
    LOADI R3, 0x10
    ADD R3, R3, R1     ; Address of number i
    LOAD R4, [R3]
    CMP R4, 0
    JZ NEXT_I          ; Skip if already marked as non-prime
    
    ; Mark multiples of i as non-prime
    LOADI R5, 2        ; j = 2
    LOADI R6, 64       ; max = 64
    
MARK_LOOP:
    MUL R7, R1, R5     ; multiple = i * j
    ; Check if multiple < 64
    CMP R7, R6
    JZ NEXT_I          ; Done if multiple >= 64
    
    ; Mark multiple as non-prime
    LOADI R3, 0x10
    ADD R3, R3, R7
    LOADI R4, 0
    STORE R4, [R3]
    
    ADD R5, R5, 1      ; j = j + 1
    CMP R5, R6
    JNZ MARK_LOOP
    
NEXT_I:
    ADD R1, R1, 1      ; i = i + 1
    CMP R1, R2
    JNZ SIEVE_LOOP
    
    HALT

; Primes found (memory locations with value 1):
; 2, 3, 5, 7, 11, 13, 17, 19, 23, 29, 31, 37, 41, 43, 47, 53, 59, 61
