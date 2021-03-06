;#
;#
;# Gromacs 4.0                         Copyright (c) 1991-2003 
;# David van der Spoel, Erik Lindahl
;#
;# This program is free software; you can redistribute it and/or
;# modify it under the terms of the GNU General Public License
;# as published by the Free Software Foundation; either version 2
;# of the License, or (at your option) any later version.
;#
;# To help us fund GROMACS development, we humbly ask that you cite
;# the research papers on the package. Check out http://www.gromacs.org
;# 
;# And Hey:
;# Gnomes, ROck Monsters And Chili Sauce
;#

;# These files require GNU binutils 2.10 or later, since we
;# use intel syntax for portability, or a recent version 
;# of NASM that understands Extended 3DNow and SSE2 instructions.
;# (NASM is normally only used with MS Visual C++).
;# Since NASM and gnu as disagree on some definitions and use 
;# completely different preprocessing options I have to introduce a
;# trick: NASM uses ';' for comments, while gnu as uses '#' on x86.
;# Gnu as treats ';' as a line break, i.e. ignores it. This is the
;# reason why all comments need both symbols...
;# The source is written for GNU as, with intel syntax. When you use
;# NASM we redefine a couple of things. The false if-statement around 
;# the following code is seen by GNU as, but NASM doesn't see it, so 
;# the code inside is read by NASM but not gcc.

; .if 0    # block below only read by NASM
%define .section	section
%define .long		dd
%define .align		align
%define .globl		global
;# NASM only wants 'dword', not 'dword ptr'.
%define ptr
%macro .equiv                  2
   %1 equ %2
%endmacro
; .endif                   # End of NASM-specific block
; .intel_syntax noprefix   # Line only read by gnu as

.section .text



.globl nb_kernel310_ia32_sse
.globl _nb_kernel310_ia32_sse
nb_kernel310_ia32_sse:	
_nb_kernel310_ia32_sse:	
.equiv          nb310_p_nri,            8
.equiv          nb310_iinr,             12
.equiv          nb310_jindex,           16
.equiv          nb310_jjnr,             20
.equiv          nb310_shift,            24
.equiv          nb310_shiftvec,         28
.equiv          nb310_fshift,           32
.equiv          nb310_gid,              36
.equiv          nb310_pos,              40
.equiv          nb310_faction,          44
.equiv          nb310_charge,           48
.equiv          nb310_p_facel,          52
.equiv          nb310_argkrf,           56
.equiv          nb310_argcrf,           60
.equiv          nb310_Vc,               64
.equiv          nb310_type,             68
.equiv          nb310_p_ntype,          72
.equiv          nb310_vdwparam,         76
.equiv          nb310_Vvdw,             80
.equiv          nb310_p_tabscale,       84
.equiv          nb310_VFtab,            88
.equiv          nb310_invsqrta,         92
.equiv          nb310_dvda,             96
.equiv          nb310_p_gbtabscale,     100
.equiv          nb310_GBtab,            104
.equiv          nb310_p_nthreads,       108
.equiv          nb310_count,            112
.equiv          nb310_mtx,              116
.equiv          nb310_outeriter,        120
.equiv          nb310_inneriter,        124
.equiv          nb310_work,             128
	;# stack offsets for local variables  
	;# bottom of stack is cache-aligned for sse use 
.equiv          nb310_ix,               0
.equiv          nb310_iy,               16
.equiv          nb310_iz,               32
.equiv          nb310_iq,               48
.equiv          nb310_dx,               64
.equiv          nb310_dy,               80
.equiv          nb310_dz,               96
.equiv          nb310_two,              112
.equiv          nb310_six,              128
.equiv          nb310_twelve,           144
.equiv          nb310_tsc,              160
.equiv          nb310_qq,               176
.equiv          nb310_c6,               192
.equiv          nb310_c12,              208
.equiv          nb310_fscal,            224
.equiv          nb310_vctot,            240
.equiv          nb310_Vvdwtot,          256
.equiv          nb310_fix,              272
.equiv          nb310_fiy,              288
.equiv          nb310_fiz,              304
.equiv          nb310_half,             320
.equiv          nb310_three,            336
.equiv          nb310_is3,              352
.equiv          nb310_ii3,              356
.equiv          nb310_ntia,             360
.equiv          nb310_innerjjnr,        364
.equiv          nb310_innerk,           368
.equiv          nb310_n,                372
.equiv          nb310_nn1,              376
.equiv          nb310_nri,              380
.equiv          nb310_facel,            384
.equiv          nb310_ntype,            388
.equiv          nb310_nouter,           392
.equiv          nb310_ninner,           396
.equiv          nb310_salign,           400
	push ebp
	mov ebp,esp	
    	push eax
    	push ebx
    	push ecx
    	push edx
	push esi
	push edi
	sub esp, 404		;# local stack space 
	mov  eax, esp
	and  eax, 0xf
	sub esp, eax
	mov [esp + nb310_salign], eax

	emms

	;# Move args passed by reference to stack
	mov ecx, [ebp + nb310_p_nri]
	mov esi, [ebp + nb310_p_facel]
	mov edi, [ebp + nb310_p_ntype]
	mov ecx, [ecx]
	mov esi, [esi]
	mov edi, [edi]
	mov [esp + nb310_nri], ecx
	mov [esp + nb310_facel], esi
	mov [esp + nb310_ntype], edi

	;# zero iteration counters
	mov eax, 0
	mov [esp + nb310_nouter], eax
	mov [esp + nb310_ninner], eax


	mov eax, [ebp + nb310_p_tabscale]
	movss xmm5, [eax]	
	shufps xmm5, xmm5, 0
	movaps [esp + nb310_tsc], xmm5

	;# create constant floating-point factors on stack
	mov eax, 0x3f000000     ;# constant 0.5 in IEEE (hex)
	mov [esp + nb310_half], eax
	movss xmm1, [esp + nb310_half]
	shufps xmm1, xmm1, 0    ;# splat to all elements
	movaps xmm2, xmm1       
	addps  xmm2, xmm2	;# constant 1.0
	movaps xmm3, xmm2
	addps  xmm2, xmm2	;# constant 2.0
	addps  xmm3, xmm2	;# constant 3.0
	movaps xmm4, xmm3
	addps  xmm4, xmm4	;# 6.0
	movaps xmm5, xmm4
	addps  xmm5, xmm5	;# constant 12.0
	movaps [esp + nb310_half],  xmm1
	movaps [esp + nb310_two],  xmm2
	movaps [esp + nb310_three],  xmm3
	movaps [esp + nb310_six],  xmm4
	movaps [esp + nb310_twelve],  xmm5

.nb310_threadloop:
        mov   esi, [ebp + nb310_count]          ;# pointer to sync counter
        mov   eax, [esi]
.nb310_spinlock:
        mov   ebx, eax                          ;# ebx=*count=nn0
        add   ebx, 1                           ;# ebx=nn1=nn0+10
        lock
        cmpxchg [esi], ebx                      ;# write nn1 to *counter,
                                                ;# if it hasnt changed.
                                                ;# or reread *counter to eax.
        pause                                   ;# -> better p4 performance
        jnz .nb310_spinlock

        ;# if(nn1>nri) nn1=nri
        mov ecx, [esp + nb310_nri]
        mov edx, ecx
        sub ecx, ebx
        cmovle ebx, edx                         ;# if(nn1>nri) nn1=nri
        ;# Cleared the spinlock if we got here.
        ;# eax contains nn0, ebx contains nn1.
        mov [esp + nb310_n], eax
        mov [esp + nb310_nn1], ebx
        sub ebx, eax                            ;# calc number of outer lists
	mov esi, eax				;# copy n to esi
        jg  .nb310_outerstart
        jmp .nb310_end

.nb310_outerstart:
	;# ebx contains number of outer iterations
	add ebx, [esp + nb310_nouter]
	mov [esp + nb310_nouter], ebx

