*------------------------------------------------------------------------*
*- The alien chase routine was written one Saturday afternoon, I wrote  -*
*- it really badly and then because I had started it I continued to     -*
*- update it - know it is a real mess, I was going to re-write it       -*
*- properly but now I never will!!					-*
*------------------------------------------------------------------------*



DUMB_ALIEN_SPEED	EQU	2
FAST_DUMB_ALIEN_SPEED	EQU	3

DUMB_UPDATE		EQU	12

PIG_OFFSET		EQU	4

*************************************************
****     BASIC ALIEN CHASE                   ****
*************************************************
Basic_Alien_Chase
*-- Alien will update its direction to the player every 8 frames

	movem.l	d0-d2/a0-a1/a3-a4,-(sp)
	
	move.b	alien_work(a2),d6	
	subq.b	#1,alien_c_pad(a2)
	ble.s	direct_alien

	btst	#SET_OVERRIDE,d6
	beq.s	dont_update_direction_of_dumb
	
	bsr	Follow_Directions	;follow ai 
	bra.s	Update_Pig_Data		
direct_alien	
	bsr	Direct_Pig_Alien
Update_Pig_Data	
	move.l	#face_direction_table,a1
	move.w	(a1,d7.w),alien_direction(a2)
	asl	d5
	move.l	#dumb_alien_directions,a1
	move.w	(a1,d5.w),alien_data(a2)
	move.w	2(a1,d5.w),alien_data_extra(a2)
	bsr	Shall_Pig_Fire	
dont_update_direction_of_dumb	
	move.l	a5,-(sp)
	bsr	Perform_Pig_Collision_Detection	;use existing data
	move.l	(sp)+,a5
	
	movem.l	(sp)+,d0-d2/a0-a1/a3-a4
	rts


*************************************************
****     NO SHOOT ALIEN CHASE                ****
*************************************************
No_Shoot_Alien_Chase
*-- Alien will update its direction to the player every 8 frames

	movem.l	d0-d2/a0-a1/a3-a5,-(sp)
	
	move.b	alien_work(a2),d6	
	subq.b	#1,alien_c_pad(a2)
	ble.s	No_Shoot_direct_alien

	btst	#SET_OVERRIDE,d6
	beq.s	No_Shoot_dont_update_direction_of_dumb
	
	bsr	Follow_Directions	;follow ai 
	bra.s	No_Shoot_Update_Pig_Data		
No_Shoot_direct_alien	
	bsr	Direct_Pig_Alien
No_shoot_Update_Pig_Data	
	move.l	#face_direction_table,a1
	move.w	(a1,d7.w),alien_direction(a2)
	asl	d5
	move.l	#dumb_alien_directions,a1
	move.w	(a1,d5.w),alien_data(a2)
	move.w	2(a1,d5.w),alien_data_extra(a2)
	
no_shoot_dont_update_direction_of_dumb	
	bsr	Perform_Pig_Collision_Detection	;use existing data
	
	movem.l	(sp)+,d0-d2/a0-a1/a3-a5
	rts


*************************************************
****     NO SHOOT FAST ALIEN CHASE           ****
*************************************************
No_Shoot_Fast_Alien_Chase
*-- Alien will update its direction to the player every 8 frames

	movem.l	d0-d2/a0-a1/a3-a5,-(sp)
	
	move.b	alien_work(a2),d6	
	subq.b	#1,alien_c_pad(a2)
	ble.s	No_Shoot_fast_direct_alien

	btst	#SET_OVERRIDE,d6
	beq.s	No_Shoot_fast_dont_update_direction_of_dumb
	
	bsr	Follow_Directions	;follow ai 
	bra.s	No_Shoot_fast_Update_Pig_Data		
No_Shoot_fast_direct_alien	
	bsr	Direct_Pig_Alien
No_shoot_fast_Update_Pig_Data	
	move.l	#face_direction_table,a1
	move.w	(a1,d7.w),alien_direction(a2)
	asl	d5
	move.l	#fast_dumb_alien_directions,a1
	move.w	(a1,d5.w),alien_data(a2)
	move.w	2(a1,d5.w),alien_data_extra(a2)
	
no_shoot_fast_dont_update_direction_of_dumb	
	bsr	Perform_Pig_Collision_Detection	;use existing data
	
	movem.l	(sp)+,d0-d2/a0-a1/a3-a5
	rts


********************************************
**** DIRECT PIG ALIEN                    ***
********************************************
Direct_Pig_Alien	
	move.b	#DUMB_UPDATE,alien_c_pad(a2)
	
	move.w	alien_x(a2),d0
	move.w	alien_y(a2),d1
	
	bsr	Aim_Alien_Bullet	
	
*-- Store direction

	lsl.w	d5
	move.l	#face_table,a1
	move.w	(a1,d5.w),d5		;face direction
	move.w	d5,d7
	
	
