#####################################################################
#
# CSCB58 Winter 2023 Assembly Final Project
# University of Toronto, Scarborough
#
# Bitmap Display Configuration:
# - Unit width in pixels: 8
# - Unit height in pixels: 8
# - Display width in pixels: 512
# - Display height in pixels: 256
# - Base Address for Display: 0x10008000 ($gp)
#
# Features that have been implemented:
# 1. Added a score to keep track of how much a player collected
# 2. Fail condition (player loses when hit by a pig (enemy))
# 3. Win Condition (PLayer wins when collected all coins in that level)
# 4. Moving objects (pic, platforms)
# 5. Different levels (explained in video)
# 6. Collect coins
# 7. Start menu
# 8. Double jump

#####################################################################
# Constants and Variables
#####################################################################
.eqv BASE_ADDRESS 0x10008000
.eqv COUNTER $s2
.eqv PLATFORM_UPDATE_RATE 5
.eqv PLATFORM_DATA_SIZE 12
.eqv ENEMY_DATA_SIZE 8

# Colour constants
.eqv GREEN 0x005EC452
.eqv BLUE 0x000000ff
.eqv PLATFORM_COLOUR 0x0071534C
.eqv RED 0x00ff0000
.eqv SKY 0x00cfecf0
.eqv COIN_COLOUR 0x00FFC500
.eqv BLACK 0x0000000
.eqv WHITE 0x00FFFFFF

# Play position
.eqv PLAYER_POS	$s7
.eqv PLAYER_LEFT_OFFSET $s6
.eqv PLAYER_VERTICAL_MOVEMENT $s5
.eqv PLATFORM_POS $s4
.eqv SCREEN_DELAY $s3
.eqv GAME_LOOP_DELAY 20
.eqv JUMP_INITIAL_AMOUNT 1024 # 256*3
.eqv NUMBER_OF_JUMPS $s1
.eqv SCORE $s0

# Variables
.data
# Maximum four platforms, need space for start of array:
# | SIZE | SPACER | SPACER | ... | X | Y | LEN |
platform_array: .space 60 # 4*((4+1)*3) --> (4 (Reserve space for first element) + 4 (#platforms + 1 (<-- for the first element + 8 bytes of spacer)
enemy_array: .space 96 # 4*((5+1)*2)
coin_array: .space 24
left_menu: .word 0
right_menu: .word 0
LEVEL: .word 0

.text

main:
	j MAIN_MENU_PAGE # Jump to Main Menu Page

#####################################################################
# MAIN GAME PAGE (Where the game happens)
#####################################################################
MAIN_GAME_PAGE:
    # LEVEL 1 of the game is to collect all the coins (Does not have enemies yet)
	LEVEL_1:
		li $t2, SKY # load light blue color (sky)
		li PLATFORM_POS, BASE_ADDRESS # Set platform position to be the base address
		li SCORE, 0 # Set score to zero to start
		li SCREEN_DELAY, 100
		la $t9, coin_array # load coin array
		li $t8, 20 # (5*4) to have 5 coins on screen at a time
		
		# Set the level
		la $t5, LEVEL # Load address of variable 'LEVEL'
		li $t6, 1 # Set $t6 to be 1
		sw $t6, 0($t5) # Set LEVEL variable to 1, since it is level 1
		
		sw $t8, 0($t9) # Store $t8 in the first address of $t9
		add $t8, $t8, $t9
		LEVEL_1_COINS_LOOP:
			move $a0, $t8
			jal LOAD_COINS
			sw $t0, 0($t8)
			subi $t8, $t8, 4
			bne $t8, $t9, LEVEL_1_COINS_LOOP
		
		la $t9, enemy_array # set $t9 to be the address of the first element in enemy_array
		li $t8, 0 # To get no enemies
		sw $t8, 0($t9)
		add $t8, $t8, $t9
		
		la $t9, platform_array # load platform array
		li $t8, 48 #(60 - 12) 
		sw $t8, 0($t9) # Store
		add $t8, $t8, $t9
		
		# Generate the first set of platforms
		# Every platform loaded, the offset from the previous platform is 20 pixels
		li $t0, 256	# Store current offset from the last platform
		LEVEL_1_PLATFORM_LOOP:
			addi $sp, $sp, -4
			sw $t0, 0($sp)		# Push offset to stack
			move $a0, $t8 
			jal LOAD_PLATFORM # Jump to LOAD_PLATFORM Branch

			move $a0, $t8 # First element of array (x)
			jal RANDOM_PLATFORM_DELAY # Call to delay platforms randomly
			
			lw $t0, 0($sp)		# Pop offset from stack
			addi $sp, $sp, 4

			lw $t1, 0($t8)		# Get the x-position of the current platform
			lw $t2, 8($t8)		# Get the platforms length
			subi $t1, $t1, 256	# Remove the 256-offset as we will apply our own offset
			add $t1, $t1, $t0	# Apply offset to platform
			add $t0, $t1, $t2 	# Move offset to platforms x-position + length, aka right edge
			addi $t0, $t0, 20	# Add a spacer of 5 cells
			sw $t1, 0($t8)		# Save new offset
			subi $t8, $t8, PLATFORM_DATA_SIZE 
			bne $t8, $t9, LEVEL_1_PLATFORM_LOOP # Keep looping until $t8 reaches first address of $t9 (meaning no more platforms)
			
		li PLAYER_POS, BASE_ADDRESS # Set player position to be the base address
		addi PLAYER_POS, PLAYER_POS, 6432 # Set the player position
		li PLAYER_LEFT_OFFSET, 32 # Get player's offset
		li COUNTER, PLATFORM_UPDATE_RATE # Set a counter to slow down paltform speed
		j GAME_LOOP
	
	# Level 2 of the game is to collect all the coins without getting hit by the enemy (1 enemy on screen at a time)
    LEVEL_2:
		li $t2, SKY # load light blue color (sky)
		li PLATFORM_POS, BASE_ADDRESS # Set platform position to be the base address
		li SCORE, 0 # Set score to zero to start
		li SCREEN_DELAY, 100
		la $t9, coin_array # load coin array
		li $t8, 20 
		
		# Set the level
		la $t5, LEVEL
		li $t6, 2 
		sw $t6, 0($t5) # Set LEVEL variable to be 2, since we are on level 2
		
		sw $t8, 0($t9) # Store first address of coin array into $t8
		add $t8, $t8, $t9
		LEVEL_2_COINS_LOOP:
			move $a0, $t8
			jal LOAD_COINS
			sw $t0, 0($t8)
			subi $t8, $t8, 4
			bne $t8, $t9, LEVEL_2_COINS_LOOP
		
		la $t9, enemy_array # Store address of enemy array into $t9
		li $t8, 8
		sw $t8, 0($t9)
		add $t8, $t8, $t9
		LEVEL_2_ENEMY_LOOP:
			# lw $t8, 0($t8)
			move $a0, $t8
			jal LOAD_ENEMY # Call this to randomly generate enemies
			subi $t8, $t8, ENEMY_DATA_SIZE
			bne $t8, $t9, LEVEL_2_ENEMY_LOOP # Keep looping until we have no more enemies
		
		la $t9, platform_array # load platform array
		li $t8, 48 #(60 - 12) 
		sw $t8, 0($t9)
		add $t8, $t8, $t9
		
		# Generate the first set of platforms
		# Every platform loaded, the offset from the previous platform is 20 pixels
		li $t0, 256	# Store current offset from the last platform
		LEVEL_2_PLATFORM_LOOP:
			addi $sp, $sp, -4
			sw $t0, 0($sp)		# Push offset to stack
			move $a0, $t8 
			jal LOAD_PLATFORM # Jump to LOAD_PLATFORM Branch

			move $a0, $t8 # First element of array (x)
			jal RANDOM_PLATFORM_DELAY
			#move $t0, $v0
			#lw $v0, 0($t8)
			
			lw $t0, 0($sp)		# Pop offset from stack
			addi $sp, $sp, 4

			lw $t1, 0($t8)		# Get the x-position of the current platform
			lw $t2, 8($t8)		# Get the platforms length
			subi $t1, $t1, 256	# Remove the 256-offset as we will apply our own offset
			add $t1, $t1, $t0	# Apply offset to platform
			add $t0, $t1, $t2 	# Move offset to platforms x-position + length, aka right edge
			addi $t0, $t0, 20	# Add a spacer of 5 cells
			sw $t1, 0($t8)		# Save new offset
			subi $t8, $t8, PLATFORM_DATA_SIZE
			bne $t8, $t9, LEVEL_2_PLATFORM_LOOP
			
		li PLAYER_POS, BASE_ADDRESS # Set player position to be the base address
		addi PLAYER_POS, PLAYER_POS, 6432 # Set the player position
		li PLAYER_LEFT_OFFSET, 32 # Set player's offset
		li COUNTER, PLATFORM_UPDATE_RATE # Set counter to slow down platform speed
		j GAME_LOOP
	
    # Level 3 of the game is to collect all the coins without getting hit by the enemies (1, 2, or 3 enemies on screen at a time - randomly generated)
	LEVEL_3:
		li $t2, 0x00659FF2 # load light blue color (sky)
		li PLATFORM_POS, BASE_ADDRESS # Set platform position to be the base address
		li SCORE, 0 # Set score to zero to start
		li SCREEN_DELAY, 100 # 40ms pass before it returns automatically to main game again
		la $t9, coin_array # load coin array
		
		la $t5, LEVEL
		li $t6, 3
		sw $t6, 0($t5) # Set the LEVEL variable to 3, since we are on level 3

		li $t8, 20 
		sw $t8, 0($t9) # Store the coins
		add $t8, $t8, $t9
		LEVEL_3_COINS_LOOP:
			move $a0, $t8
			jal LOAD_COINS
			sw $t0, 0($t8)
			subi $t8, $t8, 4
			bne $t8, $t9, LEVEL_3_COINS_LOOP
		
		la $t9, enemy_array # Get address of enemy array
		li $t8, 24
		sw $t8, 0($t9)
		add $t8, $t8, $t9
		LEVEL_3_ENEMY_LOOP:
			# lw $t8, 0($t8)
			move $a0, $t8
			jal LOAD_ENEMY # Call this to randomly generate the enemies
			subi $t8, $t8, ENEMY_DATA_SIZE
			bne $t8, $t9, LEVEL_3_ENEMY_LOOP # Keep looping until no more enemies in array
		
		la $t9, platform_array # load platform array
		li $t8, 48 #(60 - 12) 
		sw $t8, 0($t9) # Store
		add $t8, $t8, $t9
	
		# Generate the first set of platforms
		# Every platform loaded, the offset from the previous platform is 20 pixels
		li $t0, 256	# Store current offset from the last platform
		LEVEL_3_PLATFORM_LOOP:
			addi $sp, $sp, -4
			sw $t0, 0($sp)		# Push offset to stack
			move $a0, $t8 
			jal LOAD_PLATFORM # Jump to LOAD_PLATFORM Branch

			move $a0, $t8 # First element of array (x)
			jal RANDOM_PLATFORM_DELAY
			#move $t0, $v0
			#lw $v0, 0($t8)
			
			lw $t0, 0($sp)		# Pop offset from stack
			addi $sp, $sp, 4

			lw $t1, 0($t8)		# Get the x-position of the current platform
			lw $t2, 8($t8)		# Get the platforms length
			subi $t1, $t1, 256	# Remove the 256-offset as we will apply our own offset
			add $t1, $t1, $t0	# Apply offset to platform
			add $t0, $t1, $t2 	# Move offset to platforms x-position + length, aka right edge
			addi $t0, $t0, 20	# Add a spacer of 5 cells
			sw $t1, 0($t8)		# Save new offset
			subi $t8, $t8, PLATFORM_DATA_SIZE
			bne $t8, $t9, LEVEL_3_PLATFORM_LOOP
			
		li PLAYER_POS, BASE_ADDRESS # Set player position to be the base address
		addi PLAYER_POS, PLAYER_POS, 6432 # Set the player position
		li PLAYER_LEFT_OFFSET, 32 # Set player's offset
		li COUNTER, PLATFORM_UPDATE_RATE # Set counter to slow down platform speed
		j GAME_LOOP

#####################################################################
# GAME LOOP
#####################################################################
GAME_LOOP:
	# Keyboard
	li $a0, 0xffff0000
	lw $t8, 0($a0)
	bne $t8, 1, UPDATE # keypress # Check if new key was entered.
	jal KEYPRESS
	UPDATE:
	addi COUNTER, COUNTER, -1
	jal HANDLE_JUMP # Allow player to jump
	DRAW:
	jal BACKGROUND # Draw the background
	# Display Score
	li $a0, BASE_ADDRESS
	addi $a0, $a0, 360
	move $a2, SCORE
	li $a1, BLACK
	jal BEGIN_DRAW_NUMBERS # Draw the numbers and update it as the palyer collects the coins
	
	li $a0, BASE_ADDRESS # Set $a0 to be the base address
	# This portion both draws and updates at the same time. Design choice
	la $t9, platform_array # load platform array
	lw $t8, 0($t9)
	add $t8, $t8, $t9

    # Draw and update the platforms on the screen
	GAME_PLATFORM_LOOP:
		lw $a0, 0($t8)	# The x-value of platform
		lw $a1, 8($t8)	# The length of platform
		
		# If this platforms x-value is equal to its negative platform length, we can load a new one b/c out of screen
		# e.g. Platform on screen, x value > 0. Out of screen, x value < 0
		sub $a1, $zero, $a1	# Get negative platform length
		bne $a1, $a0, DONT_GENERATE_PLATFORM
		move $a0, $t8
		jal LOAD_PLATFORM

	DONT_GENERATE_PLATFORM:
		lw $a0, 0($t8)
		lw $a1, 4($t8)
		lw $a2, 8($t8)
		jal DRAW_PLATFORM
		
		subi $t8, $t8, PLATFORM_DATA_SIZE
		bne $t8, $t9, GAME_PLATFORM_LOOP
	
	jal DRAW_COINS # Draw the coins onto the screen
	
	la $t9, enemy_array # Get address of enemy array
	lw $t8, 0($t9) # Access length of enemy array (1st element in the array)
	beqz $t8, DRAW_PLAYER
	add $t8, $t8, $t9 # $t8 is the address of x at the last enemy in the array

	GAME_ENEMY_UPDATE_LOOP:	# Loop through array and recreate enemies that are outside of the screen
		lw $a0, 0($t8)	# The x-value of enemy
		li $a1, -20	# The length of enemy. To check if enemy is off screen

		blt $a1, $a0, ENEMY_IN_FRAME # The enemy is still on screen
		
        ENEMY_OUT_OF_FRAME:
			move $a0, $t8	# The enemy is outside of the screen. Uh oh
			jal LOAD_ENEMY

		ENEMY_IN_FRAME:
			subi $t8, $t8, ENEMY_DATA_SIZE
			bne $t8, $t9, GAME_ENEMY_UPDATE_LOOP	# Iterate if we still have enemies to loop
		
	la $t9, enemy_array
	lw $t8, 0($t9) # Access length of enemy array (1st element in the array)
	add $t8, $t8, $t9 # $t8 is the address of x at the last enemy in the array

	MAIN_DRAW_ENEMY:
		move $a0, $t8 
		jal DRAW_ENEMY # Draw enemy
		subi $t8, $t8, 8 # Subtract 8 until we get to the first element of enemy array
		bne $t8, $t9, MAIN_DRAW_ENEMY

	DRAW_PLAYER:
        jal PLAYER # Draw player

        la $t9, coin_array # Load address of coin array
        lw $t8, 0($t9) # Access length of coin array (1st element in the array)
        add $t8, $t8, $t9 # $t8 is the address of x at the last coin in the array
	
	GAME_COIN_LOOP:
		move $a0, $t8 
		lw $t0, 0($t8)
		lw $t1, 0($t0) # Load colour of coin
		lw $t2, 256($t0) # Load colour of coin
		beq $t1, RED, PLAYER_ON_COIN # Check if player is on the coin (match based on colours)
		beq $t2, RED, PLAYER_ON_COIN
		subi $t8, $t8, 4
		bne $t8, $t9, GAME_COIN_LOOP

	j COIN_NOT_COLLECTED
	PLAYER_ON_COIN:
		move $a0, $t8
		jal COLLECT_COIN # Collect coin when the player is on the coin

	COIN_NOT_COLLECTED:
	bltzal COUNTER, PLATFORM_MOVE_LEFT
	jal ENEMY_MOVE_LEFT
	li $v0, 32	# Delay for FPS/
	li $a0, GAME_LOOP_DELAY	# Game does not need to render
	syscall		# more than X times per second.
	j GAME_LOOP

#####################################################################
# Collisions, Jumps (Features of the game)
#####################################################################
HIT_PLAYER:
	move $t0, PLAYER_POS # Set $t0 to be the palyer's position
	li $t2, 0x00FF7400 # $t2 stores the hit colour code (when player gets hit by enemy
	sw $t2, 0($t0) # paint the player orange
	sw $t2, 260($t0)
	sw $t2, 268($t0)
	sw $t2, 516($t0)
	sw $t2, 772($t0)
	sw $t2, 776($t0)
	sw $t2, 264($t0)
	sw $t2, 524($t0)
	
	li $t2, 0x00FFA200 # $t2 stores the orange colour code
	sw $t2, 780($t0)
	
	li $t2, BLACK # $t2 stores the black colour code
	sw $t2, 520($t0)
	sw $t2, 768($t0)
	
	li $v0, 32	# Delay for FPS/
	li $a0, 2000	# Game does not need to render
	syscall	
	
	jal CLEAR # Clear screen
	# Push return address to stack.
	li $t4, BASE_ADDRESS
	li $t1, 0
	li $t2, 0x00CE7373 # Background colour
	GAME_OVER_BACKGROUND_LOOP:
	sw $t2, 0($t4)
	addi $t4, $t4, 4 # advance to next pixel position in display
	addi $t1, $t1, -1 # decrement number of pixels
	bne $t1, -2176, GAME_OVER_BACKGROUND_LOOP # repeat while number of pixels is not -1920
	
	li $a0, BASE_ADDRESS
	j GAME_OVER_PAGE # Go to game over page when player gets hit by the enemy

# Handles the jump of the player
HANDLE_JUMP:
    # Check for collisions
	COLLISION_CHECK:
	lw $t2, 780(PLAYER_POS) # Get bottom right corner of player
	lw $t3, 768(PLAYER_POS) # Get bottom left corner of player
	lw $t4, 268(PLAYER_POS) # Get top right edge of player
	lw $t5, 4(PLAYER_POS) # Get top left edge of player
	
	# ENEMY Collision (Check based on colour)
	beq $t2, 0x00A3F885, ENEMY_HIT # If player hits the enemy
	beq $t3, 0x00A3F885, ENEMY_HIT # If player hits the enemy
	beq $t2, 0x0042FF00, ENEMY_HIT # If player hits the enemy
	beq $t3, 0x0042FF00, ENEMY_HIT # If player hits the enemy
	beq $t5, 0x0042FF00, ENEMY_HIT # If top part hits player hits the enemy
	
	beq $t4, 0x00A3F885, ENEMY_HIT # If player hits the enemy
	beq $t4, 0x0042FF00, ENEMY_HIT # If player hits the enemy
	beq $t4, WHITE, ENEMY_HIT # If player hits the enemy
	lw $t4, 12(PLAYER_POS) # Get top right edge of player
	beq $t4, 0x00A3F885, ENEMY_HIT # If player hits the enemy
	beq $t4, 0x0042FF00, ENEMY_HIT # If player hits the enemy
	beq $t4, WHITE, ENEMY_HIT # If player hits the enemy
	lw $t4, 524(PLAYER_POS) # Get middle right edge of player
	beq $t4, 0x00A3F885, ENEMY_HIT # If player hits the enemy
	beq $t4, 0x0042FF00, ENEMY_HIT # If player hits the enemy
	beq $t4, WHITE, ENEMY_HIT # If player hits the enemy

	# Start of applying vertical movement
	beqz PLAYER_VERTICAL_MOVEMENT, GRAVITY	# If player has reached peak of their jump, start falling
	add PLAYER_POS, PLAYER_POS, PLAYER_VERTICAL_MOVEMENT # Otherwise, lift them up
	
	# Want to check AFTER we move player
	lw $t2, 780(PLAYER_POS) # Get bottom right corner of player
	lw $t3, 768(PLAYER_POS) # Get bottom left corner of player
    # Check collisions of the grass (ground) and the platforms
	beq $t2, GREEN, COLLISION_DETECTED
	beq $t2, PLATFORM_COLOUR, PLATFORM_COLLISION_DETECTED
	beq $t3, GREEN, COLLISION_DETECTED
	beq $t3, PLATFORM_COLOUR, PLATFORM_COLLISION_DETECTED	
	
	li $t3, BASE_ADDRESS 
	blt $t3, PLAYER_POS, ABOVE_Y # Check for if player is above the screen

	li PLAYER_POS, BASE_ADDRESS	# Put player at base address
	add PLAYER_POS, PLAYER_POS, PLAYER_LEFT_OFFSET	# Restore their x-position
	
	ABOVE_Y:
		bltz PLAYER_VERTICAL_MOVEMENT, DECREASE_JUMP_AMOUNT # Set player to fall down when at the top edge of the screen (stop them from going out of screen)
		jr $ra
	
    # Set gravity of player
	GRAVITY:
		li PLAYER_VERTICAL_MOVEMENT, 256 # Fixed Fall.
		jr $ra
	
	# When player is on the platform, keep moving the player left with the platform
    PLATFORM_COLLISION_DETECTED:
		addi $sp, $sp, -4
		sw $ra, 0($sp)
		bltzal COUNTER, A_KEY
		lw $ra, 0($sp)
		addi $sp, $sp, 4
	
	COLLISION_DETECTED:
		sub PLAYER_POS, PLAYER_POS, PLAYER_VERTICAL_MOVEMENT
		li PLAYER_VERTICAL_MOVEMENT, 0	# Previously, the player was in a falling state. Stop falling.
		li NUMBER_OF_JUMPS, 2 # Set player to only be allowed to jump once or twice
		jr $ra
	
	DECREASE_JUMP_AMOUNT:
		addi PLAYER_VERTICAL_MOVEMENT, PLAYER_VERTICAL_MOVEMENT, 256	# Decrease jump amount
		jr $ra
	
ENEMY_HIT:
	addi $sp, $sp, -4
	sw $ra, 0($sp)
	jal HIT_PLAYER # When enemy hits the player
	lw $ra, 0($sp)
	addi $sp, $sp, 4
	jr $ra

# Collect coin when player is on top of the coin	
COLLECT_COIN:
	addi, SCORE, SCORE, 1 # Increment the score when player collects the coin
	lw $t0, 0($a0)
	li $t2, SKY # Set coin to the background colour to erase coin
	sw $t2, 0($t0) # Erase coin
	sw $t2, 4($t0)
	addi $sp, $sp, -4
	sw $ra, 0($sp)
	jal LOAD_COINS # Load more coins onto the screen at random locations
	lw $ra, 0($sp)
	addi $sp, $sp, 4

	# If Player collects 10 coins, they win!
	beq SCORE, 10, Go_TO_WIN_PAGE # Go to win page!
	jr $ra

	Go_TO_WIN_PAGE:
		addi $sp, $sp, -4
		sw $ra, 0($sp)
		jal CLEAR
		lw $ra, 0($sp)
		addi $sp, $sp, 4

		# Prepare the variables.
		li $t0, BASE_ADDRESS # $t0 stores the base address for display
		li $t1, 0
		li $t2, 0x009CE2B1 # load light green color (sky)
	
		WIN_PAGE_BACKGROUND_LOOP:
		sw $t2, 0($t0)
		addi $t0, $t0, 4 # advance to next pixel position in display
		addi $t1, $t1, -1 # decrement number of pixels
		bne $t1, -2176, WIN_PAGE_BACKGROUND_LOOP # repeat while number of pixels is not -1920
	
		li $a0, BASE_ADDRESS
		addi $a0, $a0, 256
		j WIN_PAGE


#####################################################################
# END the program
#####################################################################	
END:
	li $t0, BASE_ADDRESS # $t0 stores the base address for display
	li $t1, 0
	li $t2, BLACK # load black color
	END_LOOP:
	sw $t2, 0($t0)
	addi $t0, $t0, 4 # advance to next pixel position in display
	addi $t1, $t1, -1 # decrement number of pixels
	bne $t1, -2176, END_LOOP # repeat while number of pixels is not -2176
	
	li $v0, 10 # End game
	syscall


#####################################################################
# Loading objects onto the display
#####################################################################
# Accepts $a0 as platform's starting address
LOAD_PLATFORM:
	addi $sp, $sp, -8 # Store space on stack
	sw $ra, 4($sp) # Store return address on stack
	sw $a0, 0($sp) # Store x on stack
	jal RANDOM_PLATFORM # jump to RANDOM_PLATFORM branch to generate random row location
	lw $a0, 0($sp) # Load x
	li $t7, 256 # load $t7 to be 256
	sw $t7, 0($a0) # Store $t7 on stack
	sw $v0, 4($a0) # Store randomized number in stack
	jal RANDOM_LENGTH # Jump to RANDOM_LENGTH branch to generate random length of platform
	lw $a0, 0($sp) # Load x
	sw $v0, 8($a0) # Store random length number on stack
	lw $ra, 4($sp) # Pop off stack
	addi $sp, $sp, 8 # Remove space on stack
	jr $ra # Return to caller
	
