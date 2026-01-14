        .section .data
input_string:   .asciz "Hello world!"

        # tohost/fromhost are data locations used by Spike
        .align 8
tohost: .byte 0
        .align 8
fromhost: .byte 0

        
        .section .text
        .globl _start
_start:
        # Load the address of the input string into a0
        la a0, input_string

        # Your code here!
        # load hex value for 'a' and 'z'
        mv a3, x0
        mv a4, x0
        addi a3, a3, 0x61
        addi a4, a4, 0x7A
loop:
        # load char
        lb a2, 0(a0)

        # check if null terminator
        beq a2, x0, end_program

        # check if it is a lowercase letter
        blt a2, a3, incr
        bgt a2, a4, incr

        # convert to uppercase
        addi a5, a2, -0x20
        sb a5, 0(a0)
incr:
        # increment address
        addi a0, a0, 1
        j loop

end_program:
        # jump here when you're done
        j end_program

