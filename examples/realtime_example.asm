; Real-time system example
; Demonstrates real-time task scheduling

; High-priority real-time task (priority 0)
RT_TASK_HIGH:
    ; Critical real-time operation
    LOADI R1, 100
    OUT [0xF0], R1     ; Critical output
    
    ; Signal completion
    LOADI R2, 1
    STORE R2, [0x40]   ; Task complete flag
    
    RETI               ; Return to scheduler

; Medium-priority task (priority 5)
RT_TASK_MED:
    ; Medium priority operation
    LOADI R1, 50
    OUT [0xF1], R1
    
    RETI

; Low-priority task (priority 10)
RT_TASK_LOW:
    ; Low priority background task
    LOADI R1, 10
    OUT [0xF2], R1
    
    RETI