LOAD_ENEMY:
	addi $sp, $sp, -4
	sw $ra, 0($sp)

	addi $sp, $sp, -4	# Push $a0 (address pointer) into stack
	sw $a0, 0($sp)

	li $a0, 5
	li $a1, 25
	jal GET_RANDOM_NUMBER_IN_RANGE # Choose where the enemy will be
	
	li $t0, 256 	# load $t7 to be 256
	mult $t0, $v0
	mflo $v0

	addi $v0, $v0, BASE_ADDRESS

	# Set vertical position
	lw $a0, 0($sp)	# Get address pointer from stack
	sw $v0, 4($a0) 	# Store vertical position into y-cell

	li $t0, 256 	# load $t7 to be 256
	sw $t0, 0($a0) 	# Store $t7 on stack

	addi $sp, $sp, 4	# Push stack up to where $ra is stored
	lw $ra, 0($sp)
	addi $sp, $sp, 4
	jr $ra

LOAD_COINS:
	addi $sp, $sp, -4
	sw $ra, 0($sp)
	addi $sp, $sp, -4
	sw $a0, 0($sp)
	jal RANDOM_COIN_LOCATION # Get random location of coins
	li $t0, 4
	mult $v0, $t0
	mflo $v0
	addi $v0, $v0, BASE_ADDRESS
	addi $v0, $v0, 1280 # Add to offset the areas we don't want the coin to appear
	move $t0, $v0
	lw $a0, 0($sp)
	sw $t0, 0($a0)
	addi $sp, $sp, 4
	lw $ra, 0($sp)
	addi $sp, $sp, 4
	jr $ra

#####################################################################
# DRAWING Functions for the main game
#####################################################################
# Draw Background
BACKGROUND:
	# Prepare the variables.
	li $t0, BASE_ADDRESS # $t0 stores the base address for display
	li $t1, 0
	li $t2, SKY # load light blue color (sky)
	
	BACKGROUND_LOOP:
	sw $t2, 0($t0)
	addi $t0, $t0, 4 # advance to next pixel position in display
	addi $t1, $t1, -1 # decrement number of pixels
	bne $t1, -1920, BACKGROUND_LOOP # repeat while number of pixels is not -1920
	
# Draw Bottom border (ground that player will be on)      
DRAW_BOTTOM_BORDER:                                      
	li $t2, GREEN 
	addi $t1, $zero, 128 # Set $t1 to be of length 128
	DRAW_BOTTOM_BORDER_LOOP:                                                                                                                                                                             
	sw $t2, 0($t0) # Colour pixel Green
	addi $t0, $t0, 4 # Go to next pixel
	addi $t1, $t1, -1 # Decrease pixel count
	bnez $t1, DRAW_BOTTOM_BORDER_LOOP # repeat until $t1==0
	li $a0, BASE_ADDRESS # $t0 stores the base address for display
	addi $sp, $sp, -4
	sw $ra, 0($sp)
	jal DRAW_SCORE_WORD # Draw the score word onto the screen
	lw $ra, 0($sp)
	addi, $sp, $sp, 4
	jr $ra
	
# Draw Platforms
DRAW_PLATFORM:
	li $t2, PLATFORM_COLOUR # Set $t2 to be the platform colour: brown
	move $t4, $a0 	# Set address of start of platform to $t4 (x)
	
	# Check if platform x-len is negative
	DRAW_PLATFORM_LOOP:
		add $t3, $t4, $a1 # Set $t3 to be x+y
		addi $t4, $t4, 4 # Add 4 to x to keep drawing each pixel 
		addi $a2, $a2, -4 # Subtract 4 from $t1
		
		# Prevent drawing to next row if on right edge
		bgt $t4, 256, DRAW_PLATFORM_RETURN # if x > 256, return
		# Prevent drawing to previous row if on left edge
		blez $t4, DRAW_PLATFORM_LOOP
		sw $t2, 0($t3) # Add platform (layer 1)
		bnez $a2, DRAW_PLATFORM_LOOP

	DRAW_PLATFORM_RETURN:
		jr $ra # Return to caller
	
DRAW_COINS:
	la $t9, coin_array
	lw $t8, 0($t9)
	add $t8, $t8, $t9 # Get end of array
	DRAW_COINS_LOOP:
		li $t2, COIN_COLOUR # Set $t2 to be the coin colour
		lw $t0, 0($t8) # Get position of coin
		sw $t2, 0($t0) # Draw coin
		sw $t2, 4($t0) # Draw coin
		sw $t2, 260($t0) # Draw coin
		sw $t2, 256($t0) # Draw coin
		subi $t8, $t8, 4 # Subtract 4
		bne $t8, $t9, DRAW_COINS_LOOP
	jr $ra

# Draws enemy at position $a0
DRAW_ENEMY:
	lw $t3, 0($a0) # Get the value at address x
	lw $t1, 4($a0) # Get value address y
	#move $t0, $a0 # Set start of enemy position
	#li $t0, BASE_ADDRESS # Set start of enemy position
	add $t0, $t1, $t3

    # Check if pig is outof screen (per column)
    # If it is, then don't draw the pig
	beqz $t3, DRAW_PIGGY_COLUMN2
	beq $t3, -4, DRAW_PIGGY_COLUMN3
	beq $t3, -8, DRAW_PIGGY_COLUMN4
	beq $t3, -12, DRAW_PIGGY_COLUMN5
	ble $t3, -16, DRAW_PIGGY_RETURN

	bge $t3, 260, DRAW_PIGGY_RETURN

    # Draw the Pig (Per columns)
	# Column 1
	DRAW_PIGGY_COLUMN1:
		li $t2, 0x00A3F885 # $t2 stores the light green colour code
		sw $t2, 764($t0)

	bge $t3, 256, DRAW_PIGGY_RETURN	
	# Column 2
	DRAW_PIGGY_COLUMN2:
		li $t2, 0x0042FF00 # $t2 stores the green colour code
		sw $t2, 256($t0)
		sw $t2, 1024($t0)

		li $t2, WHITE # $t2 stores the white colour code
		sw $t2, 768($t0)

		li $t2, BLACK # $t2 stores the black colour code
		sw $t2, 512($t0)	
		
	bge $t3, 252, DRAW_PIGGY_RETURN
	# Column 3
	DRAW_PIGGY_COLUMN3:
		li $t2, 0x0042FF00 # $t2 stores the green colour code
		sw $t2, 4($t0)
		sw $t2, 260($t0)
		sw $t2, 1028($t0)

		li $t2, WHITE # $t2 stores the white colour code
		sw $t2, 516($t0)
		sw $t2, 772($t0)

	bge $t3, 248, DRAW_PIGGY_RETURN
	# Column 4
	DRAW_PIGGY_COLUMN4:
		li $t2, 0x0042FF00 # $t2 stores the green colour code
		sw $t2, 264($t0)  
		sw $t2, 520($t0)
		sw $t2, 776($t0)
		sw $t2, 1032($t0)

	bge $t3, 242, DRAW_PIGGY_RETURN
	DRAW_PIGGY_COLUMN5:
		li $t2, 0x0042FF00 # $t2 stores the green colour code
		sw $t2, 268($t0)
		sw $t2, 524($t0)
		sw $t2, 780($t0)
		sw $t2, 1036($t0)

	DRAW_PIGGY_RETURN:
	jr $ra

DRAW_SCORE_WORD:
	# Push return address to stack.
	addi $sp, $sp, -4
	sw	$ra, 0($sp)
	addi $sp, $sp, -4
	sw $a0, 0($sp)
	li $t0, BLACK
	
	# Draw the S
	sw $t0, 260($a0)
	sw $t0, 264($a0)
	sw $t0, 268($a0)
	sw $t0, 516($a0)
	sw $t0, 772($a0)
	sw $t0, 776($a0)
	sw $t0, 780($a0)
	sw $t0, 1036($a0)
	sw $t0, 1292($a0)
	sw $t0, 1288($a0)
	sw $t0, 1284($a0)
	
	# Draw the c
	sw $t0, 532($a0)
	sw $t0, 536($a0)
	sw $t0, 788($a0)
	sw $t0, 1044($a0)
	sw $t0, 1300($a0)
	sw $t0, 1304($a0)
	
	# Draw the o
	sw $t0, 544($a0)
	sw $t0, 548($a0)
	sw $t0, 552($a0)
	sw $t0, 808($a0)
	sw $t0, 1064($a0)
	sw $t0, 1320($a0)
	sw $t0, 1316($a0)
	sw $t0, 1312($a0)
	sw $t0, 1056($a0)
	sw $t0, 800($a0)
	
	# Draw the r
	sw $t0, 560($a0)
	sw $t0, 564($a0)
	sw $t0, 568($a0)
	sw $t0, 824($a0)
	sw $t0, 816($a0)
	sw $t0, 1072($a0)
	sw $t0, 1328($a0)
	
	# Draw the e
	sw $t0, 320($a0)
	sw $t0, 324($a0)
	sw $t0, 328($a0)
	sw $t0, 584($a0)
	sw $t0, 840($a0)
	sw $t0, 836($a0)
	sw $t0, 832($a0)
	sw $t0, 576($a0)
	sw $t0, 1088($a0)
	sw $t0, 1344($a0)
	sw $t0, 1348($a0)
	sw $t0, 1352($a0)
	
	# Draw the semi-colons
	sw $t0, 1360($a0)
	sw $t0, 592($a0)
	
	addi $sp, $sp, 4
	# Return to sender.
	lw	$ra, 0($sp)
	addi $sp, $sp, 4
	jr	$ra
	
# Draw Player
PLAYER:
	move $t0, PLAYER_POS
	li $t2, RED # $t2 stores the red colour code
	sw $t2, 0($t0) # paint the first half of the player red
	sw $t2, 260($t0)
	sw $t2, 268($t0)
	sw $t2, 516($t0)
	sw $t2, 772($t0)
	sw $t2, 776($t0)
	sw $t2, 264($t0)
	sw $t2, 524($t0)
	
	li $t2, 0x00FFA200 # $t2 stores the orange colour code
	sw $t2, 780($t0)
	
	li $t2, BLACK # $t2 stores the black colour code
	sw $t2, 520($t0)
	sw $t2, 768($t0)
	jr $ra
	
#####################################################################
# KEYBOARD
#####################################################################
KEYPRESS:
	lw $t2, 4($a0) # This assumes $t9 is set to 0xfff0000 from before
	beq $t2, 0x61, A_KEY # ASCII code of 'a' is 0x61
	beq $t2, 0x64, D_KEY # ASCII code of 'd' is 0x64
	beq $t2, 0x77, W_KEY # ASCII code of 'w' is 0x77
	beq $t2, 0x70, P_KEY # ASCII code of 'p' is 0x70
	
	jr $ra # Above conditions not met means the key pressed
		# was not relevant
		
# Move left when a key is pressed
A_KEY:
	bgtz PLAYER_LEFT_OFFSET, MOVE_LEFT # prevent player from going out of the screen on the left
	jr $ra
	MOVE_LEFT:
		subi PLAYER_POS, PLAYER_POS, 4
		subi PLAYER_LEFT_OFFSET, PLAYER_LEFT_OFFSET, 4
		jr $ra
	
# Move right when d key is pressed	
D_KEY:
	addi $t0, PLAYER_LEFT_OFFSET, 16 # Prevent player from going off the screen on the right
	blt $t0, 256, MOVE_RIGHT
	jr $ra
	MOVE_RIGHT:
	# Draw player 1 unit to the right
	addi PLAYER_POS, PLAYER_POS, 4
	addi PLAYER_LEFT_OFFSET, PLAYER_LEFT_OFFSET, 4
	jr $ra
	
W_KEY:
	# subi PLAYER_POS, PLAYER_POS, 512
	bgtz NUMBER_OF_JUMPS, APPLY_JUMP
	jr $ra
	APPLY_JUMP:
		li PLAYER_VERTICAL_MOVEMENT, -JUMP_INITIAL_AMOUNT
		subi NUMBER_OF_JUMPS, NUMBER_OF_JUMPS, 1
		#addi PLAYER_POS, PLAYER_POS, 8
		addi $sp, $sp, -4
		sw $ra, 0($sp)
		jal D_KEY
		jal D_KEY
		lw $ra, 0($sp)
		addi $sp, $sp, 4
		jr $ra

P_KEY:
    # When P key is pressed, exit back to main menu (main branch) to allow player to restart the game
	j main

#####################################################################
# Enemy and platform movement
#####################################################################
ENEMY_MOVE_LEFT:
	la $t9, enemy_array # Load enemy array
	lw $t8, 0($t9) # Load value at enemy array
	beqz $t8, ENEMY_MOVE_LEFT_RETURN
	add $t8, $t8, $t9 # Set $t8 to be value at enemy_array
	ENEMY_MOVE_LEFT_LOOP:
		lw $a0, 0($t8) # Load $a0 to be value at $t8
		subi $a0, $a0, 4 # Subtract $a0 by 4 to make enemy move left
		sw $a0, 0($t8) # Store on stack
		subi $t8, $t8, ENEMY_DATA_SIZE
		bne $t8, $t9, ENEMY_MOVE_LEFT_LOOP # If start of enemy_array != $t8, keep looping
	
	ENEMY_MOVE_LEFT_RETURN:
	    jr $ra


PLATFORM_MOVE_LEFT:
	la $t9, platform_array # load platform array
	lw $t8, 0($t9) # load value at platform_array
	add $t8, $t8, $t9 # Set $t8 to be value at platform_array
	PLATFORM_MOVE_LEFT_LOOP:
		lw $a0, 0($t8) # Load $a0 to be value at $t8
		subi $a0, $a0, 4 # Subtract $a0  by 4 to make platform move left
		sw $a0, 0($t8) # Store on stack
		subi $t8, $t8, PLATFORM_DATA_SIZE # Subtract $t8 by 8 to get next part of platform_array
		bne $t8, $t9, PLATFORM_MOVE_LEFT_LOOP # If start of platform_array != $t8, keep looping
	li COUNTER, PLATFORM_UPDATE_RATE
	jr $ra
	
#####################################################################
# Randomizing Functions
#####################################################################
RANDOM_PLATFORM:
	# Random number to randomize the platform locations
	li $a1, 10
	li $v0, 42
	syscall
	addi $a0, $a0, 16
	move $v0, $a0
	li $t0, 256
	mult $v0, $t0 # Multiply by 256 to get a random row at column 0
	mflo $v0
	
	subi $v0, $v0, 256
	addi $v0, $v0, BASE_ADDRESS
	jr $ra

# Accepts 	$a0 = Start
# 		$a1 = End
# Returns 	$v0 = random number
GET_RANDOM_NUMBER_IN_RANGE:
	move $t0, $a0		# Store start value
	sub $t1, $a1, $a0	# Subtract start value from end
	# Random number for enemies and coins
	move $a1, $t1
	li $v0, 42
	syscall
	add $a0, $a0, $t0
	move $v0, $a0
	jr $ra

RANDOM_LENGTH:
	# Random number for length of paltforms
	li $a1, 16
	li $v0, 42
	syscall
	addi $a0, $a0, 5
	move $v0, $a0
	li $t0, 4
	mult $v0, $t0 # Multiply by 256 to get a random row at column 0
	mflo $v0

	jr $ra
	
RANDOM_PLATFORM_DELAY:	# Takes in the address of the platform as $a0 changes the first element.
	move $t1, $a0		# Save the address so that we can use the random number generator
	lw $t0, 0($a0)		# Get the current x-value 
	
	# Random number for when the platforms come onto the screen (the delay)
	li $a1, 5			# Get a random number
	li $v0, 42
	syscall

	# Make random number a multiple of 4
	li $t2, 4			# Store the value 4
	mult $a0, $t2		# Multiply by four
	mflo $a0
	# addi $a0, $a0, 100
	add $t0, $t0, $a0	# Add the current x-value with the random number
	sw $t0, 0($t1)		# Store result into the array
	
	jr $ra

RANDOM_COIN_LOCATION:
	li $a0, 0
	li $a1, 1408
	addi $sp, $sp, -4
	sw $ra, 0($sp)

	jal GET_RANDOM_NUMBER_IN_RANGE # Get random number to be able to randomize location of coins to anywhere on the screen that the player can go to
	lw $ra, 0($sp)
	addi $sp, $sp, 4
	jr $ra

# Clear the screen
CLEAR:
	li $t9, 0 # Increment
	li $t8, SKY
	li $t7, BASE_ADDRESS
	li $t6, 0x10009FFC # Last address on the display
	
	CLEAR_LOOP:
		bgt $t7, $t6, CLEAR_RETURN
		beq	$t9, $a2, CLEAR_NEXT_ROW
		sw	$t8, 0($t7)	# clear colour
		addi $t7, $t7, 4 # $t7 = $t7 + 4
		addi $t9, $t9, -4 # $t9 = $t9 - 4
		j CLEAR_LOOP # jump to clear_loop

	CLEAR_NEXT_ROW:
		add	$t7, $t7, $t9
		addi $t7, $t7, 256 # set $t7 to be the next row
		li $t9, 0 # reset $t9  to be zero
		j CLEAR_LOOP

	CLEAR_RETURN:
		jr $ra # Return back to caller
	
