*------------------------------------------------------------------------*
*- The pain....the pain...						-*
*------------------------------------------------------------------------*

*----------------------------SCROLL CODE----------------------


WAIT_DRAW_BLOCKS	EQU	0
START_DRAW_BLOCKS	EQU	1

*The two lines below dont have -4 subtracted as this is done in the
*draw y blocks routine - see the comment in the code

*-- Y OFFSETS

SCROLL_GOING_DOWN		EQU	(-48*BPR)	;up from bottom of scroll
SCROLL_GOING_UP			EQU	(-32*BPR)

MAP_SCREEN_OFFSET_DOWN		EQU	(17*BIGGEST_MAP_X)-2
MAP_SCREEN_OFFSET_UP		EQU	(-2*BIGGEST_MAP_X)-2


ALIEN_MAP_SCREEN_OFFSET_DOWN	EQU	(18*BIGGEST_MAP_X)-2
ALIEN_MAP_SCREEN_OFFSET_UP	EQU	(-3*BIGGEST_MAP_X)-2


SCROLL_POSITION_OFFSET_DOWN	EQU	(17*16)   
SCROLL_POSITION_OFFSET_UP	EQU	(-2*16)   


ALIEN_SCROLL_POSITION_OFFSET_DOWN	EQU	(18*16)   
ALIEN_SCROLL_POSITION_OFFSET_UP	EQU	(-3*16)
*-- X OFFSETS

SCROLL_GOING_LEFT		EQU	(-32*BPR)+44
SCROLL_GOING_RIGHT		EQU	(-32*BPR)-4

MAP_SCREEN_OFFSET_LEFT		EQU	(-BIGGEST_MAP_X*2)+22
MAP_SCREEN_OFFSET_RIGHT		EQU	(-BIGGEST_MAP_X*2)-2

ALIEN_MAP_SCREEN_OFFSET_LEFT			EQU	(-BIGGEST_MAP_X*2)+23
ALIEN_MAP_SCREEN_OFFSET_RIGHT			EQU	(-BIGGEST_MAP_X*2)-3


SCROLL_POSITION_OFFSET_LEFT			EQU	22*16   
SCROLL_POSITION_OFFSET_RIGHT			EQU	(-2)*16   

ALIEN_SCROLL_POSITION_OFFSET_LEFT		EQU	23*16   
ALIEN_SCROLL_POSITION_OFFSET_RIGHT		EQU	(-3)*16 

total_number_of_y_blocks_to_draw		EQU	25
current_y_map_position				dc.w	0

total_number_of_x_blocks_to_draw		EQU	20
current_x_map_position				dc.w	0

number_of_x_blocks_per_frame			EQU	3-1
number_of_y_blocks_per_frame			EQU	4-1

total_number_of_alien_y_blocks_to_add		EQU	27
total_number_of_alien_x_blocks_to_add		EQU	22

number_of_x_alien_blocks_per_frame		EQU	4-1
number_of_y_alien_blocks_per_frame		EQU	5-1

******************************************
****            MOVE SCROLL          *****
******************************************
move_scroll
	move.w	player_x_inc,d0
	move.w	player_y_inc,d1

	cmp.w	#PLAYER_INCREMENT>>PLAYER_SCALE,d0
	ble.s	x_within_speed_bounds
	move.w	#PLAYER_INCREMENT>>PLAYER_SCALE,d0
x_within_speed_bounds
	cmp.w	#PLAYER_INCREMENT>>PLAYER_SCALE,d1
	ble.s	y_within_speed_bounds
	move.w	#PLAYER_INCREMENT>>PLAYER_SCALE,d1
y_within_speed_bounds

	tst	freeze_scroll
	bne	skip_add_scroll_movements
	
*-Test x bounds

	add.w	d0,scroll_x_position
	bge.s	scroll_x_not_hit_bounds
	clr.w	scroll_x_position
	bra.s	scroll_x_not_hit_max_bounds
scroll_x_not_hit_bounds		
	move.w	map_x_size,d3
	cmp.w	scroll_x_position,d3
	bgt.s	scroll_x_not_hit_max_bounds
	move.w	d3,scroll_x_position
scroll_x_not_hit_max_bounds
	
*-<

*-Test y bounds	

	add.w	d1,scroll_y_position
	bge.s	scroll_not_hit_bounds
	clr.w	scroll_y_position
	bra.s	scroll_y_not_hit_max_bounds
scroll_not_hit_bounds
	move.w	map_y_size,d5
	cmp.w	scroll_y_position,d5
	bgt.s	scroll_y_not_hit_max_bounds
	move.w	d5,scroll_y_position
scroll_y_not_hit_max_bounds
	bra.s	do_rest_of_scroll_code

*-<
skip_add_scroll_movements	
	tst.w	goto_flag
	beq.s	do_rest_of_scroll_code
	
	clr.w	d2
	
	tst	goto_sc_x
	beq.s	x_pos_at_zero
	bpl.s	move_sc_right
	subq.w	#1,scroll_x_position
	addq.w	#1,goto_sc_x
	bra.s	check_y_move
move_sc_right
	addq.w	#1,scroll_x_position
	subq.w	#1,goto_sc_x
	bra.s	check_y_move
x_pos_at_zero
	move.w	#1,d2	
check_y_move	
	tst	goto_sc_y
	beq.s	y_pos_at_zero
	bpl.s	move_sc_up
	subq.w	#1,scroll_y_position
	addq.w	#1,goto_sc_y
	bra.s	do_rest_of_scroll_code
move_sc_up
	addq.w	#1,scroll_x_position
	subq.w	#1,goto_sc_x
	bra.s	do_rest_of_scroll_code
y_pos_at_zero
	tst	d2
	beq.s	do_rest_of_scroll_code
	clr.w	goto_flag

do_rest_of_scroll_code	
	move.w	scroll_x_position,d0
	move.w	scroll_y_position,d1
	
	sub.w	last_scroll_x,d0
	sub.w	last_scroll_y,d1
	
	move.w	scroll_x_position,last_scroll_x
	move.w	scroll_y_position,last_scroll_y
	

	bsr	check_add_blocks

	bsr	position_scroll
			
	rts

	
last_scroll_x		dc.w	0
last_scroll_y		dc.w	0	

freeze_scroll		dc.w	0	

******************************************
****    CHECK ADD BLOCKS             *****
******************************************
check_add_blocks

*-Do for y blocks


	add.w	d1,check_y_add
	cmp.w	#16,check_y_add
	blt.s	check_min_add
	sub.w	#16,check_y_add
	move.w	#START_DRAW_BLOCKS,y_ready_flag
	move.l	#SCROLL_GOING_DOWN,add_y_block_direction
	move.l	#MAP_SCREEN_OFFSET_DOWN*MAP_BLOCK_SIZE,add_y_map_direction
	move.l	#ALIEN_MAP_SCREEN_OFFSET_DOWN,add_y_map_alien_direction
	move.w	#SCROLL_POSITION_OFFSET_DOWN,scroll_add_y_offset
	move.w	#ALIEN_SCROLL_POSITION_OFFSET_DOWN,alien_scroll_add_y_offset
	move.w	fixed_x,alien_x_pos
	move.w	fixed_y,alien_y_pos
	move.l	current_screen_position,current_y_screen_position
	move.l	current_map_mem_position,current_y_map_mem_position
	move.l	current_alien_map_mem_position,current_y_alien_map_mem_position
	bra.s	drawing_please_wait