.nb310_outer:
	mov   eax, [ebp + nb310_shift]      ;# eax = pointer into shift[] 
	mov   ebx, [eax+esi*4]		;# ebx=shift[n] 
	
	lea   ebx, [ebx + ebx*2]    ;# ebx=3*is 
	mov   [esp + nb310_is3],ebx    	;# store is3 

	mov   eax, [ebp + nb310_shiftvec]   ;# eax = base of shiftvec[] 

	movss xmm0, [eax + ebx*4]
	movss xmm1, [eax + ebx*4 + 4]
	movss xmm2, [eax + ebx*4 + 8] 

	mov   ecx, [ebp + nb310_iinr]       ;# ecx = pointer into iinr[] 	
	mov   ebx, [ecx + esi*4]	    ;# ebx =ii 

	mov   edx, [ebp + nb310_charge]
	movss xmm3, [edx + ebx*4]	
	mulss xmm3, [esp + nb310_facel]
	shufps xmm3, xmm3, 0

    	mov   edx, [ebp + nb310_type] 
    	mov   edx, [edx + ebx*4]
    	imul  edx, [esp + nb310_ntype]
    	shl   edx, 1
    	mov   [esp + nb310_ntia], edx
		
	lea   ebx, [ebx + ebx*2]	;# ebx = 3*ii=ii3 
	mov   eax, [ebp + nb310_pos]    ;# eax = base of pos[]  

	addss xmm0, [eax + ebx*4]
	addss xmm1, [eax + ebx*4 + 4]
	addss xmm2, [eax + ebx*4 + 8]

	movaps [esp + nb310_iq], xmm3
	
	shufps xmm0, xmm0, 0
	shufps xmm1, xmm1, 0
	shufps xmm2, xmm2, 0

	movaps [esp + nb310_ix], xmm0
	movaps [esp + nb310_iy], xmm1
	movaps [esp + nb310_iz], xmm2

	mov   [esp + nb310_ii3], ebx
	
	;# clear vctot and i forces 
	xorps xmm4, xmm4
	movaps [esp + nb310_vctot], xmm4
	movaps [esp + nb310_Vvdwtot], xmm4
	movaps [esp + nb310_fix], xmm4
	movaps [esp + nb310_fiy], xmm4
	movaps [esp + nb310_fiz], xmm4
	
	mov   eax, [ebp + nb310_jindex]
	mov   ecx, [eax + esi*4]	     ;# jindex[n] 
	mov   edx, [eax + esi*4 + 4]	     ;# jindex[n+1] 
	sub   edx, ecx               ;# number of innerloop atoms 

	mov   esi, [ebp + nb310_pos]
	mov   edi, [ebp + nb310_faction]	
	mov   eax, [ebp + nb310_jjnr]
	shl   ecx, 2
	add   eax, ecx
	mov   [esp + nb310_innerjjnr], eax     ;# pointer to jjnr[nj0] 
	mov   ecx, edx
	sub   edx,  4
	add   ecx, [esp + nb310_ninner]
	mov   [esp + nb310_ninner], ecx
	add   edx, 0
	mov   [esp + nb310_innerk], edx    ;# number of innerloop atoms 
	jge   .nb310_unroll_loop
	jmp   .nb310_finish_inner
.nb310_unroll_loop:	
	;# quad-unroll innerloop here 
	mov   edx, [esp + nb310_innerjjnr]     ;# pointer to jjnr[k] 
	mov   eax, [edx]	
	mov   ebx, [edx + 4]              
	mov   ecx, [edx + 8]            
	mov   edx, [edx + 12]         ;# eax-edx=jnr1-4 
	add dword ptr [esp + nb310_innerjjnr],  16 ;# advance pointer (unrolled 4) 

	mov esi, [ebp + nb310_charge]    ;# base of charge[] 
	
	movss xmm3, [esi + eax*4]
	movss xmm4, [esi + ecx*4]
	movss xmm6, [esi + ebx*4]
	movss xmm7, [esi + edx*4]

	movaps xmm2, [esp + nb310_iq]
	shufps xmm3, xmm6, 0 
	shufps xmm4, xmm7, 0 
	shufps xmm3, xmm4, 136  ;# constant 10001000 ;# all charges in xmm3  
	movd  mm0, eax		;# use mmx registers as temp storage 
	movd  mm1, ebx
	mulps  xmm3, xmm2
	movd  mm2, ecx
	movd  mm3, edx

	movaps [esp + nb310_qq], xmm3
	
	mov esi, [ebp + nb310_type]
	mov eax, [esi + eax*4]
	mov ebx, [esi + ebx*4]
	mov ecx, [esi + ecx*4]
	mov edx, [esi + edx*4]
	mov esi, [ebp + nb310_vdwparam]
	shl eax, 1	
	shl ebx, 1	
	shl ecx, 1	
	shl edx, 1	
	mov edi, [esp + nb310_ntia]
	add eax, edi
	add ebx, edi
	add ecx, edi
	add edx, edi

	movlps xmm6, [esi + eax*4]
	movlps xmm7, [esi + ecx*4]
	movhps xmm6, [esi + ebx*4]
	movhps xmm7, [esi + edx*4]

	movaps xmm4, xmm6
	shufps xmm4, xmm7, 136  ;# constant 10001000
	shufps xmm6, xmm7, 221  ;# constant 11011101
	
	movd  eax, mm0		
	movd  ebx, mm1
	movd  ecx, mm2
	movd  edx, mm3

	movaps [esp + nb310_c6], xmm4
	movaps [esp + nb310_c12], xmm6
	
	mov esi, [ebp + nb310_pos]       ;# base of pos[] 

	lea   eax, [eax + eax*2]     ;# replace jnr with j3 
	lea   ebx, [ebx + ebx*2]	

	lea   ecx, [ecx + ecx*2]     ;# replace jnr with j3 
	lea   edx, [edx + edx*2]	

	;# move four coordinates to xmm0-xmm2 	

	movlps xmm4, [esi + eax*4]
	movlps xmm5, [esi + ecx*4]
	movss xmm2, [esi + eax*4 + 8]
	movss xmm6, [esi + ecx*4 + 8]

	movhps xmm4, [esi + ebx*4]
	movhps xmm5, [esi + edx*4]

	movss xmm0, [esi + ebx*4 + 8]
	movss xmm1, [esi + edx*4 + 8]

	shufps xmm2, xmm0, 0
	shufps xmm6, xmm1, 0
	
	movaps xmm0, xmm4
	movaps xmm1, xmm4

	shufps xmm2, xmm6, 136  ;# constant 10001000
	
	shufps xmm0, xmm5, 136  ;# constant 10001000
	shufps xmm1, xmm5, 221  ;# constant 11011101		

	;# move ix-iz to xmm4-xmm6 
	movaps xmm4, [esp + nb310_ix]
	movaps xmm5, [esp + nb310_iy]
	movaps xmm6, [esp + nb310_iz]

	;# calc dr 
	subps xmm4, xmm0
	subps xmm5, xmm1
	subps xmm6, xmm2

	;# store dr 
	movaps [esp + nb310_dx], xmm4
	movaps [esp + nb310_dy], xmm5
	movaps [esp + nb310_dz], xmm6
	;# square it 
	mulps xmm4,xmm4
	mulps xmm5,xmm5
	mulps xmm6,xmm6
	addps xmm4, xmm5
	addps xmm4, xmm6
	;# rsq in xmm4 

	rsqrtps xmm5, xmm4
	;# lookup seed in xmm5 
	movaps xmm2, xmm5
	mulps xmm5, xmm5
	movaps xmm1, [esp + nb310_three]
	mulps xmm5, xmm4	;# rsq*lu*lu 			
	movaps xmm0, [esp + nb310_half]
	subps xmm1, xmm5	;# constant 30-rsq*lu*lu 
	mulps xmm1, xmm2	
	mulps xmm0, xmm1	;# xmm0=rinv 
	mulps xmm4, xmm0	;# xmm4=r 
	mulps xmm4, [esp + nb310_tsc]

	movhlps xmm5, xmm4
	cvttps2pi mm6, xmm4
	cvttps2pi mm7, xmm5	;# mm6/mm7 contain lu indices 
	cvtpi2ps xmm6, mm6
	cvtpi2ps xmm5, mm7
	movlhps xmm6, xmm5
	subps xmm4, xmm6	
	movaps xmm1, xmm4	;# xmm1=eps 
	movaps xmm2, xmm1	
	mulps  xmm2, xmm2	;# xmm2=eps2 
	pslld mm6, 2
	pslld mm7, 2

	movd mm0, eax	
	movd mm1, ebx
	movd mm2, ecx
	movd mm3, edx

	mov  esi, [ebp + nb310_VFtab]
	movd eax, mm6
	psrlq mm6, 32
	movd ecx, mm7
	psrlq mm7, 32
	movd ebx, mm6
	movd edx, mm7

	movlps xmm5, [esi + eax*4]
	movlps xmm7, [esi + ecx*4]
	movhps xmm5, [esi + ebx*4]
	movhps xmm7, [esi + edx*4] ;# got half coulomb table 

	movaps xmm4, xmm5
	shufps xmm4, xmm7, 136  ;# constant 10001000
	shufps xmm5, xmm7, 221  ;# constant 11011101

	movlps xmm7, [esi + eax*4 + 8]
	movlps xmm3, [esi + ecx*4 + 8]
	movhps xmm7, [esi + ebx*4 + 8]
	movhps xmm3, [esi + edx*4 + 8] ;# other half of coulomb table  
	movaps xmm6, xmm7
	shufps xmm6, xmm3, 136  ;# constant 10001000
	shufps xmm7, xmm3, 221  ;# constant 11011101
	;# coulomb table ready, in xmm4-xmm7  	
	
	mulps  xmm6, xmm1	;# xmm6=Geps 
	mulps  xmm7, xmm2	;# xmm7=Heps2 
	addps  xmm5, xmm6
	addps  xmm5, xmm7	;# xmm5=Fp 	
	mulps  xmm7, [esp + nb310_two]	;# two*Heps2 
	movaps xmm3, [esp + nb310_qq]
	addps  xmm7, xmm6
	addps  xmm7, xmm5 ;# xmm7=FF 
	mulps  xmm5, xmm1 ;# xmm5=eps*Fp 
	addps  xmm5, xmm4 ;# xmm5=VV 
	mulps  xmm5, xmm3 ;# vcoul=qq*VV  
	mulps  xmm3, xmm7 ;# fijC=FF*qq 
	;# L-J 
	movaps xmm4, xmm0
	mulps  xmm4, xmm0	;# xmm4=rinvsq 

	;# at this point mm5 contains vcoul and mm3 fijC 
	;# increment vcoul - then we can get rid of mm5 
	;# update vctot 
	addps  xmm5, [esp + nb310_vctot]

	movaps xmm6, xmm4
	mulps  xmm6, xmm4

	movaps [esp + nb310_vctot], xmm5 

	mulps  xmm6, xmm4	;# xmm6=rinvsix 
	movaps xmm4, xmm6
	mulps  xmm4, xmm4	;# xmm4=rinvtwelve 
	mulps  xmm6, [esp + nb310_c6]
	mulps  xmm4, [esp + nb310_c12]
	movaps xmm7, [esp + nb310_Vvdwtot]
	addps  xmm7, xmm4
	mulps  xmm4, [esp + nb310_twelve]
	subps  xmm7, xmm6
	mulps  xmm3, [esp + nb310_tsc]
	mulps  xmm6, [esp + nb310_six]
	movaps [esp + nb310_Vvdwtot], xmm7
	subps  xmm4, xmm6
	mulps  xmm4, xmm0
	subps  xmm4, xmm3
	mulps  xmm4, xmm0

	movaps xmm0, [esp + nb310_dx]
	movaps xmm1, [esp + nb310_dy]
	movaps xmm2, [esp + nb310_dz]

	movd eax, mm0	
	movd ebx, mm1
	movd ecx, mm2
	movd edx, mm3

	mov    edi, [ebp + nb310_faction]
	mulps  xmm0, xmm4
	mulps  xmm1, xmm4
	mulps  xmm2, xmm4
	;# xmm0-xmm2 contains tx-tz (partial force) 
	;# now update f_i 
	movaps xmm3, [esp + nb310_fix]
	movaps xmm4, [esp + nb310_fiy]
	movaps xmm5, [esp + nb310_fiz]
	addps  xmm3, xmm0
	addps  xmm4, xmm1
	addps  xmm5, xmm2
	movaps [esp + nb310_fix], xmm3
	movaps [esp + nb310_fiy], xmm4
	movaps [esp + nb310_fiz], xmm5
	;# the fj's - start by accumulating x & y forces from memory 
	movlps xmm4, [edi + eax*4]
	movlps xmm6, [edi + ecx*4]
	movhps xmm4, [edi + ebx*4]
	movhps xmm6, [edi + edx*4]

	movaps xmm3, xmm4
	shufps xmm3, xmm6, 136  ;# constant 10001000
	shufps xmm4, xmm6, 221  ;# constant 11011101			      

	;# now xmm3-xmm5 contains fjx, fjy, fjz 
	subps  xmm3, xmm0
	subps  xmm4, xmm1
	
	;# unpack them back so we can store them - first x & y in xmm3/xmm4 

	movaps xmm6, xmm3
	unpcklps xmm6, xmm4
	unpckhps xmm3, xmm4	
	;# xmm6(l)=x & y for j1, (h) for j2 
	;# xmm3(l)=x & y for j3, (h) for j4 
	movlps [edi + eax*4], xmm6
	movlps [edi + ecx*4], xmm3
	
	movhps [edi + ebx*4], xmm6
	movhps [edi + edx*4], xmm3

	;# and the z forces 
	movss  xmm4, [edi + eax*4 + 8]
	movss  xmm5, [edi + ebx*4 + 8]
	movss  xmm6, [edi + ecx*4 + 8]
	movss  xmm7, [edi + edx*4 + 8]
	subss  xmm4, xmm2
	shufps xmm2, xmm2, 229  ;# constant 11100101
	subss  xmm5, xmm2
	shufps xmm2, xmm2, 234  ;# constant 11101010
	subss  xmm6, xmm2
	shufps xmm2, xmm2, 255  ;# constant 11111111
	subss  xmm7, xmm2
	movss  [edi + eax*4 + 8], xmm4
	movss  [edi + ebx*4 + 8], xmm5
	movss  [edi + ecx*4 + 8], xmm6
	movss  [edi + edx*4 + 8], xmm7
	
	;# should we do one more iteration? 
	sub dword ptr [esp + nb310_innerk],  4
	jl    .nb310_finish_inner
	jmp   .nb310_unroll_loop
