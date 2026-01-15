; Selection sort algorithm
; Sorts an array of numbers in ascending order
; Uses selection sort: find minimum, swap with current position

START:
    ; Initialize array with unsorted data
    ; Array at addresses 0x80-0x87 (8 elements)
    LOADI R1, 0x80     ; Array base address
    LOADI R2, 34       ; Data to sort
    STORE R2, [R1]
    ADD R1, R1, 1
    LOADI R2, 12
    STORE R2, [R1]
    ADD R1, R1, 1
    LOADI R2, 56
    STORE R2, [R1]
    ADD R1, R1, 1
    LOADI R2, 7
    STORE R2, [R1]
    ADD R1, R1, 1
    LOADI R2, 23
    STORE R2, [R1]
    ADD R1, R1, 1
    LOADI R2, 45
    STORE R2, [R1]
    ADD R1, R1, 1
    LOADI R2, 19
    STORE R2, [R1]
    ADD R1, R1, 1
    LOADI R2, 3
    STORE R2, [R1]
    
    ; Selection sort algorithm
    LOADI R1, 0x80     ; i = 0 (outer loop index)
    LOADI R2, 8        ; Array size
    SUB R2, R2, 1      ; n - 1 (last element doesn't need sorting)
    
OUTER_LOOP:
    ; Find minimum element in unsorted portion
    LOADI R3, 0xFF     ; min_value = 255 (maximum 8-bit value)
    MOV R4, R1         ; min_index = i
    MOV R5, R1         ; j = i (inner loop index)
    ADD R6, R1, R2     ; j_max = i + (n-1)
    ADD R6, R6, 1      ; j_max = i + n
    
INNER_LOOP:
    ; Load current element
    LOAD R7, [R5]      ; current = array[j]
    
    ; Compare with minimum
    CMP R7, R3
    JZ NEXT_J          ; Skip if current >= min
    JNZ UPDATE_MIN     ; Update min if current < min
    
UPDATE_MIN:
    MOV R3, R7         ; min_value = current
    MOV R4, R5         ; min_index = j
    
NEXT_J:
    ADD R5, R5, 1      ; j = j + 1
    CMP R5, R6
    JNZ INNER_LOOP
    
    ; Swap array[i] with array[min_index]
    LOAD R7, [R1]      ; temp = array[i]
    LOAD R8, [R4]      ; array[min_index]
    STORE R8, [R1]     ; array[i] = array[min_index]
    STORE R7, [R4]     ; array[min_index] = temp
    
    ; Next iteration
    ADD R1, R1, 1      ; i = i + 1
    CMP R1, R2
    JNZ OUTER_LOOP
    
    HALT

; Array before: 34, 12, 56, 7, 23, 45, 19, 3
; Array after:  3, 7, 12, 19, 23, 34, 45, 56
