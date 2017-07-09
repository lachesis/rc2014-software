SECTION CODE

main:
    ld hl, n1           ; Ask for num 1 and read
    call print
    call readnum
    ld c, a

    ld hl, nl           ; Print newline
    call print

    ld hl, n2           ; Ask for num 2 and read
    call print
    call readnum

    xor c               ; Add them
    ld c, a

    ld hl, nl           ; Print newline
    call print

    ld hl, n3
    call print

    ld a, c
    call writenum

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

readnum:            ; Return result in A
    push bc
    ld b, 0         ; Previous digits number stored in B
readdigit:          ; Returns decimal digit in A
    rst 10H         ; Rx byte
    cp 13           ; Did they press newline?
    jr z, rndone    ; We're done!
    rst 8H          ; Tx byte back out (echo)

    ; Read the digit, and store it in C
    sub 48
    ld c, a

    ld a, b
    ;call writenum

    ; Fixed multiply by 10, blame Za3k
    ld a, b
    rlca
    ld b, a
    rlca
    rlca
    add b

    ;call writenum

    ; A contains previous digits with a zero in the ones place
    ; B contains garbage
    ; C contains the current digit

    ; Add the current digit
    add c
    ;call writenum

    ; Store the accumulated value to B
    ld b, a

    jr readdigit
rndone:
    ld a, b
    pop bc
    ret             ; return the byte read in a

writedigit:         ; Writes digit that is in A
    add '0'
    rst 8H
    ret

writenum:
    push af
    push bc
    push de
    ld b, 0
    div10a:
        sub 10
        jr c, div10adone
        inc b
        jr div10a
    div10adone: add 10
    ld c, a
    ld a, b
    ld b, 0
    div10b:
        sub 10
        jr c, div10bdone
        inc b
        jr div10b
    div10bdone: add 10
    ld d, a

    ld a, b
    call writedigit
    ld a, d
    call writedigit
    ld a, c
    call writedigit
writenumdone:
    pop de
    pop bc
    pop af
    ret

SECTION DATA

n1:    DEFM "Enter Num 1: ",0
n2:    DEFM "Enter Num 2: ",0
n3:    DEFM "Result: ",0
nl:    DEFM 10, 13, 0
