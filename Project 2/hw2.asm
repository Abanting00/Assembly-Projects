		;Abigail Banting
		
		assume cs:cseg, ds:cseg 
cseg	segment 'code'
		org 100h
start:
		jmp realstart
		cd db ?						;chose either compression or decompression --> c or d?
		inname db 128 dup(?)		;input file name 
		outname db 128 dup(?) 		;output file name
		
		inh dw ?					;input handle
		outh dw ?					;output handle
		
		freq dw 512 dup(?)			;array for freq table 
		upkid dw 512 dup(?)			;the up branch of the node
		dwnkid dw 512 dup(?)		;the down branch of the node
		parent dw 512 dup(?)		;the parent node 
		
		current_char db ?			;current character 
		current_node dw ?			;current node branch
		
		min dw ?					;min value for building the node
		min2 dw ?					;second min value for building the node 
		i dw ?						;index of the min value 
		j dw ?						;index of the min2 value 
		
		outbyte db ?				;the codified output byte
		outcnt db ?					;check if the outbyte is ready to be written
		
		outchar dw ?				;use for decompression to keep up with the current node
		
		msj1 db 'Error  $'					;Produce error msg if present
		msj2 db 'File was compressed. $'	;Produce after a successful compression
		msj3 db 'File was decompressed. $'	;Produce after a successful decompression
;--------------------------------------------------------------------------------------------------
;							  MAIN FOR COMPRESSION/DECOMPRESSION 
;--------------------------------------------------------------------------------------------------
realstart:
		call CMD 
		call Fill_Freq
		
		cmp cd, 'c'
		je comp
		
		cmp cd, 'd'
		je decomp

		jmp error
comp:
		call Frequency				;set up frequency table of characters
		call Tree					;build the tree with arrays 
		call Compress				;compresss the file
		jmp end_com

decomp:
		call Frequency_2			;set up frequency table of characters from compression
	;	call save_freq
		call Tree					;build the tree with arrays
		call Decompress 			;decompress the file
		jmp end_decomp

error:								;if any error show an erro msg
		mov dx, offset msj1
		mov ah, 9
		int 21h 
		jmp end3

end_com:
		mov dx, offset msj2
		mov ah, 9
		int 21h 
		jmp end3

end_decomp:
		mov dx, offset msj3w
		mov ah, 9
		int 21h 
		jmp end3
		
end3:
		mov	ax,4c00h
		int	21h
;-------------------------------------------------------------------------------------------------
;						TAKES IN THE INPUT AND OUTPUT FILES FROM CMD LINE
;-------------------------------------------------------------------------------------------------
CMD:
		CLD							;clear the destination flag 
		mov si, 81h					;set si to point to the character after the name of the asm file

ComOrDecom:
		lodsb						;load the read byte at address es:di to al and incrament si by one 
		cmp al, 13					;cmp if the read byte is equal to char 13 which is the end of the cmd
		je error					;if equal jmp to error 
		cmp al, ' '					;cmp if the read byte is equal to space
		jbe ComOrDecom 			    ;if al is equal or less than space jump back to RFN
		mov di,offset cd 			;set di to point to the address of inname array

comp_decomp:
		stosb						;store the byte value of al to where di is set 
		lodsb						;load the new read byte at address incrament by si to al 
		cmp al, ' '					;move down to ReadOutName if equal to space 
		ja error

ReadInName:
		lodsb						;load the read byte at begining of output file name 
		mov di,offset inname		;set di to point to the address of outname array
RINcont:
		stosb						;store the byte value of al to start of outname  
		lodsb						;load the new read byte at address incrament by si to al 
		cmp al, ' '
		ja RINcont

ReadOutName:		
		lodsb						;load the read byte at begining of output file name 
		mov di,offset outname 
RONcont:
		stosb
		lodsb
		cmp al, ' '
		ja RONcont

		ret 
;--------------------------------------------------------------------------------------------------
;						SET THE FREQUENCY OF EVERY CHARACTER TO 0
;--------------------------------------------------------------------------------------------------
Fill_Freq:
		mov cx, 0
		mov bx, 0
Fill:
		mov si, offset freq
		mov ax, cx 
		shl ax, 1 
		add si, ax
		mov [si], bx 			;A+i*S where S is the # of byte of the element
		
		inc cx
		cmp cx, 511
		jbe Fill
		
		ret