.nb310_finish_inner:
	;# check if at least two particles remain 
	add dword ptr [esp + nb310_innerk],  4
	mov   edx, [esp + nb310_innerk]
	and   edx, 2
	jnz   .nb310_dopair
	jmp   .nb310_checksingle
.nb310_dopair:	
	mov esi, [ebp + nb310_charge]
    mov   ecx, [esp + nb310_innerjjnr]
	mov   eax, [ecx]	
	mov   ebx, [ecx + 4]              
	add dword ptr [esp + nb310_innerjjnr],  8	
	xorps xmm7, xmm7
	movss xmm3, [esi + eax*4]		
	movss xmm6, [esi + ebx*4]
	shufps xmm3, xmm6, 0 
	shufps xmm3, xmm3, 8 ;# constant 00001000 ;# xmm3(0,1) has the charges 

	mulps  xmm3, [esp + nb310_iq]
	movlhps xmm3, xmm7
	movaps [esp + nb310_qq], xmm3

	mov esi, [ebp + nb310_type]
	mov   ecx, eax
	mov   edx, ebx
	mov ecx, [esi + ecx*4]
	mov edx, [esi + edx*4]	
	mov esi, [ebp + nb310_vdwparam]
	shl ecx, 1	
	shl edx, 1	
	mov edi, [esp + nb310_ntia]
	add ecx, edi
	add edx, edi
	movlps xmm6, [esi + ecx*4]
	movhps xmm6, [esi + edx*4]
	mov edi, [ebp + nb310_pos]	
	
	movaps xmm4, xmm6
	shufps xmm4, xmm4, 8 ;# constant 00001000 	
	shufps xmm6, xmm6, 13 ;# constant 00001101
	movlhps xmm4, xmm7
	movlhps xmm6, xmm7
	
	movaps [esp + nb310_c6], xmm4
	movaps [esp + nb310_c12], xmm6	
			
	lea   eax, [eax + eax*2]
	lea   ebx, [ebx + ebx*2]
	;# move coordinates to xmm0-xmm2 
	movlps xmm1, [edi + eax*4]
	movss xmm2, [edi + eax*4 + 8]	
	movhps xmm1, [edi + ebx*4]
	movss xmm0, [edi + ebx*4 + 8]	

	movlhps xmm3, xmm7
	
	shufps xmm2, xmm0, 0
	
	movaps xmm0, xmm1

	shufps xmm2, xmm2, 136  ;# constant 10001000
	
	shufps xmm0, xmm0, 136  ;# constant 10001000
	shufps xmm1, xmm1, 221  ;# constant 11011101
			
	mov    edi, [ebp + nb310_faction]
	;# move ix-iz to xmm4-xmm6 
	xorps   xmm7, xmm7
	
	movaps xmm4, [esp + nb310_ix]
	movaps xmm5, [esp + nb310_iy]
	movaps xmm6, [esp + nb310_iz]

	;# calc dr 
	subps xmm4, xmm0
	subps xmm5, xmm1
	subps xmm6, xmm2

	;# store dr 
	movaps [esp + nb310_dx], xmm4
	movaps [esp + nb310_dy], xmm5
	movaps [esp + nb310_dz], xmm6
	;# square it 
	mulps xmm4,xmm4
	mulps xmm5,xmm5
	mulps xmm6,xmm6
	addps xmm4, xmm5
	addps xmm4, xmm6
	;# rsq in xmm4 

	rsqrtps xmm5, xmm4
	;# lookup seed in xmm5 
	movaps xmm2, xmm5
	mulps xmm5, xmm5
	movaps xmm1, [esp + nb310_three]
	mulps xmm5, xmm4	;# rsq*lu*lu 			
	movaps xmm0, [esp + nb310_half]
	subps xmm1, xmm5	;# constant 30-rsq*lu*lu 
	mulps xmm1, xmm2	
	mulps xmm0, xmm1	;# xmm0=rinv 
	mulps xmm4, xmm0	;# xmm4=r 
	mulps xmm4, [esp + nb310_tsc]

	cvttps2pi mm6, xmm4     ;# mm6 contain lu indices 
	cvtpi2ps xmm6, mm6
	subps xmm4, xmm6	
	movaps xmm1, xmm4	;# xmm1=eps 
	movaps xmm2, xmm1	
	mulps  xmm2, xmm2	;# xmm2=eps2 

	pslld mm6, 2

	mov  esi, [ebp + nb310_VFtab]
	movd ecx, mm6
	psrlq mm6, 32
	movd edx, mm6

	movlps xmm5, [esi + ecx*4]
	movhps xmm5, [esi + edx*4] ;# got half coulomb table 
	movaps xmm4, xmm5
	shufps xmm4, xmm4, 136  ;# constant 10001000
	shufps xmm5, xmm7, 221  ;# constant 11011101
	
	movlps xmm7, [esi + ecx*4 + 8]
	movhps xmm7, [esi + edx*4 + 8]
	movaps xmm6, xmm7
	shufps xmm6, xmm6, 136  ;# constant 10001000
	shufps xmm7, xmm7, 221  ;# constant 11011101
	;# table ready in xmm4-xmm7 

	mulps  xmm6, xmm1	;# xmm6=Geps 
	mulps  xmm7, xmm2	;# xmm7=Heps2 
	addps  xmm5, xmm6
	addps  xmm5, xmm7	;# xmm5=Fp 	
	mulps  xmm7, [esp + nb310_two]	;# two*Heps2 
	movaps xmm3, [esp + nb310_qq]
	addps  xmm7, xmm6
	addps  xmm7, xmm5 ;# xmm7=FF 
	mulps  xmm5, xmm1 ;# xmm5=eps*Fp 
	addps  xmm5, xmm4 ;# xmm5=VV 
	mulps  xmm5, xmm3 ;# vcoul=qq*VV  
	mulps  xmm3, xmm7 ;# fijC=FF*qq 
	;# L-J 
	movaps xmm4, xmm0
	mulps  xmm4, xmm0	;# xmm4=rinvsq 

	;# at this point mm5 contains vcoul and mm3 fijC 
	;# increment vcoul - then we can get rid of mm5 
	;# update vctot 
	addps  xmm5, [esp + nb310_vctot]

	movaps xmm6, xmm4
	mulps  xmm6, xmm4

	movaps [esp + nb310_vctot], xmm5 

	mulps  xmm6, xmm4	;# xmm6=rinvsix 
	movaps xmm4, xmm6
	mulps  xmm4, xmm4	;# xmm4=rinvtwelve 
	mulps  xmm6, [esp + nb310_c6]
	mulps  xmm4, [esp + nb310_c12]
	movaps xmm7, [esp + nb310_Vvdwtot]
	addps  xmm7, xmm4
	mulps  xmm4, [esp + nb310_twelve]
	subps  xmm7, xmm6
	mulps  xmm3, [esp + nb310_tsc]
	mulps  xmm6, [esp + nb310_six]
	movaps [esp + nb310_Vvdwtot], xmm7
	subps  xmm4, xmm6
	mulps  xmm4, xmm0
	subps  xmm4, xmm3
	mulps  xmm4, xmm0

	movaps xmm0, [esp + nb310_dx]
	movaps xmm1, [esp + nb310_dy]
	movaps xmm2, [esp + nb310_dz]

	mulps  xmm0, xmm4
	mulps  xmm1, xmm4
	mulps  xmm2, xmm4
	;# xmm0-xmm2 contains tx-tz (partial force) 
	;# now update f_i 
	movaps xmm3, [esp + nb310_fix]
	movaps xmm4, [esp + nb310_fiy]
	movaps xmm5, [esp + nb310_fiz]
	addps  xmm3, xmm0
	addps  xmm4, xmm1
	addps  xmm5, xmm2
	movaps [esp + nb310_fix], xmm3
	movaps [esp + nb310_fiy], xmm4
	movaps [esp + nb310_fiz], xmm5
	;# update the fj's 
	movss   xmm3, [edi + eax*4]
	movss   xmm4, [edi + eax*4 + 4]
	movss   xmm5, [edi + eax*4 + 8]
	subss   xmm3, xmm0
	subss   xmm4, xmm1
	subss   xmm5, xmm2	
	movss   [edi + eax*4], xmm3
	movss   [edi + eax*4 + 4], xmm4
	movss   [edi + eax*4 + 8], xmm5	

	shufps  xmm0, xmm0, 225  ;# constant 11100001
	shufps  xmm1, xmm1, 225  ;# constant 11100001
	shufps  xmm2, xmm2, 225  ;# constant 11100001

	movss   xmm3, [edi + ebx*4]
	movss   xmm4, [edi + ebx*4 + 4]
	movss   xmm5, [edi + ebx*4 + 8]
	subss   xmm3, xmm0
	subss   xmm4, xmm1
	subss   xmm5, xmm2	
	movss   [edi + ebx*4], xmm3
	movss   [edi + ebx*4 + 4], xmm4
	movss   [edi + ebx*4 + 8], xmm5	

