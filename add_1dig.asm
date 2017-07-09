SECTION CODE

main:
    ld hl, n1
    call print
    call readdigit
    ld c, a

    ld hl, nl           ; Print newline
    call print

    ld hl, n2
    call print
    call readdigit

    add c
    ld c, a

    ld hl, nl           ; Print newline
    call print

    ld hl, n3
    call print

    ld a, c
    call writedigit

    ld hl, nl           ; Print newline
    call print

    ret

print:
    ld a, (hl)
    or a
    ret z           ; Break if current character is zero
    rst 8H          ; Tx byte
    inc hl
    jr print

readdigit:          ; Returns decimal digit in A
    rst 10H         ; Rx byte
    sub '0'
    ret             ; return the byte read in a

writedigit:         ; Writes digit that is in A
    add '0'
    rst 8H
    ret

SECTION DATA

n1:    DEFM "Enter Num 1: ",0
n2:    DEFM "Enter Num 2: ",0
n3:    DEFM "Result: ",0
nl:    DEFM 10, 13, 0