#####################################################################
# GAME OVER Functions
#####################################################################
# This is the losing page, which is displayed once the player gets hit by the enemy
GAME_OVER_PAGE:
	addi $sp, $sp, -4
	sw $ra, 0($sp)
	addi $sp, $sp, -4
	sw $a0, 0($sp)

    # Draw the game over screen
	GAME_OVER_DRAWING:
		li $t0, 0x002d0607
		sw $t0, 3164($a0)
		sw $t0, 3160($a0)
		sw $t0, 3420($a0)
		sw $t0, 3416($a0)
		sw $t0, 3680($a0)
		sw $t0, 3940($a0)
		sw $t0, 4196($a0)
		sw $t0, 2920($a0)
		sw $t0, 3176($a0)
		sw $t0, 3688($a0)
		sw $t0, 3432($a0)
		sw $t0, 2916($a0)
		sw $t0, 2664($a0)
		sw $t0, 2660($a0)
		sw $t0, 2924($a0)
		sw $t0, 2668($a0)
		sw $t0, 2408($a0)
		sw $t0, 3944($a0)
		sw $t0, 4200($a0)
		sw $t0, 3952($a0)
		sw $t0, 4204($a0)
		sw $t0, 3696($a0)
		sw $t0, 3444($a0)
		sw $t0, 3188($a0)
		sw $t0, 3192($a0)
		sw $t0, 3448($a0)
		sw $t0, 3960($a0)
		sw $t0, 4212($a0)
		sw $t0, 4464($a0)
		sw $t0, 4460($a0)
		sw $t0, 4456($a0)
		sw $t0, 4452($a0)
		sw $t0, 3932($a0)
		sw $t0, 4192($a0)
		sw $t0, 4712($a0)
		sw $t0, 4716($a0)
		
		
		li $t0, 0x007c2023
		sw $t0, 5228($a0)
		sw $t0, 5224($a0)
		sw $t0, 5484($a0)
		sw $t0, 5480($a0)
		sw $t0, 5476($a0)
		sw $t0, 5728($a0)
		sw $t0, 5732($a0)
		sw $t0, 5736($a0)
		sw $t0, 5740($a0)
		sw $t0, 5488($a0)
		sw $t0, 5744($a0)
		sw $t0, 5748($a0)
		sw $t0, 6008($a0)
		sw $t0, 6004($a0)
		sw $t0, 6000($a0)
		sw $t0, 5996($a0)
		sw $t0, 5992($a0)
		sw $t0, 5980($a0)
		sw $t0, 7516($a0)
		sw $t0, 7520($a0)
		sw $t0, 7524($a0)
		sw $t0, 7528($a0)
		sw $t0, 7532($a0)
		sw $t0, 7536($a0)
		sw $t0, 7540($a0)
		sw $t0, 7544($a0)
		sw $t0, 7256($a0)
		sw $t0, 7000($a0)
		sw $t0, 6996($a0)
		sw $t0, 6744($a0)
		sw $t0, 6492($a0)
		sw $t0, 6488($a0)
		sw $t0, 6740($a0)
		sw $t0, 6236($a0)
		sw $t0, 6512($a0)
		sw $t0, 6516($a0)
		sw $t0, 6784($a0)
		sw $t0, 7280($a0)
		sw $t0, 7272($a0)
		sw $t0, 7268($a0)
		sw $t0, 7008($a0)
		sw $t0, 6764($a0)
		sw $t0, 7012($a0)
		sw $t0, 7264($a0)
		sw $t0, 7260($a0)
		sw $t0, 7004($a0)
		sw $t0, 6748($a0)
		sw $t0, 6752($a0)
		sw $t0, 6760($a0)
		sw $t0, 6756($a0)
		sw $t0, 6252($a0)
		sw $t0, 6256($a0)
		sw $t0, 6260($a0)
		sw $t0, 6264($a0)
		sw $t0, 6768($a0)
		sw $t0, 7020($a0)
		sw $t0, 7548($a0)
		sw $t0, 7552($a0)
		sw $t0, 7296($a0)
		sw $t0, 7044($a0)
		sw $t0, 6788($a0)
		sw $t0, 7300($a0)
		sw $t0, 7556($a0)
		sw $t0, 4968($a0)
		sw $t0, 4972($a0)
		sw $t0, 5232($a0)
		sw $t0, 5492($a0)
		sw $t0, 5496($a0)
		sw $t0, 5752($a0)
		sw $t0, 5756($a0)
		sw $t0, 6012($a0)
		sw $t0, 6536($a0)
		sw $t0, 6792($a0)
		sw $t0, 7048($a0)
		sw $t0, 7304($a0)
		sw $t0, 6796($a0)
		sw $t0, 7052($a0)
		sw $t0, 5988($a0)
		sw $t0, 5984($a0)
		sw $t0, 6496($a0)
		sw $t0, 6532($a0)
		sw $t0, 6016($a0)
		sw $t0, 5472($a0)
		
		
		li $t0, 0x00ffffff
		sw $t0, 6244($a0)
		sw $t0, 6276($a0)
		sw $t0, 6268($a0)
		sw $t0, 6520($a0)
		sw $t0, 6508($a0)
		sw $t0, 6500($a0)
		sw $t0, 6240($a0)
		sw $t0, 6248($a0)
		sw $t0, 6272($a0)
		sw $t0, 6528($a0)
		sw $t0, 6212($a0)
		sw $t0, 5952($a0)
		sw $t0, 6220($a0)
		sw $t0, 5968($a0)
		sw $t0, 5972($a0)
		sw $t0, 5948($a0)
		sw $t0, 6204($a0)
		sw $t0, 6464($a0)
		sw $t0, 6228($a0)
		sw $t0, 6480($a0)
		sw $t0, 5768($a0)
		sw $t0, 6032($a0)
		sw $t0, 5784($a0)
		sw $t0, 5536($a0)
		sw $t0, 6044($a0)
		sw $t0, 5532($a0)
		sw $t0, 5792($a0)
		sw $t0, 5512($a0)
		sw $t0, 5516($a0)
		sw $t0, 5776($a0)
		sw $t0, 6028($a0)
		sw $t0, 3036($a0)
		sw $t0, 3292($a0)
		sw $t0, 2780($a0)
		sw $t0, 2760($a0)
		sw $t0, 3016($a0)
		sw $t0, 3272($a0)
		sw $t0, 2772($a0)
		sw $t0, 3028($a0)
		sw $t0, 3284($a0)
		sw $t0, 2520($a0)
		sw $t0, 3032($a0)
		sw $t0, 2788($a0)
		sw $t0, 3044($a0)
		sw $t0, 3300($a0)
		sw $t0, 3304($a0)
		sw $t0, 2800($a0)
		sw $t0, 3312($a0)
		sw $t0, 2984($a0)
		sw $t0, 3240($a0)
		sw $t0, 2996($a0)
		sw $t0, 3252($a0)
		sw $t0, 3256($a0)
		sw $t0, 3004($a0)
		sw $t0, 3260($a0)
		sw $t0, 2516($a0)
		sw $t0, 2524($a0)
		sw $t0, 2532($a0)
		sw $t0, 2500($a0)
		sw $t0, 2504($a0)
		sw $t0, 2508($a0)
		sw $t0, 2484($a0)
		sw $t0, 2740($a0)
		sw $t0, 2488($a0)
		sw $t0, 2492($a0)
		sw $t0, 2748($a0)
		sw $t0, 2468($a0)
		sw $t0, 2472($a0)
		sw $t0, 2476($a0)
		sw $t0, 2728($a0)
		
		
		li $t0, BLACK
		sw $t0, 6504($a0)
		sw $t0, 6524($a0)
		sw $t0, 7028($a0)
		sw $t0, 7036($a0)
		sw $t0, 576($a0)
		sw $t0, 836($a0)
		sw $t0, 320($a0)
		sw $t0, 328($a0)
		sw $t0, 840($a0)
		sw $t0, 832($a0)
		sw $t0, 1096($a0)
		sw $t0, 1352($a0)
		sw $t0, 1348($a0)
		sw $t0, 1344($a0)
		sw $t0, 336($a0)
		sw $t0, 340($a0)
		sw $t0, 344($a0)
		sw $t0, 592($a0)
		sw $t0, 848($a0)
		sw $t0, 1104($a0)
		sw $t0, 1360($a0)
		sw $t0, 1360($a0)
		sw $t0, 1364($a0)
		sw $t0, 1368($a0)
		sw $t0, 600($a0)
		sw $t0, 856($a0)
		sw $t0, 1112($a0)
		sw $t0, 352($a0)
		sw $t0, 608($a0)
		sw $t0, 864($a0)
		sw $t0, 1120($a0)
		sw $t0, 1376($a0)
		sw $t0, 1380($a0)
		sw $t0, 360($a0)
		sw $t0, 616($a0)
		sw $t0, 872($a0)
		sw $t0, 1128($a0)
		sw $t0, 1384($a0)
		sw $t0, 372($a0)
		sw $t0, 628($a0)
		sw $t0, 884($a0)
		sw $t0, 1140($a0)
		sw $t0, 1396($a0)
		sw $t0, 1400($a0)
		sw $t0, 1404($a0)
		sw $t0, 388($a0)
		sw $t0, 644($a0)
		sw $t0, 900($a0)
		sw $t0, 1156($a0)
		sw $t0, 1412($a0)
		sw $t0, 1416($a0)
		sw $t0, 1420($a0)
		sw $t0, 396($a0)
		sw $t0, 652($a0)
		sw $t0, 908($a0)
		sw $t0, 1164($a0)
		sw $t0, 392($a0)
		sw $t0, 404($a0)
		sw $t0, 408($a0)
		sw $t0, 412($a0)
		sw $t0, 404($a0)
		sw $t0, 660($a0)
		sw $t0, 916($a0)
		sw $t0, 920($a0)
		sw $t0, 924($a0)
		sw $t0, 1180($a0)
		sw $t0, 1428($a0)
		sw $t0, 1432($a0)
		sw $t0, 1436($a0)
		sw $t0, 420($a0)
		sw $t0, 424($a0)
		sw $t0, 428($a0)
		sw $t0, 680($a0)
		sw $t0, 936($a0)
		sw $t0, 1192($a0)
		sw $t0, 1448($a0)
		sw $t0, 1460($a0)
		sw $t0, 436($a0)
		sw $t0, 692($a0)
		sw $t0, 948($a0)
		sw $t0, 6208($a0)
		sw $t0, 6224($a0)
		sw $t0, 6724($a0)
		sw $t0, 6732($a0)
		sw $t0, 584($a0)
		sw $t0, 5788($a0)
		sw $t0, 5772($a0)
		sw $t0, 6292($a0)
		sw $t0, 6300($a0)
		
		
		li $t0, 0x00f9f2f2
		sw $t0, 7016($a0)
		sw $t0, 7276($a0)
		
		
		li $t0, 0x00994c4c
		sw $t0, 6772($a0)
		sw $t0, 7032($a0)
		sw $t0, 7024($a0)
		sw $t0, 7288($a0)
		sw $t0, 7284($a0)
		sw $t0, 7292($a0)
		sw $t0, 6776($a0)
		sw $t0, 6780($a0)
		sw $t0, 7040($a0)
		
		
		li $t0, 0x004f0c0c
		sw $t0, 5712($a0)
		sw $t0, 5452($a0)
		sw $t0, 5448($a0)
		sw $t0, 5448($a0)
		sw $t0, 5700($a0)
		sw $t0, 5704($a0)
		sw $t0, 5708($a0)
		sw $t0, 5960($a0)
		sw $t0, 5964($a0)
		sw $t0, 6232($a0)
		sw $t0, 6460($a0)
		sw $t0, 6216($a0)
		sw $t0, 6484($a0)
		sw $t0, 7244($a0)
		sw $t0, 7248($a0)
		sw $t0, 6992($a0)
		sw $t0, 7240($a0)
		sw $t0, 7236($a0)
		sw $t0, 6976($a0)
		sw $t0, 6984($a0)
		sw $t0, 6972($a0)
		sw $t0, 6716($a0)
		sw $t0, 6456($a0)
		sw $t0, 6712($a0)
		sw $t0, 7248($a0)
		sw $t0, 7252($a0)
		sw $t0, 7248($a0)
		sw $t0, 7240($a0)
		sw $t0, 7232($a0)
		sw $t0, 5456($a0)
		sw $t0, 5444($a0)
		sw $t0, 5696($a0)
		sw $t0, 6200($a0)
		sw $t0, 5716($a0)
		sw $t0, 5976($a0)
		sw $t0, 6020($a0)
		sw $t0, 5508($a0)
		sw $t0, 5764($a0)
		sw $t0, 5256($a0)
		sw $t0, 5004($a0)
		sw $t0, 5008($a0)
		sw $t0, 5012($a0)
		sw $t0, 5272($a0)
		sw $t0, 6048($a0)
		sw $t0, 6560($a0)
		sw $t0, 6304($a0)
		sw $t0, 6812($a0)
		sw $t0, 7064($a0)
		sw $t0, 7316($a0)
		sw $t0, 7060($a0)
		sw $t0, 7056($a0)
		sw $t0, 7312($a0)
		sw $t0, 7308($a0)
		sw $t0, 6804($a0)
		sw $t0, 6800($a0)
		sw $t0, 6280($a0)
		sw $t0, 5260($a0)
		sw $t0, 5264($a0)
		sw $t0, 5268($a0)
		sw $t0, 5524($a0)
		sw $t0, 6544($a0)
		sw $t0, 6284($a0)
		sw $t0, 6540($a0)
		sw $t0, 5780($a0)
		sw $t0, 5520($a0)
		sw $t0, 5528($a0)
		sw $t0, 5784($a0)
		sw $t0, 6808($a0)
		sw $t0, 7068($a0)
		sw $t0, 6816($a0)
		sw $t0, 6564($a0)
		sw $t0, 6052($a0)
		sw $t0, 6052($a0)
		sw $t0, 6308($a0)
		sw $t0, 5276($a0)
		sw $t0, 5016($a0)
		sw $t0, 5760($a0)
		sw $t0, 5252($a0)
		sw $t0, 5000($a0)
		sw $t0, 7320($a0)
		sw $t0, 7072($a0)
		sw $t0, 5192($a0)
		sw $t0, 4932($a0)
		sw $t0, 5504($a0)
		sw $t0, 5956($a0)
		sw $t0, 5440($a0)
		sw $t0, 5692($a0)
		sw $t0, 5944($a0)
		sw $t0, 6196($a0)
		sw $t0, 6452($a0)
		sw $t0, 6708($a0)
		sw $t0, 6968($a0)
		sw $t0, 7228($a0)
		sw $t0, 5196($a0)
		sw $t0, 5188($a0)
		sw $t0, 5436($a0)
		sw $t0, 5688($a0)
		sw $t0, 5200($a0)
		sw $t0, 5460($a0)
		sw $t0, 5720($a0)
		sw $t0, 4944($a0)
		sw $t0, 4948($a0)
		sw $t0, 4672($a0)
		sw $t0, 6024($a0)
		
		
		li $t0, 0x00260000
		sw $t0, 4492($a0)
		sw $t0, 4236($a0)
		sw $t0, 4496($a0)
		sw $t0, 4232($a0)
		sw $t0, 4488($a0)
		sw $t0, 4744($a0)
		sw $t0, 4748($a0)
		sw $t0, 4752($a0)
		sw $t0, 4240($a0)
		sw $t0, 4228($a0)
		sw $t0, 3984($a0)
		sw $t0, 3976($a0)
		sw $t0, 3972($a0)
		sw $t0, 3980($a0)
		sw $t0, 3968($a0)
		sw $t0, 4224($a0)
		sw $t0, 3732($a0)
		sw $t0, 3472($a0)
		sw $t0, 3724($a0)
		sw $t0, 3728($a0)
		sw $t0, 3720($a0)
		sw $t0, 3476($a0)
		sw $t0, 3736($a0)
		sw $t0, 3988($a0)
		sw $t0, 3716($a0)
		sw $t0, 3480($a0)
		
		
		li $t0, 0x00b75454
		sw $t0, 6468($a0)
		sw $t0, 6472($a0)
		sw $t0, 6728($a0)
		sw $t0, 6476($a0)
		sw $t0, 6980($a0)
		sw $t0, 6720($a0)
		sw $t0, 6988($a0)
		sw $t0, 6736($a0)
		
		
		li $t0, 0x00cc6161
		sw $t0, 6036($a0)
		sw $t0, 6040($a0)
		sw $t0, 6296($a0)
		sw $t0, 6288($a0)
		sw $t0, 6548($a0)
		sw $t0, 6552($a0)
		sw $t0, 6556($a0)
		
		
		li $t0, 0x00210707
		sw $t0, 7692($a0)
		sw $t0, 7492($a0)
		sw $t0, 7496($a0)
		sw $t0, 7748($a0)
		sw $t0, 7752($a0)
		sw $t0, 7756($a0)
		sw $t0, 7500($a0)
		sw $t0, 7504($a0)
		sw $t0, 7760($a0)
		sw $t0, 7508($a0)
		sw $t0, 7768($a0)
		sw $t0, 7512($a0)
		sw $t0, 7764($a0)
		sw $t0, 7776($a0)
		sw $t0, 7772($a0)
		sw $t0, 7784($a0)
		sw $t0, 7792($a0)
		sw $t0, 7796($a0)
		sw $t0, 7804($a0)
		sw $t0, 7816($a0)
		sw $t0, 7812($a0)
		sw $t0, 7808($a0)
		sw $t0, 7800($a0)
		sw $t0, 7788($a0)
		sw $t0, 7780($a0)
		sw $t0, 7560($a0)
		sw $t0, 7564($a0)
		sw $t0, 7868($a0)
		sw $t0, 7820($a0)
		sw $t0, 7824($a0)
		sw $t0, 7828($a0)
		sw $t0, 7832($a0)
		sw $t0, 7836($a0)
		sw $t0, 7840($a0)
		sw $t0, 7844($a0)
		sw $t0, 7848($a0)
		sw $t0, 7852($a0)
		sw $t0, 7856($a0)
		sw $t0, 7860($a0)
		sw $t0, 7864($a0)
		sw $t0, 7868($a0)
		sw $t0, 7872($a0)
		sw $t0, 7876($a0)
		sw $t0, 7880($a0)
		sw $t0, 7884($a0)
		sw $t0, 7888($a0)
		sw $t0, 7892($a0)
		sw $t0, 7896($a0)
		sw $t0, 7900($a0)
		sw $t0, 7904($a0)
		sw $t0, 7908($a0)
		sw $t0, 7912($a0)
		sw $t0, 7916($a0)
		sw $t0, 7920($a0)
		sw $t0, 7924($a0)
		sw $t0, 7928($a0)
		sw $t0, 7932($a0)
		sw $t0, 7572($a0)
		sw $t0, 7568($a0)
		sw $t0, 7576($a0)
		sw $t0, 7324($a0)
		sw $t0, 7580($a0)
		sw $t0, 7588($a0)
		sw $t0, 7592($a0)
		sw $t0, 7608($a0)
		sw $t0, 7676($a0)
		sw $t0, 7680($a0)
		sw $t0, 7684($a0)
		sw $t0, 7688($a0)
		sw $t0, 7696($a0)
		sw $t0, 7700($a0)
		sw $t0, 7704($a0)
		sw $t0, 7708($a0)
		sw $t0, 7712($a0)
		sw $t0, 7716($a0)
		sw $t0, 7720($a0)
		sw $t0, 7724($a0)
		sw $t0, 7728($a0)
		sw $t0, 7732($a0)
		sw $t0, 7736($a0)
		sw $t0, 7740($a0)
		sw $t0, 7744($a0)
		sw $t0, 7488($a0)
		sw $t0, 7484($a0)
		sw $t0, 7444($a0)
		sw $t0, 7448($a0)
		sw $t0, 7452($a0)
		sw $t0, 7460($a0)
		sw $t0, 7204($a0)
		sw $t0, 7456($a0)
		sw $t0, 7460($a0)
		sw $t0, 7208($a0)
		sw $t0, 7468($a0)
		sw $t0, 7480($a0)
		sw $t0, 7472($a0)
		sw $t0, 7476($a0)
		sw $t0, 7464($a0)
		sw $t0, 7468($a0)
		sw $t0, 7216($a0)
		sw $t0, 7224($a0)
		sw $t0, 7220($a0)
		sw $t0, 7212($a0)
		sw $t0, 7200($a0)
		sw $t0, 7328($a0)
		sw $t0, 7332($a0)
		sw $t0, 7336($a0)
		sw $t0, 7340($a0)
		sw $t0, 7584($a0)
		sw $t0, 7592($a0)
		sw $t0, 7600($a0)
		sw $t0, 7596($a0)
		sw $t0, 7604($a0)
		sw $t0, 7612($a0)
		sw $t0, 7620($a0)
		sw $t0, 7628($a0)
		sw $t0, 7344($a0)
		sw $t0, 7348($a0)
		sw $t0, 7084($a0)
		sw $t0, 7076($a0)
		sw $t0, 7080($a0)
		sw $t0, 7616($a0)
		sw $t0, 7620($a0)
		sw $t0, 7624($a0)
		sw $t0, 7632($a0)
		sw $t0, 7636($a0)
		sw $t0, 7640($a0)
		sw $t0, 7656($a0)	
		
		li $t0, 0x00422727
		sw $t0, 7660($a0)
		sw $t0, 7664($a0)
		sw $t0, 7668($a0)
		sw $t0, 7652($a0)
		sw $t0, 7392($a0)
		sw $t0, 7644($a0)
		sw $t0, 7648($a0)
		sw $t0, 7396($a0)
		sw $t0, 7416($a0)
		sw $t0, 7672($a0)
		sw $t0, 7412($a0)
		sw $t0, 7400($a0)
		sw $t0, 7404($a0)
		sw $t0, 7420($a0)
		sw $t0, 7152($a0)
		sw $t0, 7408($a0)
		sw $t0, 7156($a0)
		sw $t0, 7160($a0)
		sw $t0, 6908($a0)
		sw $t0, 7144($a0)
		sw $t0, 7148($a0)
		sw $t0, 6904($a0)
		sw $t0, 7164($a0)
		sw $t0, 6900($a0)
		sw $t0, 6652($a0)
		sw $t0, 7440($a0)
		sw $t0, 7432($a0)
		sw $t0, 7424($a0)
		sw $t0, 7436($a0)
		sw $t0, 7188($a0)
		sw $t0, 7428($a0)
		sw $t0, 6912($a0)
		sw $t0, 7168($a0)
		sw $t0, 7172($a0)
		sw $t0, 7176($a0)
		sw $t0, 6916($a0)
		sw $t0, 6924($a0)
		sw $t0, 7180($a0)
		sw $t0, 6920($a0)
		sw $t0, 6660($a0)
		sw $t0, 6656($a0)
		sw $t0, 6400($a0)
		sw $t0, 7184($a0)
		sw $t0, 7192($a0)
		sw $t0, 6932($a0)
		sw $t0, 6928($a0)
		sw $t0, 7196($a0)
		sw $t0, 6404($a0)
		sw $t0, 6660($a0)
		sw $t0, 6144($a0)
		sw $t0, 6408($a0)
		sw $t0, 6668($a0)
		sw $t0, 6672($a0)
		sw $t0, 6664($a0)

		# Push return address to stack.
		li $t4, BASE_ADDRESS
		addi $t4, $t4, 7932
		li $t1, 0
		li $t2, 0x00210707 # Background colour
		BOTTOM_BORDER_LOOP:
		sw $t2, 0($t4)
		addi $t4, $t4, 4 # advance to next pixel position in display
		addi $t1, $t1, 1 # increment number of pixels
		bne $t1, 256, BOTTOM_BORDER_LOOP # repeat while number of pixels is not -1920
	
	addi $sp, $sp, 4
	# Return to sender.
	lw $ra, 0($sp)
	addi $sp, $sp, 4
	
	# Display Score
	li $a0, BASE_ADDRESS
	addi $a0, $a0, 4036
	move $a2, SCORE
	li $a1, WHITE
	jal BEGIN_DRAW_NUMBERS
	
	# Add delay
 	li $v0, 32
  	li $a0, 20
  	syscall
  	subi SCREEN_DELAY,SCREEN_DELAY,1

    # Check ig player presses to p key to restart game
  	li $a0, 0xffff0000
  	lw $t2, 4($a0) # This assumes $t2 is set to 0xfff0000 from before
	beq $t2, 0x70, P_KEY # ASCII code of 'p' is 0x70
  	
  	bgtz SCREEN_DELAY, GAME_OVER_PAGE

  	GAME_OVER_LAST_FRAME:
		j MAIN_MENU_PAGE # Go to main menu page when player loses to restart all the levels again


#####################################################################
# Drawing the Numbers for the player's score
#####################################################################
BEGIN_DRAW_NUMBERS:
    # For the start, when player enters the game, the score will show zero
	addi $sp, $sp, -4
	sw $ra, 0($sp)
	bne $a2, $zero, SCORE_GREATER_THAN_ZERO

	addi $sp, $sp, -4
	sw $ra, 0($sp)
	jal SCORE_IS_ZERO
	lw $ra, 0($sp)
	addi $sp, $sp, 4
	jr $ra

	SCORE_GREATER_THAN_ZERO: 
	jal DRAW_NUMBER # Draw numbers if score is not zero anymore
	lw $ra, 0($sp)
	addi $sp, $sp, 4
	jr $ra

# draw number
	# $a0: position
	# $a1: COLOUR_NUMBER
	# $a2: number to draw
	# $t0: tens place we are looking at
	# $t1: current digit to draw 
	# $t2: temp
DRAW_NUMBER:

	# If score is zero, draw zero
	li $t0, 10
	div $a2, $t0 # Divide number to draw by 10
	mflo $a2 # $a2 = $a2 / $t0 (rounds number down to nearest integer)
	mfhi $t1 # $t9 = $a2 mod $t0
 	
	bne $a2, $zero, DRAW_0
	bne $t1, $zero, DRAW_0
	
	jr $ra

# Draw Numbers from 0 to 9
SCORE_IS_ZERO:
	# Push return address to stack.
	addi $sp, $sp, -4
	sw $ra, 0($sp)
	
	sw $a1, 0($a0)
	sw $a1, 4($a0)
	sw $a1, 8($a0)
	sw $a1, 264($a0)
	sw $a1, 520($a0)
	sw $a1, 776($a0)
	sw $a1, 256($a0)
	sw $a1, 512($a0)
	sw $a1, 768($a0)
	sw $a1, 1024($a0)
	sw $a1, 1028($a0)
	sw $a1, 1028($a0)
	sw $a1, 1032($a0)

	addi $a0, $a0, -8
	# Return to sender.
	lw $ra, 0($sp)
	addi $sp, $sp, 4
	jr $ra
	
# Draw Numbers from 0 to 9
DRAW_0:
	li $t2, 0
	bne $t1, $t2, DRAW_1
	# Push return address to stack.
	addi $sp, $sp, -4
	sw $ra, 0($sp)
	addi $sp, $sp, -4
	sw $a0, 0($sp)
	
	sw $a1, 0($a0)
	sw $a1, 4($a0)
	sw $a1, 8($a0)
	sw $a1, 264($a0)
	sw $a1, 520($a0)
	sw $a1, 776($a0)
	sw $a1, 256($a0)
	sw $a1, 512($a0)
	sw $a1, 768($a0)
	sw $a1, 1024($a0)
	sw $a1, 1028($a0)
	sw $a1, 1028($a0)
	sw $a1, 1032($a0)
	
	addi $sp, $sp, 4
	# Return to sender.
	lw $ra, 0($sp)
	addi $sp, $sp, 4
	j DRAW_NEXT_NUMBER
	
DRAW_1:
	li $t2, 1
	bne $t1, $t2, DRAW_2
	# Push return address to stack.
	addi $sp, $sp, -4
	sw $ra, 0($sp)
	addi $sp, $sp, -4
	sw $a0, 0($sp)
	sw $a1, 0($a0)
	sw $a1, 256($a0)
	sw $a1, 512($a0)
	sw $a1, 768($a0)
	sw $a1, 1024($a0)
	addi $sp, $sp, 4
	# Return to sender.
	lw $ra, 0($sp)
	addi $sp, $sp, 4
	j DRAW_NEXT_NUMBER
	
DRAW_2:
	li $t2, 2
	bne $t1, $t2, DRAW_3
	# Push return address to stack.
	addi $sp, $sp, -4
	sw $ra, 0($sp)
	addi $sp, $sp, -4
	sw $a0, 0($sp)
	sw $a1, 0($a0)
	sw $a1, 8($a0)
	sw $a1, 512($a0)
	sw $a1, 768($a0)
	sw $a1, 1024($a0)
	sw $a1, 1028($a0)
	sw $a1, 1028($a0)
	sw $a1, 1032($a0)
	sw $a1, 4($a0)
	sw $a1, 516($a0)
	sw $a1, 264($a0)
	sw $a1, 520($a0)
	
	addi $sp, $sp, 4
	# Return to sender.
	lw $ra, 0($sp)
	addi $sp, $sp, 4
	j DRAW_NEXT_NUMBER
	
DRAW_3:
	li $t2, 3
	bne $t1, $t2, DRAW_4
	# Push return address to stack.
	addi $sp, $sp, -4
	sw $ra, 0($sp)
	addi $sp, $sp, -4
	sw $a0, 0($sp)
	sw $a1, 0($a0)
	sw $a1, 8($a0)
	sw $a1, 512($a0)
	sw $a1, 1024($a0)
	sw $a1, 1028($a0)
	sw $a1, 1028($a0)
	sw $a1, 1032($a0)
	sw $a1, 4($a0)
	sw $a1, 516($a0)
	sw $a1, 264($a0)
	sw $a1, 520($a0)
	sw $a1, 776($a0)
	
	addi $sp, $sp, 4
	# Return to sender.
	lw $ra, 0($sp)
	addi $sp, $sp, 4
	j DRAW_NEXT_NUMBER
	
DRAW_4:
	li $t2, 4
	bne $t1, $t2, DRAW_5
	# Push return address to stack.
	addi $sp, $sp, -4
	sw $ra, 0($sp)
	addi $sp, $sp, -4
	sw $a0, 0($sp)
	sw $a1, 0($a0)
	sw $a1, 8($a0)
	sw $a1, 512($a0)
	sw $a1, 1032($a0)
	sw $a1, 516($a0)
	sw $a1, 264($a0)
	sw $a1, 520($a0)
	sw $a1, 776($a0)
	sw $a1, 256($a0)
	
	addi $sp, $sp, 4
	# Return to sender.
	lw $ra, 0($sp)
	addi $sp, $sp, 4
	j DRAW_NEXT_NUMBER
	
DRAW_5:
	li $t2, 5
	bne $t1, $t2, DRAW_6
	# Push return address to stack.
	addi $sp, $sp, -4
	sw $ra, 0($sp)
	addi $sp, $sp, -4
	sw $a0, 0($sp)
	sw $a1, 0($a0)
	sw $a1, 512($a0)
	sw $a1, 1032($a0)
	sw $a1, 516($a0)
	sw $a1, 520($a0)
	sw $a1, 776($a0)
	sw $a1, 256($a0)
	sw $a1, 4($a0)
	sw $a1, 8($a0)
	sw $a1, 1028($a0)
	sw $a1, 1024($a0)
	
	addi $sp, $sp, 4
	# Return to sender.
	lw $ra, 0($sp)
	addi $sp, $sp, 4
	j DRAW_NEXT_NUMBER
	
DRAW_6:
	li $t2, 6
	bne $t1, $t2, DRAW_7
	# Push return address to stack.
	addi $sp, $sp, -4
	sw $ra, 0($sp)
	addi $sp, $sp, -4
	sw $a0, 0($sp)
	sw $a1, 0($a0)
	sw $a1, 512($a0)
	sw $a1, 1032($a0)
	sw $a1, 516($a0)
	sw $a1, 520($a0)
	sw $a1, 776($a0)
	sw $a1, 256($a0)
	sw $a1, 4($a0)
	sw $a1, 8($a0)
	sw $a1, 1028($a0)
	sw $a1, 1024($a0)
	sw $a1, 768($a0)

	addi $sp, $sp, 4
	# Return to sender.
	lw $ra, 0($sp)
	addi $sp, $sp, 4
	j DRAW_NEXT_NUMBER