check_min_add
	cmp.w	#-16,check_y_add
	bgt.s	drawing_please_wait
	add.w	#16,check_y_add
	move.w	#START_DRAW_BLOCKS,y_ready_flag		
	move.l	#SCROLL_GOING_UP,add_y_block_direction
	move.l	#MAP_SCREEN_OFFSET_UP*MAP_BLOCK_SIZE,add_y_map_direction
	move.l	#ALIEN_MAP_SCREEN_OFFSET_UP,add_y_map_alien_direction
	move.w	#SCROLL_POSITION_OFFSET_UP,scroll_add_y_offset
	move.w	#ALIEN_SCROLL_POSITION_OFFSET_UP,alien_scroll_add_y_offset
	move.w	fixed_x,alien_x_pos
	move.w	fixed_y,alien_y_pos
	move.l	current_screen_position,current_y_screen_position
	move.l	current_map_mem_position,current_y_map_mem_position
	move.l	current_alien_map_mem_position,current_y_alien_map_mem_position
drawing_please_wait

*-<

*- Do for x blocks

	add.w	d0,check_x_add
	cmp.w	#16,check_x_add
	blt.s	check_x_min_add
	sub.w	#16,check_x_add
	move.w	#START_DRAW_BLOCKS,x_ready_flag
	move.l	#SCROLL_GOING_LEFT,add_x_block_direction
	move.l	#MAP_SCREEN_OFFSET_LEFT*MAP_BLOCK_SIZE,add_x_map_direction
	move.l	#ALIEN_MAP_SCREEN_OFFSET_LEFT,add_x_map_alien_direction
	move.w	#SCROLL_POSITION_OFFSET_LEFT,scroll_add_x_offset
	move.w	#ALIEN_SCROLL_POSITION_OFFSET_LEFT,alien_scroll_add_x_offset
	move.w	fixed_y,alien_y_pos2
	move.w	fixed_x,alien_x_pos2
	move.l	current_screen_position,current_x_screen_position
	move.l	current_map_mem_position,current_x_map_mem_position
	move.l	current_alien_map_mem_position,current_x_alien_map_mem_position
	bra.s	drawing_x_please_wait
check_x_min_add
	cmp.w	#-16,check_x_add
	bgt.s	drawing_x_please_wait
	add.w	#16,check_x_add
	move.w	#START_DRAW_BLOCKS,x_ready_flag		
	move.l	#SCROLL_GOING_RIGHT,add_x_block_direction
	move.l	#MAP_SCREEN_OFFSET_RIGHT*MAP_BLOCK_SIZE,add_x_map_direction
	move.l	#ALIEN_MAP_SCREEN_OFFSET_RIGHT,add_x_map_alien_direction
	move.w	#SCROLL_POSITION_OFFSET_RIGHT,scroll_add_x_offset
	move.w	#ALIEN_SCROLL_POSITION_OFFSET_RIGHT,alien_scroll_add_x_offset
	move.w	fixed_y,alien_y_pos2
	move.w	fixed_x,alien_x_pos2
	move.l	current_screen_position,current_x_screen_position
	move.l	current_map_mem_position,current_x_map_mem_position
	move.l	current_alien_map_mem_position,current_x_alien_map_mem_position
drawing_x_please_wait	

*-<
	sub.w	d0,actual_x_position
	sub.w	d1,actual_y_position
	

		
	asl	#PLAYER_SCALE,d0
	asl	#PLAYER_SCALE,d1
	sub.w	d0,player_x_position
	sub.w	d1,player_y_position



	rts
fixed_x	dc.w	0
fixed_y	dc.w	0
alien_x_pos			dc.w	0
alien_y_pos			dc.w	0
alien_x_pos2			dc.w	0
alien_y_pos2			dc.w	0

add_y_block_direction		dc.l	0	
check_y_add			dc.w	0
y_ready_flag			dc.w	0	

add_x_block_direction		dc.l	0	
check_x_add			dc.w	0
x_ready_flag			dc.w	0	

add_y_map_direction		dc.l	0
add_x_map_direction		dc.l	0
add_y_map_alien_direction		dc.l	0
add_x_map_alien_direction		dc.l	0

		
scroll_add_y_offset		dc.w	0
scroll_add_x_offset		dc.w	0		

alien_scroll_add_y_offset		dc.w	0
alien_scroll_add_x_offset		dc.w	0
		
******************************************
****        POSITION SCROLL          *****
******************************************
position_scroll

*Positions scroll by the x and y values stored

	move.w	scroll_x_position,d0
	move.w	scroll_y_position,d1

position_scroll_along_x	

	moveq	#0,d3
	move.w	d0,d2
	move.w	d0,d3
	andi.w	#$000f,d2	;shift value
	move.w	d2,alien_shift
	asr.w	#4,d3		;number of blocks in
	andi.w	#$fff0,d0
	move.w	d0,fixed_x
	asr.w	#3,d0
	ext.l	d0		;bytes in
	neg.w	d2
	add.w	#15,d2
	move.w	d2,d4
	asl.w	#4,d2
	or.w	d2,d4
	move.w	d4,scroll_value
	
position_scroll_along_y

*---	get current map positions

	moveq	#0,d2
	move.w	d1,d2
	andi.w	#$fff0,d2
	move.w	d2,fixed_y
	move.w	d1,d2
	asr.w	#4,d2
	mulu	#BIGGEST_MAP_X,d2
	move.l	current_alien_map_pointer,a0
	add.l	d2,a0		;add y
	add.l	d3,a0		;add x
	move.l	a0,current_alien_map_mem_position
	
	asl.l	d2	;cos map mem = word
	asl.l	d3
	move.l	current_map_pointer,a0
	add.l	d2,a0		;add y
	add.l	d3,a0		;add x
	move.l	a0,current_map_mem_position	
		

*---

	ext.l	d1
	divu	#SCROLL_HEIGHT,d1
	swap	d1	;this is all we want - split position down screen
	neg.w	d1		;so scroll goes right way
	add.w	#SCROLL_HEIGHT,d1
	move.w	d1,split_position

*---calc where to draw
	
	moveq	#0,d3
	move.w	#SCROLL_HEIGHT,d3		;position above buffer area	
	sub.w	d1,d3		;position of buffer area
	andi.w	#$fff0,d3
	mulu	#BPR,d3	
	add.l	scroll_area,d3
	add.l	d0,d3		;add x in
	move.l	d3,current_screen_position
	
*------
	move.w	d1,d2
			
	add.w	#$2c,d1	
	moveq	#0,d4
	cmp.w	#$ff,d1
	ble.s	not_over_dodgy_line
	moveq	#1,d4
