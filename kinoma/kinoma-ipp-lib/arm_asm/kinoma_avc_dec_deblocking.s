;;
;;     Copyright (C) 2010-2015 Marvell International Ltd.
;;     Copyright (C) 2002-2010 Kinoma, Inc.
;;
;;     Licensed under the Apache License, Version 2.0 (the "License");
;;     you may not use this file except in compliance with the License.
;;     You may obtain a copy of the License at
;;
;;       http://www.apache.org/licenses/LICENSE-2.0
;;
;;     Unless required by applicable law or agreed to in writing, software
;;     distributed under the License is distributed on an "AS IS" BASIS,
;;     WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
;;     See the License for the specific language governing permissions and
;;     limitations under the License.
;;
	AREA  |.text|, CODE, READONLY

	EXPORT  |loopFilter_LumaV_BS4_with16pel_arm|
	EXPORT  |loopFilter_LumaV_BS4_with8pel_arm|
	EXPORT	|loopFilter_LumaV_BSN_arm|
	EXPORT	|loopFilter_LumaH_BSN_arm|
	EXPORT  |loopFilter_LumaH_BS4_with16pel_arm|
	EXPORT	|ippiFilterDeblockingChroma_VerEdge_H264_8u_C1IR_arm|
	EXPORT  |ippiFilterDeblockingChroma_HorEdge_H264_8u_C1IR_arm|
	EXPORT  |loopFilter_LumaV_BS4_with16pel_simply_arm|
	EXPORT  |loopFilter_LumaV_BSN_simply_arm|
	EXPORT  |loopFilter_LumaH_BS4_with16pel_simply_arm|
	EXPORT  |loopFilter_LumaH_BSN_simply_arm|


srcPtr			RN 0
alpha			RN 1
beta			RN 2
srcdstStep		RN 3

DL2				RN 4
DL1				RN 5
DL0				RN 6
DR0				RN 7
DR1				RN 8
DR2				RN 9

alpha22			RN 10
loop_count		RN 12

tmp				RN 11
tmp2_left		RN 9
tmp2_right		RN 4
tmp2			RN 14	; used in V4 only
C0_sp			RN 14	; Used in VN only
stepNEG			RN 14   ; Used in HN,H4 only

DC0				RN 10
::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
|loopFilter_LumaV_BS4_with16pel_arm| PROC
	pld			[srcPtr]
	stmdb       sp!, {r4 - r12, lr} 
	
:	Alpha22
	mov         alpha22, alpha, asr #2
	add         alpha22, alpha22, #2
	
:	loop count
	mov         loop_count, #15