DRAW_7:
	li $t2, 7
	bne $t1, $t2, DRAW_8
	# Push return address to stack.
	addi $sp, $sp, -4
	sw $ra, 0($sp)
	addi $sp, $sp, -4
	sw $a0, 0($sp)
	sw $a1, 0($a0)
	sw $a1, 1032($a0)
	sw $a1, 520($a0)
	sw $a1, 776($a0)
	sw $a1, 4($a0)
	sw $a1, 8($a0)
	sw $a1, 264($a0)
	
	addi $sp, $sp, 4
	# Return to sender.
	lw $ra, 0($sp)
	addi $sp, $sp, 4
	j DRAW_NEXT_NUMBER
	
DRAW_8:
	li $t2, 8
	bne $t1, $t2, DRAW_9
	# Push return address to stack.
	addi $sp, $sp, -4
	sw $ra, 0($sp)
	addi $sp, $sp, -4
	sw $a0, 0($sp)
	sw $a1, 0($a0)
	sw $a1, 1032($a0)
	sw $a1, 520($a0)
	sw $a1, 776($a0)
	sw $a1, 4($a0)
	sw $a1, 8($a0)
	sw $a1, 264($a0)
	sw $a1, 1028($a0)
	sw $a1, 1024($a0)
	sw $a1, 512($a0)
	sw $a1, 256($a0)
	sw $a1, 768($a0)
	sw $a1, 516($a0)
	
	addi $sp, $sp, 4
	# Return to sender.
	lw $ra, 0($sp)
	addi $sp, $sp, 4
	j DRAW_NEXT_NUMBER
	
DRAW_9:
	li $t2, 9
	bne $t1, $t2, DRAW_NEXT_NUMBER
	# Push return address to stack.
	addi $sp, $sp, -4
	sw $ra, 0($sp)
	addi $sp, $sp, -4
	sw $a0, 0($sp)
	sw $a1, 0($a0)
	sw $a1, 1032($a0)
	sw $a1, 520($a0)
	sw $a1, 776($a0)
	sw $a1, 4($a0)
	sw $a1, 8($a0)
	sw $a1, 264($a0)
	sw $a1, 512($a0)
	sw $a1, 256($a0)
	sw $a1, 516($a0)

	addi $sp, $sp, 4
	# Return to sender.
	lw $ra, 0($sp)
	addi $sp, $sp, 4
	j DRAW_NEXT_NUMBER
	
DRAW_NEXT_NUMBER:
	# Shift number to draw next number
	addi $a0, $a0, -8
	j DRAW_NUMBER

#####################################################################
# MAIN MENU Functions
#####################################################################
# MAIN MENU PAGE
MAIN_MENU_PAGE:
	jal MAIN_MENU_BACKGROUND # Set the background
	la $t0, LEVEL
	li $t1, 0
	sw $t1, 0($t0) # Set the LEVEL to be 0
	# Display page
	li $a0, 0x10008000
	addi $a0, $a0, 256
	jal MAIN_MENU_DISPLAY
	j MAIN_MENU_D_KEY	# Default to start
	j MAIN_MENU_LOOP

MAIN_MENU_BACKGROUND:
	li $t0, BASE_ADDRESS # $t0 stores the base address for display
	li $t1, 0
	li $t2, 0x009AB8E0 # load a background colour
	MAIN_MENU_BACKGROUND_LOOP:
	sw $t2, 0($t0)
	addi $t0, $t0, 4 # advance to next pixel position in display
	addi $t1, $t1, -1 # decrement number of pixels
	bne $t1, -2176, MAIN_MENU_BACKGROUND_LOOP # repeat while number of pixels is not -2176
	jr $ra

MAIN_MENU_LOOP:
	# Keyboard
	li $a0, 0xffff0000
	lw $t8, 0($a0)
	bne $t8, 1, NO_KEY_ENTERED
	lw $t2, 4($a0) # This assumes $t9 is set to 0xfff0000 from before
	
    # Check if player clicked a key
	beq $t2, 0x64, MAIN_MENU_D_KEY # ASCII code of 'd' is 0x64
	beq $t2, 0x61, MAIN_MENU_A_KEY # ASCII code of 'd' is 0x64
	beq $t2, 0x77, MAIN_MENU_W_KEY # ASCII code of 'w' is 0x77

	NO_KEY_ENTERED:
	li $v0, 32	# Delay for FPS/
	li $a0, GAME_LOOP_DELAY	# Game does not need to render
	syscall		# more than X times per second.
	j MAIN_MENU_LOOP

# Move bird to look Left when a key is pressed	
MAIN_MENU_A_KEY:
	la $t0, left_menu
	li $t1, 1
	sw $t1, 0($t0)
	la $t0, right_menu
	li $t1, 0
	sw $t1, 0($t0)

	jal DRAW_LEFT_BIRD

	j MAIN_MENU_LOOP
	
# Move bird to look right when d key is pressed	
MAIN_MENU_D_KEY:
	la $t0, right_menu
	li $t1, 1
	sw $t1, 0($t0)
	la $t0, left_menu
	li $t1, 0
	sw $t1, 0($t0)

	jal DRAW_RIGHT_BIRD
	j MAIN_MENU_LOOP

MAIN_MENU_W_KEY:
	# Select EXIT OR START
	la $t0, right_menu
	lw $t0, 0($t0)

	la $t1, left_menu
	lw $t1, 0($t1)
	li SCREEN_DELAY, 100 # Set delay 
	beq $t0, 1, LEVEL_PAGE # If player pressed d, then select start and enter game
	beq $t1, 1, EXIT_SCREEN # If player pressed a, then select exit and end the game
	
MAIN_MENU_DISPLAY:
	# Push return address to stack.
	addi $sp, $sp, -4
	sw	$ra, 0($sp)
	addi $sp, $sp, -4
	sw $a0, 0($sp)
    # Draw the main menu page
	MAIN_MENU_DRAW:
		li $t0, 0x00000000
		sw $t0, 5680($a0)
		sw $t0, 5672($a0)
		sw $t0, 4632($a0)
		sw $t0, 4888($a0)
		sw $t0, 5144($a0)
		sw $t0, 5400($a0)
		sw $t0, 5656($a0)
		sw $t0, 5660($a0)
		sw $t0, 5664($a0)
		sw $t0, 5148($a0)
		sw $t0, 5152($a0)
		sw $t0, 4636($a0)
		sw $t0, 4640($a0)
		sw $t0, 4772($a0)
		sw $t0, 5276($a0)
		sw $t0, 5280($a0)
		sw $t0, 4764($a0)
		sw $t0, 4768($a0)
		sw $t0, 5020($a0)
		sw $t0, 5284($a0)
		sw $t0, 5540($a0)
		sw $t0, 5796($a0)
		sw $t0, 5788($a0)
		sw $t0, 5792($a0)
		sw $t0, 5040($a0)
		sw $t0, 5296($a0)
		sw $t0, 5552($a0)
		sw $t0, 5808($a0)
		sw $t0, 5308($a0)
		sw $t0, 5312($a0)
		sw $t0, 5316($a0)
		sw $t0, 5564($a0)
		sw $t0, 5820($a0)
		sw $t0, 5572($a0)
		sw $t0, 5324($a0)
		sw $t0, 5580($a0)
		sw $t0, 5836($a0)
		sw $t0, 5828($a0)
		sw $t0, 5052($a0)
		sw $t0, 4800($a0)
		sw $t0, 5060($a0)
		sw $t0, 4784($a0)
		sw $t0, 4796($a0)
		sw $t0, 4804($a0)
		sw $t0, 4812($a0)
		sw $t0, 5068($a0)
		sw $t0, 4816($a0)
		sw $t0, 5076($a0)
		sw $t0, 4820($a0)
		sw $t0, 5328($a0)
		sw $t0, 5588($a0)
		sw $t0, 5844($a0)
		sw $t0, 4828($a0)
		sw $t0, 4832($a0)
		sw $t0, 4836($a0)
		sw $t0, 5088($a0)
		sw $t0, 5344($a0)
		sw $t0, 5600($a0)
		sw $t0, 5856($a0)
		sw $t0, 4780($a0)
		sw $t0, 4784($a0)
		sw $t0, 4788($a0)
		sw $t0, 4648($a0)
		sw $t0, 4904($a0)
		sw $t0, 5164($a0)
		sw $t0, 5416($a0)
		sw $t0, 4912($a0)
		sw $t0, 4656($a0)
		sw $t0, 5424($a0)
		sw $t0, 4664($a0)
		sw $t0, 4668($a0)
		sw $t0, 4672($a0)
		sw $t0, 5688($a0)
		sw $t0, 5692($a0)
		sw $t0, 5696($a0)
		sw $t0, 4668($a0)
		sw $t0, 4924($a0)
		sw $t0, 5180($a0)
		sw $t0, 5436($a0)
		sw $t0, 4680($a0)
		sw $t0, 4684($a0)
		sw $t0, 4688($a0)
		sw $t0, 4940($a0)
		sw $t0, 5196($a0)
		sw $t0, 5452($a0)
		sw $t0, 5708($a0)
		sw $t0, 3444($a0)
		sw $t0, 3192($a0)
		sw $t0, 3448($a0)
		sw $t0, 3452($a0)
		sw $t0, 3708($a0)
		sw $t0, 3704($a0)
		sw $t0, 3968($a0)
		sw $t0, 3712($a0)
		sw $t0, 3972($a0)
		sw $t0, 3716($a0)
		sw $t0, 3720($a0)
		sw $t0, 3464($a0)
		sw $t0, 3468($a0)
		sw $t0, 3472($a0)
		sw $t0, 3724($a0)
		sw $t0, 3212($a0)
		sw $t0, 3188($a0)
		sw $t0, 3216($a0)
		sw $t0, 4220($a0)
		sw $t0, 4232($a0)
		sw $t0, 7100($a0)
		sw $t0, 6868($a0)
		sw $t0, 7012($a0)
		sw $t0, 7364($a0)
		sw $t0, 7372($a0)
		sw $t0, 1252($a0)
		sw $t0, 1000($a0)
		sw $t0, 1764($a0)
		sw $t0, 1264($a0)
		
		
		li $t0, 0x00b21117
		sw $t0, 2672($a0)
		sw $t0, 2924($a0)
		sw $t0, 2928($a0)
		sw $t0, 3184($a0)
		sw $t0, 2932($a0)
		sw $t0, 2676($a0)
		sw $t0, 2936($a0)
		sw $t0, 3196($a0)
		sw $t0, 3440($a0)
		sw $t0, 3700($a0)
		sw $t0, 3696($a0)
		sw $t0, 3436($a0)
		sw $t0, 3180($a0)
		sw $t0, 3176($a0)
		sw $t0, 3432($a0)
		sw $t0, 3428($a0)
		sw $t0, 3684($a0)
		sw $t0, 3688($a0)
		sw $t0, 3692($a0)
		sw $t0, 3940($a0)
		sw $t0, 4196($a0)
		sw $t0, 4460($a0)
		sw $t0, 4728($a0)
		sw $t0, 4452($a0)
		sw $t0, 4456($a0)
		sw $t0, 4716($a0)
		sw $t0, 4720($a0)
		sw $t0, 4724($a0)
		sw $t0, 4200($a0)
		sw $t0, 3944($a0)
		sw $t0, 3948($a0)
		sw $t0, 4204($a0)
		sw $t0, 4208($a0)
		sw $t0, 3952($a0)
		sw $t0, 3956($a0)
		sw $t0, 4468($a0)
		sw $t0, 4464($a0)
		sw $t0, 3456($a0)
		sw $t0, 4992($a0)
		sw $t0, 2940($a0)
		sw $t0, 3200($a0)
		sw $t0, 3460($a0)
		sw $t0, 5252($a0)
		sw $t0, 3204($a0)
		sw $t0, 2944($a0)
		sw $t0, 2680($a0)
		sw $t0, 2684($a0)
		sw $t0, 2424($a0)
		sw $t0, 2428($a0)
		sw $t0, 2688($a0)
		sw $t0, 2948($a0)
		sw $t0, 3208($a0)
		sw $t0, 3728($a0)
		sw $t0, 3984($a0)
		sw $t0, 4496($a0)
		sw $t0, 2692($a0)
		sw $t0, 2952($a0)
		sw $t0, 4752($a0)
		sw $t0, 4972($a0)
		sw $t0, 4980($a0)
		sw $t0, 4976($a0)
		sw $t0, 3988($a0)
		sw $t0, 4244($a0)
		sw $t0, 4500($a0)
		sw $t0, 4756($a0)
		sw $t0, 5012($a0)
		sw $t0, 2956($a0)
		sw $t0, 2696($a0)
		sw $t0, 2440($a0)
		sw $t0, 2180($a0)
		sw $t0, 2432($a0)
		sw $t0, 2172($a0)
		sw $t0, 3476($a0)
		sw $t0, 3732($a0)
		sw $t0, 3736($a0)
		sw $t0, 3992($a0)
		sw $t0, 4248($a0)
		sw $t0, 4504($a0)
		sw $t0, 2420($a0)
		sw $t0, 4712($a0)
		sw $t0, 4760($a0)
		sw $t0, 5016($a0)
		sw $t0, 2960($a0)
		sw $t0, 3220($a0)
		sw $t0, 3480($a0)
		sw $t0, 3996($a0)
		sw $t0, 4252($a0)
		sw $t0, 4508($a0)
		sw $t0, 4192($a0)
		sw $t0, 3680($a0)
		sw $t0, 3936($a0)
		sw $t0, 4708($a0)
		sw $t0, 4968($a0)
		sw $t0, 5228($a0)
		sw $t0, 5272($a0)
		sw $t0, 2176($a0)
		sw $t0, 2436($a0)
		sw $t0, 2700($a0)
		sw $t0, 2168($a0)
		sw $t0, 1912($a0)
		sw $t0, 1908($a0)
		
		
		li $t0, 0x00ffffff
		sw $t0, 4216($a0)
		sw $t0, 4212($a0)
		sw $t0, 4472($a0)
		sw $t0, 4476($a0)
		sw $t0, 4224($a0)
		sw $t0, 4228($a0)
		sw $t0, 4492($a0)
		sw $t0, 4236($a0)
		sw $t0, 3980($a0)
		sw $t0, 3976($a0)
		sw $t0, 4236($a0)
		sw $t0, 4240($a0)
		sw $t0, 3964($a0)
		sw $t0, 3960($a0)
		sw $t0, 552($a0)
		sw $t0, 296($a0)
		sw $t0, 300($a0)
		sw $t0, 304($a0)
		sw $t0, 560($a0)
		sw $t0, 804($a0)
		sw $t0, 808($a0)
		sw $t0, 812($a0)
		sw $t0, 816($a0)
		sw $t0, 820($a0)
		sw $t0, 1072($a0)
		sw $t0, 1328($a0)
		sw $t0, 304($a0)
		sw $t0, 560($a0)
		sw $t0, 816($a0)
		sw $t0, 1072($a0)
		sw $t0, 1328($a0)
		sw $t0, 836($a0)
		sw $t0, 328($a0)
		sw $t0, 584($a0)
		sw $t0, 840($a0)
		sw $t0, 1096($a0)
		sw $t0, 1352($a0)
		sw $t0, 336($a0)
		sw $t0, 340($a0)
		sw $t0, 344($a0)
		sw $t0, 592($a0)
		sw $t0, 848($a0)
		sw $t0, 1104($a0)
		sw $t0, 1360($a0)
		sw $t0, 1364($a0)
		sw $t0, 1368($a0)
		sw $t0, 1112($a0)
		sw $t0, 1624($a0)
		sw $t0, 352($a0)
		sw $t0, 608($a0)
		sw $t0, 864($a0)
		sw $t0, 1120($a0)
		sw $t0, 1376($a0)
		sw $t0, 100($a0)
		sw $t0, 104($a0)
		sw $t0, 364($a0)
		sw $t0, 616($a0)
		sw $t0, 612($a0)
		sw $t0, 1132($a0)
		sw $t0, 876($a0)
		sw $t0, 1388($a0)
		sw $t0, 96($a0)
		sw $t0, 108($a0)
		sw $t0, 372($a0)
		sw $t0, 628($a0)
		sw $t0, 888($a0)
		sw $t0, 892($a0)
		sw $t0, 380($a0)
		sw $t0, 636($a0)
		sw $t0, 1148($a0)
		sw $t0, 1400($a0)
		sw $t0, 1396($a0)
		sw $t0, 132($a0)
		sw $t0, 136($a0)
		sw $t0, 140($a0)
		sw $t0, 144($a0)
		sw $t0, 392($a0)
		sw $t0, 648($a0)
		sw $t0, 904($a0)
		sw $t0, 1160($a0)
		sw $t0, 1416($a0)
		sw $t0, 1420($a0)
		sw $t0, 1424($a0)
		sw $t0, 912($a0)
		sw $t0, 1168($a0)
		sw $t0, 652($a0)
		sw $t0, 656($a0)
		sw $t0, 400($a0)
		sw $t0, 664($a0)
		sw $t0, 920($a0)
		sw $t0, 1176($a0)
		sw $t0, 1432($a0)
		sw $t0, 416($a0)
		sw $t0, 672($a0)
		sw $t0, 928($a0)
		sw $t0, 1184($a0)
		sw $t0, 1440($a0)
		sw $t0, 420($a0)
		sw $t0, 424($a0)
		sw $t0, 680($a0)
		sw $t0, 932($a0)
		sw $t0, 1192($a0)
		sw $t0, 1448($a0)
		sw $t0, 176($a0)
		sw $t0, 180($a0)
		sw $t0, 184($a0)
		sw $t0, 436($a0)
		sw $t0, 692($a0)
		sw $t0, 948($a0)
		sw $t0, 1204($a0)
		sw $t0, 1460($a0)
		sw $t0, 444($a0)
		sw $t0, 704($a0)
		sw $t0, 960($a0)
		sw $t0, 1212($a0)
		sw $t0, 1464($a0)
		sw $t0, 460($a0)
		sw $t0, 464($a0)
		sw $t0, 712($a0)
		sw $t0, 972($a0)
		sw $t0, 1232($a0)
		sw $t0, 1480($a0)
		sw $t0, 1484($a0)
		sw $t0, 576($a0)
		sw $t0, 316($a0)
		sw $t0, 316($a0)
		sw $t0, 572($a0)
		sw $t0, 828($a0)
		sw $t0, 1084($a0)
		sw $t0, 1340($a0)
		sw $t0, 1064($a0)
		sw $t0, 1320($a0)
		sw $t0, 7008($a0)
		sw $t0, 7004($a0)
		sw $t0, 7264($a0)
		sw $t0, 7268($a0)
		sw $t0, 6752($a0)
		sw $t0, 6748($a0)
		sw $t0, 7096($a0)
		sw $t0, 6840($a0)
		sw $t0, 6844($a0)
		sw $t0, 7356($a0)
		sw $t0, 6612($a0)
		sw $t0, 6616($a0)
		sw $t0, 7124($a0)
		sw $t0, 7128($a0)
		sw $t0, 6872($a0)
		sw $t0, 6608($a0)
		sw $t0, 7352($a0)
		sw $t0, 2016($a0)
		sw $t0, 1760($a0)
		sw $t0, 2020($a0)
		sw $t0, 1520($a0)
		sw $t0, 1516($a0)
		sw $t0, 1008($a0)
		sw $t0, 1012($a0)
		sw $t0, 1768($a0)
		sw $t0, 1268($a0)
		
		
		li $t0, 0x00e28c1f
		sw $t0, 4484($a0)
		sw $t0, 4736($a0)
		sw $t0, 4740($a0)
		sw $t0, 4744($a0)
		sw $t0, 4996($a0)
		sw $t0, 5000($a0)
		sw $t0, 4748($a0)
		sw $t0, 4732($a0)
		sw $t0, 5248($a0)
		sw $t0, 5256($a0)
		sw $t0, 4988($a0)
		sw $t0, 5508($a0)
		sw $t0, 4480($a0)
		sw $t0, 4488($a0)
		
		
		li $t0, 0x00ede5dc
		sw $t0, 5492($a0)
		sw $t0, 5496($a0)
		sw $t0, 5500($a0)
		sw $t0, 5512($a0)
		sw $t0, 5516($a0)
		sw $t0, 5264($a0)
		sw $t0, 5260($a0)
		sw $t0, 5520($a0)
		sw $t0, 5504($a0)
		sw $t0, 5236($a0)
		sw $t0, 5240($a0)
		sw $t0, 5244($a0)
		sw $t0, 5756($a0)
		sw $t0, 5760($a0)
		sw $t0, 5764($a0)
		sw $t0, 5768($a0)
		sw $t0, 5772($a0)
		sw $t0, 5268($a0)
		sw $t0, 5008($a0)
		sw $t0, 5004($a0)
		sw $t0, 4984($a0)
		sw $t0, 5232($a0)
		
		
		li $t0, 0x00eabe0e
		sw $t0, 5072($a0)
		sw $t0, 4824($a0)
		sw $t0, 5080($a0)
		sw $t0, 5092($a0)
		sw $t0, 4560($a0)
		sw $t0, 4564($a0)
		sw $t0, 4580($a0)
		sw $t0, 4584($a0)
		sw $t0, 4304($a0)
		sw $t0, 4324($a0)
		sw $t0, 4328($a0)
		sw $t0, 5332($a0)
		sw $t0, 5592($a0)
		sw $t0, 5604($a0)
		sw $t0, 5352($a0)
		sw $t0, 4588($a0)
		sw $t0, 4844($a0)
		sw $t0, 5100($a0)
		sw $t0, 3812($a0)
		sw $t0, 4332($a0)
		sw $t0, 5608($a0)
		sw $t0, 5356($a0)
		sw $t0, 5916($a0)
		sw $t0, 6160($a0)
		sw $t0, 6164($a0)
		sw $t0, 6420($a0)
		sw $t0, 6424($a0)
		sw $t0, 6428($a0)
		sw $t0, 6676($a0)
		sw $t0, 6680($a0)
		sw $t0, 6416($a0)
		sw $t0, 6936($a0)
		sw $t0, 6940($a0)
		sw $t0, 6948($a0)
		sw $t0, 5924($a0)
		sw $t0, 5924($a0)
		sw $t0, 5908($a0)
		sw $t0, 5652($a0)
		sw $t0, 5404($a0)
		sw $t0, 5668($a0)
		sw $t0, 5928($a0)
		sw $t0, 6696($a0)
		sw $t0, 6444($a0)
		sw $t0, 6188($a0)
		sw $t0, 5412($a0)
		sw $t0, 5904($a0)
		sw $t0, 5932($a0)
		sw $t0, 5396($a0)
		sw $t0, 5648($a0)
		sw $t0, 5156($a0)
		sw $t0, 5676($a0)
		sw $t0, 1308($a0)
		sw $t0, 1324($a0)
		sw $t0, 1580($a0)
		sw $t0, 1832($a0)
		sw $t0, 800($a0)
		sw $t0, 1052($a0)
		sw $t0, 1564($a0)
		sw $t0, 1068($a0)
		sw $t0, 2464($a0)
		sw $t0, 2724($a0)
		sw $t0, 1956($a0)
		sw $t0, 2208($a0)
		sw $t0, 2728($a0)
		sw $t0, 2220($a0)
		sw $t0, 1960($a0)
		sw $t0, 2476($a0)
		sw $t0, 6436($a0)
		sw $t0, 6700($a0)
		sw $t0, 6952($a0)
		sw $t0, 7204($a0)
		sw $t0, 7200($a0)
		sw $t0, 7196($a0)
		sw $t0, 6932($a0)
		sw $t0, 6672($a0)
		sw $t0, 3800($a0)
		sw $t0, 4052($a0)
		sw $t0, 5852($a0)
		sw $t0, 5860($a0)
		sw $t0, 5612($a0)
		sw $t0, 5360($a0)
		sw $t0, 4848($a0)
		sw $t0, 4592($a0)
		sw $t0, 5104($a0)
		sw $t0, 4076($a0)
		sw $t0, 3816($a0)
		sw $t0, 3552($a0)
		sw $t0, 3548($a0)
		sw $t0, 3796($a0)
		sw $t0, 3804($a0)
		sw $t0, 4316($a0)
		sw $t0, 5084($a0)
		sw $t0, 5596($a0)
		sw $t0, 4308($a0)
		sw $t0, 4056($a0)
		sw $t0, 4568($a0)
		sw $t0, 1824($a0)
		sw $t0, 1824($a0)
		sw $t0, 1828($a0)
		
		
		li $t0, 0x00ead272
		sw $t0, 1576($a0)
		sw $t0, 1312($a0)
		sw $t0, 1056($a0)
		sw $t0, 1568($a0)
		sw $t0, 2216($a0)
		sw $t0, 2212($a0)
		sw $t0, 2472($a0)
		sw $t0, 2468($a0)
		sw $t0, 6184($a0)
		sw $t0, 6440($a0)
		sw $t0, 6692($a0)
		sw $t0, 6688($a0)
		sw $t0, 6684($a0)
		sw $t0, 6180($a0)
		sw $t0, 6176($a0)
		sw $t0, 6172($a0)
		sw $t0, 6168($a0)
		sw $t0, 5912($a0)
		sw $t0, 5408($a0)
		sw $t0, 5920($a0)
		sw $t0, 6432($a0)
		sw $t0, 6944($a0)
		sw $t0, 4060($a0)
		sw $t0, 4572($a0)
		sw $t0, 5340($a0)
		sw $t0, 4064($a0)
		sw $t0, 5096($a0)
		sw $t0, 5348($a0)
		sw $t0, 3808($a0)
		sw $t0, 4320($a0)
		sw $t0, 4576($a0)
		sw $t0, 4312($a0)
		sw $t0, 4068($a0)
		sw $t0, 4840($a0)
		sw $t0, 1572($a0)
		sw $t0, 1312($a0)
		sw $t0, 1060($a0)
		sw $t0, 1316($a0)
		sw $t0, 4072($a0)
		sw $t0, 5336($a0)
		
		
		li $t0, 0x0026cc26
		sw $t0, 7496($a0)
		sw $t0, 7244($a0)
		sw $t0, 6992($a0)
		sw $t0, 7248($a0)
		sw $t0, 6996($a0)
		sw $t0, 6732($a0)
		sw $t0, 6740($a0)
		sw $t0, 6744($a0)
		sw $t0, 7252($a0)
		sw $t0, 7248($a0)
		sw $t0, 7504($a0)
		sw $t0, 7500($a0)
		sw $t0, 7752($a0)
		sw $t0, 7756($a0)
		sw $t0, 7760($a0)
		sw $t0, 7764($a0)
		sw $t0, 7768($a0)
		sw $t0, 7772($a0)
		sw $t0, 7776($a0)
		sw $t0, 7780($a0)
		sw $t0, 7524($a0)
		sw $t0, 7512($a0)
		sw $t0, 7508($a0)
		sw $t0, 7256($a0)
		sw $t0, 7000($a0)
		sw $t0, 7260($a0)
		sw $t0, 7516($a0)
		sw $t0, 7520($a0)
		sw $t0, 6488($a0)
		sw $t0, 6492($a0)
		sw $t0, 6756($a0)
		sw $t0, 7016($a0)
		sw $t0, 7272($a0)
		sw $t0, 7528($a0)
		sw $t0, 7780($a0)
		sw $t0, 7784($a0)
		sw $t0, 6496($a0)
		sw $t0, 7864($a0)
		sw $t0, 7604($a0)
		sw $t0, 7092($a0)
		sw $t0, 7608($a0)
		sw $t0, 7868($a0)
		sw $t0, 7872($a0)
		sw $t0, 7612($a0)
		sw $t0, 7884($a0)
		sw $t0, 7876($a0)
		sw $t0, 7880($a0)
		sw $t0, 6604($a0)
		sw $t0, 6600($a0)
		sw $t0, 6596($a0)
		sw $t0, 6592($a0)
		sw $t0, 6588($a0)
		sw $t0, 6336($a0)
		sw $t0, 6344($a0)
		sw $t0, 6348($a0)
		sw $t0, 6340($a0)
		sw $t0, 7636($a0)
		sw $t0, 7384($a0)
		sw $t0, 7380($a0)
		sw $t0, 6352($a0)
		sw $t0, 7348($a0)
		sw $t0, 6836($a0)
		sw $t0, 6584($a0)
		sw $t0, 6584($a0)
		sw $t0, 6332($a0)
		sw $t0, 6080($a0)
		sw $t0, 6084($a0)
		sw $t0, 6088($a0)
		sw $t0, 6092($a0)
		sw $t0, 6092($a0)
		sw $t0, 6096($a0)
		sw $t0, 6356($a0)
		sw $t0, 6328($a0)
		sw $t0, 6072($a0)
		sw $t0, 6076($a0)
		sw $t0, 6324($a0)
		sw $t0, 6580($a0)
		sw $t0, 6832($a0)
		sw $t0, 7088($a0)
		sw $t0, 7888($a0)
		sw $t0, 7640($a0)
		sw $t0, 7892($a0)
		sw $t0, 7388($a0)
		sw $t0, 7132($a0)
		sw $t0, 6620($a0)
		sw $t0, 6360($a0)
		sw $t0, 6100($a0)
		sw $t0, 5816($a0)
		sw $t0, 5560($a0)
		sw $t0, 5824($a0)
		sw $t0, 6876($a0)
		sw $t0, 6104($a0)
		sw $t0, 5840($a0)
		sw $t0, 5832($a0)
		sw $t0, 7344($a0)
		sw $t0, 7644($a0)
		sw $t0, 7392($a0)
		sw $t0, 6364($a0)
		sw $t0, 7136($a0)
		sw $t0, 6880($a0)
		sw $t0, 6624($a0)
		sw $t0, 1492($a0)
		sw $t0, 1748($a0)
		sw $t0, 1496($a0)
		sw $t0, 1752($a0)
		sw $t0, 1500($a0)
		sw $t0, 1244($a0)
		sw $t0, 1240($a0)
		sw $t0, 992($a0)
		sw $t0, 988($a0)
		sw $t0, 1756($a0)
		sw $t0, 2004($a0)
		sw $t0, 2264($a0)
		sw $t0, 2264($a0)
		sw $t0, 2008($a0)
		sw $t0, 2012($a0)
		sw $t0, 2012($a0)
		sw $t0, 2268($a0)
		sw $t0, 2272($a0)
		sw $t0, 2276($a0)
		sw $t0, 740($a0)
		sw $t0, 736($a0)
		sw $t0, 2024($a0)
		sw $t0, 1772($a0)
		sw $t0, 2032($a0)
		sw $t0, 2284($a0)
		
		
		li $t0, 0x008fd68f
		sw $t0, 7360($a0)
		sw $t0, 7368($a0)
		sw $t0, 7108($a0)
		sw $t0, 7112($a0)
		sw $t0, 7116($a0)
		sw $t0, 7376($a0)
		sw $t0, 7120($a0)
		sw $t0, 6860($a0)
		sw $t0, 6856($a0)
		sw $t0, 6852($a0)
		sw $t0, 7104($a0)
		
		
		li $t0, 0x008ddd8d
		sw $t0, 7628($a0)
		sw $t0, 7624($a0)
		sw $t0, 7620($a0)
		sw $t0, 7632($a0)
		sw $t0, 7616($a0)
		sw $t0, 6848($a0)
		sw $t0, 6864($a0)
		sw $t0, 744($a0)
		sw $t0, 748($a0)
		sw $t0, 1004($a0)
		sw $t0, 1512($a0)
		sw $t0, 1260($a0)
		
		
		li $t0, 0x005add5a
		sw $t0, 6764($a0)
		sw $t0, 7020($a0)
		sw $t0, 7276($a0)
		sw $t0, 6760($a0)
		sw $t0, 1248($a0)
		sw $t0, 1504($a0)
		sw $t0, 1508($a0)
		sw $t0, 996($a0)
		sw $t0, 1256($a0)
		
		
		li $t0, 0x001ec91e
		sw $t0, 2028($a0)
		sw $t0, 1524($a0)
		sw $t0, 1776($a0)
		sw $t0, 1780($a0)
		sw $t0, 488($a0)
		sw $t0, 484($a0)
		sw $t0, 2280($a0)
		sw $t0, 2540($a0)
		sw $t0, 2036($a0)
		sw $t0, 2292($a0)
		sw $t0, 752($a0)
		sw $t0, 492($a0)
		sw $t0, 756($a0)
		sw $t0, 496($a0)
		sw $t0, 1528($a0)
		sw $t0, 1272($a0)
		sw $t0, 1016($a0)
	
	
	addi $sp, $sp, 4
	# Return to sender.
	lw	$ra, 0($sp)
	addi $sp, $sp, 4
	jr	$ra

