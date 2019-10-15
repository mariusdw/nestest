; How to run the game in an emulator.
; Defines the cartridge hardware to be emulated.
.segment "HEADER"
    ; iNES header definition.
    .byte "NES"
    .byte $1a
    ; How much programmable (PRG) ROM (2*16KB=32KB).
    .byte $02
    ; How much character ROM (1*8KB).
    .byte $01
    ; Mapping and mirroring flags.
    .byte %00000000
    .byte $00
    .byte $00
    .byte $00
    .byte $00
    ; Padding.
    .byte $00, $00, $00, $00, $00

; First 256 bytes of memory (00 - FF).
.segment "ZEROPAGE"

; Startup code.
; Define interrupt handlers here.
.segment "STARTUP"
Reset:
    ; Disable interrupts (prevents interference while initialising).
    SEI
    ; Disable decimal mode (not supported by NES).
    CLD
    ; Disable sound IRQ. Sets IRQ inhibit bit.
    LDX #$40
    STX $4017

    ; Initialise stack register to point to top of stack.
    LDX #$FF
    ; Transfer X register to stack register.
    TXS

    ; Set X register to zero.
    INX
    ; Zero out PPU registers.
    STX $2000
    STX $2001

    ; Disable PCM channel.
    STX $4010

    :
    ; Wait for PPU to give first VBLANK
    ; Read bit 7 at address. One means VBLANK is active (waiting to start drawing after successful draw).
    BIT $2002
    ; Branch positive. Branch to annonymous label if sign bit (bit 7) is not set (meaning number is positive).
    BPL :-

    ; Clear memory (sets all 2KB to zero).
    ; Load value zero into accumulator register.
    TXA
    ClearMem:
        ; Store contents of A into address space $0000 offset by x.
        STA $0000, x ; Covers all memory from $0000 - $00FF
        STA $0100, x
        STA $0300, x ; Skip $0200-$02FF as thus will be used for sprite information.
        STA $0400, x
        STA $0500, x
        STA $0600, x
        STA $0700, x

        ; Initialise sprite area to #$FF
        LDA #$FF
        STA $0200, x
        LDA #$00

        ; Increment X by one.
        INX
        ; When X reaches FF and gets incremented by one, it will roll over to 00. This will cause the zero flag to be set.
        ; BNE checks the zero flag and jumps back if it is not equal to true. So we loop until X rolls over.
        BNE ClearMem

    ; Wait for VBLANK again before updating sprites.
    BIT $2002
    BPL :-

    ; Indicate to PPU where the sprite information is stored.
    ; Since the sprite info is always 256 bytes, we only need to specify the high address byte.
    LDA #$02 ; Indicates memory range $0200 - $02FF.
    STA $4014 ; Store value into OAM DMA register.
    NOP ; Burns one CPU cycle. PPU needs a moment to initialise.

    ; Load the palette data.
    ; Address PPU memory.
    ; Indicate that we want to write to $3F00 - universal background color.
    ; This is the beginning location of where palette information is stored in the PPU.
    ; First indicate high byte.
    LDA #$3F
    STA $2006
    ; Then indicate low byte.
    LDA #$00
    STA $2006

    LDX #$00
    ; 2 sets of 4 separate 4 color palettes - one set for backgrounds and set for sprites.
    ; For a total of 32 colors. Color zero is background color and much be the same for each pallete. Therefore, in effect
    ; 24 colors + 1 background.
    LoadPalettes:
        LDA PaletteData, X
        ; Writing to $2007 writes to the address previously indicated to the PPU ($3F00).
        ; It also increments the target address automatically by one. So next loop we write to $3F01.
        STA $2007
        INX
        CPX #$20 ; 32 in decimal
        BNE LoadPalettes    ; In effect, causes writes to $3F00 - $3F1F.

    LDX #$00

    LoadSprites:
        LDA SpriteData, X
        ; Load sprite data into memory rather than PPU memory.
        ; $0200 - $02FF was previously reserved for this.
        STA $0200, X
        INX
        ; Loading 8 sprites of 4 bytes each = 32 bytes.
        CPX #$20
        BNE LoadSprites

     ; Enable interrupts.
     CLI

     ; Indicate that PPU must interrupt execution during VBLANK.
     ; Also set background tileset to start at $1000.
     LDA #%10010000
     STA $2000
     ; Turn on drawing.
     ; Enable sprites and backgrounds for leftmost 8 pixels.
     ; Enable sprites and backgrounds in general.
     LDA #%00011110

    ; Ensures that code does not pass this point. As everything else will be handled in the NMI.
    ; Infinite loop
    Loop:
        JMP Loop

NMI:
    LDA #$02
    ; copy sprite data from 0200 to PPU memory for display.
    ; this prevents the sprite data from decaying in the PPU memory.
    STA $4014
    ; Return interrupt.
    RTI

; Defines our Palette data. Set $22 as the background color.
PaletteData:
    .byte $22,$29,$1A,$0F,$22,$36,$17,$0f,$22,$30,$21,$0f,$22,$27,$17,$0F  ;background palette data
    .byte $22,$16,$27,$18,$22,$1A,$30,$27,$22,$16,$30,$27,$22,$0F,$36,$17  ;sprite palette data

; NES can display 8x8 or 8x16 sprites, we will use 8x8.
; Each sprite is 4 bytes (PPU OAM data):
; 0 - y offset (distance from top)
; 1 - which tile to display (tile offset)
; 2 - attributes
; 3 - x offset (distance from left)
SpriteData:
    .byte $08, $00, $00, $08
    .byte $08, $01, $00, $10
    .byte $10, $02, $00, $08
    .byte $10, $03, $00, $10
    .byte $18, $04, $00, $08
    .byte $18, $05, $00, $10
    .byte $20, $06, $00, $08
    .byte $20, $07, $00, $10

; Special addresses.
; How code is called when interrupt happens.
; Defines interrupt handlers (labels to jump to on interrupt).
.segment "VECTORS"
     ; Non maskable interrupt.
     ; Happens on VBLANK.
    .word NMI
    ; Happens on reset button pressed.
    .word Reset
    ; When specialised hardware triggers an interrupt. Used in custom mappers like mmc3.
    ; word Special

; Graphical data.
.segment "CHARS"
    .incbin "hellomario.chr"