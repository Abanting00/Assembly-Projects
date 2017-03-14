;NAME: Abigail Banting

        assume cs:cseg, ds:cseg
cseg    segment 'code'
        org 100h

start:
		jmp realstart
		msg db "ASCII TABLE"
		title1 db "  |        Char      |        Dec       |        Hex       |        Oct       | "
		end1 db "   Press s: Next Page                                       Press q: Quit       "
		end2 db "   Press s: Next Page       Press a: Previous Page          Press q: Quit       "
		saved dw 25*80 dup(?)
		
realstart:

        mov ax, 0b800h					;Move the es to point at the top left corner of the screen
        mov es, ax

				COMMENT !
		------------------------------
		   For saving the screen to 
		        restore later
		------------------------------
		!

		sub bx,bx						;Set up base index and counter for saved screen 
		mov cx, 25*80
save:		 						    ;Copy the  current screen's to saved array before implementing changes
		mov ax, es:[bx]
		mov saved[bx],ax
		inc bx
		inc bx
		loop save
		
				COMMENT !
		------------------------------
			  For clear screen
		------------------------------
		!
		
		mov cx, 80*25					;Set up counter for clear screen
		sub di, di
		mov ax, 4720h

print:									;Clear the screen to color red
		mov es:[di],ax
		add di,2 
		loop print
        
				COMMENT !
		------------------------------
		 For title msg "Ascii Table"
		------------------------------
		!
		
		mov cx, 11 					    ;set up counter and set color to red on white
		mov ah, 47h							
		sub si, si				
		mov di, 70						;initialize where msg should print 
		
AsciiSetup:							    ;prints the the title: ASCII TABLE 
		mov al, msg[si]
		mov es:[di], ax
		add di, 2
		inc si
		loop AsciiSetup
		
				COMMENT !
		------------------------------
			  For Printing Table
		------------------------------
		!
		
Dash:							 	   ;set up counter and starting position for table
		mov cx, 80*3-7					
		mov ax, 47cdh				   ;make ax to output dashes with red on white color 
		mov di, 164
		mov dx, 2					  
		jmp DashCounter

adds:
		add di, 2
		add dx, 1 
		loop DashCounter
cont1:									
		add di,164						;Set y = 3 
		add dx, 2 
		jmp PrintDash2

cont2:									
		add di, 2884					;Set y = 22
		add dx, 2
		jmp PrintDash2

cont3:									;cont3 to cont9 makes sure to print at the right position and the right 
		mov es:[di], 47bbh				;character for table 
		add di, 4
		add dx, 2
		loop DashCounter
cont4:
		mov es:[di], 47bch
		add di, 4
		add dx, 2
		loop DashCounter
cont5:
		mov es:[di], 47cbh
		jmp adds
cont6:
		mov es:[di], 47ceh
		jmp adds
cont7:
		mov es:[di], 47cah
		jmp adds
cont8:
		mov es:[di], 47b9h
		add di, 4
		add dx, 2
		loop DashCounter
cont9:
		mov es:[di], 47cch
		jmp adds

DashCounter:		
		cmp dx, 80 					   ; makes sure to only print when y = {1,3,22}
		je cont1 					   ;screen position: 160*y +2x
		cmp dx, 160
		je cont2
		
		cmp dx, 78					   ;For printing the left corners of the table 
		je cont3
		cmp dx, 158
		je cont8
		cmp dx, 238
		je cont4
		
		cmp dx, 21						;For printing the top tables column seperator
		je cont5
		cmp dx, 40
		je cont5
		cmp dx, 59
		je cont5
		
		cmp dx, 101						;For printing the second top  tables column seperator
		je cont6
		cmp dx, 120
		je cont6
		cmp dx, 139
		je cont6
		
		cmp dx, 181					    ;For printing the right corners of the table 
		je cont7
		cmp dx, 200
		je cont7
		cmp dx, 219
		je cont7
		
		;cmp dx,
		jmp PrintDash2