not_over_dodgy_line
	cmp.w	#$ff+$2c-16,d1
	ble.s	not_off_copper
	
	move.w	#-1,d4	
	bra.s	calc_screen_split
not_off_copper	
	andi.w	#$ff,d1	;so values wraps round
	asl.w	#8,d1
	addq.w	#1,d1	; = wait value
calc_screen_split	
	neg.w	d2
	add.w	#SCROLL_HEIGHT,d2
	mulu	#BPR,d2
	ext.l	d2
	move.l	d2,d5
	add.l	buff_plane1,d5
	add.l	plane1,d2	;to display at top
	move.l	plane1,d3	;top display at split
	add.l	d0,d2		;add x in
	add.l	d0,d5
	move.l	d5,current_alien_draw_position
	move.l	buff_plane1,d5
	add.l	d0,d5
	move.l	d5,current_alien_split_draw_position
	add.l	d0,d3		;add x in
	bsr	insert_plane_pointers		
	rts

******************************************
****     INSERT PLANE POINTERS       *****
******************************************
insert_plane_pointers
*d1 contains wait value
*d2	=	top of display
*d3	=	split part of display
*d4 indicates if inserting after 255 gap
	
	tst	d4
	bmi	clear_all_banks
	beq.s	insert_before_line
	
insert_after_line	
	move.l	#scroll_bank_2,a0
	move.l	#scroll_bank_1,a1
	bsr	fill_banks
	rts
insert_before_line	
	move.l	#scroll_bank_1,a0
	move.l	#scroll_bank_2,a1			
	bsr	fill_banks
	rts
clear_all_banks
	move.l	#scroll_bank_1,a0
	move.l	#scroll_bank_2,a1			
	bsr	clear_banks
		
	rts
	
******************************************
****     FILL BANKS                  *****
******************************************
fill_banks
*a0 = bank to fill
*a1 = bank to clear
*d1 = wait
*d2 = top of display
*d3 = split display
	
*change to copper jump later - but get it working first!!!	
	
*		IN USE SPLIT POINTERS	
	
	move.w	d1,wait_pos(a0)
	move.w	#$fffe,wait_mask(a0)
	move.w	#$e2,plane_1_lo_ptr(a0)	
	move.w	d3,plane_1_lo_val(a0)
	swap	d3
	move.w	#$e0,plane_1_hi_ptr(a0)
	move.w	d3,plane_1_hi_val(a0)
	swap	d3
	
	add.l	#PLANE_INC,d3
	
	move.w	#$e6,plane_2_lo_ptr(a0)
	move.w	d3,plane_2_lo_val(a0)
	swap	d3
	move.w	#$e4,plane_2_hi_ptr(a0)
	move.w	d3,plane_2_hi_val(a0)
	swap	d3

	add.l	#PLANE_INC,d3
	
	move.w	#$ea,plane_3_lo_ptr(a0)
	move.w	d3,plane_3_lo_val(a0)
	swap	d3
	move.w	#$e8,plane_3_hi_ptr(a0)
	move.w	d3,plane_3_hi_val(a0)
	swap	d3
	
	add.l	#PLANE_INC,d3
	
	move.w	#$ee,plane_4_lo_ptr(a0)
	move.w	d3,plane_4_lo_val(a0)
	swap	d3
	move.w	#$ec,plane_4_hi_ptr(a0)
	move.w	d3,plane_4_hi_val(a0)

*		UNUSED SET OF SPLIT POINTERS	
	
	move.w	#$1f0,wait_pos(a1)
	
	move.w	#$1f0,plane_1_hi_ptr(a1)
	move.w	#$1f0,plane_1_lo_ptr(a1)

	move.w	#$1f0,plane_2_hi_ptr(a1)
	move.w	#$1f0,plane_2_lo_ptr(a1)

	move.w	#$1f0,plane_3_hi_ptr(a1)
	move.w	#$1f0,plane_3_lo_ptr(a1)

	move.w	#$1f0,plane_4_hi_ptr(a1)
	move.w	#$1f0,plane_4_lo_ptr(a1)

*		TOP OF SCREEN


	move.l	#top_of_screen-4,a0	;so rs.w's work
	move.w	d2,plane_1_lo_val(a0)
	swap	d2
	move.w	d2,plane_1_hi_val(a0)
	swap	d2
	add.l	#PLANE_INC,d2
	move.w	d2,plane_2_lo_val(a0)
	swap	d2
	move.w	d2,plane_2_hi_val(a0)
	swap	d2
	add.l	#PLANE_INC,d2
	move.w	d2,plane_3_lo_val(a0)
	swap	d2
	move.w	d2,plane_3_hi_val(a0)
	swap	d2
	add.l	#PLANE_INC,d2
	move.w	d2,plane_4_lo_val(a0)
	swap	d2
	move.w	d2,plane_4_hi_val(a0)

	rts
		
******************************************
****     CLEAR BANKS                 *****
******************************************
clear_banks

*		UNUSED SET OF SPLIT POINTERS	1
	
	move.w	#$1f0,wait_pos(a1)
	
	move.w	#$1f0,plane_1_hi_ptr(a1)
	move.w	#$1f0,plane_1_lo_ptr(a1)

	move.w	#$1f0,plane_2_hi_ptr(a1)
	move.w	#$1f0,plane_2_lo_ptr(a1)

	move.w	#$1f0,plane_3_hi_ptr(a1)
	move.w	#$1f0,plane_3_lo_ptr(a1)

	move.w	#$1f0,plane_4_hi_ptr(a1)
	move.w	#$1f0,plane_4_lo_ptr(a1)
	
*		UNUSED SET OF SPLIT POINTERS	2
	
	move.w	#$1f0,wait_pos(a0)
	
	move.w	#$1f0,plane_1_hi_ptr(a0)
	move.w	#$1f0,plane_1_lo_ptr(a0)

	move.w	#$1f0,plane_2_hi_ptr(a0)
	move.w	#$1f0,plane_2_lo_ptr(a0)

	move.w	#$1f0,plane_3_hi_ptr(a0)
	move.w	#$1f0,plane_3_lo_ptr(a0)

	move.w	#$1f0,plane_4_hi_ptr(a0)
	move.w	#$1f0,plane_4_lo_ptr(a0)



*		TOP OF SCREEN


	move.l	#top_of_screen-4,a0	;so rs.w's work
	move.w	d2,plane_1_lo_val(a0)
	swap	d2
	move.w	d2,plane_1_hi_val(a0)
	swap	d2
	add.l	#PLANE_INC,d2
	move.w	d2,plane_2_lo_val(a0)
	swap	d2
	move.w	d2,plane_2_hi_val(a0)
	swap	d2
	add.l	#PLANE_INC,d2
	move.w	d2,plane_3_lo_val(a0)
	swap	d2
	move.w	d2,plane_3_hi_val(a0)
	swap	d2
	add.l	#PLANE_INC,d2
	move.w	d2,plane_4_lo_val(a0)
	swap	d2
	move.w	d2,plane_4_hi_val(a0)


	rts
		
