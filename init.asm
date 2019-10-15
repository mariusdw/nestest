; This simple loop traverses through each byte in the 2K memory and sets it to zero.
; From https://www.youtube.com/watch?v=Xgfja8BXmNc
init_mem:
    ; Load value zero into X index register.
    LDX #$00
    init_clrmem:
        ; Load value zero into accumulator register.
        LDA #$00
        ; Store contents of A into address space 0000 offset by x.
        STA $0000, x
        STA $0100, x
        STA $0200, x
        STA $0300, x
        STA $0400, x
        STA $0500, x
        STA $0600, x
        STA $0700, x
        ; Increment X by one.
        INX
        ; Check if X is zero.
        CPX #$00
        ; Jump back to beginning if comparison is not true.
        BNE init_clrmem