DRAW_RIGHT_BIRD:
    # Draw the bird that looks right on the main menu screen
	li $a0, 0x10008000
	addi $a0, $a0, 256	

	# Push return address to stack.
	addi	$sp, $sp, -4
	sw	$ra, 0($sp)
	addi $sp, $sp, -4
	sw $a0, 0($sp)
	DRAW_RIGHT_BIRD_DRAW:
		li $t0, 0x00b21117
		sw $t0, 2672($a0)
		sw $t0, 2924($a0)
		sw $t0, 2928($a0)
		sw $t0, 3184($a0)
		sw $t0, 2932($a0)
		sw $t0, 2676($a0)
		sw $t0, 2936($a0)
		sw $t0, 3196($a0)
		sw $t0, 3440($a0)
		sw $t0, 3700($a0)
		sw $t0, 3696($a0)
		sw $t0, 3436($a0)
		sw $t0, 3180($a0)
		sw $t0, 3176($a0)
		sw $t0, 3432($a0)
		sw $t0, 3428($a0)
		sw $t0, 3684($a0)
		sw $t0, 3688($a0)
		sw $t0, 3692($a0)
		sw $t0, 3940($a0)
		sw $t0, 4196($a0)
		sw $t0, 4460($a0)
		sw $t0, 4728($a0)
		sw $t0, 4452($a0)
		sw $t0, 4456($a0)
		sw $t0, 4716($a0)
		sw $t0, 4720($a0)
		sw $t0, 4724($a0)
		sw $t0, 4200($a0)
		sw $t0, 3944($a0)
		sw $t0, 3948($a0)
		sw $t0, 4204($a0)
		sw $t0, 4208($a0)
		sw $t0, 3952($a0)
		sw $t0, 3956($a0)
		sw $t0, 4468($a0)
		sw $t0, 4464($a0)
		sw $t0, 3456($a0)
		sw $t0, 4992($a0)
		sw $t0, 2940($a0)
		sw $t0, 3200($a0)
		sw $t0, 3460($a0)
		sw $t0, 5252($a0)
		sw $t0, 3204($a0)
		sw $t0, 2944($a0)
		sw $t0, 2680($a0)
		sw $t0, 2684($a0)
		sw $t0, 2424($a0)
		sw $t0, 2428($a0)
		sw $t0, 2688($a0)
		sw $t0, 2948($a0)
		sw $t0, 3208($a0)
		sw $t0, 3728($a0)
		sw $t0, 3984($a0)
		sw $t0, 4496($a0)
		sw $t0, 2692($a0)
		sw $t0, 2952($a0)
		sw $t0, 4752($a0)
		sw $t0, 4972($a0)
		sw $t0, 4980($a0)
		sw $t0, 4976($a0)
		sw $t0, 3988($a0)
		sw $t0, 4244($a0)
		sw $t0, 4500($a0)
		sw $t0, 4756($a0)
		sw $t0, 5012($a0)
		sw $t0, 2956($a0)
		sw $t0, 2696($a0)
		sw $t0, 2440($a0)
		sw $t0, 2180($a0)
		sw $t0, 2432($a0)
		sw $t0, 2172($a0)
		sw $t0, 3476($a0)
		sw $t0, 3732($a0)
		sw $t0, 3736($a0)
		sw $t0, 3992($a0)
		sw $t0, 4248($a0)
		sw $t0, 4504($a0)
		sw $t0, 2420($a0)
		sw $t0, 4712($a0)
		sw $t0, 4760($a0)
		sw $t0, 5016($a0)
		sw $t0, 2960($a0)
		sw $t0, 3220($a0)
		sw $t0, 3480($a0)
		sw $t0, 3996($a0)
		sw $t0, 4252($a0)
		sw $t0, 4508($a0)
		sw $t0, 4192($a0)
		sw $t0, 3680($a0)
		sw $t0, 3936($a0)
		sw $t0, 4708($a0)
		sw $t0, 4968($a0)
		sw $t0, 5228($a0)
		sw $t0, 5272($a0)
		sw $t0, 2176($a0)
		sw $t0, 2436($a0)
		sw $t0, 2700($a0)
		sw $t0, 2168($a0)
		sw $t0, 1912($a0)
		sw $t0, 1908($a0)
		
		
		li $t0, 0x00000000
		sw $t0, 3444($a0)
		sw $t0, 3192($a0)
		sw $t0, 3448($a0)
		sw $t0, 3452($a0)
		sw $t0, 3708($a0)
		sw $t0, 3704($a0)
		sw $t0, 3968($a0)
		sw $t0, 3712($a0)
		sw $t0, 3972($a0)
		sw $t0, 3716($a0)
		sw $t0, 3720($a0)
		sw $t0, 3464($a0)
		sw $t0, 3468($a0)
		sw $t0, 3472($a0)
		sw $t0, 3724($a0)
		sw $t0, 3212($a0)
		sw $t0, 3188($a0)
		sw $t0, 3216($a0)
		sw $t0, 4220($a0)
		sw $t0, 4232($a0)
		
		
		li $t0, 0x00ffffff
		sw $t0, 4216($a0)
		sw $t0, 4212($a0)
		sw $t0, 4472($a0)
		sw $t0, 4476($a0)
		sw $t0, 4224($a0)
		sw $t0, 4228($a0)
		sw $t0, 4492($a0)
		sw $t0, 4236($a0)
		sw $t0, 3980($a0)
		sw $t0, 3976($a0)
		sw $t0, 4236($a0)
		sw $t0, 4240($a0)
		sw $t0, 3964($a0)
		sw $t0, 3960($a0)
		
		
		li $t0, 0x00e28c1f
		sw $t0, 4484($a0)
		sw $t0, 4736($a0)
		sw $t0, 4740($a0)
		sw $t0, 4744($a0)
		sw $t0, 4996($a0)
		sw $t0, 5000($a0)
		sw $t0, 4748($a0)
		sw $t0, 4732($a0)
		sw $t0, 5248($a0)
		sw $t0, 5256($a0)
		sw $t0, 4988($a0)
		sw $t0, 5508($a0)
		sw $t0, 4480($a0)
		sw $t0, 4488($a0)
		
		
		li $t0, 0x00ede5dc
		sw $t0, 5492($a0)
		sw $t0, 5496($a0)
		sw $t0, 5500($a0)
		sw $t0, 5512($a0)
		sw $t0, 5516($a0)
		sw $t0, 5264($a0)
		sw $t0, 5260($a0)
		sw $t0, 5520($a0)
		sw $t0, 5504($a0)
		sw $t0, 5236($a0)
		sw $t0, 5240($a0)
		sw $t0, 5244($a0)
		sw $t0, 5756($a0)
		sw $t0, 5760($a0)
		sw $t0, 5764($a0)
		sw $t0, 5768($a0)
		sw $t0, 5772($a0)
		sw $t0, 5268($a0)
		sw $t0, 5008($a0)
		sw $t0, 5004($a0)
		sw $t0, 4984($a0)
		sw $t0, 5232($a0)
	
	addi	$sp, $sp, 4
	# Return to sender.
	lw	$ra, 0($sp)
	addi	$sp, $sp, 4
	jr	$ra

DRAW_LEFT_BIRD:
    # Draw the bird that looks left on the main menu screen
	li $a0, 0x10008000
	addi $a0, $a0, -508

	# Push return address to stack.
	addi $sp, $sp, -4
	sw $ra, 0($sp)
	addi $sp, $sp, -4
	sw $a0, 0($sp)
	DRAW_LEFT_BIRD_DRAW:
		li $t0, 0x0096c0ea
		sw $t0, 1300($a0)
		
		li $t0, 0x00b21117 # RED colour of bird
		sw $t0, 2936($a0)
		sw $t0, 2940($a0)
		sw $t0, 2932($a0)
		sw $t0, 3184($a0)
		sw $t0, 3188($a0)
		sw $t0, 3192($a0)
		sw $t0, 3196($a0)
		sw $t0, 3200($a0)
		sw $t0, 3436($a0)
		sw $t0, 3440($a0)
		sw $t0, 3444($a0)
		sw $t0, 3448($a0)
		sw $t0, 3452($a0)
		sw $t0, 3456($a0)
		sw $t0, 3460($a0)
		sw $t0, 3688($a0)
		sw $t0, 3692($a0)
		sw $t0, 3696($a0)
		sw $t0, 3700($a0)
		sw $t0, 3704($a0)
		sw $t0, 3708($a0)
		sw $t0, 3712($a0)
		sw $t0, 3716($a0)
		sw $t0, 3720($a0)
		sw $t0, 3952($a0)
		sw $t0, 3956($a0)
		sw $t0, 3960($a0)
		sw $t0, 3964($a0)
		sw $t0, 4212($a0)
		sw $t0, 4216($a0)
		sw $t0, 3940($a0)
		sw $t0, 4196($a0)
		sw $t0, 4192($a0)
		sw $t0, 4452($a0)
		sw $t0, 4960($a0)
		sw $t0, 2944($a0)
		sw $t0, 3204($a0)
		sw $t0, 3464($a0)
		sw $t0, 3724($a0)
		sw $t0, 3976($a0)
		sw $t0, 3980($a0)
		sw $t0, 3984($a0)
		sw $t0, 4236($a0)
		sw $t0, 4232($a0)
		sw $t0, 4240($a0)
		sw $t0, 4244($a0)
		sw $t0, 4484($a0)
		sw $t0, 4488($a0)
		sw $t0, 4492($a0)
		sw $t0, 4496($a0)
		sw $t0, 4500($a0)
		sw $t0, 4504($a0)
		sw $t0, 4740($a0)
		sw $t0, 4744($a0)
		sw $t0, 4748($a0)
		sw $t0, 4752($a0)
		sw $t0, 4756($a0)
		sw $t0, 4760($a0)
		sw $t0, 5000($a0)
		sw $t0, 5004($a0)
		sw $t0, 5008($a0)
		sw $t0, 5012($a0)
		sw $t0, 5016($a0)
		sw $t0, 5252($a0)
		sw $t0, 5256($a0)
		sw $t0, 5260($a0)
		sw $t0, 5264($a0)
		sw $t0, 5268($a0)
		sw $t0, 5504($a0)
		sw $t0, 5508($a0)
		sw $t0, 5512($a0)
		sw $t0, 5516($a0)
		sw $t0, 5520($a0)
		sw $t0, 5524($a0)
		sw $t0, 5764($a0)
		sw $t0, 5768($a0)
		sw $t0, 5772($a0)
		sw $t0, 5776($a0)
		sw $t0, 5752($a0)
		sw $t0, 6004($a0)
		sw $t0, 4456($a0)
		sw $t0, 4712($a0)
		sw $t0, 4964($a0)
		sw $t0, 5224($a0)
		sw $t0, 5480($a0)
		sw $t0, 5732($a0)
		sw $t0, 5984($a0)
		sw $t0, 5728($a0)
		sw $t0, 5472($a0)
		sw $t0, 5476($a0)
		sw $t0, 5212($a0)
		sw $t0, 5216($a0)
		sw $t0, 5220($a0)
		sw $t0, 4956($a0)
		sw $t0, 4704($a0)
		sw $t0, 4708($a0)
		sw $t0, 4700($a0)
		sw $t0, 4448($a0)
		
		
		li $t0, WHITE
		sw $t0, 4996($a0)
		sw $t0, 4992($a0)
		sw $t0, 4736($a0)
		sw $t0, 5248($a0)
		sw $t0, 4732($a0)
		sw $t0, 5244($a0)
		sw $t0, 4984($a0)
		sw $t0, 4980($a0)
		sw $t0, 4720($a0)
		sw $t0, 4716($a0)
		sw $t0, 4972($a0)
		sw $t0, 5228($a0)
		sw $t0, 4968($a0)
		
		
		li $t0, BLACK
		sw $t0, 3968($a0)
		sw $t0, 3972($a0)
		sw $t0, 4228($a0)
		sw $t0, 4224($a0)
		sw $t0, 4220($a0)
		sw $t0, 4480($a0)
		sw $t0, 4476($a0)
		sw $t0, 4472($a0)
		sw $t0, 4468($a0)
		sw $t0, 4724($a0)
		sw $t0, 4728($a0)
		sw $t0, 4464($a0)
		sw $t0, 4460($a0)
		sw $t0, 4208($a0)
		sw $t0, 4204($a0)
		sw $t0, 4200($a0)
		sw $t0, 3948($a0)
		sw $t0, 3944($a0)
		sw $t0, 4976($a0)
		sw $t0, 4988($a0)
		
		li $t0, 0x00e28c1f
		sw $t0, 5236($a0)
		sw $t0, 5240($a0)
		sw $t0, 5232($a0)
		sw $t0, 5484($a0)
		sw $t0, 5488($a0)
		sw $t0, 5492($a0)
		sw $t0, 5496($a0)
		sw $t0, 5500($a0)
		sw $t0, 5756($a0)
		sw $t0, 6008($a0)
		sw $t0, 6260($a0)
		sw $t0, 5744($a0)
		sw $t0, 6000($a0)
		sw $t0, 5748($a0)
		
		
		li $t0, 0x00e5ddd3
		sw $t0, 6012($a0)
		sw $t0, 6268($a0)
		sw $t0, 6016($a0)
		sw $t0, 6264($a0)
		sw $t0, 5760($a0)
		sw $t0, 6508($a0)
		sw $t0, 6512($a0)
		sw $t0, 6516($a0)
		sw $t0, 6520($a0)
		sw $t0, 6524($a0)
		sw $t0, 6272($a0)
		sw $t0, 6276($a0)
		sw $t0, 6280($a0)
		sw $t0, 6020($a0)
		sw $t0, 6024($a0)
		sw $t0, 6028($a0)
		sw $t0, 6248($a0)
		sw $t0, 6252($a0)
		sw $t0, 6256($a0)
		sw $t0, 5988($a0)
		sw $t0, 5992($a0)
		sw $t0, 5996($a0)
		sw $t0, 5736($a0)
		sw $t0, 5740($a0)
	
	
	addi	$sp, $sp, 4
	# Return to sender.
	lw	$ra, 0($sp)
	addi	$sp, $sp, 4
	jr	$ra