PrintDash1:								;Print the table with c9 character 
		mov es:[di], 47c9h
		add di, 2
		inc dx
		loop DashCounter
PrintDash3:								;Print the table with c8 character 
		mov es:[di], 47c8h
		add di, 2
		inc dx
		loop DashCounter
PrintDash2:
		cmp dx, 2
		je PrintDash1
		
		cmp dx, 82
		je cont9
		
		cmp dx, 162 
		je PrintDash3 
		
		mov es:[di], ax					 ;prints the table dashes 
		add di, 2 
		inc dx
		loop DashCounter

		
				COMMENT !
		------------------------------
		For table header "Char..."
		and table ending "Press s:..."
		------------------------------
		!
		
Titlesetup:							  ;Set up counter, position, index, and color for title1
		mov di, 320
		mov ax, 4700h
		mov cx, 80
		sub si, si 

Print3:								   ;Prints string title1
		mov al, title1[si]			  
		mov es:[di], ax
		add di, 2
		inc si
		loop Print3
		
MsgSetup:							   ;Set up counter, color, position, and index for end1
		mov di, 3680
		mov ax, 4700h
		mov cx, 80
		sub si, si 

Print2:								   ;Print string end1
		mov al, end1[si]
		mov es:[di], ax
		add di, 2
		inc si
		loop Print2

line:
		mov di, 324
		mov cx, 5

line2:
		mov es:[di], 47bah
		add di, 19*2
		loop line2

				COMMENT !
		------------------------------
		  For printing each character 
		------------------------------
		!
		
charSetup:							   ;Set up the char position and color
        mov di, 644
        mov ax, 4700h
        mov bx, ax       
		
char:  								   ;Prints the character and set the position
        mov ah, 47h
		mov es:[di],47bah
        add di,18

		add di, 2
        mov es:[di], ax
        add di, 18
        jmp decimal1

		
up_char:  							    
		
		cmp bl, 255
		je keyboard
        inc bx                          ;Move to the next Character         
        mov ax, bx             
		
		
		cmp al, 18						;Check to see if the current character is the maximum amount
		je keyboard						;of character for that page if not, continue printing 
		cmp al, 36						;else move on to the next page 
		je keyboard						
		cmp bl, 54
		je keyboard
		cmp bl, 72
		je keyboard						;Each keyboard represent another page
		cmp al, 90
		je keyboard
		cmp al, 108
		je keyboard
		cmp al, 126
		je keyboard
		cmp al, 144
		je keyboard
		cmp al, 162
		je keyboard
		cmp al, 180
		je keyboard
		cmp al, 198
		je keyboard
		cmp al, 216
		je keyboard
		cmp al, 234
		je keyboard
		cmp al, 252
		je keyboard
		;cmp bl, 255 
		;je keyboard
		;cmp bx, 256
		jmp char
		
keyboard:					;Check to see if the user pressed the keyboard
		xor ah,ah
		int 16h
		cmp al, 's'			;if a is pressed move on to nextpage
		je nextpage
		
		cmp al, 'a'			;if s is pressed move back to previous page
		je backpage
		
		cmp al, 'q'			;if q is pressed quit the program
		je termjmp
		
		jmp keyboard		;if other keys are pressed other than the previous one
							
		
backpage:
		cmp bl, 18
		je keyboard
		
		cmp bl, 36
		je Msg2Setup2
		
		cmp bl, 255
		je backpage2
		
		sub bx, 36
		jmp pageSetup

backpage2:
		sub bx, 21
		jmp boxSetup

nextpage:
		cmp bl, 255
		je keyboard
		cmp bl, 251
		jg boxSetup

boxSetup:
		mov cx, 80*18				
		mov di, 640
		mov ax, 4720h

box:									
		mov es:[di],ax
		add di,2 
		loop box
		cmp bl, 252
		je Msg2Setup2
		
Msg2Setup:							   
		mov di, 3680
		mov ax, 4700h
		mov cx, 80
		sub si, si 

end2msg:								   
		mov al, end2[si]
		mov es:[di], ax
		add di, 2
		inc si
		loop end2msg		