.nb310_checksingle:				
	mov   edx, [esp + nb310_innerk]
	and   edx, 1
	jnz    .nb310_dosingle
	jmp    .nb310_updateouterdata
.nb310_dosingle:
	mov esi, [ebp + nb310_charge]
	mov edi, [ebp + nb310_pos]
	mov   ecx, [esp + nb310_innerjjnr]
	mov   eax, [ecx]	
	xorps  xmm6, xmm6
	movss xmm6, [esi + eax*4]	;# xmm6(0) has the charge 	
	mulps  xmm6, [esp + nb310_iq]
	movaps [esp + nb310_qq], xmm6

	mov esi, [ebp + nb310_type]
	mov ecx, eax
	mov ecx, [esi + ecx*4]	
	mov esi, [ebp + nb310_vdwparam]
	shl ecx, 1
	add ecx, [esp + nb310_ntia]
	movlps xmm6, [esi + ecx*4]
	movaps xmm4, xmm6
	shufps xmm4, xmm4, 252  ;# constant 11111100	
	shufps xmm6, xmm6, 253  ;# constant 11111101	
			
	movaps [esp + nb310_c6], xmm4
	movaps [esp + nb310_c12], xmm6	
		
	lea   eax, [eax + eax*2]
	
	;# move coordinates to xmm0-xmm2 
	movss xmm0, [edi + eax*4]	
	movss xmm1, [edi + eax*4 + 4]	
	movss xmm2, [edi + eax*4 + 8]	 
	
	movaps xmm4, [esp + nb310_ix]
	movaps xmm5, [esp + nb310_iy]
	movaps xmm6, [esp + nb310_iz]

	;# calc dr 
	subps xmm4, xmm0
	subps xmm5, xmm1
	subps xmm6, xmm2

	;# store dr 
	movaps [esp + nb310_dx], xmm4
	movaps [esp + nb310_dy], xmm5
	movaps [esp + nb310_dz], xmm6
	;# square it 
	mulps xmm4,xmm4
	mulps xmm5,xmm5
	mulps xmm6,xmm6
	addps xmm4, xmm5
	addps xmm4, xmm6
	;# rsq in xmm4 

	rsqrtps xmm5, xmm4
	;# lookup seed in xmm5 
	movaps xmm2, xmm5
	mulps xmm5, xmm5
	movaps xmm1, [esp + nb310_three]
	mulps xmm5, xmm4	;# rsq*lu*lu 			
	movaps xmm0, [esp + nb310_half]
	subps xmm1, xmm5	;# constant 30-rsq*lu*lu 
	mulps xmm1, xmm2	
	mulps xmm0, xmm1	;# xmm0=rinv 

	mulps xmm4, xmm0	;# xmm4=r 
	mulps xmm4, [esp + nb310_tsc]

	cvttps2pi mm6, xmm4     ;# mm6 contain lu indices 
	cvtpi2ps xmm6, mm6
	subps xmm4, xmm6	
	movaps xmm1, xmm4	;# xmm1=eps 
	movaps xmm2, xmm1	
	mulps  xmm2, xmm2	;# xmm2=eps2 

	pslld mm6, 2

	mov  esi, [ebp + nb310_VFtab]
	movd ebx, mm6
	
	movlps xmm4, [esi + ebx*4]
	movlps xmm6, [esi + ebx*4 + 8]
	movaps xmm5, xmm4
	movaps xmm7, xmm6
	shufps xmm5, xmm5, 1
	shufps xmm7, xmm7, 1
	;# table ready in xmm4-xmm7 

	mulps  xmm6, xmm1	;# xmm6=Geps 
	mulps  xmm7, xmm2	;# xmm7=Heps2 
	addps  xmm5, xmm6
	addps  xmm5, xmm7	;# xmm5=Fp 	
	mulps  xmm7, [esp + nb310_two]	;# two*Heps2 
	movaps xmm3, [esp + nb310_qq]
	addps  xmm7, xmm6
	addps  xmm7, xmm5 ;# xmm7=FF 
	mulps  xmm5, xmm1 ;# xmm5=eps*Fp 
	addps  xmm5, xmm4 ;# xmm5=VV 
	mulps  xmm5, xmm3 ;# vcoul=qq*VV  
	mulps  xmm3, xmm7 ;# fijC=FF*qq 
	;# L-J 
	movaps xmm4, xmm0
	mulps  xmm4, xmm0	;# xmm4=rinvsq 

	;# at this point mm5 contains vcoul and mm3 fijC 
	;# increment vcoul - then we can get rid of mm5 
	;# update vctot 
	addss  xmm5, [esp + nb310_vctot]

	movaps xmm6, xmm4
	mulps  xmm6, xmm4

	movss [esp + nb310_vctot], xmm5 

	mulps  xmm6, xmm4	;# xmm6=rinvsix 
	movaps xmm4, xmm6
	mulps  xmm4, xmm4	;# xmm4=rinvtwelve 
	mulps  xmm6, [esp + nb310_c6]
	mulps  xmm4, [esp + nb310_c12]
	movss xmm7, [esp + nb310_Vvdwtot]
	addps  xmm7, xmm4
	mulps  xmm4, [esp + nb310_twelve]
	subps  xmm7, xmm6
	mulps  xmm3, [esp + nb310_tsc]
	mulps  xmm6, [esp + nb310_six]
	movss [esp + nb310_Vvdwtot], xmm7
	subps  xmm4, xmm6
	mulps  xmm4, xmm0
	subps  xmm4, xmm3
	mulps  xmm4, xmm0

	movaps xmm0, [esp + nb310_dx]
	movaps xmm1, [esp + nb310_dy]
	movaps xmm2, [esp + nb310_dz]

	mov    edi, [ebp + nb310_faction]
	mulps  xmm0, xmm4
	mulps  xmm1, xmm4
	mulps  xmm2, xmm4
	;# xmm0-xmm2 contains tx-tz (partial force) 
	;# now update f_i 
	movaps xmm3, [esp + nb310_fix]
	movaps xmm4, [esp + nb310_fiy]
	movaps xmm5, [esp + nb310_fiz]
	addss  xmm3, xmm0
	addss  xmm4, xmm1
	addss  xmm5, xmm2
	movaps [esp + nb310_fix], xmm3
	movaps [esp + nb310_fiy], xmm4
	movaps [esp + nb310_fiz], xmm5
	;# update fj 
	
	movss   xmm3, [edi + eax*4]
	movss   xmm4, [edi + eax*4 + 4]
	movss   xmm5, [edi + eax*4 + 8]
	subss   xmm3, xmm0
	subss   xmm4, xmm1
	subss   xmm5, xmm2	
	movss   [edi + eax*4], xmm3
	movss   [edi + eax*4 + 4], xmm4
	movss   [edi + eax*4 + 8], xmm5	