#####################################################################
# LEVEL Page
#####################################################################
LEVEL_PAGE:
	# Prepare the variables.
	li $t0, 0x10008000 # $t0 stores the base address for display
	li $t1, 0
	li $t2, 0x009AE2CD

    # Draw the level page
	DRAW_LEVEL_PAGE_SCREEN:
	sw $t2, 0($t0)
	addi $t0, $t0, 4 # advance to next pixel position in display
	addi $t1, $t1, -1 # decrement number of pixels
	bne $t1, -2176, DRAW_LEVEL_PAGE_SCREEN # repeat while number of pixels is not -1920
	
	li $a0, BASE_ADDRESS
	addi $a0, $a0, 256
	
	DRAW_LEVEL_PAGE:
		li $t0, WHITE
		sw $t0, 4440($a0)
		sw $t0, 4696($a0)
		sw $t0, 4444($a0)
		sw $t0, 4700($a0)
		sw $t0, 4448($a0)
		sw $t0, 4704($a0)
		sw $t0, 2404($a0)
		sw $t0, 2660($a0)
		sw $t0, 2916($a0)
		sw $t0, 3172($a0)
		sw $t0, 3428($a0)
		sw $t0, 3684($a0)
		sw $t0, 2408($a0)
		sw $t0, 2664($a0)
		sw $t0, 2920($a0)
		sw $t0, 3176($a0)
		sw $t0, 3432($a0)
		sw $t0, 3688($a0)
		sw $t0, 4516($a0)
		sw $t0, 4772($a0)
		sw $t0, 4520($a0)
		sw $t0, 4776($a0)
		sw $t0, 2468($a0)
		sw $t0, 2724($a0)
		sw $t0, 2472($a0)
		sw $t0, 2728($a0)
		sw $t0, 3104($a0)
		sw $t0, 3360($a0)
		sw $t0, 3616($a0)
		sw $t0, 3872($a0)
		sw $t0, 4128($a0)
		sw $t0, 4384($a0)
		sw $t0, 4640($a0)
		sw $t0, 3108($a0)
		sw $t0, 3364($a0)
		sw $t0, 3620($a0)
		sw $t0, 3876($a0)
		sw $t0, 4132($a0)
		sw $t0, 4388($a0)
		sw $t0, 4644($a0)
		sw $t0, 2848($a0)
		sw $t0, 2852($a0)
		sw $t0, 4392($a0)
		sw $t0, 4648($a0)
		sw $t0, 4396($a0)
		sw $t0, 4652($a0)
		sw $t0, 4400($a0)
		sw $t0, 4656($a0)
		sw $t0, 2872($a0)
		sw $t0, 3128($a0)
		sw $t0, 3384($a0)
		sw $t0, 3640($a0)
		sw $t0, 3896($a0)
		sw $t0, 4152($a0)
		sw $t0, 4408($a0)
		sw $t0, 4664($a0)
		sw $t0, 2876($a0)
		sw $t0, 3132($a0)
		sw $t0, 3388($a0)
		sw $t0, 3644($a0)
		sw $t0, 3900($a0)
		sw $t0, 4156($a0)
		sw $t0, 4412($a0)
		sw $t0, 4668($a0)
		sw $t0, 4416($a0)
		sw $t0, 4672($a0)
		sw $t0, 4420($a0)
		sw $t0, 4676($a0)
		sw $t0, 4424($a0)
		sw $t0, 4680($a0)
		sw $t0, 3392($a0)
		sw $t0, 3648($a0)
		sw $t0, 3396($a0)
		sw $t0, 3652($a0)
		sw $t0, 2616($a0)
		sw $t0, 2620($a0)
		sw $t0, 2624($a0)
		sw $t0, 2628($a0)
		sw $t0, 2632($a0)
		sw $t0, 2360($a0)
		sw $t0, 2364($a0)
		sw $t0, 2368($a0)
		sw $t0, 2372($a0)
		sw $t0, 2376($a0)
		sw $t0, 2336($a0)
		sw $t0, 2592($a0)
		sw $t0, 2340($a0)
		sw $t0, 2596($a0)
		sw $t0, 2384($a0)
		sw $t0, 2640($a0)
		sw $t0, 2896($a0)
		sw $t0, 3152($a0)
		sw $t0, 3408($a0)
		sw $t0, 3664($a0)
		sw $t0, 2388($a0)
		sw $t0, 2644($a0)
		sw $t0, 2900($a0)
		sw $t0, 3156($a0)
		sw $t0, 3412($a0)
		sw $t0, 3668($a0)
		sw $t0, 3924($a0)
		sw $t0, 4180($a0)
		sw $t0, 3928($a0)
		sw $t0, 4184($a0)
		sw $t0, 3936($a0)
		sw $t0, 4192($a0)
		sw $t0, 3940($a0)
		sw $t0, 4196($a0)
		sw $t0, 2416($a0)
		sw $t0, 2672($a0)
		sw $t0, 2928($a0)
		sw $t0, 3184($a0)
		sw $t0, 3440($a0)
		sw $t0, 3696($a0)
		sw $t0, 3952($a0)
		sw $t0, 4208($a0)
		sw $t0, 4464($a0)
		sw $t0, 4720($a0)
		sw $t0, 2420($a0)
		sw $t0, 2676($a0)
		sw $t0, 2932($a0)
		sw $t0, 3188($a0)
		sw $t0, 3444($a0)
		sw $t0, 3700($a0)
		sw $t0, 3956($a0)
		sw $t0, 4212($a0)
		sw $t0, 4468($a0)
		sw $t0, 4724($a0)
		sw $t0, 4472($a0)
		sw $t0, 4728($a0)
		sw $t0, 4476($a0)
		sw $t0, 4732($a0)
		sw $t0, 4480($a0)
		sw $t0, 4736($a0)
		sw $t0, 3448($a0)
		sw $t0, 3704($a0)
		sw $t0, 3452($a0)
		sw $t0, 3708($a0)
		sw $t0, 2424($a0)
		sw $t0, 2680($a0)
		sw $t0, 2428($a0)
		sw $t0, 2684($a0)
		sw $t0, 2432($a0)
		sw $t0, 2688($a0)
		sw $t0, 2440($a0)
		sw $t0, 2696($a0)
		sw $t0, 2952($a0)
		sw $t0, 3208($a0)
		sw $t0, 3464($a0)
		sw $t0, 3720($a0)
		sw $t0, 3976($a0)
		sw $t0, 4232($a0)
		sw $t0, 4488($a0)
		sw $t0, 4744($a0)
		sw $t0, 2444($a0)
		sw $t0, 2700($a0)
		sw $t0, 2956($a0)
		sw $t0, 3212($a0)
		sw $t0, 3468($a0)
		sw $t0, 3724($a0)
		sw $t0, 3980($a0)
		sw $t0, 4236($a0)
		sw $t0, 4492($a0)
		sw $t0, 4748($a0)
		sw $t0, 4496($a0)
		sw $t0, 4752($a0)
		sw $t0, 4500($a0)
		sw $t0, 4756($a0)
		sw $t0, 4504($a0)
		sw $t0, 4760($a0)
			
	# Display Score
	# Get the level
	la $t5, LEVEL
	lw $t5, 0($t5)
	addi $t5, $t5, 1 # Add 1 to display the level coming up
	li $a0, BASE_ADDRESS
	addi $a0, $a0, 4036
	move $a2, $t5
	li $a1, WHITE
	jal BEGIN_DRAW_NUMBERS

	LEVEL_PAGE_LOOP:

		subi SCREEN_DELAY,SCREEN_DELAY,1
		li $a0, 0xffff0000
		lw $t2, 4($a0) # This assumes $t9 is set to 0xfff0000 from before

		# beq $t2, 0x70, P_KEY # ASCII code of 'p' is 0x70
		# Add delay
		li $v0, 32
		li $a0, 10
		syscall

        # Check if player presses the P key to restart the game
		li $a0, 0xffff0000
		lw $t2, 4($a0) # This assumes $t9 is set to 0xfff0000 from before
		beq $t2, 0x70, P_KEY # ASCII code of 'p' is 0x70

  		bgtz SCREEN_DELAY, LEVEL_PAGE_LOOP
  	LEVEL_LAST_FRAME:
		la $t5, LEVEL
		lw $t5, 0($t5)

		beq $t5, 0, LEVEL_1 # If level is 0, go to game level 1
		beq $t5, 1, LEVEL_2 # If level is 1, go to game level 2
		beq $t5, 2, LEVEL_3 # If level is 2, go to game level 3
		beq $t5, 3, FINISHED_PAGE # If level is 3, go to the finished page
		j MAIN_MENU_PAGE # Else, jump to main menu page
	
#####################################################################
# Win page, for when the player collects all the coins in a level
#####################################################################
WIN_PAGE:	
	# Push return address to stack.
	addi $sp, $sp, -4
	sw $a0, 0($sp)
    # Draw the win page
	WIN_PAGE_DRAW:
		li $t0, 0x00008728
		sw $t0, 7424($a0)
		sw $t0, 7680($a0)
		sw $t0, 7428($a0)
		sw $t0, 7684($a0)
		sw $t0, 7432($a0)
		sw $t0, 7688($a0)
		sw $t0, 7436($a0)
		sw $t0, 7692($a0)
		sw $t0, 7440($a0)
		sw $t0, 7696($a0)
		sw $t0, 7444($a0)
		sw $t0, 7700($a0)
		sw $t0, 7448($a0)
		sw $t0, 7704($a0)
		sw $t0, 7452($a0)
		sw $t0, 7708($a0)
		sw $t0, 7456($a0)
		sw $t0, 7712($a0)
		sw $t0, 7460($a0)
		sw $t0, 7716($a0)
		sw $t0, 7464($a0)
		sw $t0, 7720($a0)
		sw $t0, 7468($a0)
		sw $t0, 7724($a0)
		sw $t0, 7472($a0)
		sw $t0, 7728($a0)
		sw $t0, 7476($a0)
		sw $t0, 7732($a0)
		sw $t0, 7480($a0)
		sw $t0, 7736($a0)
		sw $t0, 7484($a0)
		sw $t0, 7740($a0)
		sw $t0, 7488($a0)
		sw $t0, 7744($a0)
		sw $t0, 7492($a0)
		sw $t0, 7748($a0)
		sw $t0, 7496($a0)
		sw $t0, 7752($a0)
		sw $t0, 7500($a0)
		sw $t0, 7756($a0)
		sw $t0, 7504($a0)
		sw $t0, 7760($a0)
		sw $t0, 7508($a0)
		sw $t0, 7764($a0)
		sw $t0, 7512($a0)
		sw $t0, 7768($a0)
		sw $t0, 7516($a0)
		sw $t0, 7772($a0)
		sw $t0, 7520($a0)
		sw $t0, 7776($a0)
		sw $t0, 7524($a0)
		sw $t0, 7780($a0)
		sw $t0, 7528($a0)
		sw $t0, 7784($a0)
		sw $t0, 7532($a0)
		sw $t0, 7788($a0)
		sw $t0, 7536($a0)
		sw $t0, 7792($a0)
		sw $t0, 7540($a0)
		sw $t0, 7796($a0)
		sw $t0, 7544($a0)
		sw $t0, 7800($a0)
		sw $t0, 7548($a0)
		sw $t0, 7804($a0)
		sw $t0, 7552($a0)
		sw $t0, 7808($a0)
		sw $t0, 7556($a0)
		sw $t0, 7812($a0)
		sw $t0, 7560($a0)
		sw $t0, 7816($a0)
		sw $t0, 7564($a0)
		sw $t0, 7820($a0)
		sw $t0, 7568($a0)
		sw $t0, 7824($a0)
		sw $t0, 7572($a0)
		sw $t0, 7828($a0)
		sw $t0, 7576($a0)
		sw $t0, 7832($a0)
		sw $t0, 7580($a0)
		sw $t0, 7836($a0)
		sw $t0, 7584($a0)
		sw $t0, 7840($a0)
		sw $t0, 7588($a0)
		sw $t0, 7844($a0)
		sw $t0, 7592($a0)
		sw $t0, 7848($a0)
		sw $t0, 7596($a0)
		sw $t0, 7852($a0)
		sw $t0, 7600($a0)
		sw $t0, 7856($a0)
		sw $t0, 7604($a0)
		sw $t0, 7860($a0)
		sw $t0, 7608($a0)
		sw $t0, 7864($a0)
		sw $t0, 7612($a0)
		sw $t0, 7868($a0)
		sw $t0, 7616($a0)
		sw $t0, 7872($a0)
		sw $t0, 7620($a0)
		sw $t0, 7876($a0)
		sw $t0, 7624($a0)
		sw $t0, 7880($a0)
		sw $t0, 7628($a0)
		sw $t0, 7884($a0)
		sw $t0, 7632($a0)
		sw $t0, 7888($a0)
		sw $t0, 7636($a0)
		sw $t0, 7892($a0)
		sw $t0, 7640($a0)
		sw $t0, 7896($a0)
		sw $t0, 7644($a0)
		sw $t0, 7900($a0)
		sw $t0, 7648($a0)
		sw $t0, 7904($a0)
		sw $t0, 7652($a0)
		sw $t0, 7908($a0)
		sw $t0, 7656($a0)
		sw $t0, 7912($a0)
		sw $t0, 7660($a0)
		sw $t0, 7916($a0)
		sw $t0, 7664($a0)
		sw $t0, 7920($a0)
		sw $t0, 7668($a0)
		sw $t0, 7924($a0)
		sw $t0, 7672($a0)
		sw $t0, 7928($a0)
		sw $t0, 7676($a0)
		sw $t0, 7932($a0)
		sw $t0, 7172($a0)
		sw $t0, 7176($a0)
		sw $t0, 7180($a0)
		sw $t0, 7184($a0)
		sw $t0, 7188($a0)
		sw $t0, 7192($a0)
		sw $t0, 7196($a0)
		sw $t0, 7200($a0)
		sw $t0, 7204($a0)
		sw $t0, 7208($a0)
		sw $t0, 7212($a0)
		sw $t0, 7216($a0)
		sw $t0, 7220($a0)
		sw $t0, 7224($a0)
		sw $t0, 7168($a0)
		sw $t0, 6912($a0)
		sw $t0, 6916($a0)
		sw $t0, 6920($a0)
		sw $t0, 6924($a0)
		sw $t0, 6928($a0)
		sw $t0, 6944($a0)
		sw $t0, 6940($a0)
		sw $t0, 6664($a0)
		sw $t0, 7360($a0)
		sw $t0, 7364($a0)
		sw $t0, 7368($a0)
		sw $t0, 7372($a0)
		sw $t0, 7376($a0)
		sw $t0, 7380($a0)
		sw $t0, 7384($a0)
		sw $t0, 7388($a0)
		sw $t0, 7392($a0)
		sw $t0, 7396($a0)
		sw $t0, 7400($a0)
		sw $t0, 7404($a0)
		sw $t0, 7408($a0)
		sw $t0, 7152($a0)
		sw $t0, 7156($a0)
		sw $t0, 7160($a0)
		sw $t0, 7164($a0)
		sw $t0, 7412($a0)
		sw $t0, 7416($a0)
		sw $t0, 7420($a0)
		
		
		li $t0, 0x001a9b3f
		sw $t0, 6932($a0)
		sw $t0, 6936($a0)
		sw $t0, 6672($a0)
		sw $t0, 6676($a0)
		sw $t0, 6680($a0)
		sw $t0, 6684($a0)
		sw $t0, 6668($a0)
		sw $t0, 6656($a0)
		sw $t0, 6400($a0)
		sw $t0, 6656($a0)
		sw $t0, 6404($a0)
		sw $t0, 6660($a0)
		sw $t0, 6408($a0)
		sw $t0, 6412($a0)
		sw $t0, 6416($a0)
		sw $t0, 6144($a0)
		sw $t0, 6148($a0)
		sw $t0, 6152($a0)
		sw $t0, 7120($a0)
		sw $t0, 7124($a0)
		sw $t0, 7128($a0)
		sw $t0, 7132($a0)
		sw $t0, 7136($a0)
		sw $t0, 7140($a0)
		sw $t0, 7144($a0)
		sw $t0, 7148($a0)
		sw $t0, 6880($a0)
		sw $t0, 6884($a0)
		sw $t0, 6888($a0)
		sw $t0, 6892($a0)
		sw $t0, 6896($a0)
		sw $t0, 6900($a0)
		sw $t0, 6904($a0)
		sw $t0, 6908($a0)
		
		
		li $t0, 0x00dddd0d
		sw $t0, 6632($a0)
		sw $t0, 6636($a0)
		sw $t0, 6640($a0)
		sw $t0, 6644($a0)
		sw $t0, 6120($a0)
		sw $t0, 6124($a0)
		sw $t0, 6128($a0)
		sw $t0, 6132($a0)
		sw $t0, 5860($a0)
		sw $t0, 5864($a0)
		sw $t0, 5868($a0)
		sw $t0, 5872($a0)
		sw $t0, 5876($a0)
		sw $t0, 5880($a0)
		sw $t0, 6356($a0)
		sw $t0, 6360($a0)
		sw $t0, 6364($a0)
		sw $t0, 6624($a0)
		sw $t0, 6628($a0)
		sw $t0, 5360($a0)
		sw $t0, 5364($a0)
		sw $t0, 5368($a0)
		sw $t0, 5356($a0)
		sw $t0, 5092($a0)
		sw $t0, 5096($a0)
		sw $t0, 5100($a0)
		sw $t0, 5104($a0)
		sw $t0, 5844($a0)
		sw $t0, 5848($a0)
		sw $t0, 5852($a0)
		sw $t0, 5584($a0)
		sw $t0, 5588($a0)
		sw $t0, 5592($a0)
		sw $t0, 5596($a0)
		sw $t0, 5600($a0)
		
		
		li $t0, 0x00edcf0e
		sw $t0, 6864($a0)
		sw $t0, 6868($a0)
		sw $t0, 6872($a0)
		sw $t0, 6876($a0)
		sw $t0, 6608($a0)
		sw $t0, 6612($a0)
		sw $t0, 6616($a0)
		sw $t0, 6100($a0)
		sw $t0, 6104($a0)
		sw $t0, 6108($a0)
		sw $t0, 6112($a0)
		sw $t0, 5608($a0)
		sw $t0, 5612($a0)
		sw $t0, 5616($a0)
		sw $t0, 5620($a0)
		sw $t0, 4840($a0)
		sw $t0, 4844($a0)
		sw $t0, 4848($a0)
		sw $t0, 4852($a0)
		sw $t0, 4856($a0)
		sw $t0, 6372($a0)
		sw $t0, 6376($a0)
		sw $t0, 6380($a0)
		sw $t0, 6384($a0)
		sw $t0, 6388($a0)
		sw $t0, 6392($a0)
		sw $t0, 6348($a0)
		sw $t0, 6344($a0)
		sw $t0, 6600($a0)
		sw $t0, 6848($a0)
		sw $t0, 6596($a0)
		sw $t0, 6852($a0)
		sw $t0, 7100($a0)
		sw $t0, 7104($a0)
		sw $t0, 7228($a0)
		sw $t0, 7232($a0)
		sw $t0, 7236($a0)
		sw $t0, 7240($a0)
		sw $t0, 7244($a0)
		sw $t0, 7248($a0)
		sw $t0, 6996($a0)
		sw $t0, 7252($a0)
		sw $t0, 7000($a0)
		sw $t0, 7256($a0)
		sw $t0, 7004($a0)
		sw $t0, 7260($a0)
		sw $t0, 7008($a0)
		sw $t0, 7264($a0)
		sw $t0, 7012($a0)
		sw $t0, 7268($a0)
		sw $t0, 7016($a0)
		sw $t0, 7272($a0)
		sw $t0, 7020($a0)
		sw $t0, 7276($a0)
		sw $t0, 7024($a0)
		sw $t0, 7280($a0)
		sw $t0, 7028($a0)
		sw $t0, 7284($a0)
		sw $t0, 7032($a0)
		sw $t0, 7288($a0)
		sw $t0, 7036($a0)
		sw $t0, 7292($a0)
		sw $t0, 7040($a0)
		sw $t0, 7296($a0)
		sw $t0, 7044($a0)
		sw $t0, 7300($a0)
		sw $t0, 7048($a0)
		sw $t0, 7304($a0)
		sw $t0, 7052($a0)
		sw $t0, 7308($a0)
		sw $t0, 7056($a0)
		sw $t0, 7312($a0)
		sw $t0, 7060($a0)
		sw $t0, 7316($a0)
		sw $t0, 6972($a0)
		sw $t0, 6976($a0)
		sw $t0, 6980($a0)
		sw $t0, 6984($a0)
		sw $t0, 6988($a0)
		sw $t0, 6992($a0)
		sw $t0, 6472($a0)
		sw $t0, 6728($a0)
		sw $t0, 6476($a0)
		sw $t0, 6732($a0)
		sw $t0, 6480($a0)
		sw $t0, 6736($a0)
		sw $t0, 6484($a0)
		sw $t0, 6740($a0)
		sw $t0, 6488($a0)
		sw $t0, 6744($a0)
		sw $t0, 6492($a0)
		sw $t0, 6748($a0)
		sw $t0, 6496($a0)
		sw $t0, 6752($a0)
		sw $t0, 6500($a0)
		sw $t0, 6756($a0)
		sw $t0, 6504($a0)
		sw $t0, 6760($a0)
		sw $t0, 6508($a0)
		sw $t0, 6764($a0)
		sw $t0, 6512($a0)
		sw $t0, 6768($a0)
		sw $t0, 6516($a0)
		sw $t0, 6772($a0)
		sw $t0, 6520($a0)
		sw $t0, 6776($a0)
		sw $t0, 6524($a0)
		sw $t0, 6780($a0)
		sw $t0, 6528($a0)
		sw $t0, 6784($a0)
		sw $t0, 6532($a0)
		sw $t0, 6788($a0)
		sw $t0, 6536($a0)
		sw $t0, 6792($a0)
		sw $t0, 3928($a0)
		sw $t0, 3932($a0)
		sw $t0, 3936($a0)
		sw $t0, 3940($a0)
		sw $t0, 3944($a0)
		sw $t0, 3948($a0)
		sw $t0, 3952($a0)
		sw $t0, 3956($a0)
		sw $t0, 3668($a0)
		sw $t0, 3672($a0)
		sw $t0, 3676($a0)
		sw $t0, 3680($a0)
		sw $t0, 3684($a0)
		sw $t0, 3688($a0)
		sw $t0, 3692($a0)
		sw $t0, 3696($a0)
		sw $t0, 3700($a0)
		sw $t0, 3704($a0)
		sw $t0, -184($a0)
		sw $t0, 328($a0)
		sw $t0, 840($a0)
		sw $t0, 1608($a0)
		sw $t0, 2376($a0)
		sw $t0, 2632($a0)
		sw $t0, 2120($a0)
		sw $t0, 1864($a0)
		sw $t0, 1096($a0)
		sw $t0, 1352($a0)
		sw $t0, 584($a0)
		sw $t0, 344($a0)
		sw $t0, -180($a0)
		sw $t0, -176($a0)
		sw $t0, -172($a0)
		sw $t0, -168($a0)
		sw $t0, -164($a0)
		sw $t0, -160($a0)
		sw $t0, -156($a0)
		sw $t0, -152($a0)
		sw $t0, -148($a0)
		sw $t0, -144($a0)
		sw $t0, -140($a0)
		sw $t0, -136($a0)
		sw $t0, -132($a0)
		sw $t0, -128($a0)
		sw $t0, 4192($a0)
		sw $t0, 4448($a0)
		sw $t0, 4704($a0)
		sw $t0, 4960($a0)
		sw $t0, 5216($a0)
		sw $t0, 5472($a0)
		sw $t0, 5728($a0)
		sw $t0, 5984($a0)
		sw $t0, 6240($a0)
		sw $t0, 4452($a0)
		sw $t0, 4708($a0)
		sw $t0, 4964($a0)
		sw $t0, 5220($a0)
		sw $t0, 5476($a0)
		sw $t0, 5732($a0)
		sw $t0, 5988($a0)
		sw $t0, 6244($a0)
		sw $t0, 4456($a0)
		sw $t0, 4712($a0)
		sw $t0, 4968($a0)
		sw $t0, 5224($a0)
		sw $t0, 5480($a0)
		sw $t0, 5736($a0)
		sw $t0, 5992($a0)
		sw $t0, 6248($a0)
		sw $t0, 4460($a0)
		sw $t0, 4716($a0)
		sw $t0, 4972($a0)
		sw $t0, 5228($a0)
		sw $t0, 5484($a0)
		sw $t0, 5740($a0)
		sw $t0, 5996($a0)
		sw $t0, 6252($a0)
		sw $t0, 4464($a0)
		sw $t0, 4720($a0)
		sw $t0, 4976($a0)
		sw $t0, 5232($a0)
		sw $t0, 5488($a0)
		sw $t0, 5744($a0)
		sw $t0, 6000($a0)
		sw $t0, 6256($a0)
		sw $t0, 4188($a0)
		sw $t0, 4196($a0)
		sw $t0, 4200($a0)
		sw $t0, 4204($a0)
		sw $t0, 4208($a0)
		sw $t0, 4212($a0)
		sw $t0, 3960($a0)
		sw $t0, 3708($a0)
		sw $t0, 2952($a0)
		sw $t0, 3716($a0)
		sw $t0, 3208($a0)
		sw $t0, 3712($a0)
		sw $t0, 3664($a0)
		sw $t0, 3404($a0)
		sw $t0, -120($a0)
		sw $t0, 136($a0)
		sw $t0, 392($a0)
		sw $t0, 648($a0)
		sw $t0, 904($a0)
		sw $t0, 1160($a0)
		sw $t0, 1416($a0)
		sw $t0, 1672($a0)
		sw $t0, 1928($a0)
		sw $t0, 2184($a0)
		sw $t0, 2440($a0)
		sw $t0, 2696($a0)
		sw $t0, -124($a0)
		sw $t0, -164($a0)
		sw $t0, 92($a0)
		sw $t0, 348($a0)
		sw $t0, 604($a0)
		sw $t0, 860($a0)
		sw $t0, 1116($a0)
		sw $t0, 1372($a0)
		sw $t0, 1628($a0)
		sw $t0, 1884($a0)
		sw $t0, 2140($a0)
		sw $t0, -116($a0)
		sw $t0, 140($a0)
		sw $t0, 396($a0)
		sw $t0, 652($a0)
		sw $t0, 908($a0)
		sw $t0, 1164($a0)
		sw $t0, 1420($a0)
		sw $t0, 1676($a0)
		sw $t0, 1932($a0)
		sw $t0, 2188($a0)
		sw $t0, 2372($a0)
		sw $t0, -192($a0)
		sw $t0, 64($a0)
		sw $t0, 320($a0)
		sw $t0, 576($a0)
		sw $t0, 832($a0)
		sw $t0, 1088($a0)
		sw $t0, 1344($a0)
		sw $t0, 1600($a0)
		sw $t0, 1856($a0)
		sw $t0, 2112($a0)
		sw $t0, 2628($a0)
		sw $t0, 840($a0)
		sw $t0, 844($a0)
		sw $t0, 848($a0)
		sw $t0, 1076($a0)
		sw $t0, 1072($a0)
		sw $t0, 1332($a0)
		sw $t0, 1328($a0)
		sw $t0, 1588($a0)
		sw $t0, 1608($a0)
		sw $t0, 1840($a0)
		sw $t0, 1844($a0)
		sw $t0, 2096($a0)
		sw $t0, 2100($a0)
		sw $t0, 2616($a0)
		sw $t0, 2884($a0)
		sw $t0, 2876($a0)
		sw $t0, 3136($a0)
		sw $t0, 3140($a0)
		sw $t0, 3144($a0)
		sw $t0, 2872($a0)
		sw $t0, 2612($a0)
		sw $t0, 2352($a0)
		sw $t0, 3132($a0)
		sw $t0, 916($a0)
		sw $t0, 920($a0)
		sw $t0, 2396($a0)
		sw $t0, 2444($a0)
		sw $t0, 912($a0)
		sw $t0, 1176($a0)
		sw $t0, 1180($a0)
		sw $t0, 1432($a0)
		sw $t0, 1688($a0)
		sw $t0, 1944($a0)
		sw $t0, 2200($a0)
		sw $t0, 2456($a0)
		sw $t0, 1436($a0)
		sw $t0, 1692($a0)
		sw $t0, 1948($a0)
		sw $t0, 2204($a0)
		sw $t0, 2460($a0)
		sw $t0, 2708($a0)
		sw $t0, 2712($a0)
		sw $t0, 2960($a0)
		sw $t0, 2964($a0)
		sw $t0, 3212($a0)
		sw $t0, 3216($a0)
		sw $t0, 80($a0)
		sw $t0, 2152($a0)
		sw $t0, 2400($a0)
		sw $t0, 2648($a0)
		sw $t0, 2644($a0)
		sw $t0, 2380($a0)
		sw $t0, 2384($a0)
		sw $t0, 2388($a0)
		sw $t0, 2396($a0)
		sw $t0, 2392($a0)
		sw $t0, 2124($a0)
		sw $t0, 2128($a0)
		sw $t0, 2132($a0)
		sw $t0, 2136($a0)
		sw $t0, 2144($a0)
		sw $t0, 2148($a0)
		sw $t0, 2140($a0)
		sw $t0, 1868($a0)
		sw $t0, 1612($a0)
		sw $t0, 96($a0)
		sw $t0, 328($a0)
		sw $t0, 844($a0)
		sw $t0, 1108($a0)
		sw $t0, 1388($a0)
		sw $t0, 1388($a0)
		sw $t0, 2428($a0)
		sw $t0, 2432($a0)
		sw $t0, 3148($a0)
		sw $t0, 2888($a0)
		sw $t0, 2640($a0)
		sw $t0, 2896($a0)
		sw $t0, 2904($a0)
		sw $t0, 3412($a0)
		sw $t0, 3164($a0)
		sw $t0, 3420($a0)
		sw $t0, 3168($a0)
		sw $t0, 3424($a0)
		sw $t0, 2656($a0)
		sw $t0, 2912($a0)
		sw $t0, 2672($a0)
		sw $t0, 2928($a0)
		sw $t0, 3184($a0)
		sw $t0, 3440($a0)
		sw $t0, 2920($a0)
		sw $t0, 3176($a0)
		sw $t0, 3192($a0)
		sw $t0, 3448($a0)
		sw $t0, 3452($a0)
		sw $t0, 3460($a0)
		sw $t0, 132($a0)
		sw $t0, 388($a0)
		sw $t0, 644($a0)
		sw $t0, 900($a0)
		sw $t0, 1156($a0)
		sw $t0, 1412($a0)
		sw $t0, 1668($a0)
		sw $t0, 1924($a0)
		sw $t0, 2180($a0)
		sw $t0, 2436($a0)
		sw $t0, 2692($a0)
		sw $t0, 2948($a0)
		sw $t0, 3204($a0)
		sw $t0, 120($a0)
		sw $t0, 376($a0)
		sw $t0, 632($a0)
		sw $t0, 124($a0)
		sw $t0, 380($a0)
		sw $t0, 636($a0)
		sw $t0, 128($a0)
		sw $t0, 384($a0)
		sw $t0, 640($a0)
		sw $t0, 892($a0)
		sw $t0, 1148($a0)
		sw $t0, 1404($a0)
		sw $t0, 1660($a0)
		sw $t0, 1916($a0)
		sw $t0, 2172($a0)
		sw $t0, 896($a0)
		sw $t0, 1152($a0)
		sw $t0, 1408($a0)
		sw $t0, 1664($a0)
		sw $t0, 1920($a0)
		sw $t0, 2176($a0)
		sw $t0, 2156($a0)
		sw $t0, 2412($a0)
		sw $t0, 2160($a0)
		sw $t0, 2416($a0)
		sw $t0, 2164($a0)
		sw $t0, 2420($a0)
		sw $t0, 2168($a0)
		sw $t0, 2424($a0)
		sw $t0, 2404($a0)
		sw $t0, 2408($a0)
		sw $t0, 2680($a0)
		sw $t0, 2684($a0)
		sw $t0, 2940($a0)
		sw $t0, 1616($a0)
		sw $t0, 1620($a0)
		sw $t0, 844($a0)
		sw $t0, 1100($a0)
		sw $t0, 1356($a0)
		sw $t0, 84($a0)
		sw $t0, 340($a0)
		sw $t0, 596($a0)
		sw $t0, 88($a0)
		sw $t0, 344($a0)
		sw $t0, 600($a0)
		sw $t0, 92($a0)
		sw $t0, 348($a0)
		sw $t0, 604($a0)
		sw $t0, 96($a0)
		sw $t0, 352($a0)
		sw $t0, 608($a0)
		sw $t0, 100($a0)
		sw $t0, 356($a0)
		sw $t0, 612($a0)
		sw $t0, 104($a0)
		sw $t0, 360($a0)
		sw $t0, 616($a0)
		sw $t0, 108($a0)
		sw $t0, 364($a0)
		sw $t0, 620($a0)
		sw $t0, 112($a0)
		sw $t0, 368($a0)
		sw $t0, 624($a0)
		sw $t0, 116($a0)
		sw $t0, 372($a0)
		sw $t0, 628($a0)
		sw $t0, 332($a0)
		sw $t0, 588($a0)
		sw $t0, 336($a0)
		sw $t0, 592($a0)
		sw $t0, 860($a0)
		sw $t0, 1116($a0)
		sw $t0, 1372($a0)
		sw $t0, 1628($a0)
		sw $t0, 1884($a0)
		sw $t0, 852($a0)
		sw $t0, 876($a0)
		sw $t0, 1132($a0)
		sw $t0, 1388($a0)
		sw $t0, 1644($a0)
		sw $t0, 1900($a0)
		sw $t0, 884($a0)
		sw $t0, 1140($a0)
		sw $t0, 1396($a0)
		sw $t0, 1652($a0)
		sw $t0, 1124($a0)
		sw $t0, 1380($a0)
		sw $t0, 1636($a0)
		sw $t0, 3400($a0)
		sw $t0, 3660($a0)
		sw $t0, 3920($a0)
		sw $t0, 3924($a0)
		sw $t0, 3928($a0)
		sw $t0, 4184($a0)
		sw $t0, 4216($a0)
		sw $t0, 3964($a0)
		sw $t0, 3968($a0)
		sw $t0, 3464($a0)
		sw $t0, 3972($a0)
		sw $t0, 4220($a0)
		sw $t0, 4468($a0)
		sw $t0, 4724($a0)
		sw $t0, 4980($a0)
		sw $t0, 5236($a0)
		sw $t0, 5492($a0)
		sw $t0, 5748($a0)
		sw $t0, 6004($a0)
		sw $t0, 6260($a0)
		sw $t0, 6540($a0)
		sw $t0, 6796($a0)
		sw $t0, 7064($a0)
		sw $t0, 7320($a0)
		sw $t0, 1588($a0)
		sw $t0, 2356($a0)
		sw $t0, 1584($a0)
		sw $t0, 820($a0)
		sw $t0, 824($a0)
		sw $t0, 828($a0)
		sw $t0, 2368($a0)
		sw $t0, -184($a0)
		sw $t0, 72($a0)
		sw $t0, 328($a0)
		sw $t0, 584($a0)
		sw $t0, 840($a0)
		sw $t0, 1096($a0)
		sw $t0, 1352($a0)
		sw $t0, 1608($a0)
		sw $t0, 1864($a0)
		sw $t0, 2120($a0)
		sw $t0, 76($a0)
		sw $t0, -188($a0)
		sw $t0, 68($a0)
		sw $t0, 324($a0)
		sw $t0, 580($a0)
		sw $t0, 836($a0)
		sw $t0, 1092($a0)
		sw $t0, 1348($a0)
		sw $t0, 1604($a0)
		sw $t0, 1860($a0)
		sw $t0, 2116($a0)
		
		
		li $t0, 0x00000000
		sw $t0, 848($a0)
		sw $t0, 1104($a0)
		sw $t0, 1360($a0)
		sw $t0, 1364($a0)
		sw $t0, 1368($a0)
		sw $t0, 1112($a0)
		sw $t0, 1624($a0)
		sw $t0, 1880($a0)
		sw $t0, 1872($a0)
		sw $t0, 1876($a0)
		sw $t0, 864($a0)
		sw $t0, 868($a0)
		sw $t0, 892($a0)
		sw $t0, 1128($a0)
		sw $t0, 1384($a0)
		sw $t0, 1640($a0)
		sw $t0, 1640($a0)
		sw $t0, 1896($a0)
		sw $t0, 1892($a0)
		sw $t0, 1888($a0)
		sw $t0, 1632($a0)
		sw $t0, 1376($a0)
		sw $t0, 1120($a0)
		sw $t0, 880($a0)
		sw $t0, 1136($a0)
		sw $t0, 1392($a0)
		sw $t0, 1648($a0)
		sw $t0, 1904($a0)
		sw $t0, 1908($a0)
		sw $t0, 1908($a0)
		sw $t0, 1656($a0)
		sw $t0, 1400($a0)
		sw $t0, 1144($a0)
		sw $t0, 888($a0)
		sw $t0, 1912($a0)
		sw $t0, 3432($a0)
		sw $t0, 3436($a0)
		sw $t0, 2936($a0)
		sw $t0, 2636($a0)
		sw $t0, 2892($a0)
		sw $t0, 3152($a0)
		sw $t0, 3408($a0)
		sw $t0, 3156($a0)
		sw $t0, 2900($a0)
		sw $t0, 3160($a0)
		sw $t0, 3416($a0)
		sw $t0, 2908($a0)
		sw $t0, 2652($a0)
		sw $t0, 2660($a0)
		sw $t0, 2660($a0)
		sw $t0, 2916($a0)
		sw $t0, 3172($a0)
		sw $t0, 3428($a0)
		sw $t0, 2664($a0)
		sw $t0, 2668($a0)
		sw $t0, 2924($a0)
		sw $t0, 3180($a0)
		sw $t0, 2676($a0)
		sw $t0, 2932($a0)
		sw $t0, 3188($a0)
		sw $t0, 3444($a0)
		sw $t0, 3196($a0)
		sw $t0, 3456($a0)
		sw $t0, 2688($a0)
		sw $t0, 2944($a0)
		sw $t0, 3200($a0)
		sw $t0, 2012($a0)
		sw $t0, 2268($a0)
		sw $t0, 2524($a0)
		sw $t0, 2264($a0)
		sw $t0, 2536($a0)
		sw $t0, 2540($a0)
		sw $t0, 1956($a0)
		sw $t0, 1960($a0)
		sw $t0, 1964($a0)
		sw $t0, 1972($a0)
		sw $t0, 1976($a0)
		sw $t0, 1980($a0)
		sw $t0, 2228($a0)
		sw $t0, 2484($a0)
		sw $t0, 2488($a0)
		sw $t0, 2492($a0)
		sw $t0, 2236($a0)
		sw $t0, 1988($a0)
		sw $t0, 1992($a0)
		sw $t0, 1996($a0)
		sw $t0, 2248($a0)
		sw $t0, 2504($a0)
		sw $t0, 2004($a0)
		sw $t0, 2260($a0)
		sw $t0, 2516($a0)
		sw $t0, 2008($a0)
		sw $t0, 2020($a0)
		sw $t0, 2276($a0)
		sw $t0, 2532($a0)
		sw $t0, 2036($a0)
		sw $t0, 2548($a0)
		sw $t0, 2216($a0)
		sw $t0, 2472($a0)
		sw $t0, 4932($a0)
		sw $t0, 5188($a0)
		sw $t0, 5696($a0)
		sw $t0, 5448($a0)
		sw $t0, 5176($a0)
		sw $t0, 5180($a0)
		sw $t0, 5184($a0)
		sw $t0, 6176($a0)
		sw $t0, 6436($a0)
		sw $t0, 6692($a0)
		sw $t0, 6688($a0)
		sw $t0, 6696($a0)
		sw $t0, 6952($a0)
		sw $t0, 872($a0)
		sw $t0, 6564($a0)
		sw $t0, 6572($a0)
		sw $t0, 856($a0)
		sw $t0, 6948($a0)
		
		
		li $t0, 0x00ff0000
		sw $t0, 4920($a0)
		sw $t0, 5172($a0)
		sw $t0, 5424($a0)
		sw $t0, 5680($a0)
		sw $t0, 5684($a0)
		sw $t0, 5428($a0)
		sw $t0, 5688($a0)
		sw $t0, 5940($a0)
		sw $t0, 6196($a0)
		sw $t0, 6456($a0)
		sw $t0, 6460($a0)
		sw $t0, 6212($a0)
		sw $t0, 4924($a0)
		sw $t0, 6204($a0)
		sw $t0, 5944($a0)
		sw $t0, 6200($a0)
		sw $t0, 6208($a0)
		sw $t0, 4928($a0)
		sw $t0, 5964($a0)
		sw $t0, 6468($a0)
		sw $t0, 6464($a0)
		sw $t0, 5936($a0)
		sw $t0, 6192($a0)
		sw $t0, 6452($a0)
		sw $t0, 6712($a0)
		sw $t0, 6716($a0)
		sw $t0, 6720($a0)
		sw $t0, 6724($a0)
		sw $t0, 5968($a0)
		sw $t0, 5712($a0)
		sw $t0, 6224($a0)
		sw $t0, 5456($a0)
		sw $t0, 5196($a0)
		sw $t0, 4936($a0)
		sw $t0, 6968($a0)
		sw $t0, 6964($a0)
		sw $t0, 6708($a0)
		sw $t0, 6960($a0)
		sw $t0, 6704($a0)
		sw $t0, 6448($a0)
		sw $t0, 6700($a0)
		sw $t0, 6444($a0)
		sw $t0, 6188($a0)
		sw $t0, 6184($a0)
		sw $t0, 5928($a0)
		sw $t0, 5932($a0)
		sw $t0, 5676($a0)
		sw $t0, 5420($a0)
		sw $t0, 5168($a0)
		sw $t0, 4916($a0)
		sw $t0, 4912($a0)
		sw $t0, 5164($a0)
		sw $t0, 4660($a0)
		sw $t0, 5432($a0)
		sw $t0, 6956($a0)
		sw $t0, 6440($a0)
		sw $t0, 4668($a0)
		sw $t0, 4672($a0)
		sw $t0, 4676($a0)
		sw $t0, 4664($a0)
		sw $t0, 4400($a0)
		sw $t0, 4396($a0)
		sw $t0, 4908($a0)
		sw $t0, 4904($a0)
		sw $t0, 4940($a0)
		sw $t0, 5200($a0)
		sw $t0, 5716($a0)
		sw $t0, 5972($a0)
		sw $t0, 4680($a0)
		sw $t0, 4416($a0)
		sw $t0, 4412($a0)
		sw $t0, 4408($a0)
		
		
		li $t0, 0x00ffffff
		sw $t0, 5948($a0)
		sw $t0, 5692($a0)
		sw $t0, 5692($a0)
		sw $t0, 5952($a0)
		sw $t0, 5444($a0)
		sw $t0, 5192($a0)
		sw $t0, 5452($a0)
		sw $t0, 5440($a0)
		sw $t0, 5436($a0)
		sw $t0, 7072($a0)
		sw $t0, 7080($a0)
		
		
		li $t0, 0x00ff8800
		sw $t0, 5704($a0)
		sw $t0, 5708($a0)
		sw $t0, 5700($a0)
		sw $t0, 5956($a0)
		sw $t0, 6216($a0)
		sw $t0, 6220($a0)
		sw $t0, 5960($a0)
		
		
		li $t0, 0x00ba21ba
		sw $t0, 6576($a0)
		
		
		li $t0, 0x00bc27bc
		sw $t0, 6296($a0)
		sw $t0, 6548($a0)
		sw $t0, 6808($a0)
		sw $t0, 6552($a0)
		
		
		li $t0, 0x00b230b2
		sw $t0, 6300($a0)
		sw $t0, 6556($a0)
		sw $t0, 6320($a0)
		
		
		li $t0, 0x008cea8c
		sw $t0, 6812($a0)
		sw $t0, 6816($a0)
		sw $t0, 6560($a0)
		sw $t0, 6304($a0)
		sw $t0, 6308($a0)
		sw $t0, 6312($a0)
		sw $t0, 6568($a0)
		sw $t0, 6820($a0)
		sw $t0, 6828($a0)
		sw $t0, 6316($a0)
		
		
		li $t0, 0x0015ed15
		sw $t0, 6036($a0)
		sw $t0, 6292($a0)
		sw $t0, 6288($a0)
		sw $t0, 6544($a0)
		sw $t0, 6800($a0)
		sw $t0, 6804($a0)
		sw $t0, 6040($a0)
		sw $t0, 5784($a0)
		sw $t0, 5528($a0)
		sw $t0, 5788($a0)
		sw $t0, 6044($a0)
		sw $t0, 5536($a0)
		sw $t0, 5792($a0)
		sw $t0, 6048($a0)
		sw $t0, 5796($a0)
		sw $t0, 6052($a0)
		sw $t0, 6056($a0)
		sw $t0, 6060($a0)
		sw $t0, 5800($a0)
		sw $t0, 6064($a0)
		sw $t0, 6324($a0)
		sw $t0, 6580($a0)
		sw $t0, 6836($a0)
		sw $t0, 7092($a0)
		sw $t0, 6832($a0)
		sw $t0, 7088($a0)
		sw $t0, 7344($a0)
		sw $t0, 7084($a0)
		sw $t0, 7340($a0)
		sw $t0, 7336($a0)
		sw $t0, 7076($a0)
		sw $t0, 7332($a0)
		sw $t0, 7068($a0)
		sw $t0, 7324($a0)
		sw $t0, 7328($a0)

	# Display Score
	li $a0, BASE_ADDRESS
	addi $a0, $a0, 4036
	move $a2, SCORE
	li $a1, BLACK
	jal BEGIN_DRAW_NUMBERS
	
	# Add delay
 	li $v0, 32
  	li $a0, 20
  	syscall

  	subi SCREEN_DELAY,SCREEN_DELAY,1

    # Check if player presses the P key to restart the game
  	li $a0, 0xffff0000
  	lw $t2, 4($a0) # This assumes $t9 is set to 0xfff0000 from before
	beq $t2, 0x70, P_KEY # ASCII code of 'p' is 0x70
  	# addi $sp, $sp, 4
	lw $a0, 0($sp)
	addi $sp, $sp, 4
  	bgtz SCREEN_DELAY, WIN_PAGE
  	WIN_LAST_FRAME:
		li SCREEN_DELAY, 100
		la $t9, LEVEL
		lw $t9, 0($t9)
		beq $t9, 3, JUMP_TO_FINISH # If player won last level, go to the finished page

		j LEVEL_PAGE # If still on a level that isn't the last, go to next level
		JUMP_TO_FINISH:
			jal CLEAR # Clear screen
			# Push return address to stack.
			li $t4, BASE_ADDRESS
			li $t1, 0
			li $t2, 0x008A8AD1 # Background colour
			FINISHED_PAGE_BACKGROUND_LOOP:
				sw $t2, 0($t4)
				addi $t4, $t4, 4 # advance to next pixel position in display
				addi $t1, $t1, -1 # decrement number of pixels
				bne $t1, -2176, FINISHED_PAGE_BACKGROUND_LOOP # repeat while number of pixels is not -1920

			li $a0, BASE_ADDRESS
			j FINISHED_PAGE
	