scroll_x_position		dc.w	0
scroll_y_position		dc.w	0	

split_position			dc.w	0

**********************************************************
***********   DRAW BLOCKS FOR SCROLL           ***********
**********************************************************
draw_blocks_for_scroll

	tst.w	y_ready_flag
	beq.s	see_if_x_to_draw
	move.l	current_y_screen_position,a0
	move.l	current_y_map_mem_position,a1
	bsr	draw_y_blocks
	
	move.l	current_y_alien_map_mem_position,a0
	bsr	Add_Y_Aliens	
	
see_if_x_to_draw
	
	tst.w	x_ready_flag
	beq.s	quit_draw_blocks_for_scroll
	move.l	current_x_screen_position,a0
	move.l	current_x_map_mem_position,a1
	bsr	draw_x_blocks
	
	move.l	current_x_alien_map_mem_position,a0
	bsr	Add_X_Aliens
	
quit_draw_blocks_for_scroll
	
	rts
	
current_screen_position			dc.l	0
	
current_y_screen_position		dc.l	0
current_x_screen_position		dc.l	0

current_map_mem_position		dc.l	0	
current_alien_map_mem_position		dc.l	0	

current_x_map_mem_position		dc.l	0
current_y_map_mem_position		dc.l	0
current_x_alien_map_mem_position	dc.l	0
current_y_alien_map_mem_position	dc.l	0



**********************************************************
***********   DRAW Y BLOCKS                    ***********
**********************************************************
draw_y_blocks
*current screen mem position in a0
*current map position in a1
	
				
	
	add.l	add_y_block_direction,a0

	cmp.l	scroll_area,a0
	bge.s	draw_inside_plane_area
	add.l	#SCROLL_HEIGHT*BPR,a0
draw_inside_plane_area

*---- So starts one block back so filling in x strips - see design
*---- must be done here or else cant do the check above - i.e will
*----- just be above plane and then blocks will be drawn in wrong place

	subq.l	#4,a0
*-<
	add.l	add_y_map_direction,a1

draw_blocks_main


	moveq	#0,d0
	move.w  current_y_map_position,d0
	ext.l	d0
	asl	d0	;cos map data = word
	add.l	d0,a1	;current map position
	add.l	d0,a0	;get to current line

	move.l	a0,a5		;store for buff write

	
	move.w	#total_number_of_y_blocks_to_draw,d2	
	moveq	#0,d7	;count number of blocks drawn

init_blit_values	
	btst	#14,dmaconr(a6)
	bne.s	init_blit_values	


	move.w	#BPR-2,bltdmod(a6)	
	move.w	#0,bltamod(a6)
	move.l	#$ffffffff,bltafwm(a6)
	move.l	#$09F00000,bltcon0(A6)	


	
	move.w	#number_of_y_blocks_per_frame,d0
draw_loop
	move.l	level_background_blocks,a2
	moveq	#0,d1

	move.w	(a1)+,d1
	asl.l	#7,d1		;same as mulu (16*2)*4
	add.l	d1,a2	;get to correct position in block data


*Messy to look at but faster than 68000 - only very marginally
*slower than blitter and map blocks can be in fast mem!!

	move.l	a0,a3

	move.w	(a2)+,(a3)
	move.w	(a2)+,BPR(a3)
	move.w	(a2)+,BPR*2(a3)
	move.w	(a2)+,BPR*3(a3)
	move.w	(a2)+,BPR*4(a3)
	move.w	(a2)+,BPR*5(a3)
	move.w	(a2)+,BPR*6(a3)
	move.w	(a2)+,BPR*7(a3)
	move.w	(a2)+,BPR*8(a3)
	move.w	(a2)+,BPR*9(a3)
	move.w	(a2)+,BPR*10(a3)
	move.w	(a2)+,BPR*11(a3)
	move.w	(a2)+,BPR*12(a3)
	move.w	(a2)+,BPR*13(a3)
	move.w	(a2)+,BPR*14(a3)
	move.w	(a2)+,BPR*15(a3)
		
	add.l	#PLANE_INC,a3
	
	move.w	(a2)+,(a3)
	move.w	(a2)+,BPR(a3)
	move.w	(a2)+,BPR*2(a3)
	move.w	(a2)+,BPR*3(a3)
	move.w	(a2)+,BPR*4(a3)
	move.w	(a2)+,BPR*5(a3)
	move.w	(a2)+,BPR*6(a3)
	move.w	(a2)+,BPR*7(a3)
	move.w	(a2)+,BPR*8(a3)
	move.w	(a2)+,BPR*9(a3)
	move.w	(a2)+,BPR*10(a3)
	move.w	(a2)+,BPR*11(a3)
	move.w	(a2)+,BPR*12(a3)
	move.w	(a2)+,BPR*13(a3)
	move.w	(a2)+,BPR*14(a3)
	move.w	(a2)+,BPR*15(a3)

	add.l	#PLANE_INC,a3
	
	move.w	(a2)+,(a3)
	move.w	(a2)+,BPR(a3)
	move.w	(a2)+,BPR*2(a3)
	move.w	(a2)+,BPR*3(a3)
	move.w	(a2)+,BPR*4(a3)
	move.w	(a2)+,BPR*5(a3)
	move.w	(a2)+,BPR*6(a3)
	move.w	(a2)+,BPR*7(a3)
	move.w	(a2)+,BPR*8(a3)
	move.w	(a2)+,BPR*9(a3)
	move.w	(a2)+,BPR*10(a3)
	move.w	(a2)+,BPR*11(a3)
	move.w	(a2)+,BPR*12(a3)
	move.w	(a2)+,BPR*13(a3)
	move.w	(a2)+,BPR*14(a3)
	move.w	(a2)+,BPR*15(a3)

	add.l	#PLANE_INC,a3
	
	move.w	(a2)+,(a3)
	move.w	(a2)+,BPR(a3)
	move.w	(a2)+,BPR*2(a3)
	move.w	(a2)+,BPR*3(a3)
	move.w	(a2)+,BPR*4(a3)
	move.w	(a2)+,BPR*5(a3)
	move.w	(a2)+,BPR*6(a3)
	move.w	(a2)+,BPR*7(a3)
	move.w	(a2)+,BPR*8(a3)
	move.w	(a2)+,BPR*9(a3)
	move.w	(a2)+,BPR*10(a3)
	move.w	(a2)+,BPR*11(a3)
	move.w	(a2)+,BPR*12(a3)
	move.w	(a2)+,BPR*13(a3)
	move.w	(a2)+,BPR*14(a3)
	move.w	(a2)+,BPR*15(a3)
	

done_a_block
	addq.l	#2,a0	;next block position along screen
	addq.w	#1,current_y_map_position
	addq.w	#1,d7		;count number blocks drawn	
	cmp.w	current_y_map_position,d2
	bne.s	not_yet_done_line
	clr	current_y_map_position
	move.w	#WAIT_DRAW_BLOCKS,y_ready_flag	;done our line now wait for screen to scroll 16
	bra.s	done_all_blocks
