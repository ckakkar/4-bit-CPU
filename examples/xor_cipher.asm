; XOR cipher (simple encryption/decryption)
; Encrypts/decrypts data using XOR with a key
; Same operation encrypts and decrypts (XOR is reversible)

START:
    ; Initialize message to encrypt (at 0x90-0x94)
    LOADI R1, 0x90     ; Message address
    LOADI R2, 'H'      ; Message: "HELLO" (ASCII values)
    STORE R2, [R1]
    ADD R1, R1, 1
    LOADI R2, 'E'
    STORE R2, [R1]
    ADD R1, R1, 1
    LOADI R2, 'L'
    STORE R2, [R1]
    ADD R1, R1, 1
    LOADI R2, 'L'
    STORE R2, [R1]
    ADD R1, R1, 1
    LOADI R2, 'O'
    STORE R2, [R1]
    
    ; Encryption key
    LOADI R3, 0xAA     ; Key = 0xAA (10101010 in binary)
    
    ; Encrypt message
    LOADI R1, 0x90     ; Message address
    LOADI R2, 0xA0     ; Encrypted message address
    LOADI R4, 0        ; Counter
    LOADI R5, 5        ; Message length
    
ENCRYPT_LOOP:
    LOAD R6, [R1]      ; Load plaintext byte
    XOR R7, R6, R3     ; Encrypt: cipher = plaintext XOR key
    STORE R7, [R2]     ; Store encrypted byte
    
    ADD R1, R1, 1      ; Next source byte
    ADD R2, R2, 1      ; Next destination byte
    ADD R4, R4, 1      ; Increment counter
    CMP R4, R5
    JNZ ENCRYPT_LOOP
    
    ; Decrypt message (same operation!)
    LOADI R1, 0xA0     ; Encrypted message address
    LOADI R2, 0xB0     ; Decrypted message address
    LOADI R4, 0        ; Counter
    
DECRYPT_LOOP:
    LOAD R6, [R1]      ; Load ciphertext byte
    XOR R7, R6, R3     ; Decrypt: plaintext = ciphertext XOR key
    STORE R7, [R2]     ; Store decrypted byte
    
    ADD R1, R1, 1      ; Next source byte
    ADD R2, R2, 1      ; Next destination byte
    ADD R4, R4, 1      ; Increment counter
    CMP R4, R5
    JNZ DECRYPT_LOOP
    
    HALT

; Memory layout:
; 0x90-0x94: Original message "HELLO" (72, 69, 76, 76, 79)
; 0xA0-0xA4: Encrypted message (XOR with 0xAA)
; 0xB0-0xB4: Decrypted message (should match original)