#####################################################################
# FINISHED Page, for when the player finishes all the levels
#####################################################################
FINISHED_PAGE:
	# Draw the finished page (once player won all levels)
	DRAW_FINISHED_PAGE:
		addi	$sp, $sp, -4
		sw	$ra, 0($sp)
		addi $sp, $sp, -4
		sw $a0, 0($sp)
		li $t0, 0x0018186d
		sw $t0, 3096($a0)
		sw $t0, 3100($a0)
		sw $t0, 1640($a0)
		sw $t0, 1896($a0)
		sw $t0, 2152($a0)
		sw $t0, 2408($a0)
		sw $t0, 2664($a0)
		sw $t0, 1052($a0)
		sw $t0, 1308($a0)
		sw $t0, 1564($a0)
		sw $t0, 1820($a0)
		sw $t0, 2076($a0)
		sw $t0, 1060($a0)
		sw $t0, 1316($a0)
		sw $t0, 1572($a0)
		sw $t0, 1828($a0)
		sw $t0, 2084($a0)
		sw $t0, 888($a0)
		sw $t0, 1144($a0)
		sw $t0, 1400($a0)
		sw $t0, 1656($a0)
		sw $t0, 1912($a0)
		sw $t0, 2168($a0)
		sw $t0, 2424($a0)
		sw $t0, 2680($a0)
		sw $t0, 896($a0)
		sw $t0, 1152($a0)
		sw $t0, 1408($a0)
		sw $t0, 1664($a0)
		sw $t0, 1920($a0)
		sw $t0, 2176($a0)
		sw $t0, 2432($a0)
		sw $t0, 2688($a0)
		sw $t0, 2596($a0)
		sw $t0, 2852($a0)
		sw $t0, 3108($a0)
		sw $t0, 3104($a0)
		sw $t0, 2076($a0)
		sw $t0, 2080($a0)
		sw $t0, 2340($a0)
		sw $t0, 1068($a0)
		sw $t0, 1324($a0)
		sw $t0, 1580($a0)
		sw $t0, 1836($a0)
		sw $t0, 2092($a0)
		sw $t0, 2348($a0)
		sw $t0, 1072($a0)
		sw $t0, 1076($a0)
		sw $t0, 2352($a0)
		sw $t0, 2356($a0)
		sw $t0, 1332($a0)
		sw $t0, 1588($a0)
		sw $t0, 1844($a0)
		sw $t0, 2100($a0)
		sw $t0, 1084($a0)
		sw $t0, 1340($a0)
		sw $t0, 1596($a0)
		sw $t0, 1852($a0)
		sw $t0, 2108($a0)
		sw $t0, 2364($a0)
		sw $t0, 2368($a0)
		sw $t0, 2372($a0)
		sw $t0, 1092($a0)
		sw $t0, 1348($a0)
		sw $t0, 1604($a0)
		sw $t0, 1860($a0)
		sw $t0, 2116($a0)
		sw $t0, 2628($a0)
		sw $t0, 1108($a0)
		sw $t0, 1364($a0)
		sw $t0, 1620($a0)
		sw $t0, 1876($a0)
		sw $t0, 2132($a0)
		sw $t0, 2388($a0)
		sw $t0, 2644($a0)
		sw $t0, 2648($a0)
		sw $t0, 2652($a0)
		sw $t0, 600($a0)
		sw $t0, 596($a0)
		sw $t0, 604($a0)
		sw $t0, 852($a0)
		sw $t0, 608($a0)
		sw $t0, 864($a0)
		sw $t0, 2656($a0)
		sw $t0, 2400($a0)
		sw $t0, 1644($a0)
		sw $t0, 1648($a0)
		sw $t0, 1904($a0)
		sw $t0, 2160($a0)
		sw $t0, 2416($a0)
		sw $t0, 2672($a0)
		sw $t0, 2668($a0)
		sw $t0, 1928($a0)
		sw $t0, 1932($a0)
		sw $t0, 1936($a0)
		sw $t0, 1940($a0)
		sw $t0, 1684($a0)
		sw $t0, 1420($a0)
		sw $t0, 1424($a0)
		sw $t0, 1672($a0)
		sw $t0, 2184($a0)
		sw $t0, 2440($a0)
		sw $t0, 2700($a0)
		sw $t0, 2704($a0)
		sw $t0, 2452($a0)
		sw $t0, 1436($a0)
		sw $t0, 1440($a0)
		sw $t0, 1444($a0)
		sw $t0, 1692($a0)
		sw $t0, 1948($a0)
		sw $t0, 2204($a0)
		sw $t0, 2460($a0)
		sw $t0, 2716($a0)
		sw $t0, 2720($a0)
		sw $t0, 2724($a0)
		sw $t0, 1452($a0)
		sw $t0, 1456($a0)
		sw $t0, 1460($a0)
		sw $t0, 944($a0)
		sw $t0, 1200($a0)
		sw $t0, 1456($a0)
		sw $t0, 1712($a0)
		sw $t0, 1968($a0)
		sw $t0, 2224($a0)
		sw $t0, 2480($a0)
		sw $t0, 2736($a0)
		sw $t0, 1980($a0)
		sw $t0, 1984($a0)
		sw $t0, 1988($a0)
		sw $t0, 1992($a0)
		sw $t0, 1736($a0)
		sw $t0, 1476($a0)
		sw $t0, 1472($a0)
		sw $t0, 1724($a0)
		sw $t0, 2236($a0)
		sw $t0, 2492($a0)
		sw $t0, 2752($a0)
		sw $t0, 2756($a0)
		sw $t0, 2504($a0)
		sw $t0, 1492($a0)
		sw $t0, 1496($a0)
		sw $t0, 1488($a0)
		sw $t0, 1500($a0)
		sw $t0, 1744($a0)
		sw $t0, 2000($a0)
		sw $t0, 2256($a0)
		sw $t0, 2512($a0)
		sw $t0, 2768($a0)
		sw $t0, 2772($a0)
		sw $t0, 2776($a0)
		sw $t0, 2780($a0)
		sw $t0, 476($a0)
		sw $t0, 732($a0)
		sw $t0, 988($a0)
		sw $t0, 1244($a0)
		sw $t0, 1500($a0)
		sw $t0, 1756($a0)
		sw $t0, 2012($a0)
		sw $t0, 2268($a0)
		sw $t0, 2524($a0)
		sw $t0, 4368($a0)
		sw $t0, 4624($a0)
		sw $t0, 4880($a0)
		sw $t0, 5136($a0)
		sw $t0, 5392($a0)
		sw $t0, 5648($a0)
		sw $t0, 5904($a0)
		sw $t0, 4372($a0)
		sw $t0, 4376($a0)
		sw $t0, 4632($a0)
		sw $t0, 4888($a0)
		sw $t0, 5144($a0)
		sw $t0, 5400($a0)
		sw $t0, 5656($a0)
		sw $t0, 5912($a0)
		sw $t0, 5140($a0)
		sw $t0, 4384($a0)
		sw $t0, 4640($a0)
		sw $t0, 4896($a0)
		sw $t0, 5152($a0)
		sw $t0, 5408($a0)
		sw $t0, 5664($a0)
		sw $t0, 5920($a0)
		sw $t0, 4392($a0)
		sw $t0, 4648($a0)
		sw $t0, 4904($a0)
		sw $t0, 5160($a0)
		sw $t0, 5416($a0)
		sw $t0, 5672($a0)
		sw $t0, 5928($a0)
		sw $t0, 6412($a0)
		sw $t0, 6416($a0)
		sw $t0, 6420($a0)
		sw $t0, 6424($a0)
		sw $t0, 6428($a0)
		sw $t0, 6432($a0)
		sw $t0, 6436($a0)
		sw $t0, 6440($a0)
		sw $t0, 6444($a0)
		sw $t0, 4412($a0)
		sw $t0, 4416($a0)
		sw $t0, 4420($a0)
		sw $t0, 4672($a0)
		sw $t0, 4928($a0)
		sw $t0, 5184($a0)
		sw $t0, 5440($a0)
		sw $t0, 5696($a0)
		sw $t0, 5952($a0)
		sw $t0, 4408($a0)
		sw $t0, 4424($a0)
		sw $t0, 4432($a0)
		sw $t0, 4688($a0)
		sw $t0, 4944($a0)
		sw $t0, 5200($a0)
		sw $t0, 5456($a0)
		sw $t0, 5712($a0)
		sw $t0, 5968($a0)
		sw $t0, 5204($a0)
		sw $t0, 5208($a0)
		sw $t0, 5212($a0)
		sw $t0, 5468($a0)
		sw $t0, 5724($a0)
		sw $t0, 5980($a0)
		sw $t0, 5480($a0)
		sw $t0, 5484($a0)
		sw $t0, 5488($a0)
		sw $t0, 5476($a0)
		sw $t0, 5232($a0)
		sw $t0, 4972($a0)
		sw $t0, 4968($a0)
		sw $t0, 5220($a0)
		sw $t0, 5732($a0)
		sw $t0, 6248($a0)
		sw $t0, 5988($a0)
		sw $t0, 6252($a0)
		sw $t0, 6000($a0)
		sw $t0, 6236($a0)
		sw $t0, 6224($a0)
		sw $t0, 5952($a0)
		sw $t0, 6208($a0)
		sw $t0, 4228($a0)
		sw $t0, 4232($a0)
		sw $t0, 4236($a0)
		sw $t0, 4240($a0)
		sw $t0, 4496($a0)
		sw $t0, 4484($a0)
		sw $t0, 4740($a0)
		sw $t0, 4996($a0)
		sw $t0, 5252($a0)
		sw $t0, 5508($a0)
		sw $t0, 5764($a0)
		sw $t0, 6020($a0)
		sw $t0, 6276($a0)
		sw $t0, 6032($a0)
		sw $t0, 5528($a0)
		sw $t0, 5784($a0)
		sw $t0, 6040($a0)
		sw $t0, 6296($a0)
		sw $t0, 6300($a0)
		sw $t0, 6304($a0)
		sw $t0, 5792($a0)
		sw $t0, 6048($a0)
		sw $t0, 5272($a0)
		sw $t0, 5276($a0)
		sw $t0, 5280($a0)
		sw $t0, 5536($a0)
		sw $t0, 5288($a0)
		sw $t0, 5544($a0)
		sw $t0, 5800($a0)
		sw $t0, 6056($a0)
		sw $t0, 6312($a0)
		sw $t0, 4776($a0)
		sw $t0, 5296($a0)
		sw $t0, 5552($a0)
		sw $t0, 5808($a0)
		sw $t0, 6064($a0)
		sw $t0, 6320($a0)
		sw $t0, 5040($a0)
		sw $t0, 5300($a0)
		sw $t0, 5304($a0)
		sw $t0, 5308($a0)
		sw $t0, 5564($a0)
		sw $t0, 5820($a0)
		sw $t0, 6076($a0)
		sw $t0, 6332($a0)
		sw $t0, 4808($a0)
		sw $t0, 4812($a0)
		sw $t0, 4816($a0)
		sw $t0, 5076($a0)
		sw $t0, 5060($a0)
		sw $t0, 5316($a0)
		sw $t0, 5572($a0)
		sw $t0, 5576($a0)
		sw $t0, 5580($a0)
		sw $t0, 6348($a0)
		sw $t0, 6344($a0)
		sw $t0, 6340($a0)
		sw $t0, 6352($a0)
		sw $t0, 6100($a0)
		sw $t0, 5584($a0)
		sw $t0, 5844($a0)
		sw $t0, 6372($a0)
		sw $t0, 4324($a0)
		sw $t0, 4580($a0)
		sw $t0, 4836($a0)
		sw $t0, 5092($a0)
		sw $t0, 5348($a0)
		sw $t0, 5604($a0)
		sw $t0, 5860($a0)
		
		
		li $t0, 0x00e5d440
		sw $t0, 7432($a0)
		sw $t0, 7436($a0)
		sw $t0, 7440($a0)
		sw $t0, 7444($a0)
		sw $t0, 7448($a0)
		sw $t0, 7452($a0)
		sw $t0, 7180($a0)
		sw $t0, 7184($a0)
		sw $t0, 7188($a0)
		sw $t0, 7192($a0)
		sw $t0, 528($a0)
		sw $t0, 532($a0)
		sw $t0, 536($a0)
		sw $t0, 784($a0)
		sw $t0, 788($a0)
		sw $t0, 792($a0)
		sw $t0, 796($a0)
		sw $t0, 780($a0)
		sw $t0, 1032($a0)
		sw $t0, 1036($a0)
		sw $t0, 1040($a0)
		sw $t0, 1044($a0)
		sw $t0, 1048($a0)
		sw $t0, 1292($a0)
		sw $t0, 1296($a0)
		sw $t0, 1300($a0)
		sw $t0, 1304($a0)
		sw $t0, 1552($a0)
		sw $t0, 1556($a0)
		sw $t0, 1560($a0)
		sw $t0, 1808($a0)
		sw $t0, 2064($a0)
		sw $t0, 1812($a0)
		sw $t0, 2068($a0)
		sw $t0, 1816($a0)
		sw $t0, 2072($a0)
		sw $t0, 1548($a0)
		sw $t0, 1804($a0)
		sw $t0, 1800($a0)
		sw $t0, 1288($a0)
		sw $t0, 1544($a0)
		sw $t0, 2784($a0)
		sw $t0, 3040($a0)
		sw $t0, 3296($a0)
		sw $t0, 3552($a0)
		sw $t0, 2788($a0)
		sw $t0, 3044($a0)
		sw $t0, 3300($a0)
		sw $t0, 3556($a0)
		sw $t0, 2792($a0)
		sw $t0, 3048($a0)
		sw $t0, 3304($a0)
		sw $t0, 3560($a0)
		sw $t0, 2796($a0)
		sw $t0, 3052($a0)
		sw $t0, 3308($a0)
		sw $t0, 3564($a0)
		sw $t0, 2532($a0)
		sw $t0, 2536($a0)
		sw $t0, 3812($a0)
		sw $t0, 3816($a0)
		sw $t0, 3820($a0)
		sw $t0, 2800($a0)
		sw $t0, 3056($a0)
		sw $t0, 3312($a0)
		sw $t0, 3568($a0)
		sw $t0, 2540($a0)
		
		
		li $t0, 0x0018185e
		sw $t0, 6280($a0)
		sw $t0, 6284($a0)
		sw $t0, 6288($a0)
		
		
		li $t0, 0x00d8d85b
		sw $t0, 6012($a0)
		sw $t0, 6016($a0)
		sw $t0, 6268($a0)
		sw $t0, 6272($a0)
		sw $t0, 6528($a0)
		sw $t0, 6784($a0)
		sw $t0, 6788($a0)
		sw $t0, 6532($a0)
		sw $t0, 6536($a0)
		sw $t0, 6796($a0)
		sw $t0, 6540($a0)
		sw $t0, 6796($a0)
		sw $t0, 7048($a0)
		sw $t0, 6792($a0)
		sw $t0, 6544($a0)
		sw $t0, 6028($a0)
		sw $t0, 5772($a0)
		sw $t0, 5768($a0)
		sw $t0, 5512($a0)
		sw $t0, 5760($a0)
		sw $t0, 5504($a0)
		sw $t0, 6024($a0)
		sw $t0, 5776($a0)
		sw $t0, 5516($a0)
		sw $t0, 7396($a0)
		sw $t0, 7900($a0)
		sw $t0, 7644($a0)
		sw $t0, 7392($a0)
		sw $t0, 7648($a0)
		sw $t0, 7904($a0)
		sw $t0, 7652($a0)
		sw $t0, 7908($a0)
		sw $t0, 7656($a0)
		sw $t0, 7912($a0)
		sw $t0, -212($a0)
		sw $t0, 44($a0)
		sw $t0, -208($a0)
		sw $t0, 48($a0)
		sw $t0, -216($a0)
		sw $t0, -204($a0)
		sw $t0, 3660($a0)
		sw $t0, 3760($a0)
		sw $t0, 664($a0)
		sw $t0, 7256($a0)
		sw $t0, 3852($a0)
		sw $t0, 1776($a0)
		sw $t0, 6644($a0)
		
		addi	$sp, $sp, 4
		# Return to sender.
		lw	$ra, 0($sp)
		addi	$sp, $sp, 4

    # Stay on this page for 3 seconds
	li $v0, 32	# Delay for FPS/
	li $a0, 3000
	syscall

    # Check if player presses the P key to restart the game
  	li $a0, 0xffff0000
  	lw $t2, 4($a0) # This assumes $t9 is set to 0xfff0000 from before
	beq $t2, 0x70, P_KEY # ASCII code of 'p' is 0x70

	j MAIN_MENU_PAGE