.nb310_updateouterdata:
	mov   ecx, [esp + nb310_ii3]
	mov   edi, [ebp + nb310_faction]
	mov   esi, [ebp + nb310_fshift]
	mov   edx, [esp + nb310_is3]

	;# accumulate i forces in xmm0, xmm1, xmm2 
	movaps xmm0, [esp + nb310_fix]
	movaps xmm1, [esp + nb310_fiy]
	movaps xmm2, [esp + nb310_fiz]

	movhlps xmm3, xmm0
	movhlps xmm4, xmm1
	movhlps xmm5, xmm2
	addps  xmm0, xmm3
	addps  xmm1, xmm4
	addps  xmm2, xmm5 ;# sum is in 1/2 in xmm0-xmm2 

	movaps xmm3, xmm0	
	movaps xmm4, xmm1	
	movaps xmm5, xmm2	

	shufps xmm3, xmm3, 1
	shufps xmm4, xmm4, 1
	shufps xmm5, xmm5, 1
	addss  xmm0, xmm3
	addss  xmm1, xmm4
	addss  xmm2, xmm5	;# xmm0-xmm2 has single force in pos0 

	;# increment i force 
	movss  xmm3, [edi + ecx*4]
	movss  xmm4, [edi + ecx*4 + 4]
	movss  xmm5, [edi + ecx*4 + 8]
	addss  xmm3, xmm0
	addss  xmm4, xmm1
	addss  xmm5, xmm2
	movss  [edi + ecx*4],     xmm3
	movss  [edi + ecx*4 + 4], xmm4
	movss  [edi + ecx*4 + 8], xmm5

	;# increment fshift force  
	movss  xmm3, [esi + edx*4]
	movss  xmm4, [esi + edx*4 + 4]
	movss  xmm5, [esi + edx*4 + 8]
	addss  xmm3, xmm0
	addss  xmm4, xmm1
	addss  xmm5, xmm2
	movss  [esi + edx*4],     xmm3
	movss  [esi + edx*4 + 4], xmm4
	movss  [esi + edx*4 + 8], xmm5

	;# get n from stack
	mov esi, [esp + nb310_n]
        ;# get group index for i particle 
        mov   edx, [ebp + nb310_gid]      	;# base of gid[]
        mov   edx, [edx + esi*4]		;# ggid=gid[n]

	;# accumulate total potential energy and update it 
	movaps xmm7, [esp + nb310_vctot]
	;# accumulate 
	movhlps xmm6, xmm7
	addps  xmm7, xmm6	;# pos 0-1 in xmm7 have the sum now 
	movaps xmm6, xmm7
	shufps xmm6, xmm6, 1
	addss  xmm7, xmm6		

	;# add earlier value from mem 
	mov   eax, [ebp + nb310_Vc]
	addss xmm7, [eax + edx*4] 
	;# move back to mem 
	movss [eax + edx*4], xmm7 
	
	;# accumulate total lj energy and update it 
	movaps xmm7, [esp + nb310_Vvdwtot]
	;# accumulate 
	movhlps xmm6, xmm7
	addps  xmm7, xmm6	;# pos 0-1 in xmm7 have the sum now 
	movaps xmm6, xmm7
	shufps xmm6, xmm6, 1
	addss  xmm7, xmm6		

	;# add earlier value from mem 
	mov   eax, [ebp + nb310_Vvdw]
	addss xmm7, [eax + edx*4] 
	;# move back to mem 
	movss [eax + edx*4], xmm7 
	
        ;# finish if last 
        mov ecx, [esp + nb310_nn1]
	;# esi already loaded with n
	inc esi
        sub ecx, esi
        jz .nb310_outerend

        ;# not last, iterate outer loop once more!  
        mov [esp + nb310_n], esi
        jmp .nb310_outer
.nb310_outerend:
        ;# check if more outer neighborlists remain
        mov   ecx, [esp + nb310_nri]
	;# esi already loaded with n above
        sub   ecx, esi
        jz .nb310_end
        ;# non-zero, do one more workunit
        jmp   .nb310_threadloop
.nb310_end:
	emms

	mov eax, [esp + nb310_nouter]
	mov ebx, [esp + nb310_ninner]
	mov ecx, [ebp + nb310_outeriter]
	mov edx, [ebp + nb310_inneriter]
	mov [ecx], eax
	mov [edx], ebx

	mov eax, [esp + nb310_salign]
	add esp, eax
	add esp, 404
	pop edi
	pop esi
    	pop edx
    	pop ecx
    	pop ebx
    	pop eax
	leave
	ret



.globl nb_kernel310nf_ia32_sse
.globl _nb_kernel310nf_ia32_sse
nb_kernel310nf_ia32_sse:	
_nb_kernel310nf_ia32_sse:	
.equiv          nb310nf_p_nri,          8
.equiv          nb310nf_iinr,           12
.equiv          nb310nf_jindex,         16
.equiv          nb310nf_jjnr,           20
.equiv          nb310nf_shift,          24
.equiv          nb310nf_shiftvec,       28
.equiv          nb310nf_fshift,         32
.equiv          nb310nf_gid,            36
.equiv          nb310nf_pos,            40
.equiv          nb310nf_faction,        44
.equiv          nb310nf_charge,         48
.equiv          nb310nf_p_facel,        52
.equiv          nb310nf_argkrf,         56
.equiv          nb310nf_argcrf,         60
.equiv          nb310nf_Vc,             64
.equiv          nb310nf_type,           68
.equiv          nb310nf_p_ntype,        72
.equiv          nb310nf_vdwparam,       76
.equiv          nb310nf_Vvdw,           80
.equiv          nb310nf_p_tabscale,     84
.equiv          nb310nf_VFtab,          88
.equiv          nb310nf_invsqrta,       92
.equiv          nb310nf_dvda,           96
.equiv          nb310nf_p_gbtabscale,   100
.equiv          nb310nf_GBtab,          104
.equiv          nb310nf_p_nthreads,     108
.equiv          nb310nf_count,          112
.equiv          nb310nf_mtx,            116
.equiv          nb310nf_outeriter,      120
.equiv          nb310nf_inneriter,      124
.equiv          nb310nf_work,           128
	;# stack offsets for local variables  
	;# bottom of stack is cache-aligned for sse use 
.equiv          nb310nf_ix,             0
.equiv          nb310nf_iy,             16
.equiv          nb310nf_iz,             32
.equiv          nb310nf_iq,             48
.equiv          nb310nf_tsc,            64
.equiv          nb310nf_qq,             80
.equiv          nb310nf_c6,             96
.equiv          nb310nf_c12,            112
.equiv          nb310nf_vctot,          128
.equiv          nb310nf_Vvdwtot,        144
.equiv          nb310nf_half,           160
.equiv          nb310nf_three,          176
.equiv          nb310nf_is3,            192
.equiv          nb310nf_ii3,            196
.equiv          nb310nf_ntia,           200
.equiv          nb310nf_innerjjnr,      204
.equiv          nb310nf_innerk,         208
.equiv          nb310nf_n,              212
.equiv          nb310nf_nn1,            216
.equiv          nb310nf_nri,            220
.equiv          nb310nf_facel,          224
.equiv          nb310nf_ntype,          228
.equiv          nb310nf_nouter,         232
.equiv          nb310nf_ninner,         236
.equiv          nb310nf_salign,         240
	push ebp
	mov ebp,esp	
    	push eax
    	push ebx
    	push ecx
    	push edx
	push esi
	push edi
	sub esp, 244		;# local stack space 
	mov  eax, esp
	and  eax, 0xf
	sub esp, eax
	mov [esp + nb310nf_salign], eax

	emms

	;# Move args passed by reference to stack
	mov ecx, [ebp + nb310nf_p_nri]
	mov esi, [ebp + nb310nf_p_facel]
	mov edi, [ebp + nb310nf_p_ntype]
	mov ecx, [ecx]
	mov esi, [esi]
	mov edi, [edi]
	mov [esp + nb310nf_nri], ecx
	mov [esp + nb310nf_facel], esi
	mov [esp + nb310nf_ntype], edi

	;# zero iteration counters
	mov eax, 0
	mov [esp + nb310nf_nouter], eax
	mov [esp + nb310nf_ninner], eax


	;# create constant floating-point factors on stack
	mov eax, 0x3f000000     ;# constant 0.5 in IEEE (hex)
	mov [esp + nb310nf_half], eax
	movss xmm1, [esp + nb310nf_half]
	shufps xmm1, xmm1, 0    ;# splat to all elements
	movaps xmm2, xmm1       
	addps  xmm2, xmm2	;# constant 1.0
	movaps xmm3, xmm2
	addps  xmm2, xmm2	;# constant 2.0
	addps  xmm3, xmm2	;# constant 3.0
	movaps [esp + nb310nf_half],  xmm1
	movaps [esp + nb310nf_three],  xmm3
	mov eax, [ebp + nb310nf_p_tabscale]
	movss xmm5, [eax]
	shufps xmm5, xmm5, 0
	movaps [esp + nb310nf_tsc],  xmm5	