;--------------------------------------------------------------------------------------------------
;					MAKE THE FREQUENCY TABLE USING CHARACTER AS INDEX
;--------------------------------------------------------------------------------------------------
Frequency: 

OpenFile:
		mov dx, offset inname
		mov al, 0
		mov ah, 3dh
		int 21h
		jc error
		mov inh, ax					;Move the infile ax to inhandle

ReadFile:
		mov ah, 3fh					;set ah to read file
		mov bx, inh					;inhandle 
		mov cx, 1					;set to read one byte
		mov dx, offset current_char	;where the read byte will we stored 
		int 21h 
		cmp ax, 0
		je done						;if no read byte
		
		mov si, offset freq 		;move si pointer to beginning of the freq table 
		mov al, current_char		;move current_char ascii value to al 
		mov ah, 0            		;clear the value of ah inorder to use ax 
		shl ax, 1           		;AX * 2, since freq is a doubleword and EVERY COUNTER IS 2 BYTES.			
		add si, ax           		;si point to the ascii position of the character 
		inc word ptr [si]			;incrament the value of the current character read 
		jmp  ReadFile

done:	
		mov	ah,3eh
		mov	bx,inh 
		int	21h
		
		call save_freq
		
		ret 
;---------------------------------------------------------------------------------------------------		
;								REFERENCE FOR BULDING THE TREE 
;---------------------------------------------------------------------------------------------------
;				loop through the freq array searching for the two lowest number
;						variables i = index , j = index 
;						
;						m = 0,	m2 = 0 
;		
;						for(a = 0; a <= 511; a++){
;							if(freq[a] != 0)
;								if(min == 0)
;									min = freq[a]
;									i = a
;							else if( min > freq[a])
;									min = freq[a]
;									i = a 
;						}
;							freq[i] <-- 0 
;		
;						for(a = 0; a <= 511; a++){
;							if(freq[a] != 0)
;								if(min2 == 0)
;									min2 = freq[a]
;									j = a
;							else if( min2 > freq[a])
;									min2 = freq[a]
;									j = a 
;						}
;						if(min2 == 0) 				;means there is only one minimum left and has reach the root node
;							done
;						else
;							freq[j] <-- 0
;							freq[current_node] = min + min2 
;							parent[i] = current_node
;							parent[j] = current_node
;							upkid[current_node] = i
;							dwnkid[current_node] = j
;							repeat
;
;
;----------------------------------------------------------------------------------------------------
;										BUILD THE HUFFMAN TREE
;----------------------------------------------------------------------------------------------------
Tree:
	
		mov current_node, 256	;set value of current node to 256

BuildTree:
		mov min, 0				;set values of min and min2 = 0
		mov min2, 0 
		mov i, 0
		mov j, 0 
		
		mov cx, 0				;a = 0
		
		
for_min:
		mov si, offset freq		;indexing of the array freq
		mov bx, cx
		shl bx, 1				;BX*2  updating the element
		add si, bx 				;bx or ax?
		
		mov ax, [si]
		cmp ax, word ptr 0				;if(freq[c] == 0)
		je next 
		
		cmp min, 0				;if(min == 0)
		je setmin
		
		cmp min, ax 			;if(min > freq[c])
		jg setmin
		
		jmp next				;else inc to the next element

setmin:
		mov min, ax 			;set min == freq[c] 
		mov i, bx				;set index of min
		jmp next
		
next:							
		inc cx					;inc the counter
		cmp cx, 511				;condition of for loop (c <= 511)
		jbe for_min

		mov si, offset freq		;set the min char freq found as 0 
		add si, i
		mov [si], word ptr 0
		
		mov cx, 0				;i = 0

for_min2:
		mov si, offset freq		;indexing of the array freq
		mov bx, cx
		shl bx, 1				;BX*2  updating the element
		add si, bx 
		
		mov ax, [si]
		cmp ax, word ptr 0				;if(freq[c] == 0)
		je next2 
		
		cmp min2, 0				;if(min2 == 0)
		je setmin2
		
		cmp min2, ax 			;if(min2 > freq[c])
		jg setmin2
		
		jmp next2 				;if(min2 <= freq[c]) jump to next index 