not_yet_done_line
	dbra	d0,draw_loop	
	
done_all_blocks	

	
*------------------Draw y blocks into buffer--------------

	move.l	a5,a4		;a5 stored from above
	add.l	#PLANE_INC*4,a5		;buff position	
	move.l	a5,a3
	add.l	#PLANE_INC*4,a3
	move.w	#BPR,d0
	move.w	d7,d1
	asl	d1
	sub.w	d1,d0			;modulus
	add.w	#16<<6,d7		;blitsize
	
wait_y_buff_start
	btst	#14,dmaconr(a6)
	bne.s	wait_y_buff_start

	move.w	d0,bltamod(a6)
	move.w	d0,bltdmod(a6)
	
	move.l	a4,bltapth(a6)
	move.l	a5,bltdpth(a6)
	move.w	d7,bltsize(a6)

draw_y_copy1
	btst	#14,dmaconr(a6)
	bne.s	draw_y_copy1
	move.l	a3,bltdpth(a6)
	move.l	a4,bltapth(a6)
	move.w	d7,bltsize(a6)	
	
	add.l	#PLANE_INC,a4
	add.l	#PLANE_INC,a5
	add.l	#PLANE_INC,a3
	
y_buff_block_p2
	btst	#14,dmaconr(a6)
	bne.s	y_buff_block_p2
	move.l	a4,bltapth(a6)
	move.l	a5,bltdpth(a6)
	move.w	d7,bltsize(a6)
	
draw_y_copy2
	btst	#14,dmaconr(a6)
	bne.s	draw_y_copy2
	move.l	a3,bltdpth(a6)
	move.l	a4,bltapth(a6)
	move.w	d7,bltsize(a6)	
	
	add.l	#PLANE_INC,a4
	add.l	#PLANE_INC,a5
	add.l	#PLANE_INC,a3
y_buff_block_p3
	btst	#14,dmaconr(a6)
	bne.s	y_buff_block_p3
	move.l	a4,bltapth(a6)
	move.l	a5,bltdpth(a6)
	move.w	d7,bltsize(a6)

draw_y_copy3
	btst	#14,dmaconr(a6)
	bne.s	draw_y_copy3
	move.l	a3,bltdpth(a6)
	move.l	a4,bltapth(a6)
	move.w	d7,bltsize(a6)	
	
	add.l	#PLANE_INC,a4
	add.l	#PLANE_INC,a5
	add.l	#PLANE_INC,a3
y_buff_block_p4
	btst	#14,dmaconr(a6)
	bne.s	y_buff_block_p4
	move.l	a4,bltapth(a6)
	move.l	a5,bltdpth(a6)
	move.w	d7,bltsize(a6)

draw_y_copy4
	btst	#14,dmaconr(a6)
	bne.s	draw_y_copy4
	move.l	a3,bltdpth(a6)
	move.l	a4,bltapth(a6)
	move.w	d7,bltsize(a6)	
	rts

**********************************************************
***********   DRAW X BLOCKS                    ***********
**********************************************************
draw_x_blocks
*current screen mem position in a0
*current map position in a1
	

		
	
		
**make it draw always on right
	
	add.l	add_x_block_direction,a0
	add.l	add_x_map_direction,a1

draw_x_blocks_straight
	moveq	#0,d0
	moveq	#0,d6
	move.w  current_x_map_position,d0
	move.w	d0,d1
	mulu	#BIGGEST_MAP_X,d0
	asl	d0	;cos map data = word	
	add.l	d0,a1	;get to current line
	asl	#4,d1
	mulu	#BPR,d1   ;way BPR*16 but already done *16
	add.l	d1,a0	;current screen block position

*Check that we are not trying to draw above scroll (remember we are
* subtracting values so blocks are drawn at bottom first)

	move.l	scroll_area,a3	;top of scroll area
	cmp.l	a3,a0
	bge.s	within_plane_still
	add.l	#SCROLL_HEIGHT*BPR,a0
within_plane_still
	add.l	#SCROLL_HEIGHT*BPR,a3
	cmp.l	a3,a0
	blt.s	test2
	sub.l	#SCROLL_HEIGHT*BPR,a0
test2
	move.l	a0,a5		;for buff purposes
	
	move.w	#total_number_of_x_blocks_to_draw,d2	
	moveq	#0,d7	;count number of blocks drawn

init_x_blit_values	
	btst	#14,dmaconr(a6)
	bne.s	init_x_blit_values	


	move.w	#BPR-2,bltdmod(a6)	
	move.w	#0,bltamod(a6)
	move.l	#$ffffffff,bltafwm(a6)
	move.l	#$09F00000,bltcon0(A6)	


	
	move.w	#number_of_x_blocks_per_frame,d0
draw_x_loop
	move.l	level_background_blocks,a2
	moveq	#0,d1
	move.w	(a1),d1
	
	asl.l	#7,d1		;same as mulu (16*2)*4
	add.l	d1,a2		;get to correct position in block data
	
	move.l	a0,a3
	
	move.w	(a2)+,(a3)
	move.w	(a2)+,BPR(a3)
	move.w	(a2)+,BPR*2(a3)
	move.w	(a2)+,BPR*3(a3)
	move.w	(a2)+,BPR*4(a3)
	move.w	(a2)+,BPR*5(a3)
	move.w	(a2)+,BPR*6(a3)
	move.w	(a2)+,BPR*7(a3)
	move.w	(a2)+,BPR*8(a3)
	move.w	(a2)+,BPR*9(a3)
	move.w	(a2)+,BPR*10(a3)
	move.w	(a2)+,BPR*11(a3)
	move.w	(a2)+,BPR*12(a3)
	move.w	(a2)+,BPR*13(a3)
	move.w	(a2)+,BPR*14(a3)
	move.w	(a2)+,BPR*15(a3)

	
	add.l	#PLANE_INC,a3
	
	move.w	(a2)+,(a3)
	move.w	(a2)+,BPR(a3)
	move.w	(a2)+,BPR*2(a3)
	move.w	(a2)+,BPR*3(a3)
	move.w	(a2)+,BPR*4(a3)
	move.w	(a2)+,BPR*5(a3)
	move.w	(a2)+,BPR*6(a3)
	move.w	(a2)+,BPR*7(a3)
	move.w	(a2)+,BPR*8(a3)
	move.w	(a2)+,BPR*9(a3)
	move.w	(a2)+,BPR*10(a3)
	move.w	(a2)+,BPR*11(a3)
	move.w	(a2)+,BPR*12(a3)
	move.w	(a2)+,BPR*13(a3)
	move.w	(a2)+,BPR*14(a3)
	move.w	(a2)+,BPR*15(a3)

	
	add.l	#PLANE_INC,a3

	move.w	(a2)+,(a3)
	move.w	(a2)+,BPR(a3)
	move.w	(a2)+,BPR*2(a3)
	move.w	(a2)+,BPR*3(a3)
	move.w	(a2)+,BPR*4(a3)
	move.w	(a2)+,BPR*5(a3)
	move.w	(a2)+,BPR*6(a3)
	move.w	(a2)+,BPR*7(a3)
	move.w	(a2)+,BPR*8(a3)
	move.w	(a2)+,BPR*9(a3)
	move.w	(a2)+,BPR*10(a3)
	move.w	(a2)+,BPR*11(a3)
	move.w	(a2)+,BPR*12(a3)
	move.w	(a2)+,BPR*13(a3)
	move.w	(a2)+,BPR*14(a3)
	move.w	(a2)+,BPR*15(a3)

	
	add.l	#PLANE_INC,a3

	move.w	(a2)+,(a3)
	move.w	(a2)+,BPR(a3)
	move.w	(a2)+,BPR*2(a3)
	move.w	(a2)+,BPR*3(a3)
	move.w	(a2)+,BPR*4(a3)
	move.w	(a2)+,BPR*5(a3)
	move.w	(a2)+,BPR*6(a3)
	move.w	(a2)+,BPR*7(a3)
	move.w	(a2)+,BPR*8(a3)
	move.w	(a2)+,BPR*9(a3)
	move.w	(a2)+,BPR*10(a3)
	move.w	(a2)+,BPR*11(a3)
	move.w	(a2)+,BPR*12(a3)
	move.w	(a2)+,BPR*13(a3)
	move.w	(a2)+,BPR*14(a3)
	move.w	(a2)+,BPR*15(a3)
	