.nb310nf_threadloop:
        mov   esi, [ebp + nb310nf_count]          ;# pointer to sync counter
        mov   eax, [esi]
.nb310nf_spinlock:
        mov   ebx, eax                          ;# ebx=*count=nn0
        add   ebx, 1                           ;# ebx=nn1=nn0+10
        lock
        cmpxchg [esi], ebx                      ;# write nn1 to *counter,
                                                ;# if it hasnt changed.
                                                ;# or reread *counter to eax.
        pause                                   ;# -> better p4 performance
        jnz .nb310nf_spinlock

        ;# if(nn1>nri) nn1=nri
        mov ecx, [esp + nb310nf_nri]
        mov edx, ecx
        sub ecx, ebx
        cmovle ebx, edx                         ;# if(nn1>nri) nn1=nri
        ;# Cleared the spinlock if we got here.
        ;# eax contains nn0, ebx contains nn1.
        mov [esp + nb310nf_n], eax
        mov [esp + nb310nf_nn1], ebx
        sub ebx, eax                            ;# calc number of outer lists
	mov esi, eax				;# copy n to esi
        jg  .nb310nf_outerstart
        jmp .nb310nf_end

.nb310nf_outerstart:
	;# ebx contains number of outer iterations
	add ebx, [esp + nb310nf_nouter]
	mov [esp + nb310nf_nouter], ebx

.nb310nf_outer:
	mov   eax, [ebp + nb310nf_shift]      ;# eax = pointer into shift[] 
	mov   ebx, [eax + esi*4]		;# ebx=shift[n] 
	
	lea   ebx, [ebx + ebx*2]    ;# ebx=3*is 
	mov   [esp + nb310nf_is3],ebx    	;# store is3 

	mov   eax, [ebp + nb310nf_shiftvec]   ;# eax = base of shiftvec[] 

	movss xmm0, [eax + ebx*4]
	movss xmm1, [eax + ebx*4 + 4]
	movss xmm2, [eax + ebx*4 + 8] 

	mov   ecx, [ebp + nb310nf_iinr]       ;# ecx = pointer into iinr[] 	
	mov   ebx, [ecx + esi*4]	    ;# ebx =ii 

	mov   edx, [ebp + nb310nf_charge]
	movss xmm3, [edx + ebx*4]	
	mulss xmm3, [esp + nb310nf_facel]
	shufps xmm3, xmm3, 0

    	mov   edx, [ebp + nb310nf_type] 
    	mov   edx, [edx + ebx*4]
    	imul  edx, [esp + nb310nf_ntype]
    	shl   edx, 1
    	mov   [esp + nb310nf_ntia], edx
		
	lea   ebx, [ebx + ebx*2]	;# ebx = 3*ii=ii3 
	mov   eax, [ebp + nb310nf_pos]    ;# eax = base of pos[]  

	addss xmm0, [eax + ebx*4]
	addss xmm1, [eax + ebx*4 + 4]
	addss xmm2, [eax + ebx*4 + 8]

	movaps [esp + nb310nf_iq], xmm3
	
	shufps xmm0, xmm0, 0
	shufps xmm1, xmm1, 0
	shufps xmm2, xmm2, 0

	movaps [esp + nb310nf_ix], xmm0
	movaps [esp + nb310nf_iy], xmm1
	movaps [esp + nb310nf_iz], xmm2

	mov   [esp + nb310nf_ii3], ebx
	
	;# clear vctot and i forces 
	xorps xmm4, xmm4
	movaps [esp + nb310nf_vctot], xmm4
	movaps [esp + nb310nf_Vvdwtot], xmm4
	
	mov   eax, [ebp + nb310nf_jindex]
	mov   ecx, [eax + esi*4]	     ;# jindex[n] 
	mov   edx, [eax + esi*4 + 4]	     ;# jindex[n+1] 
	sub   edx, ecx               ;# number of innerloop atoms 

	mov   esi, [ebp + nb310nf_pos]
	mov   eax, [ebp + nb310nf_jjnr]
	shl   ecx, 2
	add   eax, ecx
	mov   [esp + nb310nf_innerjjnr], eax     ;# pointer to jjnr[nj0] 
	mov   ecx, edx
	sub   edx,  4
	add   ecx, [esp + nb310nf_ninner]
	mov   [esp + nb310nf_ninner], ecx
	add   edx, 0
	mov   [esp + nb310nf_innerk], edx    ;# number of innerloop atoms 
	jge   .nb310nf_unroll_loop
	jmp   .nb310nf_finish_inner
