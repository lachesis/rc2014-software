;==================================================================================
; Contents of this file are copyright Grant Searle
;
; You have permission to use this for NON COMMERCIAL USE ONLY
; If you wish to use it elsewhere, please include an acknowledgement to myself.
;
; http://searle.hostei.com/grant/index.html
;
; eMail: home.micros01@btinternet.com
;
; If the above don't work, please perform an Internet search to see if I have
; updated the web page hosting service.
;
;==================================================================================

; Minimum 6850 ACIA interrupt driven serial I/O to run modified NASCOM Basic 4.7
; Full input buffering with incoming data hardware handshaking
; Handshake shows full before the buffer is totally filled to allow run-on from the sender

SER_BUFSIZE     .EQU     3FH
SER_FULLSIZE    .EQU     30H
SER_EMPTYSIZE   .EQU     5
LINEBUF_SIZE    .EQU     080H

RTS_HIGH        .EQU     0D6H
RTS_LOW         .EQU     096H

serBuf          .EQU     $8000
serInPtr        .EQU     serBuf+SER_BUFSIZE
serRdPtr        .EQU     serInPtr+2
serBufUsed      .EQU     serRdPtr+2
basicStarted    .EQU     serBufUsed+1
TEMPSTACK       .EQU     $80ED ; Top of BASIC line input buffer so is "free ram" when BASIC resets
lineBuf         .EQU     $8100

CR              .EQU     0DH
LF              .EQU     0AH
CS              .EQU     0CH             ; Clear screen

                .ORG $0000
;------------------------------------------------------------------------------
; Reset

RST00           DI                       ;Disable interrupts
                JP       INIT            ;Initialize Hardware and go

;------------------------------------------------------------------------------
; TX a character over RS232

                .ORG     0008H
RST08            JP      TXA

;------------------------------------------------------------------------------
; RX a character over RS232 Channel A [Console], hold here until char ready.

                .ORG 0010H
RST10            JP      RXA

;------------------------------------------------------------------------------
; Check serial status

                .ORG 0018H
RST18            JP      CKINCHAR

;------------------------------------------------------------------------------
; RST 38 - INTERRUPT VECTOR [ for IM 1 ]

                .ORG     0038H
RST38            JR      serialInt

;------------------------------------------------------------------------------
serialInt:      PUSH     AF
                PUSH     HL

                IN       A,($80)
                AND      $01             ; Check if interupt due to read buffer full
                JR       Z,rts0          ; if not, ignore

                IN       A,($81)
                PUSH     AF
                LD       A,(serBufUsed)
                CP       SER_BUFSIZE     ; If full then ignore
                JR       NZ,notFull
                POP      AF
                JR       rts0

notFull:        LD       HL,(serInPtr)
                INC      HL
                LD       A,L             ; Only need to check low byte becasuse buffer<256 bytes
                CP       (serBuf+SER_BUFSIZE) & $FF
                JR       NZ, notWrap
                LD       HL,serBuf
notWrap:        LD       (serInPtr),HL
                POP      AF
                LD       (HL),A
                LD       A,(serBufUsed)
                INC      A
                LD       (serBufUsed),A
                CP       SER_FULLSIZE
                JR       C,rts0
                LD       A,RTS_HIGH
                OUT      ($80),A
rts0:           POP      HL
                POP      AF
                EI
                RETI

;------------------------------------------------------------------------------
RXA:
waitForChar:    LD       A,(serBufUsed)
                CP       $00
                JR       Z, waitForChar
                PUSH     HL
                LD       HL,(serRdPtr)
                INC      HL
                LD       A,L             ; Only need to check low byte becasuse buffer<256 bytes
                CP       (serBuf+SER_BUFSIZE) & $FF
                JR       NZ, notRdWrap
                LD       HL,serBuf
notRdWrap:      DI
                LD       (serRdPtr),HL
                LD       A,(serBufUsed)
                DEC      A
                LD       (serBufUsed),A
                CP       SER_EMPTYSIZE
                JR       NC,rts1
                LD       A,RTS_LOW
                OUT      ($80),A
rts1:
                LD       A,(HL)
                EI
                POP      HL
                RET                      ; Char ready in A

;------------------------------------------------------------------------------
TXA:            PUSH     AF              ; Store character
conout1:        IN       A,($80)         ; Status byte
                BIT      1,A             ; Set Zero flag if still transmitting character
                JR       Z,conout1       ; Loop until flag signals ready
                POP      AF              ; Retrieve character
                OUT      ($81),A         ; Output the character
                RET

;------------------------------------------------------------------------------
CKINCHAR        LD       A,(serBufUsed)
                CP       $0
                RET

PRINT:          LD       A,(HL)          ; Get character
                OR       A               ; Is it $00 ?
                RET      Z               ; Then RETurn on terminator
                RST      08H             ; Print it
                INC      HL              ; Next Character
                JR       PRINT           ; Continue until $00
                RET
;------------------------------------------------------------------------------
INIT:
                LD        HL,TEMPSTACK    ; Temp stack
                LD        SP,HL           ; Set up a temporary stack
                LD        HL,serBuf
                LD        (serInPtr),HL
                LD        (serRdPtr),HL
                XOR       A               ;0 to accumulator
                LD        (serBufUsed),A
                LD        A,RTS_LOW
                OUT       ($80),A         ; Initialise ACIA
                IM        1
                EI
                LD        HL,SIGNON1      ; Sign-on message
                CALL      PRINT           ; Output string
                JR        REPL

REPL:
                ld hl, NL
                call PRINT
                LD        HL,PROMPT
                CALL      PRINT
                LD        HL, lineBuf
BUFCHAR:
                RST       10H  ; Read a char into A
                CP        13   ; CR
                JR        z, EXEC
                CP        8    ; Backspace
                JR        z, BACKSPACE
                CP        3     ; Ctrl-C
                JR        z, REPL
                LD        (HL), A
                INC       HL
                RST       8H  ; Echo char
                JR        BUFCHAR

EXEC:
    ; Null-terminate the buffer
    ld (hl), 0

    ; Print a newline
    ld hl, NL
    call PRINT

    ; Print a *
    ld a, 42
    rst 8H

    ; Print the message
    ld hl, lineBuf
    call PRINT

    ; Print another *
    ld a, 42
    rst 8H

    ; Print newline
    ld hl, NL
    call PRINT

    jr REPL

BACKSPACE:
    ; 16 bit compare bc (linebuf) with hl
    ld bc, lineBuf
    or a
    sbc hl, bc
    add hl, bc

    ; If equal, don't decrement HL anymore - just jump back
    jr z, BUFCHAR

    ; Print a backspace
    ld a, 8
    rst 8H

    ; Print a space
    ld a, 20H
    rst 8H

    ; Print a backspace
    ld a, 8
    rst 8H

    dec hl
    jr BUFCHAR

NL:            .BYTE     CR,LF,0
SIGNON1:       .BYTE     CS
               .BYTE     "Z80 SBC ROM Monitor",CR,LF,0
PROMPT:        .BYTE     "> ",0

.END