done_x_block
	add.l	#BPR*16,a0
	
*Cant go off top only bottom so thats the only check

	move.l	scroll_area,a3
	add.l	#SCROLL_HEIGHT*BPR,a3
	cmp.l	a3,a0
	blt.s	have_not_gone_off_scroll_bottom
	move.w	d7,d6		;point where split
	addq.w	#1,d6
	sub.l	#SCROLL_HEIGHT*BPR,a0
have_not_gone_off_scroll_bottom
	add.l	#BIGGEST_MAP_X*MAP_BLOCK_SIZE,a1
	addq.w	#1,current_x_map_position
	addq.w	#1,d7		;count number blocks drawn	
	cmp.w	current_x_map_position,d2
	bne.s	not_yet_done_x_line
	clr	current_x_map_position
	move.w	#WAIT_DRAW_BLOCKS,x_ready_flag	;done our line now wait for screen to scroll 16
	bra.s	done_all_x_blocks
not_yet_done_x_line
	dbra	d0,draw_x_loop	
done_all_x_blocks	


*----------------Now do one big blit to buffer areas---------------
	
*need to know if wrapped - so have to do two blits

	move.l	a5,a4		;a5 stored from above
	move.l	a4,a0
buff_wait_fin
	btst	#14,dmaconr(a6)
	bne.s	buff_wait_fin
	move.w	#BPR-2,bltamod(a6)
	
	move.l	a4,a5
	add.l	#PLANE_INC*4,a4	;buff start position	
	move.l	a4,a3
	add.l	#PLANE_INC*4,a3	;copyback area 

	moveq	#0,d0	
	tst	d6
	beq.s	no_split_occured
	move.w	d7,d0		;number of blocks to draw
	sub.w	d6,d0		;blocks after split
	move.w	d6,d7
no_split_occured	

	move.l	a4,bltdpth(a6)			;screen
	move.l	a5,bltapth(a6)			;graphics
	asl.w	#4,d7				;height of blocks
	asl.w	#6,d7
	addq.w	#1,d7
	move.w	d7,bltsize(a6)	
	
	
draw_x_copy1
	btst	#14,dmaconr(a6)
	bne.s	draw_x_copy1
	move.l	a3,bltdpth(a6)
	move.l	a4,bltapth(a6)
	move.w	d7,bltsize(a6)		
	
	add.l	#PLANE_INC,a4
	add.l	#PLANE_INC,a5
	add.l	#PLANE_INC,a3
	
draw_x_buff2
	btst	#14,dmaconr(a6)
	bne.s	draw_x_buff2
	move.l	a4,bltdpth(a6)
	move.l	a5,bltapth(a6)		
	move.w	d7,bltsize(a6)	

draw_x_copy2
	btst	#14,dmaconr(a6)
	bne.s	draw_x_copy2
	move.l	a3,bltdpth(a6)
	move.l	a4,bltapth(a6)
	move.w	d7,bltsize(a6)	
	
	add.l	#PLANE_INC,a4
	add.l	#PLANE_INC,a5
	add.l	#PLANE_INC,a3
	
draw_x_buff3
	btst	#14,dmaconr(a6)
	bne.s	draw_x_buff3
	move.l	a4,bltdpth(a6)
	move.l	a5,bltapth(a6)		
	move.w	d7,bltsize(a6)	
	
draw_x_copy3
	btst	#14,dmaconr(a6)
	bne.s	draw_x_copy3
	move.l	a3,bltdpth(a6)
	move.l	a4,bltapth(a6)
	move.w	d7,bltsize(a6)	

	add.l	#PLANE_INC,a4
	add.l	#PLANE_INC,a5
	add.l	#PLANE_INC,a3
	
draw_x_buff4
	btst	#14,dmaconr(a6)
	bne.s	draw_x_buff4
	move.l	a4,bltdpth(a6)
	move.l	a5,bltapth(a6)		
	move.w	d7,bltsize(a6)	

draw_x_copy4
	btst	#14,dmaconr(a6)
	bne.s	draw_x_copy4
	move.l	a3,bltdpth(a6)
	move.l	a4,bltapth(a6)
	move.w	d7,bltsize(a6)	
	
	tst	d0
	beq	no_need_to_draw_more_blocks

	
	move.l	a0,a5
	asl.w	#4,d6
	mulu	#BPR,d6
	add.l	d6,a5
	sub.l	#SCROLL_HEIGHT*BPR,a5
	move.l	a5,a4
	add.l	#PLANE_INC*4,a4
	move.l	a4,a3
	add.l	#PLANE_INC*4,a3
	move.w	d0,d7		;blocks after split
draw_x_buff1_split
	btst	#14,dmaconr(a6)
	bne.s	draw_x_buff1_split
	move.l	a4,bltdpth(a6)			;screen
	move.l	a5,bltapth(a6)			;graphics
	asl.w	#4,d7				;height of blocks
	asl.w	#6,d7
	addq.w	#1,d7
	move.w	d7,bltsize(a6)	
	
draw_x_copy1_split
	btst	#14,dmaconr(a6)
	bne.s	draw_x_copy1_split
	move.l	a3,bltdpth(a6)
	move.l	a4,bltapth(a6)
	move.w	d7,bltsize(a6)	
	
	add.l	#PLANE_INC,a4
	add.l	#PLANE_INC,a5
	add.l	#PLANE_INC,a3
	