*-- alter direction (D5) depending on collision information	


	tst.b	d6		;collision info
	beq	quit_direct_routine

*-- so d5 contains the desired direction the alien would like to go in
	move.b	alien_work+9(a2),d4	;old direction
	move.b	d5,alien_work+9(a2)	;store new direction	
	
			
	btst	#SET_OVERRIDE,d6
	beq.s	alien_not_in_override_mode
	
*-- if collision data and desired direction are not for same direction wait 
*-- until they are

	cmp.b	d5,d4
	beq	follow_escape_pattern
	
	
	subq.b	#1,alien_work+11(a2)
	bne.s	follow_escape_pattern	
	
	clr.b	alien_work(a2)		;clear collision data
	bra	quit_direct_routine
	
follow_escape_pattern
	bsr	Follow_Directions	
	bra	quit_direct_routine
	
	
alien_not_in_override_mode	
	
*-- see where alien has got stuck  (d6 = alien_work)

	move.b	#3,alien_work+11(A2)	;bored counter
	
*-------------------------TEST LEFT----------------------
	btst	#SET_FACE_LEFT,d6
	beq.s	not_left_blocked
	
*-- LEFT IS HIT	

	btst	#SET_FACE_UP,d6
	beq.s	check_left_down

*-- LEFT AND UP BLOCKED
	
	bra	quit_direct_routine
		
check_left_down	
	btst	#SET_FACE_DOWN,d6
	beq.s	only_left_blocked

*-- LEFT AND DOWN BLOCKED
	
only_left_blocked	
	
*-- LEFT BLOCKED ONLY

	bset.b	#SET_OVERRIDE,alien_work(a2)
	
*-- Where is player relative

	sub.w	actual_player_map_y_position,d1
	blt.s	left_alien_higher
	move.l	#left_blocked_list_go_up,alien_work+4(a2)
	bra	start_follow_routine
left_alien_higher
	move.l	#left_blocked_list,alien_work+4(a2)
	bra	start_follow_routine
	

*------------------------TEST RIGHT--------------------


not_left_blocked
	btst	#SET_FACE_RIGHT,d6
	beq.s	not_right_blocked
	
	btst	#SET_FACE_UP,d6
	beq.s	check_right_down

*-- RIGHT AND UP BLOCKED
	
check_right_down	
	btst	#SET_FACE_DOWN,d6
	beq.s	only_right_blocked

*-- RIGHT AND DOWN BLOCKED

only_right_blocked

*-- RIGHT BLOCKED ONLY
	bset.b	#SET_OVERRIDE,alien_work(a2)
	
	sub.w	actual_player_map_y_position,d1
	blt.s	right_alien_higher
	move.l	#right_blocked_list_go_up,alien_work+4(a2)
	bra.s	start_follow_routine
right_alien_higher
	move.l	#right_blocked_list,alien_work+4(a2)
	bra.s	start_follow_routine


*---------------------------TEST UP------------------------	
not_right_blocked
	btst	#SET_FACE_UP,d6
	beq.s	down_blocked
	
	bset.b	#SET_OVERRIDE,alien_work(a2)

	sub.w	actual_player_map_x_position,d0
	blt.s	up_alien_greater
	move.l	#up_blocked_list_left_choice,alien_work+4(a2)
	bra.s	start_follow_routine
up_alien_greater
	move.l	#up_blocked_list_right_choice,alien_work+4(a2)
	bra.s	start_follow_routine


	


*-----------------------------TEST DOWN--------------------

	
down_blocked
*-- ONLY POSSIBILITY LEFT
	
	bset.b	#SET_OVERRIDE,alien_work(a2)

	sub.w	actual_player_map_x_position,d0
	blt.s	down_alien_greater
	move.l	#down_blocked_list_left_choice,alien_work+4(a2)
	bra.s	start_follow_routine
down_alien_greater
	move.l	#down_blocked_list_right_choice,alien_work+4(a2)
start_follow_routine
	bsr	Follow_Directions		

*----------------------------END OF TESTS-----------------------------

quit_direct_routine
	rts


*********************************************
***   FOLLOW DIRECTIONS                  ****
*********************************************
Follow_Directions
*-- follow ai reccomendations
	move.l	alien_work+4(a2),a3
	bsr	Interpret_AI_List	;GIVE NEW D5
	move.l	a3,alien_work+4(a2)
	rts

**********************************************
*** SHALL PIG FIRE                         ***
**********************************************
Shall_Pig_Fire

	btst	#SET_OVERRIDE,d6
	bne.s	dont_shoot_pig  	;NOT WHEN SEARCHING	
*Shall pig fire a missile (only if in chase mode)?

	move.l	random_direction_ptr,a1
	move.b	(a1)+,d0
	cmp.b	#-1,(a1)
	bne.s	not_reset_list
	move.l	#random_direction_table,a1
