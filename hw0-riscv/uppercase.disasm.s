
uppercase.bin:     file format elf32-littleriscv


Disassembly of section .text:

00010074 <_start>:
   10074:	ffff2517          	auipc	a0,0xffff2
   10078:	f8c50513          	addi	a0,a0,-116 # 2000 <__DATA_BEGIN__>
   1007c:	00000693          	li	a3,0
   10080:	00000713          	li	a4,0
   10084:	06168693          	addi	a3,a3,97
   10088:	07a70713          	addi	a4,a4,122

0001008c <loop>:
   1008c:	00050603          	lb	a2,0(a0)
   10090:	00060e63          	beqz	a2,100ac <end_program>
   10094:	00d64863          	blt	a2,a3,100a4 <incr>
   10098:	00c74663          	blt	a4,a2,100a4 <incr>
   1009c:	fe060793          	addi	a5,a2,-32
   100a0:	00f50023          	sb	a5,0(a0)

000100a4 <incr>:
   100a4:	00150513          	addi	a0,a0,1
   100a8:	fe5ff06f          	j	1008c <loop>

000100ac <end_program>:
   100ac:	0000006f          	j	100ac <end_program>