.nb310nf_unroll_loop:	
	;# quad-unroll innerloop here 
	mov   edx, [esp + nb310nf_innerjjnr]     ;# pointer to jjnr[k] 
	mov   eax, [edx]	
	mov   ebx, [edx + 4]              
	mov   ecx, [edx + 8]            
	mov   edx, [edx + 12]         ;# eax-edx=jnr1-4 
	add dword ptr [esp + nb310nf_innerjjnr],  16 ;# advance pointer (unrolled 4) 

	mov esi, [ebp + nb310nf_charge]    ;# base of charge[] 
	
	movss xmm3, [esi + eax*4]
	movss xmm4, [esi + ecx*4]
	movss xmm6, [esi + ebx*4]
	movss xmm7, [esi + edx*4]

	movaps xmm2, [esp + nb310nf_iq]
	shufps xmm3, xmm6, 0 
	shufps xmm4, xmm7, 0 
	shufps xmm3, xmm4, 136  ;# constant 10001000 ;# all charges in xmm3  
	movd  mm0, eax		;# use mmx registers as temp storage 
	movd  mm1, ebx
	mulps  xmm3, xmm2
	movd  mm2, ecx
	movd  mm3, edx

	movaps [esp + nb310nf_qq], xmm3
	
	mov esi, [ebp + nb310nf_type]
	mov eax, [esi + eax*4]
	mov ebx, [esi + ebx*4]
	mov ecx, [esi + ecx*4]
	mov edx, [esi + edx*4]
	mov esi, [ebp + nb310nf_vdwparam]
	shl eax, 1	
	shl ebx, 1	
	shl ecx, 1	
	shl edx, 1	
	mov edi, [esp + nb310nf_ntia]
	add eax, edi
	add ebx, edi
	add ecx, edi
	add edx, edi

	movlps xmm6, [esi + eax*4]
	movlps xmm7, [esi + ecx*4]
	movhps xmm6, [esi + ebx*4]
	movhps xmm7, [esi + edx*4]

	movaps xmm4, xmm6
	shufps xmm4, xmm7, 136  ;# constant 10001000
	shufps xmm6, xmm7, 221  ;# constant 11011101
	
	movd  eax, mm0		
	movd  ebx, mm1
	movd  ecx, mm2
	movd  edx, mm3

	movaps [esp + nb310nf_c6], xmm4
	movaps [esp + nb310nf_c12], xmm6
	
	mov esi, [ebp + nb310nf_pos]       ;# base of pos[] 

	lea   eax, [eax + eax*2]     ;# replace jnr with j3 
	lea   ebx, [ebx + ebx*2]	

	lea   ecx, [ecx + ecx*2]     ;# replace jnr with j3 
	lea   edx, [edx + edx*2]	

	;# move four coordinates to xmm0-xmm2 	

	movlps xmm4, [esi + eax*4]
	movlps xmm5, [esi + ecx*4]
	movss xmm2, [esi + eax*4 + 8]
	movss xmm6, [esi + ecx*4 + 8]

	movhps xmm4, [esi + ebx*4]
	movhps xmm5, [esi + edx*4]

	movss xmm0, [esi + ebx*4 + 8]
	movss xmm1, [esi + edx*4 + 8]

	shufps xmm2, xmm0, 0
	shufps xmm6, xmm1, 0
	
	movaps xmm0, xmm4
	movaps xmm1, xmm4

	shufps xmm2, xmm6, 136  ;# constant 10001000
	
	shufps xmm0, xmm5, 136  ;# constant 10001000
	shufps xmm1, xmm5, 221  ;# constant 11011101		

	;# move ix-iz to xmm4-xmm6 
	movaps xmm4, [esp + nb310nf_ix]
	movaps xmm5, [esp + nb310nf_iy]
	movaps xmm6, [esp + nb310nf_iz]

	;# calc dr 
	subps xmm4, xmm0
	subps xmm5, xmm1
	subps xmm6, xmm2

	;# square it 
	mulps xmm4,xmm4
	mulps xmm5,xmm5
	mulps xmm6,xmm6
	addps xmm4, xmm5
	addps xmm4, xmm6
	;# rsq in xmm4 

	rsqrtps xmm5, xmm4
	;# lookup seed in xmm5 
	movaps xmm2, xmm5
	mulps xmm5, xmm5
	movaps xmm1, [esp + nb310nf_three]
	mulps xmm5, xmm4	;# rsq*lu*lu 			
	movaps xmm0, [esp + nb310nf_half]
	subps xmm1, xmm5	;# constant 30-rsq*lu*lu 
	mulps xmm1, xmm2	
	mulps xmm0, xmm1	;# xmm0=rinv 
	mulps xmm4, xmm0	;# xmm4=r 
	mulps xmm4, [esp + nb310nf_tsc]

	movhlps xmm5, xmm4
	cvttps2pi mm6, xmm4
	cvttps2pi mm7, xmm5	;# mm6/mm7 contain lu indices 
	cvtpi2ps xmm6, mm6
	cvtpi2ps xmm5, mm7
	movlhps xmm6, xmm5
	subps xmm4, xmm6	
	movaps xmm1, xmm4	;# xmm1=eps 
	movaps xmm2, xmm1	
	mulps  xmm2, xmm2	;# xmm2=eps2 
	pslld mm6, 2
	pslld mm7, 2

	movd mm0, eax	
	movd mm1, ebx
	movd mm2, ecx
	movd mm3, edx

	mov  esi, [ebp + nb310nf_VFtab]
	movd eax, mm6
	psrlq mm6, 32
	movd ecx, mm7
	psrlq mm7, 32
	movd ebx, mm6
	movd edx, mm7

	movlps xmm5, [esi + eax*4]
	movlps xmm7, [esi + ecx*4]
	movhps xmm5, [esi + ebx*4]
	movhps xmm7, [esi + edx*4] ;# got half coulomb table 

	movaps xmm4, xmm5
	shufps xmm4, xmm7, 136  ;# constant 10001000
	shufps xmm5, xmm7, 221  ;# constant 11011101

	movlps xmm7, [esi + eax*4 + 8]
	movlps xmm3, [esi + ecx*4 + 8]
	movhps xmm7, [esi + ebx*4 + 8]
	movhps xmm3, [esi + edx*4 + 8] ;# other half of coulomb table  
	movaps xmm6, xmm7
	shufps xmm6, xmm3, 136  ;# constant 10001000
	shufps xmm7, xmm3, 221  ;# constant 11011101
	;# coulomb table ready, in xmm4-xmm7  	
	
	mulps  xmm6, xmm1	;# xmm6=Geps 
	mulps  xmm7, xmm2	;# xmm7=Heps2 
	addps  xmm5, xmm6
	addps  xmm5, xmm7	;# xmm5=Fp 	
	movaps xmm3, [esp + nb310nf_qq]
	mulps  xmm5, xmm1 ;# xmm5=eps*Fp 
	addps  xmm5, xmm4 ;# xmm5=VV 
	mulps  xmm5, xmm3 ;# vcoul=qq*VV  
	;# L-J 
	movaps xmm4, xmm0
	mulps  xmm4, xmm0	;# xmm4=rinvsq 

	;# at this point mm5 contains vcoul  
	;# increment vcoul - then we can get rid of mm5 
	;# update vctot 
	addps  xmm5, [esp + nb310nf_vctot]
	movaps xmm6, xmm4
 	mulps  xmm6, xmm4
	movaps [esp + nb310nf_vctot], xmm5 

	mulps  xmm6, xmm4	;# xmm6=rinvsix 
	movaps xmm4, xmm6
	mulps  xmm4, xmm4	;# xmm4=rinvtwelve 
	mulps  xmm6, [esp + nb310nf_c6]
	mulps  xmm4, [esp + nb310nf_c12]
	movaps xmm7, [esp + nb310nf_Vvdwtot]
	addps  xmm7, xmm4
	subps  xmm7, xmm6
	movaps [esp + nb310nf_Vvdwtot], xmm7


	;# should we do one more iteration? 
	sub dword ptr [esp + nb310nf_innerk],  4
	jl    .nb310nf_finish_inner
	jmp   .nb310nf_unroll_loop
.nb310nf_finish_inner:
	;# check if at least two particles remain 
	add dword ptr [esp + nb310nf_innerk],  4
	mov   edx, [esp + nb310nf_innerk]
	and   edx, 2
	jnz   .nb310nf_dopair
	jmp   .nb310nf_checksingle
.nb310nf_dopair:	
	mov esi, [ebp + nb310nf_charge]
    mov   ecx, [esp + nb310nf_innerjjnr]
	mov   eax, [ecx]	
	mov   ebx, [ecx + 4]              
	add dword ptr [esp + nb310nf_innerjjnr],  8	
	xorps xmm7, xmm7
	movss xmm3, [esi + eax*4]		
	movss xmm6, [esi + ebx*4]
	shufps xmm3, xmm6, 0 
	shufps xmm3, xmm3, 8 ;# constant 00001000 ;# xmm3(0,1) has the charges 

	mulps  xmm3, [esp + nb310nf_iq]
	movlhps xmm3, xmm7
	movaps [esp + nb310nf_qq], xmm3

	mov esi, [ebp + nb310nf_type]
	mov   ecx, eax
	mov   edx, ebx
	mov ecx, [esi + ecx*4]
	mov edx, [esi + edx*4]	
	mov esi, [ebp + nb310nf_vdwparam]
	shl ecx, 1	
	shl edx, 1	
	mov edi, [esp + nb310nf_ntia]
	add ecx, edi
	add edx, edi
	movlps xmm6, [esi + ecx*4]
	movhps xmm6, [esi + edx*4]
	mov edi, [ebp + nb310nf_pos]	
	
	movaps xmm4, xmm6
	shufps xmm4, xmm4, 8 ;# constant 00001000 	
	shufps xmm6, xmm6, 13 ;# constant 00001101
	movlhps xmm4, xmm7
	movlhps xmm6, xmm7
	
	movaps [esp + nb310nf_c6], xmm4
	movaps [esp + nb310nf_c12], xmm6	
			
	lea   eax, [eax + eax*2]
	lea   ebx, [ebx + ebx*2]
	;# move coordinates to xmm0-xmm2 
	movlps xmm1, [edi + eax*4]
	movss xmm2, [edi + eax*4 + 8]	
	movhps xmm1, [edi + ebx*4]
	movss xmm0, [edi + ebx*4 + 8]	

	movlhps xmm3, xmm7
	
	shufps xmm2, xmm0, 0
	
	movaps xmm0, xmm1

	shufps xmm2, xmm2, 136  ;# constant 10001000
	
	shufps xmm0, xmm0, 136  ;# constant 10001000
	shufps xmm1, xmm1, 221  ;# constant 11011101
			
	;# move ix-iz to xmm4-xmm6 
	xorps   xmm7, xmm7
	
	movaps xmm4, [esp + nb310nf_ix]
	movaps xmm5, [esp + nb310nf_iy]
	movaps xmm6, [esp + nb310nf_iz]

	;# calc dr 
	subps xmm4, xmm0
	subps xmm5, xmm1
	subps xmm6, xmm2

	;# square it 
	mulps xmm4,xmm4
	mulps xmm5,xmm5
	mulps xmm6,xmm6
	addps xmm4, xmm5
	addps xmm4, xmm6
	;# rsq in xmm4 

	rsqrtps xmm5, xmm4
	;# lookup seed in xmm5 
	movaps xmm2, xmm5
	mulps xmm5, xmm5
	movaps xmm1, [esp + nb310nf_three]
	mulps xmm5, xmm4	;# rsq*lu*lu 			
	movaps xmm0, [esp + nb310nf_half]
	subps xmm1, xmm5	;# constant 30-rsq*lu*lu 
	mulps xmm1, xmm2	
	mulps xmm0, xmm1	;# xmm0=rinv 
	mulps xmm4, xmm0	;# xmm4=r 
	mulps xmm4, [esp + nb310nf_tsc]

	cvttps2pi mm6, xmm4     ;# mm6 contain lu indices 
	cvtpi2ps xmm6, mm6
	subps xmm4, xmm6	
	movaps xmm1, xmm4	;# xmm1=eps 
	movaps xmm2, xmm1	
	mulps  xmm2, xmm2	;# xmm2=eps2 

	pslld mm6, 2

	mov  esi, [ebp + nb310nf_VFtab]
	movd ecx, mm6
	psrlq mm6, 32
	movd edx, mm6

	movlps xmm5, [esi + ecx*4]
	movhps xmm5, [esi + edx*4] ;# got half coulomb table 
	movaps xmm4, xmm5
	shufps xmm4, xmm4, 136  ;# constant 10001000
	shufps xmm5, xmm7, 221  ;# constant 11011101
	
	movlps xmm7, [esi + ecx*4 + 8]
	movhps xmm7, [esi + edx*4 + 8]
	movaps xmm6, xmm7
	shufps xmm6, xmm6, 136  ;# constant 10001000
	shufps xmm7, xmm7, 221  ;# constant 11011101
	;# table ready in xmm4-xmm7 

	mulps  xmm6, xmm1	;# xmm6=Geps 
	mulps  xmm7, xmm2	;# xmm7=Heps2 
	addps  xmm5, xmm6
	addps  xmm5, xmm7	;# xmm5=Fp 	
	movaps xmm3, [esp + nb310nf_qq]
	mulps  xmm5, xmm1 ;# xmm5=eps*Fp 
	addps  xmm5, xmm4 ;# xmm5=VV 
	mulps  xmm5, xmm3 ;# vcoul=qq*VV  
	;# L-J 
	movaps xmm4, xmm0
	mulps  xmm4, xmm0	;# xmm4=rinvsq 

	;# at this point mm5 contains vcoul  
	;# increment vcoul - then we can get rid of mm5 
	;# update vctot 
	addps  xmm5, [esp + nb310nf_vctot]

	movaps xmm6, xmm4
	mulps  xmm6, xmm4

	movaps [esp + nb310nf_vctot], xmm5 

	mulps  xmm6, xmm4	;# xmm6=rinvsix 
	movaps xmm4, xmm6
	mulps  xmm4, xmm4	;# xmm4=rinvtwelve 
	mulps  xmm6, [esp + nb310nf_c6]
	mulps  xmm4, [esp + nb310nf_c12]
	movaps xmm7, [esp + nb310nf_Vvdwtot]
	addps  xmm7, xmm4
	subps  xmm7, xmm6
	movaps [esp + nb310nf_Vvdwtot], xmm7