not_reset_list	
	move.l	a1,random_direction_ptr
	cmpi.b	#8,d0
	bne.s	dont_shoot_pig
	
	move.w	alien_x(a2),d0
	addq.w	#8,d0
	move.w	alien_y(a2),d1
	add.w	#18,d1
	
	move.l	#PigMissile_Object,d2
	move.l	a2,-(sp)
	bsr	Simple_Add_Alien_To_List
	move.l	(sp)+,a2
	move.w	alien_data(a2),d0
	muls	#3,d0
	move.w	d0,alien_data(a1)
	move.w	alien_data_extra(a2),d0
	muls	#3,d0
	move.w	d0,alien_data_extra(a1)
	move.w	#Sound_Swoosh,sound_chan4
dont_shoot_pig
	rts


*************************************************
*** PERFORM PIG COLLISION DETECTION           ***
*************************************************
Perform_Pig_Collision_Detection

****NOTE --->>>
****pretend that pig is only 31 pixels square - can then fit between blocks

*reliant on other pig routines for data

	andi.b	#OVERRIDE,alien_work(a2)
	
	move.w	alien_data(a2),d0		;xinc
	move.w	alien_data_extra(a2),d1		;yinc

	clr.b	pig_hit_flags			
	bsr	Do_Pig_On_Pig_Collision
	tst.b	pig_hit_flags
	bne.s	pig_flags_not_clear
	clr.b	alien_work+10(a2)
pig_flags_not_clear		
	
	
	moveq	#0,d0
	moveq	#0,d5
	move.w	alien_data(a2),d0		;xinc
	move.w	alien_data_extra(a2),d1		;yinc

	
	move.w	alien_x(a2),d5
	move.l	current_map_pointer,a0
	
	move.w	d5,d2
	btst.b	#0,pig_hit_flags
	beq.s	do_alien_x_collision
	
*pig hit another pig - so send him off in other x direction

	btst.b	#0,alien_work+10(a2)
	bne.s	do_alien_x_collision	;take action
	bset.b	#0,alien_work+10(a2)
	neg.w	alien_data(a2)
*find new x direction	
	move.l	#new_direction_x,a3
	move.w	alien_direction(a2),d4
	move.b	(a3,d4.w),alien_direction+1(a2)		
	
	move.l	random_walk_ptr,a3	
	move.b	(a3)+,alien_c_pad(a2)
	bge.s	not_end_get_xwalk
	move.l	#random_walk_table,a3
not_end_get_xwalk
	move.l	a3,random_walk_ptr
	
*nothing happens first time - just stops	

do_alien_x_collision	

	tst	d0
	bmi.s	al_left
	move.w	#31,d4
	move.w	#SET_FACE_RIGHT,d7
	bra.s	past_lr_calc
al_left
	move.w	#SET_FACE_LEFT,d7
	clr.w	d4
past_lr_calc
	add.w	d5,d0		;add x position to inc
	move.w	d0,d2
	add.w	d4,d0		;add side to x ( 0 or 32 )
	move.w	alien_y(a2),d3
	addq.w	#PIG_OFFSET,d3		;start collision down a bit
	move.w	d3,d6		;store y
	andi.w	#$fff0,d0
	asr.w	#3,d0		;cos word map			
	add.l	d0,a0				;where currently is
	move.l	a0,a3		;store for next test
	asr.w	#4,d3		;give map y line
	muls	#BIGGEST_MAP_X*MAP_BLOCK_SIZE,d3
	add.l	d3,a0	
	moveq	#0,d0
	move.w	(a0),d0
	
	asl.w	#BLOCK_STRUCT_MULT,d0
	move.l	#block_data_information,a1
	btst.b	#COLLISION_FLAG,block_details(a1,d0)
	bne.s	alien_hit_xblock
	
*-- Second test	
	move.l	a3,a0
	move.w	d6,d3
	add.w	#31,d3		;right at bottom of block
	asr.w	#4,d3		;give map y line
	muls	#BIGGEST_MAP_X*MAP_BLOCK_SIZE,d3
	add.l	d3,a0	
	moveq	#0,d0
	move.w	(a0),d0
	asl.w	#BLOCK_STRUCT_MULT,d0
	btst.b	#COLLISION_FLAG,block_details(a1,d0)
	bne.s	alien_hit_xblock

*-- THIRD TEST	
	move.l	a3,a0
	move.w	d6,d3
	add.w	#15,d3		;middle of block
	asr.w	#4,d3		;give map y line
	muls	#BIGGEST_MAP_X*MAP_BLOCK_SIZE,d3
	add.l	d3,a0	
	moveq	#0,d0
	move.w	(a0),d0
	asl.w	#BLOCK_STRUCT_MULT,d0
	btst.b	#COLLISION_FLAG,block_details(a1,d0)
	bne.s	alien_hit_xblock

	move.w	d2,alien_x(a2)
	bra.s	done_al_x_col		
