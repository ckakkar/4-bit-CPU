; Interrupt-driven program example
; Main program with timer interrupt service routine

MAIN:
    ; Enable interrupts
    LOADI R1, 1
    OUT [0xFF], R1      ; Enable interrupts in control register
    
    ; Initialize counter
    LOADI R2, 0
    
MAIN_LOOP:
    ; Main program loop
    ADD R2, R2, 1
    
    ; Do some work
    ; ...
    
    JUMP MAIN_LOOP

; Timer interrupt service routine (at address 0x10)
TIMER_ISR:
    ; Save registers
    PUSH R1
    PUSH R2
    
    ; Toggle GPIO port 0
    IN R1, [0xF0]       ; Read current GPIO value
    XOR R1, R1, 1      ; Toggle bit 0
    OUT [0xF0], R1     ; Write back
    
    ; Restore registers
    POP R2
    POP R1
    
    ; Return from interrupt
    RETI
