	.h8300s

	.equ	PUTS,0x114
	.equ	GETS,0x113
	.equ	syscall,0x1FF00
	
; ----- datovy segment -------------------------
		.data
vstup:		.space	6
prompt:		.asciz	"Zadejte cislo uint16: "
is_prime:	.ascii	"Zadane cislo je prvocislo.\n"
not_prime:	.ascii	"Zadane cislo neni prvocislo.\n"
	
		.align	2
par_vstup:		.long	vstup	;ukazatel na vstupni buffer
par_prompt:		.long	prompt	;ukazatel na vystupni buffer
par_isPrime:	.long	is_prime	;ukaz. na text is_prime
par_notPrime:	.long	not_prime	;ukaz. na text not_prime
	
		.align	1
		.space	100
stack:

; ----- kodovy segment -------------------------
		.text
		.global _start

; ----- podprogram: testovani na prvocislo
testPrime:
			
; ----- kontrola jestli vstup je 0 nebo 1
	mov.w	#0x02,R5		;presun hodnoty 2 do registru R5
	cmp.l	ER5,ER0			;porovnani registru ER0 s ER5
	blt	lab3				;pokud mensi, tak skoci do lab3
	
; ----- kontrola zda cislo == 2
	mov.w	#0x02,R5		;presun hodnoty 2 do registru R5 (neni nutny)
	cmp.w	R5,R0			;porovnani zda registr R5 neni roven 2
	beq	lab2				;pokud ano, tak skok do lab2
	
; ----- kontrola sudosti zadaneho cisla
	mov.l	ER0,ER4			;zkopirovani hodnoty registru ER0 do ER4
	divxu.w	R5,ER4			;vydeleni ER4(=vstupu) registrem R5(=2)
	cmp.w	#0x00,E4		;porovnani zbytku s 0
	beq	lab3				;pokud roven, tak do lab3

; ----- test delenim
		add.w	#0x01,R5	;pricteme 1 k R5 -> 2 + 1 = 3
loop:	cmp.w	R5,R0		;porovnani zda delitel == vstup
		beq	lab2			;pokud ano, tak je prvocislo a skok do lab2
		
		mov.l ER0,ER4		;zkopirovani registru ER0(=vstup) do ER4
		divxu.w	R5,ER4		;deleni ER4 delitelem R5
		cmp.w	#0x0000,E4	;porovnani zbytku s 0
		beq	lab3			;kdyz zbytek == 0, tak neni prvocislo a skok do lab3
		inc.w	#0x02,R5	;zvyseni delitele o 2 (jen licha cisla)
		xor.l ER4,ER4		;vynulovani registru ER4
		jmp @loop			;skok na loop(=zacatek cyklu)
	
; ----- zprava: je prvocislo	
lab2:	mov.w	#PUTS,R0	
	mov.l	#par_isPrime,ER1
	jsr		@syscall
	jmp	@lab1
	
; ----- zprava: neni prvocislo	
lab3:	mov.w	#PUTS,R0
	mov.l	#par_notPrime,ER1
	jsr		@syscall
	jmp @lab1
	
_start:	mov.l	#stack,ER7	;definovani stacku do ER7

	mov.w	#PUTS,R0		;kod fce do R0H a R0L
	mov.l	#par_prompt,ER1	;odkaz na par.blok do ER1
	jsr		@syscall		;volani systemove fce
	
	mov.w	#GETS,R0		;kod fce do R0H a R0L
	mov.l	#par_vstup,ER1	;odkaz na par.blok do ER1
	jsr		@syscall		;volani systemove fce

	mov.l #vstup, ER6		;ulozeni vstupu do ER6
	
	jsr @prevod				;skok do podprogramu prevod
	jsr @testPrime			;skok do podprogramu testPrime
	
lab1:	jmp @lab1			;zacykleni, konec programu

prevod:	push.l ER1			;ulozeni registru
	xor.l ER0,ER0			;vynulovani ER0
	xor.l ER1,ER1			;vynulovani ER1
	mov.w #10,E1			;ciselny zaklad = 10
	
lab5:	mov.b @ER6,R1L		;cteni znaku z pameti
	cmp.b #0x0A,R1L			;test zda to neni konec retezce
	beq lab6				;jestli je konec tak skok na lab6
	add.b #-'0',R1L			;odecteni '0' tedy (0x30)
	mulxu.w E1,ER0			;ER0 = E1(=10) * ER0
	add.w R1,R0				;R0 = R0 + R1
	inc.l #1,ER6			;dalsi znak v retezci
	jmp @lab5				;skok na lab5
	
lab6:	pop.l ER1			;ziskani puvodni hodnoty registru
	rts						;navrat z podprogramu
	
	.end