alien_hit_xblock		
	andi.w	#$fff0,d2
	tst	d4
	bne.s	skip_alien_x_add
	add.w	#16,d2
skip_alien_x_add	
	move.w	d2,alien_x(a2)
	bset.b	d7,alien_work(a2)	;collision info
done_al_x_col


alien_y_collision

	btst.b	#1,pig_hit_flags
	beq.s	do_pig_y_tests
	
*pig hit another pig - so send him off in other y direction
	btst.b	#1,alien_work+10(a2)
	bne.s	do_pig_y_tests
	bset.b	#1,alien_work+10(a2)
	neg.w	alien_data_extra(a2)
*find new y direction	
	move.l	#new_direction_y,a3
	move.w	alien_direction(a2),d4
	move.b	(a3,d4.w),alien_direction+1(a2)		
	move.l	random_walk_ptr,a3	
	move.b	(a3)+,alien_c_pad(a2)
	bge.s	not_end_get_walk
	move.l	#random_walk_table,a3
not_end_get_walk
	move.l	a3,random_walk_ptr		

do_pig_y_tests	

*-- 		DO ALIEN Y COLLISION

*-- TEST THREE POINTS - EITHER END OF BLOCK    +---+---+ 0, 15, 31

*-- D2 = X

	move.w	d2,d5
	
	tst	d1
	bmi.s	al_up
	move.w	#31,d4
	move.w	#SET_FACE_DOWN,d7
	bra.s	past_calc
al_up	
	move.w	#SET_FACE_UP,d7
	clr.w	d4
past_calc

	move.w	d5,d6		;store X

	add.w	alien_y(a2),d1	
	addq.w	#PIG_OFFSET,d1
	move.w	d1,d2
	add.w	d4,d1
	move.l	current_map_pointer,a0
	asr.w	#4,d1		;give map y line
	muls	#BIGGEST_MAP_X*MAP_BLOCK_SIZE,d1
	add.l	d1,a0	
	andi.w	#$fff0,d5
	asr.w	#3,d5	;cos	word map
	move.l	a0,a3	;store for next test
	add.l	d5,a0				;where currently is
	moveq	#0,d0
	move.w	(a0),d0
	asl.w	#BLOCK_STRUCT_MULT,d0
	move.l	#block_data_information,a1
	btst.b	#COLLISION_FLAG,block_details(a1,d0)
	bne.s	alien_hit_yblock
	
*-- Second Test	
	move.l	a3,a0
	move.w	d6,d5
	add.w	#31,d5		;end of block
	andi.w	#$fff0,d5
	asr.w	#3,d5	;cos	word map
	add.l	d5,a0
	moveq	#0,d0
	move.w	(a0),d0
	asl.w	#BLOCK_STRUCT_MULT,d0
	btst.b	#COLLISION_FLAG,block_details(a1,d0)
	bne.s	alien_hit_yblock
	
*-- THIRD TEST
	move.l	a3,a0
	move.w	d6,d5
	add.w	#15,d5		;middle of block
	andi.w	#$fff0,d5
	asr.w	#3,d5	;cos	word map
	add.l	d5,a0
	moveq	#0,d0
	move.w	(a0),d0
	asl.w	#BLOCK_STRUCT_MULT,d0
	btst.b	#COLLISION_FLAG,block_details(a1,d0)
	bne.s	alien_hit_yblock


*-- Pig follow blocks cleanly frig
	move.b	alien_work(a2),d5
	btst	#SET_OVERRIDE,d5
	beq.s	pig_not_in_override_y
	andi.b	#OVERRIDE_MASK,d5	;any collisions??
	bne.s	pig_not_in_override_y
	cmp.b	#SET_FACE_UP,alien_work+1(a2)
	bne.s	pig_not_in_override_y
	addq.w	#4,d2	
	addq.b	#1,d4
	bra.s	alien_hit_yblock
pig_not_in_override_y	
*---	
	
	subq.w	#PIG_OFFSET,d2
	move.w	d2,alien_y(a2)
	bra.s	fin_alien_tests		
	
alien_hit_yblock

	andi.w	#$fff0,d2		;cut to block border
	tst.w	d4
	bne.s	skip_alien_y_add
	add.w	#16,d2
skip_alien_y_add
	subq.w	#PIG_OFFSET,d2	
	move.w	d2,alien_y(a2)	
	bset.b	d7,alien_work(a2)	;collision info		

fin_alien_tests	
	move.b	alien_work(a2),d0
	btst	#OVERRIDE,d0
	bne.s   dont_clear_wait	
	andi.b	#$1f,d0
	beq.s	dont_clear_wait
