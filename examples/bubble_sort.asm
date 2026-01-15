; Bubble sort algorithm
; Sorts an array of numbers in memory locations 0x10-0x19

START:
    LOADI R1, 0x10     ; Array start address
    LOADI R2, 10       ; Array size
    LOADI R3, 0        ; Outer loop counter
    
OUTER_LOOP:
    LOADI R4, 0        ; Inner loop counter
    LOADI R5, 0        ; Swapped flag
    
INNER_LOOP:
    ; Load array[i]
    ADD R6, R1, R4
    LOAD R7, [R6]
    
    ; Load array[i+1]
    ADD R6, R6, 1
    LOAD R8, [R6]
    
    ; Compare array[i] and array[i+1]
    CMP R7, R8
    
    ; If array[i] > array[i+1], swap
    ; (This is simplified - would need signed comparison)
    ; For now, assume unsigned comparison
    SUB R9, R7, R8     ; R9 = R7 - R8
    JZ NO_SWAP          ; If equal, no swap needed
    
    ; Swap values
    STORE R8, [R6-1]    ; array[i] = array[i+1]
    STORE R7, [R6]      ; array[i+1] = array[i]
    LOADI R5, 1         ; Set swapped flag
    
NO_SWAP:
    ; Increment inner loop counter
    ADD R4, R4, 1
    
    ; Check inner loop condition
    SUB R9, R2, R3      ; R9 = size - outer_counter
    SUB R9, R9, 1       ; R9 = size - outer_counter - 1
    CMP R4, R9
    JNZ INNER_LOOP
    
    ; Check if any swaps occurred
    CMP R5, 0
    JZ DONE              ; If no swaps, array is sorted
    
    ; Increment outer loop counter
    ADD R3, R3, 1
    
    ; Check outer loop condition
    CMP R3, R2
    JNZ OUTER_LOOP
    
DONE:
    HALT