pageSetup:		
		mov di, 644
		mov ax, bx 
		jmp char

keyboardjmp:
		sub bx, 36
		jmp pageSetup
		
termjmp:
		jmp terminate

Msg2Setup2:							   
		mov di, 3680
		mov ax, 4700h
		mov cx, 80
		sub si, si 

end2msg2:								   
		mov al, end1[si]
		mov es:[di], ax
		add di, 2
		inc si
		loop end2msg2
		
		cmp bl, 36
		je keyboardjmp
		
		;jmp pageSetup
		
		mov di, 1284 
		mov ax, 47bah
		mov cx, 5
		mov dx, 0
fix:
		mov es:[di], ax
		add di, 19*2
		inc dx
		loop fix
		
		cmp dx, 14*5
		je pageSetup
		sub di, 15*2
		mov cx, 6
		loop fix 
		
     		COMMENT !
------------------------------
	  For printing decimal
------------------------------ !
	 
decimal1:
		mov es:[di],47bah
        add di,18
        xor dx,dx 
        mov ah, 00h
          
        mov cx, 000Ah
        idiv cx 
        cmp al, 9
		jle decimal2
		
		mov ah, 00h
		mov cx, 000Ah
		idiv cl 
		mov cl, ah
		
		mov ah, 47h 
		mov ch, 47h
		mov dh, 47h
		
		add ax, 48
		add cx, 48
		add dx, 48
		
		mov es:[di], ax
        add di,2  
        mov es:[di], cx
        add di,2
		mov es:[di], dx
        add di,16
        
        jmp hex1
        
		;jmp up_char
        
        
decimal2:        
        add ax, 48
        add dx, 48  
        
        mov dh, 47h
        mov ah, 47h
        
        mov byte ptr es:[di], ' '
        add di,2  
        mov es:[di], ax
        add di,2
        mov es:[di], dx
        add di,16
        
        jmp hex1
        
oct1:   
		mov es:[di],47bah
        add di,18
		
        mov ax, bx
        xor dx,dx 
        mov ah, 00h
          
        mov cx, 0008h
        idiv cx 
        cmp al, 8
		jl oct2
		
		mov ah, 00h
		mov cx, 0008h
		idiv cl 
		mov cl, ah
		
		mov ah, 47h 
		mov ch, 47h
		mov dh, 47h
		
		add ax, 48
		add cx, 48
		add dx, 48
		
		mov es:[di], ax
        add di,2  
        mov es:[di], cx
        add di,2
		mov es:[di], dx
        add di,16
		
		mov es:[di],47bah
        add di,8
        
        jmp up_char
       
        
        
oct2:        
        add ax, 48
        add dx, 48  
        
        mov dh, 47h
        mov ah, 47h
        
        mov byte ptr es:[di], ' '
        add di,2  
        mov es:[di], ax
        add di,2
        mov es:[di], dx
        add di,16 
		
	    mov es:[di],47bah
        add di,8
        
        jmp up_char    
        
hex1:	
		mov es:[di],47bah
        add di,18
		
        mov ax, bx  
        mov ah, 00h
        mov dx, 0010h 
        idiv dl
        mov dl, ah
        
        add ax, 48
        cmp al, 57
        jg hex3
hex5:    
        add dx, 48
        cmp dl, 57
        jg hex4 
     	  
	  
hex2:
        mov ah, 47h
        mov dh, 47h
        
        mov byte ptr es:[di], ' '
        add di,2
        mov es:[di], ax
        add di,2
        mov es:[di], dx
        add di,16 
        
        jmp oct1
          
  
hex3:   
        add ax, 7
        jmp hex5 

hex4:
        add dx, 7
        jmp hex2    
        
 
terminate: 
		mov cx, 80*25 
		sub bx, bx
		sub di, di 
		
terminate2:
		mov ax, saved[bx]
		mov es:[di], ax
		inc bx
		inc bx 
		add di, 2
		loop terminate2
        
        int 20h
		
cseg	ends
		end start