no_collision
*	clr.b	alien_c_pad(a2)
	subq.b	#6,alien_c_pad(a2)
dont_clear_wait	
	rts

	
random_walk_table
	dc.b	24
	dc.b	14
	dc.b	10
	dc.b	20
	dc.b	5
	dc.b	34
	dc.b	24
	dc.b	12
	dc.b	15
	dc.b	4
	dc.b	29
	dc.b	-1
	even

random_walk_ptr
	dc.l	random_walk_table		
	
*****************************************
****     AIM ALIEN BULLET          ******
*****************************************
Aim_Alien_Bullet
*Send place to go to in d0 and d1

	move.w	actual_player_map_x_position,d2
	move.w	actual_player_map_y_position,d3
	
	moveq	#0,d5
	
	sub.w	d1,d3			;sub y1 from y2
	bpl.s	y2bigger
	neg.w	d3
	bset    #3,d5
y2bigger
	sub.w	d0,d2			;x1 from x2
	bpl.s	x2bigger
	neg.w	d2
	bset	#2,d5
x2bigger
	cmp.w	d2,d3			;is deltax smaller than deltay
	BGe.s	deltaxsmaller
	BSET	#1,D5		
	
	asl	d3
	cmp.w	d2,d3
	ble.s	skip_last_test
	bset	#0,d5
	bra.s	skip_last_test	
deltaxsmaller	
	asl	d2	;x*2
	cmp.w	d3,d2
	ble.s	skip_last_test
	bset	#0,d5
skip_last_test	
	rts


*****************************************
**** INTERPRET PIG COLLISION DATA  ******
*****************************************
Interpret_Pig_Collision_Data

*If pig is following pattern then this routine must be
*called to enable pigs to follow blocks properly

	rts

*****************************************
****     INTERPRET AI LIST         ******
*****************************************
Interpret_AI_list

*-- SEND POINTER TO LIST IN A3
*-- ROUTINE WILL USE alien_work+1(a2) to store information
*-- ROUTINE USES D6 WHICH CONTAINS COLLISION INFORMATION

*-- ROUTINE WILL SEND BACK D5

	moveq	#0,d7
	moveq	#0,d4
	moveq	#0,d5

do_it_man	
	cmp.w	#SET_WANT_TRY,(a3)
	bne.s	whatelse
	addq.l	#2,a3
	move.w	(a3)+,d7	;WANT
	move.w	(a3)+,d4	;TRY
	move.b	d4,alien_work+1(a2)	;STORE
	move.b	d7,alien_work+2(a2)
	
	bset	d4,d5			;MOVE IN TRY DIRECTION
	move.b	d5,alien_work+8(a2)	;pig face direction
	bset	d7,d5
	clr.w	d7
	move.b	alien_work+8(a2),d7
	move.b	d5,alien_work+3(a2)	;pig try direction
	
*-- GO TO TEST WANTS CODE AS THIS WILL ALWAYS FOLLOW ON
	rts
			
whatelse	
	cmp.w	#RESTART_CHECKS,(a3)
	bne.s	test_wants_code
	move.l	2(a3),a3
	bra	do_it_man
	
test_wants_code	
	addq.l	#2,a3
	move.b	alien_work+1(a2),d4	;TRY
	move.b	alien_work+2(a2),d7	;WANT
		
	btst	d7,d6			;IS WANT FREE
	bne.s	is_try_free
	move.l	(a3),a3
	tst	(a3)
	bne.s	not_escaped
	bclr.b	#SET_OVERRIDE,alien_work(a2)	

*----------Pig is free - so find position he originally wanted	
	
	bsr	Aim_Alien_Bullet	
	lsl	d5
	move.l	#face_table,a1
	move.w	(a1,d5.w),d5		;face direction
	move.w	d5,d7
	move.b	#DUMB_UPDATE,alien_c_pad(a2)
*----------	

	rts
not_escaped
	bra	do_it_man
	
is_try_free	
	btst	d4,d6
	bne.s	go_down_list
	move.l	4(a3),a3
	move.b	alien_work+3(a2),d5
	move.b	alien_work+8(a2),d7
	clr.b	alien_c_pad(a2)
	rts	
go_down_list	
	addq.l	#8,a3	
	bra	do_it_man
	rts

*-- AI ROUTINES

SET_WANT_TRY	EQU	100
TEST_WANTS	EQU	200
RESTART_CHECKS	EQU	300	


*-- LEFT LISTS


left_blocked_list			;IF LEFT BLOCKED!!
	dc.w	SET_WANT_TRY
	dc.w	SET_FACE_LEFT
	dc.w	SET_FACE_DOWN
down_repeat	
	dc.w	TEST_WANTS
	dc.l	end_list		;WANT = FREE
	dc.l	down_repeat		;TRY = FREE