draw_x_buff2_split
	btst	#14,dmaconr(a6)
	bne.s	draw_x_buff2_split
	move.l	a4,bltdpth(a6)
	move.l	a5,bltapth(a6)		
	move.w	d7,bltsize(a6)	

draw_x_copy2_split
	btst	#14,dmaconr(a6)
	bne.s	draw_x_copy2_split
	move.l	a3,bltdpth(a6)
	move.l	a4,bltapth(a6)
	move.w	d7,bltsize(a6)	

	add.l	#PLANE_INC,a4
	add.l	#PLANE_INC,a5
	add.l	#PLANE_INC,a3
	
draw_x_buff3_split
	btst	#14,dmaconr(a6)
	bne.s	draw_x_buff3_split
	move.l	a4,bltdpth(a6)
	move.l	a5,bltapth(a6)		
	move.w	d7,bltsize(a6)	
	
draw_x_copy3_split
	btst	#14,dmaconr(a6)
	bne.s	draw_x_copy3_split
	move.l	a3,bltdpth(a6)
	move.l	a4,bltapth(a6)
	move.w	d7,bltsize(a6)	

	add.l	#PLANE_INC,a4
	add.l	#PLANE_INC,a5
	add.l	#PLANE_INC,a3
	
draw_x_buff4_split
	btst	#14,dmaconr(a6)
	bne.s	draw_x_buff4_split
	move.l	a4,bltdpth(a6)
	move.l	a5,bltapth(a6)		
	move.w	d7,bltsize(a6)	

draw_x_copy4_split
	btst	#14,dmaconr(a6)
	bne.s	draw_x_copy4_split
	move.l	a3,bltdpth(a6)
	move.l	a4,bltapth(a6)
	move.w	d7,bltsize(a6)	
	
no_need_to_draw_more_blocks	
	rts


********************************************************
****  ADD X ALIENS                                  ****
********************************************************
Add_X_Aliens
*send alien map pointer in a0		


	add.l	add_x_map_alien_direction,a0

add_alien_x_blocks_straight

	moveq	#0,d2
	move.l	current_add_alien_ptr,a1
	move.l	current_alien_list_ptr,a4
	move.l	#Species_Table,a3


*---Set up start x and y values

		
	move.w	alien_x_pos2,d0
	move.w	alien_y_pos2,d1
	sub.w	#16*3,d1
	sub.l	#BIGGEST_MAP_X,a0
	add.w	alien_scroll_add_x_offset,d0
*----

	move.w  alien_block_x_pos,d2
	move.w	d2,d7	;use as counter
	move.w	d2,d6
	mulu	#BIGGEST_MAP_X,d2
	add.l	d2,a0	;get to current line in alien map
	asl	#4,d6
	add.w	d6,d1	;current y position on screen


	move.w	#number_of_x_alien_blocks_per_frame,d6
add_alien_x_loop	
	clr.w	d2
	move.b	(a0),d2
	beq.s	alien_x_already_in_map
	btst	#ALIEN_BUSY,d2
	bne.s	alien_x_already_in_map
	bset.b	#ALIEN_BUSY,(a0)
	
	cmp.l	#$ffffffff,(a1)
	beq.s	add_alien_list_full
	move.l	(a1)+,a2
	move.w	d0,alien_x(a2)
	move.w	d1,alien_y(a2)
	move.l	a0,alien_map_pos(a2)
	clr.w	alien_data(a2)
	clr.b	alien_work(a2)		;do we need this?
	clr.l	alien_frame(a2)		;clears and flags & cpad as well

	asl	#2,d2
	move.l	(a3,d2.w),alien_type_ptr(a2)
	move.l	alien_type_ptr(a2),a5
	move.l	alien_pattern_ptr(a5),alien_pat_ptr(a2)
	move.w	alien_frame_rate(a5),alien_frame_counter(a2)
	move.w	alien_hit_count(a5),alien_hits(a2)
	move.l	a2,(a4)+
alien_x_already_in_map	

	add.w	#16,d1
	addq.w	#1,d7
	add.l	#BIGGEST_MAP_X,a0
	
	cmp.w	#total_number_of_alien_x_blocks_to_add,d7
	beq.s	have_reached_alien_x_limit
	dbra	d6,add_alien_x_loop
	move.w	d7,alien_block_x_pos
	bra.s	add_alien_list_full
have_reached_alien_x_limit
	clr.w	alien_block_x_pos
		
add_alien_list_full	
	move.l	#$ffffffff,(a4)
	move.l	a4,current_alien_list_ptr
	move.l	a1,current_add_alien_ptr

	rts


********************************************************
****  ADD Y ALIENS                                  ****
********************************************************
Add_Y_Aliens
*send alien map pointer in a0		

	add.l	add_y_map_alien_direction,a0
add_alien_y_blocks_straight

	moveq	#0,d2
	move.l	current_add_alien_ptr,a1
	move.l	current_alien_list_ptr,a4
	move.l	#Species_Table,a3


*---Set up start x and y values
	move.w	alien_x_pos,d0
	sub.w	#3*16,d0
	move.w	alien_y_pos,d1
	add.w	alien_scroll_add_y_offset,d1	
	subq.l	#1,a0	;back one block		
*----

	move.w  alien_block_y_pos,d2
	move.w	d2,d7	;use as counter
	add.l	d2,a0	;get to current line in alien map
	asl	#4,d2
	add.w	d2,d0	;current x position on screen


	move.w	#number_of_y_alien_blocks_per_frame,d3
add_alien_y_loop	
	clr.w	d2
	move.b	(a0),d2
	beq.s	alien_y_already_in_map
	btst	#ALIEN_BUSY,d2
	bne.s	alien_y_already_in_map
	bset.b	#ALIEN_BUSY,(a0)
	

	cmp.l	#$ffffffff,(a1)
	beq.s	add_yalien_list_full
	move.l	(a1)+,a2
	move.w	d0,alien_x(a2)
	move.w	d1,alien_y(a2)
	move.l	a0,alien_map_pos(a2)
	clr.w	alien_data(a2)
	clr.b	alien_work(a2)		;do we need this?
	clr.l	alien_frame(a2)		;clears and flags & cpad as well

	asl	#2,d2
	move.l	(a3,d2.w),alien_type_ptr(a2)
	move.l	alien_type_ptr(a2),a5
	move.l	alien_pattern_ptr(a5),alien_pat_ptr(a2)
	move.w	alien_frame_rate(a5),alien_frame_counter(a2)
	move.w	alien_hit_count(a5),alien_hits(a2)
	move.l	a2,(a4)+
alien_y_already_in_map	
	
	addq.l	#1,a0
	add.w	#16,d0
	addq.w	#1,d7
	
	cmp.w	#total_number_of_alien_y_blocks_to_add,d7
	beq.s	have_reached_alien_y_limit
	dbra	d3,add_alien_y_loop
	move.w	d7,alien_block_y_pos
	bra.s	add_yalien_list_full
have_reached_alien_y_limit
	clr.w	alien_block_y_pos
		