setmin2:
		mov min2, ax 			;set min == freq[c] 
		mov j, bx
		jmp next2
		
next2:							
		inc cx					;inc the counter
		cmp cx, 511				;condition of for loop (c <= 511)
		jbe for_min2
		
		cmp min2, 0				;If no second minimum then it reach the root node 
		je done2

		mov si, offset freq		;set the min char freq found as 0 
		add si, j
		mov [si], word ptr 0		
		
nodes:
		mov si, offset freq 	;freq[current_node] = min + min2
		mov ax, current_node
		shl ax, 1
		add si, ax 
		
		mov bx, min 
		add bx, min2
		mov [si], bx 
		
		mov si, offset parent	;parent[i] = current_node
		mov ax, i 
		add si, ax
		
		mov bx, current_node
		mov [si], bx
		
		mov si, offset parent	;parent[j] = current_node
		mov ax, j 
		add si, ax
		
		mov bx, current_node
		mov [si], bx
		
		mov si, offset upkid	;upkid[current_node] = i 
		mov ax, current_node 
		shl ax, 1
		add si, ax
		
		mov bx, i
		shr bx, 1				;MAKE SURE THAT THE CHARACTER IS IN BX NOT THE ARRAY INDEX CHARACTER 
		mov [si], bx
		
		mov si, offset dwnkid	;dwnkid[current_node] = j 
		mov ax, current_node 
		shl ax, 1
		add si, ax
		
		mov bx, j
		shr bx, 1				;MAKE SURE THAT THE CHARACTER IS IN BX NOT THE ARRAY INDEX CHARACTER 
		mov [si], bx
		
		inc current_node
		jmp BuildTree
		
done2:
		dec current_node
		ret 
;----------------------------------------------------------------------------------------------------
error2:								;FIller for jump error 
		jmp error
;----------------------------------------------------------------------------------------------------
;----------------------------------------------------------------------------------------------------
;						COMPRESSING THE FILE USING THE HUFFMAN TREE 
;----------------------------------------------------------------------------------------------------
Compress: 

		mov dx, offset inname
		mov al, 0
		mov ah, 3dh
		int 21h
		mov inh, ax					;Move the infile ax to inhandle
		
		mov outbyte, 0				;set bit to 0
		mov outcnt, 0				;set counter for bit to 0

ReadFile2:
		mov ah, 3fh					;set ah to read file
		mov bx, inh					;inhandle 
		mov cx, 1					;set to read one byte
		mov dx, offset current_char	;where the read byte will we stored 
		int 21h 
		cmp ax, 0
		je end_compress				;if carry is present means no byte read 

		call huffman_tree
		jmp ReadFile2

end_compress:
		
		cmp outcnt, 8
		jb fill2
		
		jmp done4

fill2:
		call fill_byte

done4:
		mov	ah, 3eh
		mov	bx, inh
		int	21h
		
		mov ah, 3eh
		mov bx, outh 
		int 21h 
		
		ret
;----------------------------------------------------------------------------------------------------
;					CONVERTING THE CHARACTER TO ITS BITS VALUE FROM HUFFMAN TREE
;----------------------------------------------------------------------------------------------------	
huffman_tree:
		mov al, current_char
		mov ah, 0
		mov cx, 0 
huff:	
		mov dx, ax 
		
		cmp dx, current_node				;if root node == ax the reached the end of huffman tree 
		je write_bit
		
		mov si, offset parent
		shl dx, 1
		add si, dx
		mov dx, [si]						;parent[current_char] = dx --> parent node location
	
		push dx								;pushes the current node index value
		
		mov si, offset upkid		
		shl dx, 1 
		add si, dx 							;actual indexing of dx 
		cmp ax, [si]						;upkid[dx] =? [si]
		je setup_0							;if equal write bit 0
		
		mov si, offset dwnkid				
		add si, dx
		cmp ax, [si]
		je setup_1
		
		jmp error

setup_0:									;
		pop ax 
		inc cx 
		mov bx, 0
		push bx
		jmp huff

setup_1:
		pop ax
		inc cx
		mov bx, 1 
		push bx
		jmp huff

write_bit:
		pop bx
		shl outbyte, 1 
		or outbyte, bl
		
		inc outcnt
		cmp outcnt, 8 
		jb skip
		
		push cx
		call write_byte
		pop cx