right_direction
	dc.w	SET_WANT_TRY
	dc.w	SET_FACE_DOWN
	dc.w	SET_FACE_RIGHT
right_repeat
	dc.w	TEST_WANTS
	dc.l	left_blocked_list	;DOWN FREE		
	dc.l	right_repeat		

up_direction	
	dc.w	SET_WANT_TRY
	dc.w	SET_FACE_RIGHT
	dc.w	SET_FACE_UP
up_repeat
	dc.w	TEST_WANTS
	dc.l	right_direction
	dc.l	up_repeat
		
	dc.w	SET_WANT_TRY		
	dc.w	SET_FACE_UP
	dc.w	SET_FACE_LEFT
left_repeat
	dc.w	TEST_WANTS
	dc.l	up_direction
	dc.l	left_repeat
	
	dc.w	RESTART_CHECKS
	dc.l	left_blocked_list	


left_blocked_list_go_up			
	dc.w	SET_WANT_TRY
	dc.w	SET_FACE_LEFT
	dc.w	SET_FACE_UP
try_up_repeat	
	dc.w	TEST_WANTS
	dc.l	end_list		;WANT = FREE
	dc.l	try_up_repeat		;TRY = FREE
tryright_direction
	dc.w	SET_WANT_TRY
	dc.w	SET_FACE_UP
	dc.w	SET_FACE_RIGHT
tryright_repeat
	dc.w	TEST_WANTS
	dc.l	left_blocked_list_go_up	;DOWN FREE		
	dc.l	tryright_repeat		

try_down_direction	
	dc.w	SET_WANT_TRY
	dc.w	SET_FACE_RIGHT
	dc.w	SET_FACE_DOWN
try_down_repeat
	dc.w	TEST_WANTS
	dc.l	right_direction
	dc.l	try_down_repeat
		
	dc.w	SET_WANT_TRY		
	dc.w	SET_FACE_DOWN
	dc.w	SET_FACE_LEFT
try_left_repeat
	dc.w	TEST_WANTS
	dc.l	try_down_direction
	dc.l	try_left_repeat
	
	dc.w	RESTART_CHECKS
	dc.l	left_blocked_list_go_up




*-- RIGHT LISTS


right_blocked_list			;IF RIGHT BLOCKED!!
	dc.w	SET_WANT_TRY
	dc.w	SET_FACE_RIGHT
	dc.w	SET_FACE_DOWN
rdown_repeat	
	dc.w	TEST_WANTS
	dc.l	end_list		;WANT = FREE
	dc.l	rdown_repeat		;TRY = FREE
rleft_direction
	dc.w	SET_WANT_TRY
	dc.w	SET_FACE_DOWN
	dc.w	SET_FACE_LEFT
rleft_repeat
	dc.w	TEST_WANTS
	dc.l	right_blocked_list	;DOWN FREE		
	dc.l	rleft_repeat		

rup_direction	
	dc.w	SET_WANT_TRY
	dc.w	SET_FACE_LEFT
	dc.w	SET_FACE_UP
rup_repeat
	dc.w	TEST_WANTS
	dc.l	rleft_direction
	dc.l	rup_repeat
		
	dc.w	SET_WANT_TRY		
	dc.w	SET_FACE_UP
	dc.w	SET_FACE_RIGHT
rright_repeat
	dc.w	TEST_WANTS
	dc.l	rup_direction
	dc.l	rright_repeat
	
	dc.w	RESTART_CHECKS
	dc.l	right_blocked_list	



right_blocked_list_go_up			;IF RIGHT BLOCKED!!
	dc.w	SET_WANT_TRY
	dc.w	SET_FACE_RIGHT
	dc.w	SET_FACE_UP
tryrup_repeat	
	dc.w	TEST_WANTS
	dc.l	end_list		;WANT = FREE
	dc.l	tryrup_repeat		;TRY = FREE
tryrleft_direction
	dc.w	SET_WANT_TRY
	dc.w	SET_FACE_UP
	dc.w	SET_FACE_LEFT
tryrleft_repeat
	dc.w	TEST_WANTS
	dc.l	right_blocked_list_go_up	;UP FREE		
	dc.l	tryrleft_repeat		

tryrdown_direction	
	dc.w	SET_WANT_TRY
	dc.w	SET_FACE_LEFT
	dc.w	SET_FACE_DOWN
tryrdown_repeat
	dc.w	TEST_WANTS
	dc.l	tryrleft_direction
	dc.l	tryrdown_repeat
		
	dc.w	SET_WANT_TRY		
	dc.w	SET_FACE_DOWN
	dc.w	SET_FACE_RIGHT
tryrright_repeat
	dc.w	TEST_WANTS
	dc.l	tryrdown_direction
	dc.l	tryrright_repeat
	
	dc.w	RESTART_CHECKS
	dc.l	right_blocked_list_go_up



*-- UP LISTS