add_yalien_list_full	
	move.l	#$ffffffff,(a4)
	move.l	a4,current_alien_list_ptr
	move.l	a1,current_add_alien_ptr


	rts


alien_block_y_pos	dc.w	0
alien_block_x_pos	dc.w	0


*The following routine is code from HELL, it was done quickly  to
*get a result, and as it is not speed critical I have not bothered 
*to re-write it. Ha ha ha.
	
********************************************************
****  FILL SCREEN WITH BLOCKS                       ****
********************************************************
fill_screen_with_blocks
*send in d0 and d1 as the x and y

*--
	move.w	d0,scroll_x_position
	move.w	d1,scroll_y_position
	move.w	d0,last_scroll_x
	move.w	d1,last_scroll_y
	bsr	Position_Scroll
	
*--

*--    SET UP ALIEN ADD POSITIONS

	clr.w	scroll_add_y_offset
	clr.w	scroll_add_x_offset
	clr.w	alien_scroll_add_y_offset
	clr.w	alien_scroll_add_x_offset

	sub.w	#32,fixed_y	;position on screen properly
	add.w	#32,fixed_x	;position on screen properly
	move.w	fixed_x,alien_x_pos
	move.w	fixed_y,alien_y_pos
	move.w	fixed_x,alien_x_pos2
	move.w	fixed_y,alien_y_pos2


	
	move.l	current_alien_draw_position,a0
	move.l	current_map_mem_position,a1
	move.l	current_alien_map_mem_position,a4  
	sub.l	#PLANE_INC*4,a0		;cos buff
	
*--Position back two lines to fill gap above
		
	tst	scroll_y_position
	beq.s	dont_do_extra2		
	sub.l	#(BPR*16)*2,a0
	cmp.l	plane1,a0
	bge.s	not_wrapped_off
	add.l	#SCROLL_HEIGHT*BPR,a0
not_wrapped_off	
	sub.l	#(2*BIGGEST_MAP_X)*MAP_BLOCK_SIZE,a1
	sub.l	#2*BIGGEST_MAP_X,a4
dont_do_extra2	
*---------	
	
	move.w	#20-1,d0
do_all_blocks	
	move.w	#START_DRAW_BLOCKS,y_ready_flag
keep_drawing
	movem.l	a0-a5/d0-d7,-(sp)
	move.l	a4,alien_mp
	bsr	draw_blocks_main
	move.l	alien_mp,a0
	bsr	add_alien_y_blocks_straight
	movem.l	(sp)+,a0-a5/d0-d7
	tst	y_ready_flag
	bne.s	keep_drawing
	
	add.w	#16,alien_y_pos
	add.l	#16*BPR,a0
	move.l	plane1,a2
	add.l	#SCROLL_HEIGHT*BPR,a2
	cmp.l	a2,a0
	blt.s	not_in_area_yet
	sub.l	#SCROLL_HEIGHT*BPR,a0	
not_in_area_yet	
	add.l	#(BIGGEST_MAP_X*MAP_BLOCK_SIZE),a1
	add.l	#BIGGEST_MAP_X,a4
	dbra	d0,do_all_blocks
	move.w	#WAIT_DRAW_BLOCKS,y_ready_flag
	
*-- FILL IN TWO COLS OF X BLOCKS	
	
	move.w	#START_DRAW_BLOCKS,x_ready_flag
wait_until_done	
	move.l	current_alien_draw_position,a0
	sub.l	#PLANE_INC*4,a0		;cos buff
	move.l	current_map_mem_position,a1
	
*--	
	sub.l	#33*BPR,a0
	sub.l	#(2*BIGGEST_MAP_X)*MAP_BLOCK_SIZE,a1
*--
	
	move.l	current_alien_map_mem_position,a4
	
	add.l	#46,a0
	sub.l	#2*MAP_BLOCK_SIZE,a1
	move.l	a4,alien_mp
	bsr	draw_x_blocks_straight
	move.l	alien_mp,a0
	bsr	add_alien_x_blocks_straight
	cmp.w	#WAIT_DRAW_BLOCKS,x_ready_flag
	bne.s	wait_until_done

	move.w	#START_DRAW_BLOCKS,x_ready_flag	
wait_until_done2
	move.l	current_alien_draw_position,a0
	sub.l	#PLANE_INC*4,a0		;cos buff
	move.l	current_map_mem_position,a1
	move.l	current_alien_map_mem_position,a4

*--	
	sub.l	#33*BPR,a0
	sub.l	#(2*BIGGEST_MAP_X)*MAP_BLOCK_SIZE,a1
*--

	add.l	#48,a0
	sub.l	#1*MAP_BLOCK_SIZE,a1
	move.l	a4,alien_mp
	bsr	draw_x_blocks_straight
	move.l	alien_mp,a0
	bsr	add_alien_x_blocks_straight
	cmp.w	#WAIT_DRAW_BLOCKS,x_ready_flag
	bne.s	wait_until_done2

	move.w	#WAIT_DRAW_BLOCKS,x_ready_flag

	rts

alien_mp	dc.l	0
********************************************************
****  SET UP SCROLL POSITION                        ****
********************************************************
set_up_scroll_position
	clr.w	current_x_map_position	;position of drawn blocks
	clr.w	current_y_map_position
	clr.w	check_x_add
	clr.w	check_y_add

	move.l	#Generic_Map_Header,a0		
	move.w	map_data_x(a0),d0
	move.w	d0,map_x_size
	move.w	map_datasize(a0),d1
	asl	d1,d0
	mulu	map_data_y(a0),d0	;=size of map
	move.w	map_data_y(a0),map_y_size
		
	move.w	map_x_size,d0
	move.w	map_y_size,d1
	sub.w	#20,d0	;sub screen widths
	sub.w	#15,d1
	
	asl	#4,d0
	asl	#4,d1
	subq.w	#1,d0
	
	move.w	d0,map_x_size
	move.w	d1,map_y_size

	rts



current_map_pointer		dc.l	0
current_alien_map_pointer	dc.l	0

	rsreset


wait_pos  rs.w	1
wait_mask rs.w	1
plane_1_hi_ptr	rs.w	1
plane_1_hi_val	rs.w	1
plane_1_lo_ptr	rs.w	1
plane_1_lo_val	rs.w	1

plane_2_hi_ptr	rs.w	1
plane_2_hi_val	rs.w	1
plane_2_lo_ptr	rs.w	1
plane_2_lo_val	rs.w	1

plane_3_hi_ptr	rs.w	1
plane_3_hi_val	rs.w	1
plane_3_lo_ptr	rs.w	1
plane_3_lo_val	rs.w	1

plane_4_hi_ptr	rs.w	1
plane_4_hi_val	rs.w	1
plane_4_lo_ptr	rs.w	1
plane_4_lo_val	rs.w	1



	rsreset
map_file_header	rs.l	1
map_blk_size	rs.w	1	
map_data_x	rs.w	1
map_data_y	rs.w	1
Map_Planes     rs.w 1		;also map filesize in compressed form
Map_DataSize   rs.w 1
Map_data       rs.l 1



