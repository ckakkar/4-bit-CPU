; Virtual memory example
; Demonstrates virtual address space usage

USER_PROGRAM:
    ; User-mode program (runs in virtual memory)
    ; Virtual addresses are translated by MMU
    
    ; Access virtual address 0x10
    LOADI R1, 42
    STORE R1, [0x10]   ; Virtual address - translated by MMU
    
    ; Access virtual address 0x20
    LOAD R2, [0x20]    ; Virtual address - translated by MMU
    
    ; Jump to virtual address
    JUMP 0x30          ; Virtual address - translated by MMU
    
    HALT

; Kernel code (runs in physical memory, no translation)
KERNEL_CODE:
    ; Kernel has direct physical memory access
    LOADI R1, 0xFF
    STORE R1, [0x00]   ; Physical address (no translation)
    
    HALT