up_blocked_list_left_choice
	dc.w	SET_WANT_TRY
	dc.w	SET_FACE_UP
	dc.w	SET_FACE_LEFT
upb_desireleft_repeat	
	dc.w	TEST_WANTS
	dc.l	end_list		;WANT = FREE
	dc.l	upb_desireleft_repeat	;TRY = FREE
upb_try_down_direction
	dc.w	SET_WANT_TRY
	dc.w	SET_FACE_LEFT
	dc.w	SET_FACE_DOWN
upb_trydown_repeat
	dc.w	TEST_WANTS
	dc.l	up_blocked_list_left_choice		
	dc.l	upb_trydown_repeat

upb_tryright_direction	
	dc.w	SET_WANT_TRY
	dc.w	SET_FACE_DOWN
	dc.w	SET_FACE_RIGHT
upb_tryright_repeat
	dc.w	TEST_WANTS
	dc.l	upb_try_down_direction
	dc.l	upb_tryright_repeat
		
	dc.w	SET_WANT_TRY		
	dc.w	SET_FACE_RIGHT
	dc.w	SET_FACE_UP
upb_tryup_repeat
	dc.w	TEST_WANTS
	dc.l	upb_tryright_direction
	dc.l	upb_tryup_repeat
	
	dc.w	RESTART_CHECKS
	dc.l	up_blocked_list_left_choice



up_blocked_list_right_choice
	dc.w	SET_WANT_TRY
	dc.w	SET_FACE_UP
	dc.w	SET_FACE_RIGHT
upb_desireright_repeat	
	dc.w	TEST_WANTS
	dc.l	end_list		;WANT = FREE
	dc.l	upb_desireright_repeat	;TRY = FREE
upbr_try_down_direction
	dc.w	SET_WANT_TRY
	dc.w	SET_FACE_RIGHT
	dc.w	SET_FACE_DOWN
upbr_trydown_repeat
	dc.w	TEST_WANTS
	dc.l	up_blocked_list_right_choice		
	dc.l	upbr_trydown_repeat

upbr_tryleft_direction	
	dc.w	SET_WANT_TRY
	dc.w	SET_FACE_DOWN
	dc.w	SET_FACE_LEFT
upbr_tryleft_repeat
	dc.w	TEST_WANTS
	dc.l	upbr_try_down_direction
	dc.l	upbr_tryleft_repeat
		
	dc.w	SET_WANT_TRY		
	dc.w	SET_FACE_LEFT
	dc.w	SET_FACE_UP
upbr_tryup_repeat
	dc.w	TEST_WANTS
	dc.l	upbr_tryleft_direction
	dc.l	upbr_tryup_repeat
	
	dc.w	RESTART_CHECKS
	dc.l	up_blocked_list_right_choice





*-- DOWN LISTS

down_blocked_list_left_choice
	dc.w	SET_WANT_TRY
	dc.w	SET_FACE_DOWN
	dc.w	SET_FACE_LEFT
downd_desireleft_repeat	
	dc.w	TEST_WANTS
	dc.l	end_list		;WANT = FREE
	dc.l	downd_desireleft_repeat	;TRY = FREE
downd_try_up_direction
	dc.w	SET_WANT_TRY
	dc.w	SET_FACE_LEFT
	dc.w	SET_FACE_UP
downd_tryup_repeat
	dc.w	TEST_WANTS
	dc.l	down_blocked_list_left_choice		
	dc.l	downd_tryup_repeat

downd_tryright_direction	
	dc.w	SET_WANT_TRY
	dc.w	SET_FACE_UP
	dc.w	SET_FACE_RIGHT
downd_tryright_repeat
	dc.w	TEST_WANTS
	dc.l	downd_try_up_direction
	dc.l	downd_tryright_repeat
		
	dc.w	SET_WANT_TRY		
	dc.w	SET_FACE_RIGHT
	dc.w	SET_FACE_DOWN
downd_trydown_repeat
	dc.w	TEST_WANTS
	dc.l	downd_tryright_direction
	dc.l	downd_trydown_repeat
	
	dc.w	RESTART_CHECKS
	dc.l	down_blocked_list_left_choice


down_blocked_list_right_choice
	dc.w	SET_WANT_TRY
	dc.w	SET_FACE_DOWN
	dc.w	SET_FACE_RIGHT
down_desireright_repeat	
	dc.w	TEST_WANTS
	dc.l	end_list		;WANT = FREE
	dc.l	down_desireright_repeat	;TRY = FREE
down_try_up_direction
	dc.w	SET_WANT_TRY
	dc.w	SET_FACE_RIGHT		;want
	dc.w	SET_FACE_UP		;move
down_tryup_repeat
	dc.w	TEST_WANTS
	dc.l	down_blocked_list_right_choice		
	dc.l	down_tryup_repeat