#####################################################################
# EXIT Screen, for when the player chooses to 'Exit' the game
#####################################################################
EXIT_SCREEN:
	li $t0, BASE_ADDRESS # $t0 stores the base address for display
	li $t1, 0
	li $t2, BLACK
    # Set background to black
	BLACK_BACKGROUND_LOOP:
	sw $t2, 0($t0)
	addi $t0, $t0, 4 # advance to next pixel position in display
	addi $t1, $t1, -1 # decrement number of pixels
	bne $t1, -2176, BLACK_BACKGROUND_LOOP # repeat while number of pixels is not -1920

	li $a0, BASE_ADDRESS # $a0 stores the base address for display
	# Push return address to stack.
	# Write the word "Exiting"
	addi $sp, $sp, -4
	sw $ra, 0($sp)
	addi $sp, $sp, -4
	sw $a0, 0($sp)
	li $t0, 0x00fcf9f9
	sw $t0, 3604($a0)
	sw $t0, 3860($a0)
	sw $t0, 3608($a0)
	sw $t0, 3864($a0)
	sw $t0, 3612($a0)
	sw $t0, 3868($a0)
	sw $t0, 3616($a0)
	sw $t0, 3872($a0)
	sw $t0, 4884($a0)
	sw $t0, 5140($a0)
	sw $t0, 4888($a0)
	sw $t0, 5144($a0)
	sw $t0, 4892($a0)
	sw $t0, 5148($a0)
	sw $t0, 4896($a0)
	sw $t0, 5152($a0)
	sw $t0, 4900($a0)
	sw $t0, 5156($a0)
	sw $t0, 2348($a0)
	sw $t0, 2604($a0)
	sw $t0, 2860($a0)
	sw $t0, 3116($a0)
	sw $t0, 2352($a0)
	sw $t0, 2608($a0)
	sw $t0, 2864($a0)
	sw $t0, 3120($a0)
	sw $t0, 3380($a0)
	sw $t0, 3636($a0)
	sw $t0, 3892($a0)
	sw $t0, 4148($a0)
	sw $t0, 3384($a0)
	sw $t0, 3640($a0)
	sw $t0, 3896($a0)
	sw $t0, 4152($a0)
	sw $t0, 4412($a0)
	sw $t0, 4668($a0)
	sw $t0, 4924($a0)
	sw $t0, 5180($a0)
	sw $t0, 4416($a0)
	sw $t0, 4672($a0)
	sw $t0, 4928($a0)
	sw $t0, 5184($a0)
	sw $t0, 2364($a0)
	sw $t0, 2620($a0)
	sw $t0, 2876($a0)
	sw $t0, 3132($a0)
	sw $t0, 2368($a0)
	sw $t0, 2624($a0)
	sw $t0, 2880($a0)
	sw $t0, 3136($a0)
	sw $t0, 2376($a0)
	sw $t0, 2632($a0)
	sw $t0, 2380($a0)
	sw $t0, 2636($a0)
	sw $t0, 2384($a0)
	sw $t0, 2640($a0)
	sw $t0, 2388($a0)
	sw $t0, 2644($a0)
	sw $t0, 2392($a0)
	sw $t0, 2648($a0)
	sw $t0, 2396($a0)
	sw $t0, 2652($a0)
	sw $t0, 2896($a0)
	sw $t0, 3152($a0)
	sw $t0, 3408($a0)
	sw $t0, 3664($a0)
	sw $t0, 3920($a0)
	sw $t0, 4176($a0)
	sw $t0, 4432($a0)
	sw $t0, 4688($a0)
	sw $t0, 2900($a0)
	sw $t0, 3156($a0)
	sw $t0, 3412($a0)
	sw $t0, 3668($a0)
	sw $t0, 3924($a0)
	sw $t0, 4180($a0)
	sw $t0, 4436($a0)
	sw $t0, 4692($a0)
	sw $t0, 4936($a0)
	sw $t0, 5192($a0)
	sw $t0, 4940($a0)
	sw $t0, 5196($a0)
	sw $t0, 4944($a0)
	sw $t0, 5200($a0)
	sw $t0, 4948($a0)
	sw $t0, 5204($a0)
	sw $t0, 4952($a0)
	sw $t0, 5208($a0)
	sw $t0, 4956($a0)
	sw $t0, 5212($a0)
	sw $t0, 2404($a0)
	sw $t0, 2660($a0)
	sw $t0, 2408($a0)
	sw $t0, 2664($a0)
	sw $t0, 2412($a0)
	sw $t0, 2668($a0)
	sw $t0, 2416($a0)
	sw $t0, 2672($a0)
	sw $t0, 2420($a0)
	sw $t0, 2676($a0)
	sw $t0, 2424($a0)
	sw $t0, 2680($a0)
	sw $t0, 2924($a0)
	sw $t0, 3180($a0)
	sw $t0, 3436($a0)
	sw $t0, 3692($a0)
	sw $t0, 3948($a0)
	sw $t0, 4204($a0)
	sw $t0, 4460($a0)
	sw $t0, 4716($a0)
	sw $t0, 4972($a0)
	sw $t0, 5228($a0)
	sw $t0, 2928($a0)
	sw $t0, 3184($a0)
	sw $t0, 3440($a0)
	sw $t0, 3696($a0)
	sw $t0, 3952($a0)
	sw $t0, 4208($a0)
	sw $t0, 4464($a0)
	sw $t0, 4720($a0)
	sw $t0, 4976($a0)
	sw $t0, 5232($a0)
	sw $t0, 2464($a0)
	sw $t0, 2720($a0)
	sw $t0, 2976($a0)
	sw $t0, 3232($a0)
	sw $t0, 3488($a0)
	sw $t0, 3744($a0)
	sw $t0, 4000($a0)
	sw $t0, 4256($a0)
	sw $t0, 4512($a0)
	sw $t0, 4768($a0)
	sw $t0, 5024($a0)
	sw $t0, 5280($a0)
	sw $t0, 2468($a0)
	sw $t0, 2724($a0)
	sw $t0, 2980($a0)
	sw $t0, 3236($a0)
	sw $t0, 3492($a0)
	sw $t0, 3748($a0)
	sw $t0, 4004($a0)
	sw $t0, 4260($a0)
	sw $t0, 4516($a0)
	sw $t0, 4772($a0)
	sw $t0, 5028($a0)
	sw $t0, 5284($a0)
	sw $t0, 2316($a0)
	sw $t0, 2572($a0)
	sw $t0, 2828($a0)
	sw $t0, 3084($a0)
	sw $t0, 3340($a0)
	sw $t0, 3596($a0)
	sw $t0, 3852($a0)
	sw $t0, 4108($a0)
	sw $t0, 4364($a0)
	sw $t0, 4620($a0)
	sw $t0, 4876($a0)
	sw $t0, 5132($a0)
	sw $t0, 2320($a0)
	sw $t0, 2576($a0)
	sw $t0, 2832($a0)
	sw $t0, 3088($a0)
	sw $t0, 3344($a0)
	sw $t0, 3600($a0)
	sw $t0, 3856($a0)
	sw $t0, 4112($a0)
	sw $t0, 4368($a0)
	sw $t0, 4624($a0)
	sw $t0, 4880($a0)
	sw $t0, 5136($a0)
	sw $t0, 2324($a0)
	sw $t0, 2580($a0)
	sw $t0, 2328($a0)
	sw $t0, 2584($a0)
	sw $t0, 2332($a0)
	sw $t0, 2588($a0)
	sw $t0, 2336($a0)
	sw $t0, 2592($a0)
	sw $t0, 2340($a0)
	sw $t0, 2596($a0)
	sw $t0, 4396($a0)
	sw $t0, 4652($a0)
	sw $t0, 4908($a0)
	sw $t0, 5164($a0)
	sw $t0, 4400($a0)
	sw $t0, 4656($a0)
	sw $t0, 4912($a0)
	sw $t0, 5168($a0)
	sw $t0, 2432($a0)
	sw $t0, 2688($a0)
	sw $t0, 2436($a0)
	sw $t0, 2692($a0)
	sw $t0, 2440($a0)
	sw $t0, 2696($a0)
	sw $t0, 2444($a0)
	sw $t0, 2700($a0)
	sw $t0, 2448($a0)
	sw $t0, 2704($a0)
	sw $t0, 2452($a0)
	sw $t0, 2708($a0)
	sw $t0, 2952($a0)
	sw $t0, 3208($a0)
	sw $t0, 3464($a0)
	sw $t0, 3720($a0)
	sw $t0, 3976($a0)
	sw $t0, 4232($a0)
	sw $t0, 4488($a0)
	sw $t0, 4744($a0)
	sw $t0, 5000($a0)
	sw $t0, 2956($a0)
	sw $t0, 3212($a0)
	sw $t0, 3468($a0)
	sw $t0, 3724($a0)
	sw $t0, 3980($a0)
	sw $t0, 4236($a0)
	sw $t0, 4492($a0)
	sw $t0, 4748($a0)
	sw $t0, 5004($a0)
	sw $t0, 4992($a0)
	sw $t0, 5248($a0)
	sw $t0, 4996($a0)
	sw $t0, 5252($a0)
	sw $t0, 5000($a0)
	sw $t0, 5256($a0)
	sw $t0, 5004($a0)
	sw $t0, 5260($a0)
	sw $t0, 5008($a0)
	sw $t0, 5264($a0)
	sw $t0, 5012($a0)
	sw $t0, 5268($a0)
	sw $t0, 4800($a0)
	sw $t0, 5056($a0)
	sw $t0, 5312($a0)
	sw $t0, 4804($a0)
	sw $t0, 5060($a0)
	sw $t0, 5316($a0)
	sw $t0, 2496($a0)
	sw $t0, 2752($a0)
	sw $t0, 3008($a0)
	sw $t0, 3264($a0)
	sw $t0, 3520($a0)
	sw $t0, 3776($a0)
	sw $t0, 4032($a0)
	sw $t0, 4288($a0)
	sw $t0, 4544($a0)
	sw $t0, 2500($a0)
	sw $t0, 2756($a0)
	sw $t0, 3012($a0)
	sw $t0, 3268($a0)
	sw $t0, 3524($a0)
	sw $t0, 3780($a0)
	sw $t0, 4036($a0)
	sw $t0, 4292($a0)
	sw $t0, 4548($a0)
	sw $t0, 4792($a0)
	sw $t0, 5048($a0)
	sw $t0, 5304($a0)
	sw $t0, 4796($a0)
	sw $t0, 5052($a0)
	sw $t0, 5308($a0)
	sw $t0, 3248($a0)
	sw $t0, 3504($a0)
	sw $t0, 3760($a0)
	sw $t0, 4016($a0)
	sw $t0, 4272($a0)
	sw $t0, 4528($a0)
	sw $t0, 3252($a0)
	sw $t0, 3508($a0)
	sw $t0, 3764($a0)
	sw $t0, 4020($a0)
	sw $t0, 4276($a0)
	sw $t0, 4532($a0)
	sw $t0, 4784($a0)
	sw $t0, 5040($a0)
	sw $t0, 5296($a0)
	sw $t0, 4788($a0)
	sw $t0, 5044($a0)
	sw $t0, 5300($a0)
	sw $t0, 2992($a0)
	sw $t0, 3024($a0)
	sw $t0, 3280($a0)
	sw $t0, 3536($a0)
	sw $t0, 3792($a0)
	sw $t0, 4048($a0)
	sw $t0, 4304($a0)
	sw $t0, 4560($a0)
	sw $t0, 4816($a0)
	sw $t0, 5072($a0)
	sw $t0, 5328($a0)
	sw $t0, 3028($a0)
	sw $t0, 3284($a0)
	sw $t0, 3540($a0)
	sw $t0, 3796($a0)
	sw $t0, 4052($a0)
	sw $t0, 4308($a0)
	sw $t0, 4564($a0)
	sw $t0, 4820($a0)
	sw $t0, 5076($a0)
	sw $t0, 5332($a0)
	sw $t0, 5076($a0)
	sw $t0, 5332($a0)
	sw $t0, 5080($a0)
	sw $t0, 5336($a0)
	sw $t0, 5084($a0)
	sw $t0, 5340($a0)
	sw $t0, 5088($a0)
	sw $t0, 5344($a0)
	sw $t0, 5092($a0)
	sw $t0, 5348($a0)
	sw $t0, 5096($a0)
	sw $t0, 5352($a0)
	sw $t0, 4580($a0)
	sw $t0, 4836($a0)
	sw $t0, 4584($a0)
	sw $t0, 4840($a0)
	sw $t0, 4328($a0)
	sw $t0, 4584($a0)
	sw $t0, 4332($a0)
	sw $t0, 4588($a0)
	sw $t0, 4324($a0)
	sw $t0, 4840($a0)
	sw $t0, 5096($a0)
	sw $t0, 4332($a0)
	sw $t0, 4588($a0)
	sw $t0, 4336($a0)
	sw $t0, 4592($a0)
	sw $t0, 4848($a0)
	sw $t0, 4340($a0)
	sw $t0, 4596($a0)
	sw $t0, 4852($a0)
	sw $t0, 2512($a0)
	sw $t0, 2768($a0)
	sw $t0, 2516($a0)
	sw $t0, 2772($a0)
	sw $t0, 2520($a0)
	sw $t0, 2776($a0)
	sw $t0, 2524($a0)
	sw $t0, 2780($a0)
	sw $t0, 2528($a0)
	sw $t0, 2784($a0)
	sw $t0, 2532($a0)
	sw $t0, 2788($a0)
	sw $t0, 2536($a0)
	sw $t0, 2792($a0)
	sw $t0, 3044($a0)
	sw $t0, 3048($a0)
	sw $t0, 5040($a0)
	sw $t0, 5044($a0)
	sw $t0, 2476($a0)
	sw $t0, 2732($a0)
	sw $t0, 2988($a0)
	sw $t0, 2480($a0)
	sw $t0, 2736($a0)
	sw $t0, 2992($a0)
	sw $t0, 2484($a0)
	sw $t0, 2740($a0)
	sw $t0, 2996($a0)
	sw $t0, 2472($a0)
	sw $t0, 2728($a0)
	sw $t0, 2984($a0)
	sw $t0, 2476($a0)
	sw $t0, 2732($a0)
	sw $t0, 2988($a0)
	
	addi	$sp, $sp, 4
	# Return to sender.
	lw	$ra, 0($sp)
	addi	$sp, $sp, 4

    # Stay on this page for 2 seconds before ending the game
	li $v0, 32	# Delay for FPS/
	li $a0, 2000
	syscall	
	j END # Jump to END branch