skip:
		loop write_bit
		
next_char:
		ret
;---------------------------------------------------------------------------------------------
error3:								;FIller for jump error 
		jmp error2
;---------------------------------------------------------------------------------------------
;---------------------------------------------------------------------------------------------
;					WRITE FREQUENCY TABLE IN COMPRESS FILE FOR DECOMPRESSION
;--------------------------------------------------------------------------------------------- 		
save_freq:
		mov ah, 3ch 
		mov cx, 0
		mov dx, offset outname
		int 21h
		mov outh, ax 

		mov ah, 40h
		mov bx, outh
		mov cx, 256*2									;256*2 or 512*2????????
		mov dx, offset freq 
		int 21h 
		
		ret
		
;-----------------------------------------------------------------------------------------------
;							WRITE BYTE TO OUTPUT COMPRESS FILE
;-----------------------------------------------------------------------------------------------
write_byte:
		 mov  ah, 40h           	
		 mov  bx, outh				
		 mov  dx, offset outbyte	
		 mov  cx, 1            		;DATA SIZE IN BYTES.
		 int  21h

		 mov  outbyte, 0   
		 mov outcnt, 0
         

  ret
;-----------------------------------------------------------------------------------------------
;					READ FREQUENCY TABLE FROM INPUT FILE FOR DECOMPRESSION
;-----------------------------------------------------------------------------------------------
Frequency_2:
		mov dx, offset inname						;open file in inname 
		mov al, 0
		mov ah, 3dh
		int 21h
		jc error3
		mov inh, ax		
		
		mov ah, 3fh									;read 256*2 bytes of the file which contains
		mov bx, inh									;the freq table and move it to freq array
		mov cx, 256*2 
		mov dx, offset freq							
		int 21h 
		cmp ax, 0
		je done3
		
done3:

		ret

;-----------------------------------------------------------------------------------------------
;								DECOMPRESSION OF THE FILE
;-----------------------------------------------------------------------------------------------
Decompress:
		
		mov ah, 3ch 
		mov cx, 0
		mov dx, offset outname
		int 21h
		mov outh, ax 
		
		mov bx, current_node
		mov outchar, bx
	;	
		
ReadChar:		
		mov ah, 3fh
		mov bx, inh
		mov cx, 1
		mov dx, offset current_char
		int 21h
		cmp ax, 0
		je end_decompress
		
		;call test3
		
		call bit_char
		jmp ReadChar
		
end_decompress:
		mov ah, 3eh
		mov bx, inh
		int 21h 
		
		mov ah, 3eh
		mov bx, outh
		int 21h
		
		ret
		
;-----------------------------------------------------------------------------------------------
;							CONVERTING THE BITS INTO ITS CHAR VALUE
;-----------------------------------------------------------------------------------------------
bit_char:
		mov al, current_char
		mov outbyte, 0 
		mov outcnt, 0 
		mov bx, outchar
		
dehuff:
		cmp bx, 255
		jbe write_char
		
		mov ah, 0
		shl ax, 1
		
		cmp ah, 0
		je up_branch
		
		cmp ah, 1
		je dwn_branch
		
		jmp error3

up_branch:
		mov si, offset upkid
		shl bx, 1
		add si, bx
		mov bx, [si]
		
		jmp current_bit

dwn_branch:	
		mov si, offset dwnkid
		shl bx, 1
		add si, bx
		mov bx, [si]
		
		jmp current_bit
		
		jmp error3 
		
write_char:
		mov outbyte, bl
		push ax
		
		mov  ah, 40h  
		mov dx, offset outbyte		
		mov  bx, outh				
		mov  cx, 1            	
		int  21h
		
		pop ax 
		mov bx, current_node
		jmp dehuff

current_bit:
		inc outcnt
		cmp outcnt, 8 
		jb dehuff
		
		mov outchar, bx
		ret
;-----------------------------------------------------------------------------------------------
;							FILL THE LAST BYTE WITH JUNK BITS
;-----------------------------------------------------------------------------------------------		
fill_byte:
		mov al, 1
		
		shl outbyte, 1
		or outbyte, al
		inc outcnt
		
		cmp outcnt, 8
		jb fill_byte
		
		call write_byte
		
		ret 



cseg 	ends 
end		start