down_tryleft_direction	
	dc.w	SET_WANT_TRY
	dc.w	SET_FACE_UP
	dc.w	SET_FACE_LEFT
down_tryleft_repeat
	dc.w	TEST_WANTS
	dc.l	down_try_up_direction
	dc.l	down_tryleft_repeat
		
	dc.w	SET_WANT_TRY		
	dc.w	SET_FACE_LEFT
	dc.w	SET_FACE_DOWN
down_trydown_repeat
	dc.w	TEST_WANTS
	dc.l	down_tryleft_direction
	dc.l	down_trydown_repeat
	
	dc.w	RESTART_CHECKS
	dc.l	down_blocked_list_right_choice


end_list
	dc.w	0


dumb_alien_directions
	dc.w	0,0					;0000
	dc.w	0,-DUMB_ALIEN_SPEED			;0001
	
	dc.w	DUMB_ALIEN_SPEED,0			;0010
	dc.w	DUMB_ALIEN_SPEED,-DUMB_ALIEN_SPEED	;0011
	
	dc.w	0,DUMB_ALIEN_SPEED			;0100
	dc.w	0,0					;0101
	
	dc.w	DUMB_ALIEN_SPEED,DUMB_ALIEN_SPEED	;0110
	dc.w	0,0					;0111
	
	dc.w	-DUMB_ALIEN_SPEED,0			;1000
	dc.w	-DUMB_ALIEN_SPEED,-DUMB_ALIEN_SPEED	;1001
	
	dc.w	0,0					;1010
	dc.w	0,0					;1011
	
	dc.w	-DUMB_ALIEN_SPEED,DUMB_ALIEN_SPEED	;1100
	dc.w	0,0					;1101
	
	dc.w	0,0					;1110
	dc.w	0,0					;1111

fast_dumb_alien_directions
	dc.w	0,0					;0000
	dc.w	0,-FAST_DUMB_ALIEN_SPEED			;0001
	
	dc.w	FAST_DUMB_ALIEN_SPEED,0			;0010
	dc.w	FAST_DUMB_ALIEN_SPEED,-FAST_DUMB_ALIEN_SPEED	;0011
	
	dc.w	0,FAST_DUMB_ALIEN_SPEED			;0100
	dc.w	0,0					;0101
	
	dc.w	FAST_DUMB_ALIEN_SPEED,FAST_DUMB_ALIEN_SPEED	;0110
	dc.w	0,0					;0111
	
	dc.w	-FAST_DUMB_ALIEN_SPEED,0			;1000
	dc.w	-FAST_DUMB_ALIEN_SPEED,-FAST_DUMB_ALIEN_SPEED	;1001
	
	dc.w	0,0					;1010
	dc.w	0,0					;1011
	
	dc.w	-FAST_DUMB_ALIEN_SPEED,FAST_DUMB_ALIEN_SPEED	;1100
	dc.w	0,0					;1101
	
	dc.w	0,0					;1110
	dc.w	0,0	
	
FACE_LEFT	EQU	8<<1
FACE_RIGHT	EQU	2<<1		
FACE_UP		EQU	1<<1
FACE_DOWN	EQU	4<<1

SET_FACE_LEFT	EQU	4
SET_FACE_RIGHT	EQU	2
SET_FACE_UP	EQU	1
SET_FACE_DOWN	EQU	3

OVERRIDE	EQU	16<<1
OVERRIDE_MASK	EQU	$1f
SET_OVERRIDE	EQU	5

face_table
	dc.w	FACE_DOWN
	dc.w	FACE_DOWN+FACE_RIGHT
	
	dc.w	FACE_RIGHT
	dc.w	FACE_DOWN+FACE_RIGHT
	
	dc.w	FACE_DOWN
	dc.w	FACE_LEFT+FACE_DOWN
	
	dc.w	FACE_LEFT
	dc.w	FACE_LEFT+FACE_DOWN
	
	dc.w	FACE_UP
	dc.w	FACE_RIGHT+FACE_UP
	
	dc.w	FACE_RIGHT
	dc.w	FACE_RIGHT+FACE_UP
	
	dc.w	FACE_UP
	dc.w	FACE_UP+FACE_LEFT
	
	dc.w	FACE_LEFT
	dc.w	FACE_UP+FACE_LEFT

face_direction_table
	dc.w	0		;0000
	dc.w	0		;0001
	
	dc.w	2		;0010
	dc.w	1		;0011
	
	dc.w	4		;0100
	dc.w	0		;0101
	
	dc.w	3		;0110
	dc.w	0		;0111
	
	dc.w	6		;1000
	dc.w	7		;1001
	
	dc.w	0		;1010
	dc.w	0		;1011
	
	dc.w	5		;1100
	dc.w	0		;1101
	
	dc.w	0		;1110
	dc.w	0		;1111
	