.nb310nf_checksingle:				
	mov   edx, [esp + nb310nf_innerk]
	and   edx, 1
	jnz    .nb310nf_dosingle
	jmp    .nb310nf_updateouterdata
.nb310nf_dosingle:
	mov esi, [ebp + nb310nf_charge]
	mov edi, [ebp + nb310nf_pos]
	mov   ecx, [esp + nb310nf_innerjjnr]
	mov   eax, [ecx]	
	xorps  xmm6, xmm6
	movss xmm6, [esi + eax*4]	;# xmm6(0) has the charge 	
	mulps  xmm6, [esp + nb310nf_iq]
	movaps [esp + nb310nf_qq], xmm6

	mov esi, [ebp + nb310nf_type]
	mov ecx, eax
	mov ecx, [esi + ecx*4]	
	mov esi, [ebp + nb310nf_vdwparam]
	shl ecx, 1
	add ecx, [esp + nb310nf_ntia]
	movlps xmm6, [esi + ecx*4]
	movaps xmm4, xmm6
	shufps xmm4, xmm4, 252  ;# constant 11111100	
	shufps xmm6, xmm6, 253  ;# constant 11111101	
			
	movaps [esp + nb310nf_c6], xmm4
	movaps [esp + nb310nf_c12], xmm6	
		
	lea   eax, [eax + eax*2]
	
	;# move coordinates to xmm0-xmm2 
	movss xmm0, [edi + eax*4]	
	movss xmm1, [edi + eax*4 + 4]	
	movss xmm2, [edi + eax*4 + 8]	 
	
	movaps xmm4, [esp + nb310nf_ix]
	movaps xmm5, [esp + nb310nf_iy]
	movaps xmm6, [esp + nb310nf_iz]

	;# calc dr 
	subps xmm4, xmm0
	subps xmm5, xmm1
	subps xmm6, xmm2

	;# square it 
	mulps xmm4,xmm4
	mulps xmm5,xmm5
	mulps xmm6,xmm6
	addps xmm4, xmm5
	addps xmm4, xmm6
	;# rsq in xmm4 

	rsqrtps xmm5, xmm4
	;# lookup seed in xmm5 
	movaps xmm2, xmm5
	mulps xmm5, xmm5
	movaps xmm1, [esp + nb310nf_three]
	mulps xmm5, xmm4	;# rsq*lu*lu 			
	movaps xmm0, [esp + nb310nf_half]
	subps xmm1, xmm5	;# constant 30-rsq*lu*lu 
	mulps xmm1, xmm2	
	mulps xmm0, xmm1	;# xmm0=rinv 

	mulps xmm4, xmm0	;# xmm4=r 
	mulps xmm4, [esp + nb310nf_tsc]

	cvttps2pi mm6, xmm4     ;# mm6 contain lu indices 
	cvtpi2ps xmm6, mm6
	subps xmm4, xmm6	
	movaps xmm1, xmm4	;# xmm1=eps 
	movaps xmm2, xmm1	
	mulps  xmm2, xmm2	;# xmm2=eps2 

	pslld mm6, 2

	mov  esi, [ebp + nb310nf_VFtab]
	movd ebx, mm6
	
	movlps xmm4, [esi + ebx*4]
	movlps xmm6, [esi + ebx*4 + 8]
	movaps xmm5, xmm4
	movaps xmm7, xmm6
	shufps xmm5, xmm5, 1
	shufps xmm7, xmm7, 1
	;# table ready in xmm4-xmm7 

	mulps  xmm6, xmm1	;# xmm6=Geps 
	mulps  xmm7, xmm2	;# xmm7=Heps2 
	addps  xmm5, xmm6
	addps  xmm5, xmm7	;# xmm5=Fp 	
	movaps xmm3, [esp + nb310nf_qq]
	mulps  xmm5, xmm1 ;# xmm5=eps*Fp 
	addps  xmm5, xmm4 ;# xmm5=VV 
	mulps  xmm5, xmm3 ;# vcoul=qq*VV  
	;# L-J 
	movaps xmm4, xmm0
	mulps  xmm4, xmm0	;# xmm4=rinvsq 

	;# at this point mm5 contains vcoul  
	;# increment vcoul - then we can get rid of mm5 
	;# update vctot 
	addss  xmm5, [esp + nb310nf_vctot]

	movaps xmm6, xmm4
	mulps  xmm6, xmm4

	movss [esp + nb310nf_vctot], xmm5 

	mulps  xmm6, xmm4	;# xmm6=rinvsix 
	movaps xmm4, xmm6
	mulps  xmm4, xmm4	;# xmm4=rinvtwelve 
	mulps  xmm6, [esp + nb310nf_c6]
	mulps  xmm4, [esp + nb310nf_c12]
	movss xmm7, [esp + nb310nf_Vvdwtot]
	addps  xmm7, xmm4
	subps  xmm7, xmm6
	movss [esp + nb310nf_Vvdwtot], xmm7

.nb310nf_updateouterdata:
	;# get n from stack
	mov esi, [esp + nb310nf_n]
        ;# get group index for i particle 
        mov   edx, [ebp + nb310nf_gid]      	;# base of gid[]
        mov   edx, [edx + esi*4]		;# ggid=gid[n]

	;# accumulate total potential energy and update it 
	movaps xmm7, [esp + nb310nf_vctot]
	;# accumulate 
	movhlps xmm6, xmm7
	addps  xmm7, xmm6	;# pos 0-1 in xmm7 have the sum now 
	movaps xmm6, xmm7
	shufps xmm6, xmm6, 1
	addss  xmm7, xmm6		

	;# add earlier value from mem 
	mov   eax, [ebp + nb310nf_Vc]
	addss xmm7, [eax + edx*4] 
	;# move back to mem 
	movss [eax + edx*4], xmm7 
	
	;# accumulate total lj energy and update it 
	movaps xmm7, [esp + nb310nf_Vvdwtot]
	;# accumulate 
	movhlps xmm6, xmm7
	addps  xmm7, xmm6	;# pos 0-1 in xmm7 have the sum now 
	movaps xmm6, xmm7
	shufps xmm6, xmm6, 1
	addss  xmm7, xmm6		

	;# add earlier value from mem 
	mov   eax, [ebp + nb310nf_Vvdw]
	addss xmm7, [eax + edx*4] 
	;# move back to mem 
	movss [eax + edx*4], xmm7 
	
        ;# finish if last 
        mov ecx, [esp + nb310nf_nn1]
	;# esi already loaded with n
	inc esi
        sub ecx, esi
        jz .nb310nf_outerend

        ;# not last, iterate outer loop once more!  
        mov [esp + nb310nf_n], esi
        jmp .nb310nf_outer
.nb310nf_outerend:
        ;# check if more outer neighborlists remain
        mov   ecx, [esp + nb310nf_nri]
	;# esi already loaded with n above
        sub   ecx, esi
        jz .nb310nf_end
        ;# non-zero, do one more workunit
        jmp   .nb310nf_threadloop
.nb310nf_end:
	emms

	mov eax, [esp + nb310nf_nouter]
	mov ebx, [esp + nb310nf_ninner]
	mov ecx, [ebp + nb310nf_outeriter]
	mov edx, [ebp + nb310nf_inneriter]
	mov [ecx], eax
	mov [edx], ebx

	mov eax, [esp + nb310nf_salign]
	add esp, eax
	add esp, 244
	pop edi
	pop esi
    	pop edx
    	pop ecx
    	pop ebx
    	pop eax
	leave
	ret

