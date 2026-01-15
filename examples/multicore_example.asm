; Multi-core programming example
; Core 0: Main program
; Core 1-3: Worker threads

; Core 0 program
CORE0_START:
    ; Initialize shared data
    LOADI R1, 0        ; Counter
    STORE R1, [0x10]   ; Store in shared memory
    
    ; Signal cores 1-3 to start
    LOADI R2, 1
    STORE R2, [0x11]   ; Start flag
    
    ; Wait for completion
    LOAD R3, [0x12]    ; Completion flag
    CMP R3, 3          ; All 3 cores done?
    JNZ CORE0_START
    
    HALT

; Core 1 worker (would be at different memory location)
CORE1_START:
    ; Read work item from shared queue
    LOAD R1, [0x20]    ; Work queue
    
    ; Process work
    ADD R1, R1, 1
    
    ; Write result
    STORE R1, [0x30]
    
    ; Signal completion
    LOAD R2, [0x12]
    ADD R2, R2, 1
    STORE R2, [0x12]
    
    HALT