|V4_16pel_loop_begin|
	ldrb        DL0, [srcPtr, #3]
	ldrb        DR0, [srcPtr, #4]
	ldrb        DL1, [srcPtr, #2]
:	(AbsDelta )	
	subs        tmp2, DR0, DL0
	ldrb        DR1, [srcPtr, #5]	
	submi       tmp2, DL0, DR0
	
:	absm( R0 - R1) < Beta)	
	subs        tmp2_left, DR0, DR1
	submi       tmp2_left, DR1, DR0
	
:	(absm(L0 - L1) < Beta)	
	subs        tmp2_right, DL0, DL1
	submi       tmp2_right, DL1, DL0
	
:	(AbsDelta < Alpha)
	subs		tmp2_left,	tmp2_left,	beta
	submis		tmp2_left,	tmp2,		alpha
	submis		tmp2_left,	tmp2_right,	beta	
	bpl         |V4_16pel_update_for_loop|

	ldrb        DL2,	[srcPtr, #1]
:   from now, tmp2_right can not be used untill left finished!!!
	
:	absm(L0 - L2)	
	subs		tmp2_left,	DL0,	DL2
	submis		tmp2_left,	DL2,	DL0
	
:	(AbsDelta )	
:	subs        tmp, DR0, DL0
:	submi       tmp, DL0, DR0
:   We have do in it above code when calculate FLAGs, so, just use it
:	AbsDelta - Alpha22;
	subs		tmp,		tmp2,		alpha22
	submis		tmp2_left,	tmp2_left,	beta
	bpl			|V4_16pel_simple_filter_for_left|
		
:	Complex calculation for left
:	temp = L1 + RL0 +2; 
	add         tmp2_left, DL0, DR0
	add         tmp2_left, tmp2_left, DL1
	add			tmp2_left, tmp2_left, #2
	
:	SrcPtr[3] = (R1 + (temp << 1) +  L2) >> 3;
	add         tmp,DR1, tmp2_left, lsl #1
	add			tmp, tmp, DL2
	mov			tmp, tmp, asr #3
	strb		tmp,	[srcPtr, #3]
	
:	temp2 = L2 + temp;
	add			tmp2_left, tmp2_left, DL2
	
:	SrcPtr[2] = (temp2) >> 2 ;
	mov			tmp,	tmp2_left, asr #2
	strb		tmp,	[srcPtr, #2]

:	SrcPtr[1] = (((L3 + L2) <<1) + temp2 + 2) >> 3 ;
	ldrb        tmp,	[srcPtr]  ; load L3
	add			tmp2_left, tmp2_left, #2	; eliminate bublle of above instruction
	add			tmp,	tmp,  DL2
	add			tmp2_left, tmp2_left, tmp,lsl #1
	mov			tmp2_left, tmp2_left, asr #3	
	strb		tmp2_left,	[srcPtr, #1]
	b           |V4_16pel_start_right|
	
|V4_16pel_simple_filter_for_left|
:	SrcPtr[3] = ((L1 +1)<< 1) + L0 + R1) >> 2 ;
	add         tmp2_left, DL1, #1
	add         tmp2_left, DL0, tmp2_left, lsl #1
	add         tmp2_left, tmp2_left, DR1
	mov         tmp2_left, tmp2_left, asr #2
	strb		tmp2_left, [srcPtr, #3]
	
		
|V4_16pel_start_right|
	ldrb        DR2,	[srcPtr, #6]
:   from now, tmp2_left can not be used untill left finished!!!
	
:	absm(R0 - R2)	
	subs		tmp2_right,	DR0,	DR2
	submis		tmp2_right,	DR2,	DR0

:	(AbsDelta )	
:	subs        tmp, DR0, DL0
:	submi       tmp, DL0, DR0	
:	AbsDelta - Alpha22;
	subs		tmp,	tmp2,	alpha22
	submis		tmp2_right,	tmp2_right,	beta
	bpl			|V4_16pel_simple_filter_for_right|
	
:	Complex calculation for right
:	temp = RL0 + R1 + 2;
	add         tmp2_right, DL0, DR0
	add         tmp2_right, tmp2_right, DR1
	add			tmp2_right, tmp2_right, #2
	
:	SrcPtr[ 4] = ( L1 + (temp << 1) +  R2) >> 3 
	add         tmp, DL1, tmp2_right, lsl #1
	add			tmp, tmp, DR2
	mov			tmp, tmp, asr #3
	strb		tmp,	[srcPtr, #4]
	
:	temp2 = temp + R2;
	add			tmp2_right, tmp2_right, DR2
	
:	SrcPtr[ 5] = (temp2) >> 2 ;
	mov			tmp,	tmp2_right, asr #2
	strb		tmp,	[srcPtr, #5]

:	SrcPtr[ 6] = (((R3 + R2) <<1) + temp2 + 2) >> 3 ;
	ldrb        tmp,	[srcPtr, #7]
	add			tmp2_right, tmp2_right, #2
	add			tmp,	tmp,  DR2
	add			tmp2_right, tmp2_right, tmp,lsl #1
	mov			tmp2_right, tmp2_right, asr #3	
	strb		tmp2_right,	[srcPtr, #6]
	
	b           |V4_16pel_update_for_loop|
		
|V4_16pel_simple_filter_for_right|
:	SrcPtr[ 4] = ((R1 +1)<< 1) + R0 + L1) >> 2 
	add         tmp2_right, DR1, #1
	add         tmp2_right, DR0, tmp2_right, lsl #1
	add         tmp2_right, tmp2_right, DL1
	mov         tmp2_right, tmp2_right, asr #2
	strb		tmp2_right, [srcPtr, #4]
	
|V4_16pel_update_for_loop|
	add         srcPtr, srcPtr, srcdstStep	
	subs        loop_count, loop_count, #1
	bpl         |V4_16pel_loop_begin|

|V4_16pel_end_function|

	ldmia       sp!, {r4 - r12, pc} 

	ENDP  ; |loopFilter_LumaV_BS4_with16pel_arm|



::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
|loopFilter_LumaV_BS4_with8pel_arm| PROC
	pld			[srcPtr]
	stmdb       sp!, {r4 - r11, lr} 

:	Alpha22
	mov         alpha22, alpha, asr #2
	add         alpha22, alpha22, #2
	
:	loop count
	mov         loop_count, #7
|V4_8pel_loop_begin|
	ldrb        DL1, [srcPtr, #2]
	ldrb        DL0, [srcPtr, #3]
	ldrb        DR0, [srcPtr, #4]
	ldrb        DR1, [srcPtr, #5]
	
:	(AbsDelta )	
	subs        tmp, DR0, DL0
	submi       tmp, DL0, DR0
	
:	absm( R0 - R1) < Beta)	
	subs        tmp2_left, DR0, DR1
	submi       tmp2_left, DR1, DR0
	
:	(absm(L0 - L1) < Beta)	
	subs        tmp2_right, DL0, DL1
	submi       tmp2_right, DL1, DL0
	
:	(AbsDelta < Alpha)
	subs		tmp2_left,	tmp2_left,	beta
	submis		tmp2_left,	tmp,		alpha
	submis		tmp2_left,	tmp2_right,	beta
	
	bpl         |V4_8pel_update_for_loop|


	ldrb        DL2,	[srcPtr, #1]
:   from now, tmp2_right can not be used untill left finished!!!
	
:	absm(L0 - L2)	
	subs		tmp2_left,	DL0,	DL2
	submis		tmp2_left,	DL2,	DL0
	
:	(AbsDelta )	
:	subs        tmp, DR0, DL0
:	submi       tmp, DL0, DR0
:   We have do in it above code when calculate FLAGs
:	AbsDelta - Alpha22;
	subs		tmp,		tmp,		alpha22
	submis		tmp2_left,	tmp2_left,	beta
	bpl			|V4_8pel_simple_filter_for_left|
		
:	Complex calculation for left
:	temp = L1 + RL0 +2; 
	add         tmp2_left, DL0, DR0
	add         tmp2_left, tmp2_left, DL1
	add			tmp2_left, tmp2_left, #2
	
:	SrcPtr[3] = (R1 + (temp << 1) +  L2) >> 3;
	add         tmp,DR1, tmp2_left, lsl #1
	add			tmp, tmp, DL2
	mov			tmp, tmp, asr #3
	strb		tmp,	[srcPtr, #3]
	
:	temp2 = L2 + temp;
	add			tmp2_left, tmp2_left, DL2
	
:	SrcPtr[2] = (temp2) >> 2 ;
	mov			tmp,	tmp2_left, asr #2
	strb		tmp,	[srcPtr, #2]

:	SrcPtr[1] = (((L3 + L2) <<1) + temp2 + 2) >> 3 ;
	ldrb        tmp,	[srcPtr]
	add			tmp2_left, tmp2_left, #2
	add			tmp,	tmp,  DL2
	add			tmp2_left, tmp2_left, tmp,lsl #1
	mov			tmp2_left, tmp2_left, asr #3	
	strb		tmp2_left,	[srcPtr, #1]
	b           |V4_8pel_start_right|
	
|V4_8pel_simple_filter_for_left|
:	SrcPtr[3] = ((L1 +1)<< 1) + L0 + R1) >> 2 ;
	add         tmp2_left, DL1, #1
	add         tmp2_left, DL0, tmp2_left, lsl #1
	add         tmp2_left, tmp2_left, DR1
	mov         tmp2_left, tmp2_left, asr #2
	strb		tmp2_left, [srcPtr, #3]
	
		
|V4_8pel_start_right|
	ldrb        DR2,	[srcPtr, #6]
:   from now, tmp2_left can not be used untill left finished!!!
	
:	absm(R0 - R2)	
	subs		tmp2_right,	DR0,	DR2
	submis		tmp2_right,	DR2,	DR0

:	(AbsDelta )	
	subs        tmp, DR0, DL0
	submi       tmp, DL0, DR0	
:	AbsDelta - Alpha22;
	subs		tmp,	tmp,	alpha22

	submis		tmp2_right,	tmp2_right,	beta
	bpl			|V4_8pel_simple_filter_for_right|
	
:	Complex calculation for right
:	temp = RL0 + R1 + 2;
	add         tmp2_right, DL0, DR0
	add         tmp2_right, tmp2_right, DR1
	add			tmp2_right, tmp2_right, #2
	
:	SrcPtr[ 4] = ( L1 + (temp << 1) +  R2) >> 3 
	add         tmp, DL1, tmp2_right, lsl #1
	add			tmp, tmp, DR2
	mov			tmp, tmp, asr #3
	strb		tmp,	[srcPtr, #4]
	
:	temp2 = temp + R2;
	add			tmp2_right, tmp2_right, DR2
	
:	SrcPtr[ 5] = (temp2) >> 2 ;
	mov			tmp,	tmp2_right, asr #2
	strb		tmp,	[srcPtr, #5]

:	SrcPtr[ 6] = (((R3 + R2) <<1) + temp2 + 2) >> 3 ;
	ldrb        tmp,	[srcPtr, #7]
	add			tmp,	tmp,  DR2
	add			tmp2_right, tmp2_right, tmp,lsl #1
	add			tmp2_right, tmp2_right, #2
	mov			tmp2_right, tmp2_right, asr #3	
	strb		tmp2_right,	[srcPtr, #6]
	
	b           |V4_8pel_update_for_loop|
		
|V4_8pel_simple_filter_for_right|
:	SrcPtr[ 4] = ((R1 +1)<< 1) + R0 + L1) >> 2 
	add         tmp2_right, DR1, #1
	add         tmp2_right, DR0, tmp2_right, lsl #1
	add         tmp2_right, tmp2_right, DL1
	mov         tmp2_right, tmp2_right, asr #2
	strb		tmp2_right, [srcPtr, #4]
	
|V4_8pel_update_for_loop|
	add         srcPtr, srcPtr, srcdstStep
	
	subs        loop_count, loop_count, #1
	bpl         |V4_8pel_loop_begin|

|V4_8pel_end_function|

	ldmia       sp!, {r4 - r11, pc} 

	ENDP  ; |loopFilter_LumaV_BS4_with8pel_arm|



: =========== ************** scheduled !!===============================
|loopFilter_LumaV_BSN_arm| PROC
	pld			[srcPtr]
	stmdb       sp!, {r4 - r12, lr} 
:	loop count
	mov         loop_count, #3
	ldr			C0_sp, [sp, #0x28]
|VN_loop_begin|	
	ldrb        DL0, [srcPtr, #3]
	ldrb        DR0, [srcPtr, #4]
	ldrb        DL1, [srcPtr, #2]
:	(AbsDelta )	
	subs        tmp, DR0, DL0
	ldrb        DR1, [srcPtr, #5]
	submi       tmp, DL0, DR0	
	
:	absm( R0 - R1) < Beta)	
	subs        tmp2_left, DR0, DR1
	submi       tmp2_left, DR1, DR0
	
:	(absm(L0 - L1) < Beta)	
	subs        tmp2_right, DL0, DL1
	submi       tmp2_right, DL1, DL0
	
:	(AbsDelta < Alpha)
	subs		tmp2_left,	tmp2_left,	beta
	submis		tmp2_left,	tmp,		alpha
	submis		tmp2_left,	tmp2_right,	beta

:  =================================================================
:   I choose to use branch insetad of condition instruction because
:      There are too much instructions involved and
:      ARM-v5 is one single-issume mechine. It is revised in ARM-v6E
:  =================================================================	
	bpl         |VN_update_for_loop|
	
:	Start filetr
:	Start filetr for left(Complex)
:	RL0 = (L0 + R0+1)>>1;
:   Need filter for left	
	add		tmp,	DL0, DR0
	add		tmp,	tmp, #1
	mov		tmp,	tmp, asr #1	
:	DC0, it can be destried in one loop, so, reload it
	ldrb	DL2, [srcPtr, #1]
	mov		DC0, C0_sp
:	if( (absm( L0 - L2) < Beta ) )
	subs	tmp2_left,	DL0, DL2
	submi	tmp2_left,	DL2, DL0
	subs	tmp2_left,	tmp2_left, beta
	bpl		|VN_start_right|

:	( L2 + RL0  - (L1<<1)) >> 1;	
	add		tmp2_left,	DL2, tmp
	sub		tmp2_left,	tmp2_left, DL1,lsl #1
	mov		tmp2_left,  tmp2_left, asr #1
:   Do ICLIP
	cmp		tmp2_left,	DC0
	movgt   tmp2_left,	DC0
	cmnlt   tmp2_left,	DC0
	rsblt   tmp2_left,	DC0, #0
	add		tmp2_left,	tmp2_left, DL1
	
	strb	tmp2_left,	[srcPtr, #2]
	add		DC0,	DC0, #1

|VN_start_right|
:	Start filter for right(complex)
	ldrb	DR2,	[srcPtr, #6]
:   here is one interlock, need eliminate it???????
:   if( (absm( R0 - R2) < Beta )  )
	subs	tmp2_right,	DR0, DR2
	submi	tmp2_right,	DR2, DR0
	subs	tmp2_right,	tmp2_right, beta
	bpl		|VN_start_all|

:	( R2 + RL0  - (R1<<1)) >> 1
	add		tmp2_right,	DR2, tmp
	sub		tmp,	tmp2_right, DR1 lsl #1
	mov		tmp,	tmp, asr #1

:   Do ICLIP
:	DC0, it can be destried in one loop, so, reload it
	cmp		tmp,	C0_sp
	movgt   tmp,	C0_sp
	cmnlt   tmp,	C0_sp
	rsblt   tmp,	C0_sp, #0
	add		tmp,	tmp, DR1
	
:   NOTE@@: DR1 do not used any more	
	strb	tmp,	[srcPtr, #5]
	add		DC0,	DC0, #1
	
|VN_start_all|
:   Now start simple filter for left+right
	sub		DL1,	DL1, DR1
	sub		tmp,	DR0, DL0
	add		tmp,	DL1, tmp,lsl #2
	add		tmp,	tmp, #4
	mov		tmp,    tmp, asr #3
	
:	do clip-- got diff
	cmp		tmp,	DC0
	movgt   tmp,	DC0
	cmnlt   tmp,	DC0
	rsblt   tmp,	DC0, #0

	mov		tmp2_right,	#0xFF		; prepare clip for (0,255)
	add		DL0,	DL0,tmp
	sub		DR0,	DR0,tmp
:	do two (0,255) clip
:	cmp		DL0,	#0xFF  : movgt	DL0,	#0xFF:	cmplt	DL0,	#0:	movlt	DL0,	#0	
	cmp		DL0,	tmp2_right
	bichi	DL0,	tmp2_right,	DL0,asr #31
	strb	DL0,	[srcPtr, #3]
	
	cmp		DR0,	tmp2_right
	bichi	DR0,	tmp2_right,	DR0,asr #31
	strb	DR0,	[srcPtr, #4]
	
|VN_update_for_loop|
	add         srcPtr, srcPtr, srcdstStep
	subs        loop_count, loop_count, #1
	bpl         |VN_loop_begin|

:|VN_end_function|
	ldmia       sp!, {r4 - r12, pc} 

	ENDP  ; |loopFilter_LumaV_BSN_arm|
	
::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::	
::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
|loopFilter_LumaH_BSN_arm| PROC
	pld			[srcPtr]
	stmdb       sp!, {r4 - r12, lr} 
:	loop count
	mov         loop_count, #3
	rsb			stepNEG, srcdstStep, #0	;
|HN_loop_begin|	
	ldrb        DL0, [srcPtr, stepNEG]
	ldrb        DR0, [srcPtr]
	ldrb        DL1, [srcPtr, stepNEG,lsl #1]
:	(AbsDelta )	
	subs        tmp, DR0, DL0
	ldrb        DR1, [srcPtr, srcdstStep]
	submi       tmp, DL0, DR0	
	
:	absm( R0 - R1) < Beta)	
	subs        tmp2_left, DR0, DR1
	submi       tmp2_left, DR1, DR0
	
:	(absm(L0 - L1) < Beta)	
	subs        tmp2_right, DL0, DL1
	submi       tmp2_right, DL1, DL0
	
:	(AbsDelta < Alpha)
	subs		tmp2_left,	tmp2_left,	beta
	submis		tmp2_left,	tmp,		alpha
	submis		tmp2_left,	tmp2_right,	beta

:  =================================================================
:   I choose to use branch insetad of condition instruction because
:      There are too much instructions involved and
:      ARM-v5 is one single-issume mechine. It is revised in ARM-v6E
:  =================================================================	
	bpl         |HN_update_for_loop|
	
:	Start filetr
:	Start filetr for left(Complex)
:	RL0 = (L0 + R0+1)>>1;
:   Need filter for left	
	add		tmp,	DL0, DR0
	add		tmp,	tmp, #1
	mov		tmp,	tmp, asr #1	
:	DC0, it can be destried in one loop, so, reload it
	add		DL2,	stepNEG, stepNEG,lsl #1
	ldrb	DL2, [srcPtr, DL2]
	ldr		DC0, [sp, #0x28]
:	if( (absm( L0 - L2) < Beta ) )
	subs	tmp2_left,	DL0, DL2
	submi	tmp2_left,	DL2, DL0
	subs	tmp2_left,	tmp2_left, beta
	bpl		|HN_start_right|

:	( L2 + RL0  - (L1<<1)) >> 1;	
	add		tmp2_left,	DL2, tmp
	sub		tmp2_left,	tmp2_left, DL1,lsl #1
	mov		tmp2_left,  tmp2_left, asr #1
:   Do ICLIP
	cmp		tmp2_left,	DC0
	movgt   tmp2_left,	DC0
	cmnlt   tmp2_left,	DC0
	rsblt   tmp2_left,	DC0, #0
	add		tmp2_left,	tmp2_left, DL1
	
	strb	tmp2_left,	[srcPtr, stepNEG,lsl #1]
	add		DC0,	DC0, #1

|HN_start_right|
:	Start filter for right(complex)
	ldrb	DR2,	[srcPtr, srcdstStep,lsl #1]
:   here is one interlock, need eliminate it???????
:   if( (absm( R0 - R2) < Beta )  )
	subs	tmp2_right,	DR0, DR2
	submi	tmp2_right,	DR2, DR0
	subs	tmp2_right,	tmp2_right, beta
	bpl		|HN_start_all|

:	( R2 + RL0  - (R1<<1)) >> 1
	add		tmp2_right,	DR2, tmp
	sub		tmp,	tmp2_right, DR1,lsl #1
	mov		tmp,	tmp, asr #1

:   Do ICLIP
:	DC0, it can be destried in one loop, so, reload it
	ldr		tmp2_right, [sp, #0x28]
	cmp		tmp,	tmp2_right
	movgt   tmp,	tmp2_right
	cmnlt   tmp,	tmp2_right
	rsblt   tmp,	tmp2_right, #0
	add		tmp,	tmp, DR1
	
:   NOTE@@: DR1 do not used any more	
	strb	tmp,	[srcPtr, srcdstStep]
	add		DC0,	DC0, #1
	
|HN_start_all|
:   Now start simple filter for left+right
	sub		DL1,	DL1, DR1
	sub		tmp,	DR0, DL0
	add		tmp,	DL1, tmp,lsl #2
	add		tmp,	tmp, #4
	mov		tmp,    tmp, asr #3
	
:	do clip-- got diff
	cmp		tmp,	DC0
	movgt   tmp,	DC0
	cmnlt   tmp,	DC0
	rsblt   tmp,	DC0, #0

	mov		tmp2_right,	#0xFF		; prepare clip for (0,255)
	add		DL0,	DL0,tmp
	sub		DR0,	DR0,tmp
:	do two (0,255) clip
:	cmp		DL0,	#0xFF  : movgt	DL0,	#0xFF:	cmplt	DL0,	#0:	movlt	DL0,	#0	
	cmp		DL0,	tmp2_right
	bichi	DL0,	tmp2_right,	DL0,asr #31
	strb	DL0,	[srcPtr, stepNEG]
	
	cmp		DR0,	tmp2_right
	bichi	DR0,	tmp2_right,	DR0,asr #31
	strb	DR0,	[srcPtr]
	
|HN_update_for_loop|
	add         srcPtr, srcPtr, #1
	subs        loop_count, loop_count, #1
	bpl         |HN_loop_begin|

:|HN_end_function|
	ldmia       sp!, {r4 - r12, pc} 

	ENDP  ; |loopFilter_LumaH_BSN_arm|


::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
|loopFilter_LumaH_BS4_with16pel_arm| PROC
	pld			[srcPtr]
	stmdb       sp!, {r4 - r12, lr} 
	
:	Alpha22
	mov         alpha22, alpha, asr #2
	add         alpha22, alpha22, #2

	rsb			stepNEG, srcdstStep, #0	;
	
:	loop count
	mov         loop_count, #15
|H4_16pel_loop_begin|
	ldrb        DL0, [srcPtr, stepNEG]
	ldrb        DR0, [srcPtr]
	ldrb        DL1, [srcPtr, stepNEG,lsl #1]
:	(AbsDelta )	
	subs        tmp, DR0, DL0
	ldrb        DR1, [srcPtr, srcdstStep]
	submi       tmp, DL0, DR0
	
:	absm( R0 - R1) < Beta)	
	subs        tmp2_left, DR0, DR1
	submi       tmp2_left, DR1, DR0
	
:	(absm(L0 - L1) < Beta)	
	subs        tmp2_right, DL0, DL1
	submi       tmp2_right, DL1, DL0
	
:	(AbsDelta < Alpha)
	subs		tmp2_left,	tmp2_left,	beta
	submis		tmp2_left,	tmp,		alpha
	submis		tmp2_left,	tmp2_right,	beta	
	bpl         |H4_16pel_update_for_loop|

	add			DL2,    stepNEG, stepNEG,lsl #1		;-3*srcdstStep
	ldrb        DL2,	[srcPtr, DL2]
:   from now, tmp2_right can not be used untill left finished!!!
	
:	absm(L0 - L2)	
	subs		tmp2_left,	DL0,	DL2
	submis		tmp2_left,	DL2,	DL0
	
:	(AbsDelta )	
:	subs        tmp, DR0, DL0
:	submi       tmp, DL0, DR0
:   We have do in it above code when calculate FLAGs, so, just use it
:	AbsDelta - Alpha22;
	subs		tmp,		tmp,		alpha22
	submis		tmp2_left,	tmp2_left,	beta
	bpl			|H4_16pel_simple_filter_for_left|
		
:	Complex calculation for left
:	temp = L1 + RL0 +2; 
	add         tmp2_left, DL0, DR0
	add         tmp2_left, tmp2_left, DL1
	add			tmp2_left, tmp2_left, #2
	
:	SrcPtr[3] = (R1 + (temp << 1) +  L2) >> 3;
	add         tmp,DR1, tmp2_left, lsl #1
	add			tmp, tmp, DL2
	mov			tmp, tmp, asr #3
	strb		tmp,	[srcPtr, stepNEG]
	
:	temp2 = L2 + temp;
	add			tmp2_left, tmp2_left, DL2
	
:	SrcPtr[2] = (temp2) >> 2 ;
	mov			tmp,	tmp2_left, asr #2
	strb		tmp,	[srcPtr, stepNEG,lsl #1]

:	SrcPtr[1] = (((L3 + L2) <<1) + temp2 + 2) >> 3 ;
	ldrb        tmp,	[srcPtr, stepNEG,lsl #2]  ; load L3
	add			tmp2_left, tmp2_left, #2	; eliminate bublle of above instruction
	add			tmp,	tmp,  DL2
	add			tmp2_left, tmp2_left, tmp,lsl #1
	mov			tmp2_left, tmp2_left, asr #3
	add			DL2, stepNEG, stepNEG,lsl #1
	strb		tmp2_left,	[srcPtr, DL2]
	b           |H4_16pel_start_right|	
	
|H4_16pel_simple_filter_for_left|
:	SrcPtr[3] = ((L1 +1)<< 1) + L0 + R1) >> 2 ;
	add         tmp2_left, DL1, #1
	add         tmp2_left, DL0, tmp2_left, lsl #1
	add         tmp2_left, tmp2_left, DR1
	mov         tmp2_left, tmp2_left, asr #2
	strb		tmp2_left, [srcPtr, stepNEG]
	
		
|H4_16pel_start_right|
	ldrb        DR2,	[srcPtr, srcdstStep,lsl #1]
:   from now, tmp2_left can not be used untill left finished!!!
	
:	absm(R0 - R2)	
	subs		tmp2_right,	DR0,	DR2
	submis		tmp2_right,	DR2,	DR0

:	(AbsDelta )	
	subs        tmp, DR0, DL0
	submi       tmp, DL0, DR0	
:	AbsDelta - Alpha22;
	subs		tmp,	tmp,	alpha22
	submis		tmp2_right,	tmp2_right,	beta
	bpl			|H4_16pel_simple_filter_for_right|
	
:	Complex calculation for right
:	temp = RL0 + R1 + 2;
	add         tmp2_right, DL0, DR0
	add         tmp2_right, tmp2_right, DR1
	add			tmp2_right, tmp2_right, #2
	
:	SrcPtr[ 4] = ( L1 + (temp << 1) +  R2) >> 3 
	add         tmp, DL1, tmp2_right, lsl #1
	add			tmp, tmp, DR2
	mov			tmp, tmp, asr #3
	strb		tmp,	[srcPtr]
	
:	temp2 = temp + R2;
	add			tmp2_right, tmp2_right, DR2
	
:	SrcPtr[ 5] = (temp2) >> 2 ;
	mov			tmp,	tmp2_right, asr #2
	strb		tmp,	[srcPtr, srcdstStep]

:	SrcPtr[ 6] = (((R3 + R2) <<1) + temp2 + 2) >> 3 ;
	add			tmp,	srcdstStep, srcdstStep,lsl #1
	ldrb        tmp,	[srcPtr, tmp]
	add			tmp2_right, tmp2_right, #2
	add			tmp,	tmp,  DR2
	add			tmp2_right, tmp2_right, tmp,lsl #1
	mov			tmp2_right, tmp2_right, asr #3	
	strb		tmp2_right,	[srcPtr, srcdstStep,lsl #1]
	
	b           |H4_16pel_update_for_loop|
		
|H4_16pel_simple_filter_for_right|
:	SrcPtr[ 4] = ((R1 +1)<< 1) + R0 + L1) >> 2 
	add         tmp2_right, DR1, #1
	add         tmp2_right, DR0, tmp2_right, lsl #1
	add         tmp2_right, tmp2_right, DL1
	mov         tmp2_right, tmp2_right, asr #2
	strb		tmp2_right, [srcPtr]
	
|H4_16pel_update_for_loop|
	add         srcPtr, srcPtr, #1	
	subs        loop_count, loop_count, #1
	bpl         |H4_16pel_loop_begin|

|H4_16pel_end_function|

	ldmia       sp!, {r4 - r12, pc} 

	ENDP  ; |loopFilter_LumaH_BS4_with16pel_arm|
	
	
: Start lossy optimization in 20071215	
::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
:: ***************      Start  *****************************************
::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
|loopFilter_LumaV_BS4_with16pel_simply_arm| PROC
	pld			[srcPtr]
	stmdb       sp!, {r4 - r10, r12, lr} 
	
:	Alpha22
	mov         alpha22, alpha, asr #2
	add         alpha22, alpha22, #2
	
:	loop count
	mov         loop_count, #15
|V4_16pel_S_loop_begin|
	ldrb        DL0, [srcPtr, #3]
	ldrb        DR0, [srcPtr, #4]
	ldrb        DL1, [srcPtr, #2]
:	(AbsDelta )	
	subs        tmp2, DR0, DL0
	ldrb        DR1, [srcPtr, #5]	
	submi       tmp2, DL0, DR0
	
:	absm( R0 - R1) < Beta)	
	subs        tmp2_left, DR0, DR1
	submi       tmp2_left, DR1, DR0
	
:	(absm(L0 - L1) < Beta)	
	subs        tmp2_right, DL0, DL1
	submi       tmp2_right, DL1, DL0
	
:	(AbsDelta < Alpha)
	subs		tmp2_left,	tmp2_left,	beta
	submis		tmp2_left,	tmp2,		alpha
	submis		tmp2_left,	tmp2_right,	beta	
	bpl         |V4_16pel_S_update_for_loop|

:|V4_16pel_S_filter_for_left|
:	SrcPtr[3] = ((L1 +1)<< 1) + L0 + R1) >> 2 ;
	add         tmp2_left, DL1, #1
	add         tmp2_left, DL0, tmp2_left, lsl #1
	add         tmp2_left, tmp2_left, DR1
	mov         tmp2_left, tmp2_left, asr #2
	strb		tmp2_left, [srcPtr, #3]
		
:|V4_16pel_S_filter_for_right|
:	SrcPtr[ 4] = ((R1 +1)<< 1) + R0 + L1) >> 2 
	add         tmp2_right, DR1, #1
	add         tmp2_right, DR0, tmp2_right, lsl #1
	add         tmp2_right, tmp2_right, DL1
	mov         tmp2_right, tmp2_right, asr #2
	strb		tmp2_right, [srcPtr, #4]
	
|V4_16pel_S_update_for_loop|
	add         srcPtr, srcPtr, srcdstStep	
	subs        loop_count, loop_count, #1
	bpl         |V4_16pel_S_loop_begin|

|V4_16pel_S_end_function|

	ldmia       sp!, {r4 - r10, r12, pc} 

	ENDP  ; |loopFilter_LumaV_BS4_with16pel_simply_arm|
	
::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::	
|loopFilter_LumaV_BSN_simply_arm| PROC
	pld			[srcPtr]
	stmdb       sp!, {r4 - r10, r12, lr} 
	
:	Alpha22
	mov         alpha22, alpha, asr #2
	add         alpha22, alpha22, #2
	
:	loop count
	mov         loop_count, #3
|LumaV_BSN_simply_loop_begin|
	ldrb        DL0, [srcPtr, #3]
	ldrb        DR0, [srcPtr, #4]
	ldrb        DL1, [srcPtr, #2]
:	(AbsDelta )	
	subs        tmp2, DR0, DL0
	ldrb        DR1, [srcPtr, #5]	
	submi       tmp2, DL0, DR0
	
:	absm( R0 - R1) < Beta)	
	subs        tmp2_left, DR0, DR1
	submi       tmp2_left, DR1, DR0
	
:	(absm(L0 - L1) < Beta)	
	subs        tmp2_right, DL0, DL1
	submi       tmp2_right, DL1, DL0
	
:	(AbsDelta < Alpha)
	subs		tmp2_left,	tmp2_left,	beta
	submis		tmp2_left,	tmp2,		alpha
	submis		tmp2_left,	tmp2_right,	beta	
	bpl         |LumaV_BSN_simply_update_for_loop|

:|LumaV_BSN_simply_filter_for_left|
:   SrcPtr[3] = (L1  + (L0<<1) + R1 + 2) >> 2 ;
	add         tmp2_left, DL0, #1
	add         tmp2_left, DL1, tmp2_left, lsl #1
	add         tmp2_left, tmp2_left, DR1
	mov         tmp2_left, tmp2_left, asr #2
	strb		tmp2_left, [srcPtr, #3]
		
:|LumaV_BSN_simply_filter_for_right|
:   SrcPtr[4] = (R1  + (R0<<1) + L1 + 2) >> 2;
	add         tmp2_right, DR0, #1
	add         tmp2_right, DR1, tmp2_right, lsl #1
	add         tmp2_right, tmp2_right, DL1
	mov         tmp2_right, tmp2_right, asr #2
	strb		tmp2_right, [srcPtr, #4]
	
|LumaV_BSN_simply_update_for_loop|
	add         srcPtr, srcPtr, srcdstStep	
	subs        loop_count, loop_count, #1
	bpl         |LumaV_BSN_simply_loop_begin|

:|LumaV_BSN_simply_end_function|

	ldmia       sp!, {r4 - r10, r12, pc} 

	ENDP  ; |loopFilter_LumaV_BSN_simply_arm|	
	
	
::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::	
|loopFilter_LumaH_BS4_with16pel_simply_arm| PROC
	pld			[srcPtr]
	stmdb       sp!, {r4 - r12, lr} 
	
:	Alpha22
	mov         alpha22, alpha, asr #2
	add         alpha22, alpha22, #2

	rsb			stepNEG, srcdstStep, #0	;
	
:	loop count
	mov         loop_count, #15
|H4_16pel_S_loop_begin|
	ldrb        DL0, [srcPtr, stepNEG]
	ldrb        DR0, [srcPtr]
	ldrb        DL1, [srcPtr, stepNEG,lsl #1]
:	(AbsDelta )	
	subs        tmp, DR0, DL0
	ldrb        DR1, [srcPtr, srcdstStep]
	submi       tmp, DL0, DR0
	
:	absm( R0 - R1) < Beta)	
	subs        tmp2_left, DR0, DR1
	submi       tmp2_left, DR1, DR0
	
:	(absm(L0 - L1) < Beta)	
	subs        tmp2_right, DL0, DL1
	submi       tmp2_right, DL1, DL0
	
:	(AbsDelta < Alpha)
	subs		tmp2_left,	tmp2_left,	beta
	submis		tmp2_left,	tmp,		alpha
	submis		tmp2_left,	tmp2_right,	beta	
	bpl         |H4_16pel_S_update_for_loop|

	
:|H4_16pel_S_simple_filter_for_left|
:	SrcPtr[stepNEG] = ((L1 +1)<< 1) + L0 + R1) >> 2 ;
	add         tmp2_left, DL1, #1
	add         tmp2_left, DL0, tmp2_left, lsl #1
	add         tmp2_left, tmp2_left, DR1
	mov         tmp2_left, tmp2_left, asr #2
	strb		tmp2_left, [srcPtr, stepNEG]
	
				
:|H4_16pel_S_simple_filter_for_right|
:	SrcPtr[ 0] = ((R1 +1)<< 1) + R0 + L1) >> 2 
	add         tmp2_right, DR1, #1
	add         tmp2_right, DR0, tmp2_right, lsl #1
	add         tmp2_right, tmp2_right, DL1
	mov         tmp2_right, tmp2_right, asr #2
	strb		tmp2_right, [srcPtr]
	
|H4_16pel_S_update_for_loop|
	add         srcPtr, srcPtr, #1	
	subs        loop_count, loop_count, #1
	bpl         |H4_16pel_S_loop_begin|

:|H4_16pel_S_end_function|

	ldmia       sp!, {r4 - r12, pc} 

	ENDP  ; |loopFilter_LumaH_BS4_with16pel_simply_arm|	
	
::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::	
|loopFilter_LumaH_BSN_simply_arm| PROC
	pld			[srcPtr]
	stmdb       sp!, {r4 - r12, lr} 
	
:	Alpha22
	mov         alpha22, alpha, asr #2
	add         alpha22, alpha22, #2

	rsb			stepNEG, srcdstStep, #0	;
	
:	loop count
	mov         loop_count, #3
|LumaH_BSN_simply_loop_begin|
	ldrb        DL0, [srcPtr, stepNEG]
	ldrb        DR0, [srcPtr]
	ldrb        DL1, [srcPtr, stepNEG,lsl #1]
:	(AbsDelta )	
	subs        tmp, DR0, DL0
	ldrb        DR1, [srcPtr, srcdstStep]
	submi       tmp, DL0, DR0
	
:	absm( R0 - R1) < Beta)	
	subs        tmp2_left, DR0, DR1
	submi       tmp2_left, DR1, DR0
	
:	(absm(L0 - L1) < Beta)	
	subs        tmp2_right, DL0, DL1
	submi       tmp2_right, DL1, DL0
	
:	(AbsDelta < Alpha)
	subs		tmp2_left,	tmp2_left,	beta
	submis		tmp2_left,	tmp,		alpha
	submis		tmp2_left,	tmp2_right,	beta	
	bpl         |LumaH_BSN_simply_update_for_loop|

	
:|LumaH_BSN_simply_filter_for_left|
: 	SrcPtr[-srcdstStep ] = (L1 + (L0<<1) + R1 + 2) >> 2;

	add         tmp2_left, DL0, #1
	add         tmp2_left, DL1, tmp2_left, lsl #1
	add         tmp2_left, tmp2_left, DR1
	mov         tmp2_left, tmp2_left, asr #2
	strb		tmp2_left, [srcPtr, stepNEG]
	
				
:|LumaH_BSN_simply_filter_for_right|
:   SrcPtr[ 0] = (R1 + (R0<<1) + L1 + 2) >> 2;
	add         tmp2_right, DR0, #1
	add         tmp2_right, DR1, tmp2_right, lsl #1
	add         tmp2_right, tmp2_right, DL1
	mov         tmp2_right, tmp2_right, asr #2
	strb		tmp2_right, [srcPtr]
	
|LumaH_BSN_simply_update_for_loop|
	add         srcPtr, srcPtr, #1	
	subs        loop_count, loop_count, #1
	bpl         |LumaH_BSN_simply_loop_begin|

:|LumaH_BSN_simply_end_function|

	ldmia       sp!, {r4 - r12, pc} 

	ENDP  ; |loopFilter_LumaH_BSN_simply_arm|		
::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
:: ********************  END    ****************************************
::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::	
	
::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
 
srcdst     RN     0
step       RN     1
s_alpha    RN     2
s_beta     RN     3	

lf1        RN     4			;left
lf0        RN     5
rt0        RN     6			;right
rt1        RN     7	

delta      RN     8
lr_diff    RN     8			;l0+diff, r0-diff
tmpsum     RN     8
offset     RN     8

absdelta   RN     9
tmpdiff    RN     9			;absm(R0-R1) , absm(L0-L1)
tmplr      RN     9

cc0        RN     10
thresh     RN     10

bs         RN     11

bsaddr     RN     12
threshaddr RN     12
tmpAaddr   RN     12

index      RN     14
tmpBaddr   RN     14
	
	MACRO
	loopFilter_ChromaV_BS4_arm  $if_exit
		ldrb        rt0, [srcdst]
		ldrb        rt1, [srcdst, #1]
		ldrb        lf1, [srcdst, #-2]						;L1 = SrcPtr[-2]
		ldrb        lf0, [srcdst, #-1]
		
		; if((absm( R0 - R1) < Beta) * (absm(L0 - L1) < Beta) * (AbsDelta < Alpha))
		; Modified by WWD in 20070920
		subs        tmplr, rt0, rt1
	    submi       tmplr, rt1, rt0							;absm(R0-R1)
	    
	    subs        tmpsum, lf0, lf1
	    submi       tmpsum, lf1, lf0						;absm(L0-L1))
	    
		subs        thresh, rt0, lf0						; WWD: use thresh as temp register!!
		submi       thresh, lf0, rt0						;AbsDelta = absm(R0-L0)
		      
		subs		tmplr,	tmplr,		s_beta
		submis		tmplr,	thresh,		s_alpha
		submis		tmplr,	tmpsum,		s_beta
		bpl         $if_exit
		;  Modify END

        
        add         tmplr, rt1, lf1                         
        add         tmplr, tmplr, #2                        ;RL0 = R1 + L1 +2;
        
        add         tmpsum, tmplr, lf0
        add         tmpsum, tmpsum, lf1
        mov         tmpsum, tmpsum, ASR #2
        strb        tmpsum, [srcdst, #-1]                   ;(RL0 + L0 + L1) >> 2;
        
        add         tmpsum, tmplr, rt0
        add         tmpsum, tmpsum, rt1		
        mov         tmpsum, tmpsum, ASR #2
        strb        tmpsum, [srcdst]						;(RL0 + R0 + R1) >> 2
        
	        		
	MEND
	
	
	MACRO
	loopFilter_ChromaV_BSN_arm  $if_exit
		ldrb        rt0, [srcdst]
		ldrb        rt1, [srcdst, #1]	
		ldrb        lf1, [srcdst, #-2]						;L1 = SrcPtr[-2]
		ldrb        lf0, [srcdst, #-1]

		;if((absm( R0 - R1) < Beta)&& (absm(L0 - L1) < Beta) && (AbsDelta < Alpha)) 
		; Register confilct?
		subs        tmpdiff, rt0, rt1
	    submi       tmpdiff, rt1, rt0						;absm(R0-R1)
	    cmp         tmpdiff, s_beta							;absm(R0-R1) < Beta ?
	    bge         $if_exit
	    subs        tmpdiff, lf0, lf1
	    submi       tmpdiff, lf1, lf0						;absm(L0-L1))
	    cmp         tmpdiff, s_beta							;absm(L0-L1) < Beta ?
	    bge         $if_exit
		subs		absdelta,rt0, lf0
		submi       absdelta,lf0, rt0						;AbsDelta = absm(Delta = R0-L0)
        cmp         absdelta, s_alpha
        bge         $if_exit
      
		subs        delta, rt0, lf0      
        sub         tmpdiff, lf1, rt1
		add         tmpdiff, tmpdiff, delta, LSL #2
        add         tmpdiff, tmpdiff, #4
        mov         tmpdiff, tmpdiff, ASR #3				;((Delta << 2)+(L1-R1)+4) >> 3 
        cmp         tmpdiff, cc0
        movgt       tmpdiff, cc0
        cmnlt       tmpdiff, cc0 
        rsblt       tmpdiff, cc0, #0						;IClip( -c0, c0, diff) ;
      
		mov			rt1,	#255
        add         lr_diff, lf0, tmpdiff
        cmp         lr_diff, rt1
        ; Modified by WWD
        bichi		lr_diff, lr_diff, lr_diff,asr #31
        ;movgt       lr_diff, #0xff
        ;cmplt       lr_diff, #0
        ;movlt       lr_diff, #0
        strb        lr_diff, [srcdst,#-1]					;SrcPtr[ -1] = clip_uint8(L0 + dif)
      
        sub         lr_diff, rt0, tmpdiff
        cmp         lr_diff, rt1
        bichi		lr_diff, lr_diff, lr_diff,asr #31
        strb        lr_diff, [srcdst]						;SrcPtr[  0] = clip_uint8(R0 - dif)

	MEND
	
		
	MACRO
	loopFilter_ChromaH_BS4_arm $if_exit
		ldrb        rt0, [srcdst]
		ldrb        rt1, [srcdst, step]
		ldrb        lf1, [srcdst, -step,LSL #1]				;L1 = SrcPtr[-2]
		ldrb        lf0, [srcdst, -step]                   
		
		; if((absm( R0 - R1) < Beta) * (absm(L0 - L1) < Beta) * (AbsDelta < Alpha))
		; if((absm( R0 - R1) < Beta) * (absm(L0 - L1) < Beta) * (AbsDelta < Alpha))
		; Modified by WWD in 20070920
		subs        tmplr, rt0, rt1
	    submi       tmplr, rt1, rt0							;absm(R0-R1)
	    
	    subs        tmpsum, lf0, lf1
	    submi       tmpsum, lf1, lf0						;absm(L0-L1))
	    
		subs        thresh, rt0, lf0						; WWD: use thresh as temp register!!
		submi       thresh, lf0, rt0						;AbsDelta = absm(R0-L0)
		      
		subs		tmplr,	tmplr,		s_beta
		submis		tmplr,	thresh,		s_alpha
		submis		tmplr,	tmpsum,		s_beta
		bpl         $if_exit
		;  Modify END
        
        add         tmplr, rt1, lf1                         
        add         tmplr, tmplr, #2                        ;RL0 = R1 + L1 +2;
        
        add         tmpsum, tmplr, lf0
        add         tmpsum, tmpsum, lf1
        mov         tmpsum, tmpsum, ASR #2
        strb        tmpsum, [srcdst, -step]                   ;(RL0 + L0 + L1) >> 2;
        
        add         tmpsum, tmplr, rt0
        add         tmpsum, tmpsum, rt1		
        mov         tmpsum, tmpsum, ASR #2
        strb        tmpsum, [srcdst]						;(RL0 + R0 + R1) >> 2	
	MEND
	

	
	MACRO
	loopFilter_ChromaH_BSN_arm $if_exit
		ldrb        rt0, [srcdst]
		ldrb        rt1, [srcdst, step]
		ldrb        lf1, [srcdst, -step,LSL #1]				;L1 = SrcPtr[-2]
		ldrb        lf0, [srcdst, -step]                   
    
		;if((absm( R0 - R1) < Beta)&& (absm(L0 - L1) < Beta) && (AbsDelta < Alpha)) 
		subs        tmpdiff, rt0, rt1
	    submi       tmpdiff, rt1, rt0						;absm(R0-R1)
	    cmp         tmpdiff, s_beta							;absm(R0-R1) < Beta ?
	    bge         $if_exit
	    subs        tmpdiff, lf0, lf1
	    submi       tmpdiff, lf1, lf0						;absm(L0-L1))
	    cmp         tmpdiff, s_beta							;absm(L0-L1) < Beta ?
	    bge         $if_exit
		subs        delta, rt0, lf0      
		movpl       absdelta,delta
		submi       absdelta,lf0, rt0						;AbsDelta = absm(Delta = R0-L0)
        cmp         absdelta, s_alpha
        bge         $if_exit
      
        sub         tmpdiff, lf1, rt1
		add         tmpdiff, tmpdiff, delta, LSL #2
        add         tmpdiff, tmpdiff, #4
        mov         tmpdiff, tmpdiff, ASR #3				;((Delta << 2)+(L1-R1)+4) >> 3 
        cmp         tmpdiff, cc0
        movgt       tmpdiff, cc0
        cmnlt       tmpdiff, cc0 
        rsblt       tmpdiff, cc0, #0						;IClip( -c0, c0, diff) ;
      
		mov			rt1,	#255
        add         lr_diff, lf0, tmpdiff
        cmp         lr_diff, rt1
        bichi		lr_diff, lr_diff, lr_diff,asr #31
        strb        lr_diff, [srcdst,-step]				;SrcPtr[ -1] = clip_uint8(L0 + dif)
      
        sub         lr_diff, rt0, tmpdiff
        cmp         lr_diff, rt1
        bichi		lr_diff, lr_diff, lr_diff,asr #31
        strb        lr_diff, [srcdst]						;SrcPtr[  0] = clip_uint8(R0 - dif)

	MEND
	
;------------------------------------------------------------------------------
; function : ippiFilterDeblockingChroma_VerEdge_H264_8u_C1IR_arm
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;	
|ippiFilterDeblockingChroma_VerEdge_H264_8u_C1IR_arm|	 PROC

	stmdb      sp!, {r4 - r12,lr}
	sub        sp, sp, #0x10
	
	mov        tmpBaddr, s_beta
	str        tmpBaddr, [sp, #0x4]
	ldrb       s_beta, [tmpBaddr]

    mov        tmpAaddr, s_alpha
    str        tmpAaddr, [sp, #0x8]
    ldrb       s_alpha, [tmpAaddr]
    
    str        srcdst, [sp, #0xc]                           ; bak pSrcDst
   	mov        index, #0

V_Step1
	ldr		   bsaddr, [sp,#0x3c]
	ldrb       bs, [bsaddr, index]
	cmp		   bs, #4
	bne        V_Bs_Less_4
	
	loopFilter_ChromaV_BS4_arm V_if_v4_1
V_if_v4_1
    add        srcdst, srcdst, step
	loopFilter_ChromaV_BS4_arm V_if_v4_2
V_if_v4_2	
    add        srcdst, srcdst, step
	b          V_Next1
	
	
V_Bs_Less_4
    cmp        bs, #1
    blt        V_Bs_less_1
    ldr        threshaddr, [sp,#0x38]
    ldrb       thresh, [threshaddr, index]
    add        cc0, thresh, #1                              ;c0  = pThresholds[ bsIndex ] + 1;
    
    loopFilter_ChromaV_BSN_arm V_if_vn_1
V_if_vn_1 
    add        srcdst, srcdst, step
    loopFilter_ChromaV_BSN_arm V_if_vn_2
V_if_vn_2
    add        srcdst, srcdst, step
    b          V_Next1
       
    
V_Bs_less_1
    add        srcdst, srcdst, step,LSL #1


V_Next1	
	add        index, index, #1
	cmp        index, #4
	blt        V_Step1 
    
    
    ;Next, we process other three edge
    ldr        srcdst, [sp, #0xc]                           ;restore pSrcDst
    ldr        tmpBaddr, [sp,#0x4]
    ldrb       s_beta, [tmpBaddr,#1]	
    ldr        tmpAaddr, [sp,#0x8]
    ldrb       s_alpha, [tmpAaddr,#1]
    add        srcdst, srcdst, #4
    
    mov        index, #0
V_Step2
	ldr		   bsaddr, [sp,#0x3c]
    add        offset, index, #8    
    ldrb       bs,[bsaddr, offset]           
    cmp        bs,#1
    blt        V_else_if
    ldr        threshaddr, [sp,#0x38]
    add        offset, index,#4
    ldrb       thresh,[threshaddr, offset]
    add        cc0, thresh, #1
    loopFilter_ChromaV_BSN_arm V_if_vn_3
V_if_vn_3 
    add        srcdst, srcdst, step
    loopFilter_ChromaV_BSN_arm V_if_vn_4
V_if_vn_4    
    add        srcdst, srcdst, step    
    b          V_Next2

V_else_if       
    add        srcdst, srcdst, step,LSL #1
    
V_Next2    
	add        index, index, #1
	cmp        index, #4
	blt        V_Step2     
    
	mov        r0, #0	
	add        sp, sp, #0x10	
    ldmia      sp!, {r4 - r12, pc}
    
	ENDP  ; |ippiFilterDeblockingChroma_VerEdge_H264_8u_C1IR_arm|
;==============================================================================
;   END  ippiFilterDeblockingChroma_VerEdge_H264_8u_C1IR_arm
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;




;------------------------------------------------------------------------------
; function : ippiFilterDeblockingChroma_HorEdge_H264_8u_C1IR_arm
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;	
|ippiFilterDeblockingChroma_HorEdge_H264_8u_C1IR_arm|	 PROC

	stmdb      sp!, {r4 - r12,lr}
	sub        sp, sp, #0x10
	
	mov        tmpBaddr, s_beta
	str        tmpBaddr, [sp, #0x4]
	ldrb       s_beta, [tmpBaddr]

    mov        tmpAaddr, s_alpha
    str        tmpAaddr, [sp, #0x8]
    ldrb       s_alpha, [tmpAaddr]
    
    str        srcdst, [sp, #0xc]                           ; bak pSrcDst
   	mov        index, #0

H_Step1
	ldr		   bsaddr, [sp,#0x3c]
	ldrb       bs, [bsaddr, index]
	cmp		   bs, #4
	bne        H_Bs_Less_4
	
	loopFilter_ChromaH_BS4_arm H_if_v4_1
H_if_v4_1
    add        srcdst, srcdst, #1
	loopFilter_ChromaH_BS4_arm H_if_v4_2
H_if_v4_2	
    add        srcdst, srcdst, #1
	b          H_Next1
	
	
H_Bs_Less_4
    cmp        bs, #1
    blt        H_Bs_less_1
    ldr        threshaddr, [sp,#0x38]
    ldrb       thresh, [threshaddr, index]
    add        cc0, thresh, #1                              ;c0  = pThresholds[ bsIndex ] + 1;
    
    loopFilter_ChromaH_BSN_arm H_if_vn_1
H_if_vn_1 
    add        srcdst, srcdst, #1
    loopFilter_ChromaH_BSN_arm H_if_vn_2
H_if_vn_2
    add        srcdst, srcdst, #1
    b          H_Next1
       
H_Bs_less_1
    add        srcdst, srcdst, #2
	
H_Next1	
	add        index, index, #1
	cmp        index, #4
	blt        H_Step1 
    
    
    ;Next, we process other three edge
    ldr        srcdst, [sp, #0xc]                           ;restore pSrcDst
    ldr        tmpBaddr, [sp,#0x4]
    ldrb       s_beta, [tmpBaddr,#1]	
    ldr        tmpAaddr, [sp,#0x8]
    ldrb       s_alpha, [tmpAaddr,#1]
    add        srcdst, srcdst, step,LSL #2
    
    mov        index, #0
H_Step2
	ldr		   bsaddr, [sp,#0x3c]
    add        offset, index, #8    
    ldrb       bs,[bsaddr, offset]           
    cmp        bs,#1
    blt        H_else_if
    ldr        threshaddr, [sp,#0x38]
    add        offset, index,#4
    ldrb       thresh,[threshaddr, offset]
    add        cc0, thresh, #1
    loopFilter_ChromaH_BSN_arm H_if_vn_3
H_if_vn_3 
    add        srcdst, srcdst, #1
    loopFilter_ChromaH_BSN_arm H_if_vn_4
H_if_vn_4    
    add        srcdst, srcdst, #1    
    b          H_Next2

H_else_if       
    add        srcdst, srcdst, #2
    
H_Next2    
	add        index, index, #1
	cmp        index, #4
	blt        H_Step2     
    
	mov        r0, #0	
	add        sp, sp, #0x10	
    ldmia      sp!, {r4 - r12, pc}
    
	ENDP  ; |ippiFilterDeblockingChroma_HorEdge_H264_8u_C1IR_arm|
;==============================================================================
;   END  ippiFilterDeblockingChroma_HorEdge_H264_8u_C1IR_arm
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;



	
	END	
