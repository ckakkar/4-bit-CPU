; Palindrome checker
; Checks if a number is a palindrome (reads same forwards and backwards)
; Example: 121, 1331, 1221 are palindromes
; Stores result: 1 if palindrome, 0 if not

START:
    LOADI R1, 121      ; Number to check (121 is a palindrome)
    LOADI R2, 0        ; Reversed number
    LOADI R3, 0        ; Original number (backup)
    MOV R3, R1         ; Save original
    
    ; Reverse the number
    LOADI R4, 10       ; Base 10
    LOADI R5, 0        ; Digit counter
    
REVERSE_LOOP:
    ; Extract last digit: digit = number % 10
    DIV R6, R1, R4     ; R6 = number / 10 (quotient)
    ; Note: DIV stores quotient in R6, remainder in R7
    ; We need the remainder (last digit)
    ; For now, we'll use: remainder = number - (quotient * 10)
    MUL R7, R6, R4     ; R7 = quotient * 10
    SUB R7, R1, R7     ; R7 = number - (quotient * 10) = last digit
    
    ; Add digit to reversed number: reversed = reversed * 10 + digit
    MUL R2, R2, R4     ; reversed = reversed * 10
    ADD R2, R2, R7     ; reversed = reversed + digit
    
    ; Update number: number = number / 10
    MOV R1, R6         ; number = quotient
    
    ; Check if done
    CMP R1, 0
    JNZ REVERSE_LOOP
    
    ; Compare original with reversed
    CMP R3, R2
    JZ IS_PALINDROME
    
    ; Not a palindrome
    LOADI R1, 0
    STORE R1, [0x50]   ; Store 0 (not palindrome)
    HALT
    
IS_PALINDROME:
    ; Is a palindrome
    LOADI R1, 1
    STORE R1, [0x50]   ; Store 1 (is palindrome)
    HALT

; Test with different numbers:
; 121 -> palindrome (1)
; 123 -> not palindrome (0)
; 1331 -> palindrome (1)
; 1221 -> palindrome (1)
