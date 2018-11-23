segment pila stack
		resb 64
stacktop:

segment datos data
fileName db    "prueba.dat",0

num      resb  4
signo    resb  1
expexc   resb  1
mantisa  resb  3

fHandle  resw  1

cadena    resb  78
base10    db    " * 10 ^ $"
msgerr    db    " El archivo no se pudo abrir $"
msgread   db    "Error al leer el archivo $"
msgclose  db    "Error al cerrar el archivo $"


segment codigo code
..start:mov   ax,datos
        mov   ds,ax
		mov   ax,pila
        mov   ss,ax
        mov   sp,stacktop
		
		call  open
otro:	call  get
		call  copiar
		call  procesar
		call  impsalto
		jmp   otro
		
salir:   
        mov    ah,4ch
        ;mov  ax,4c00h 
		int  21h
		
open:
		mov	al,0		 
		mov	dx,fileName	         
		mov	ah,3dh		         
		int	21h
		jc	erropen
	    mov	[fHandle],ax	
		ret
			
get:
        mov	bx,[fHandle]	;bx = handle del archivo
		mov	cx,4		;cx = cantidad de bytes a escribir
		mov	dx,num	;dx = dir del area de memoria q contiene los bytes leidos del archivo
		mov	ah,3fh		;ah = servicio para escribir un archivo: 40h
		int	21h
	    jc	errread
		cmp ax,4 ;compara con el cero que seria el ultimo registro del archivo binario
		jne  close
        ret

copiar:
		mov   ah,[num] ; primer byte
        mov   al,[num+1] ; segundo byte
        shr   ax,7 ; agrego 7 ceros a la derecha para obtener el valor del signo
        mov   [signo],ah ; al desplazarlo en ah quedo el signo 
        mov   [expexc],al ; y en al quedo el exponente en exceso
        mov   ah,[num+1] ; me posiciono en el segundo byte
        mov   al,[num+2] ; y en la parte baja queda el tercer byte
        shl   ax,1 ; agrega un cero por izquierda para obtener la mantisa
        mov   [mantisa],ah ; la parte alta apunta al segundo byte almaceno un byte a mantisa
        mov   ah,[num+2] ;
        mov   al,[num+3] ; posiciono los otros 2 bytes que faltan a los otros bytes de la mantisa
        shl   ax,1
        mov   [mantisa+1],ah
        mov   [mantisa+2],al
        ret

procesar:
		call  PIEEE
		call  impsigno
		call  impnorma
		call  impmantisa
		call  impbase
		call  impexp
		ret
		
; IMPRIMR POR PANTALLA UN SALTO DE LIENA
impsalto:
         ;RETORNO DE CARRO
         mov   ah,02h
         mov   dl,13
         int   21h

         ;SALTO DE LINEA
         mov   ah,02h
         mov   dl,10
         int   21h

         mov   si,0
         ret

impsigno:
        cmp   byte[signo],00h
        jne   impneg
        ret

impneg:
		mov   ah,02h
        mov   dl,'-'
        int   21h

impnorma:
        mov   word[cadena],'1,'
        mov   byte[cadena+2],'$'
        call  imprimir
        ret

impmantisa:
		mov   ax,0
        mov   al,[mantisa]
        call  convertir

        mov   ax,0
        mov   al,[mantisa+1]
        call  convertir

        mov   ax,0
        mov   al,[mantisa+2]
        call  convertir
        dec   si
        mov   byte[cadena+si],'$'

        mov   al,[expexc]
        sub   al,127
  
        mov   bx,0
        cmp   al,0
        jng   QUITAR0
        mov   bl,al
        dec   bx
QUITAR0:
		dec   si
        call  QCEROD
		call  imprimir
		
        ret

QCEROD:
         cmp   si,bx
         jng   salir
         cmp   byte[cadena+si],31h
         je    salir
         mov   byte[cadena+si],'$'
         dec   si
         jmp   QCEROD
		 ret
		 
PIEEE:
         mov   si,0
         mov   ax,0
         mov   al,[num]
         call  CONVERH
         call  imprimir
         mov   al,[num+1]
         call  CONVERH
         call  imprimir
         mov   al,[num+2]
         call  CONVERH
         call  imprimir
         mov   al,[num+3]
         call  CONVERH
         mov   word[cadena+si],': '
         add   si,2
         mov   word[cadena+si],'$ '
         call  imprimir
         ret
		 
CONVERH:
		 mov   cx,2
CICLOH:  mov   ah,0
         shl   ax,4
         cmp   ah,0Ah
         jnl   LETRA
         add   ah,30h
         jmp   IMPH
LETRA    add   ah,37h
IMPH:    mov   byte[cadena+si],ah
         inc   si
         loop  CICLOH
         mov   byte[cadena+si],'$'
         ret
		
impbase:
		mov   dx,base10
        mov   ah,09h
        int   21h
        ret

impexp:
		mov   al,[expexc]
        sub   al,127
        cmp   al,0
        jnl   exppos
        neg   al
        mov   byte[cadena],'-'
        inc   si
exppos:
        mov   ah,0
        call  CEQCEROI
        mov   byte[cadena+si],'$'
        call  imprimir
        ret
        
imprimir:
        mov   dx,cadena
        mov   ah,09h
        int   21h
		
		mov   cx,78
        lea   si,[cadena]
rep     movsb
        mov   si,0
        ret
		
convertir:
		mov   cx,8
bites:  shl   ax,1 ;loop de 8 bits
        add   ah,30h
        mov   [cadena+si],ah
        inc   si
        mov   ah,0
        loop  bites
        ret
		
CEQCEROI:
         mov   cx,8
        ; mov   byte[flag],0FFh
BTOSE:
         shl   ax,1
;         cmp   ah,1
;         jne   CONTINU
         ;mov   byte[flag],00h
;CONTINU: ;cmp   byte[flag],00h
         ;jne   OMITIR0
         add   ah,30h
         mov   [cadena+si],ah
         inc   si
OMITIR0: mov   ah,0
         cmp   cx,2
         jne   CICLO
CICLO:   loop  BTOSE
         ret
 
erropen:
        mov   dx,msgerr
        mov   ah,09h
        int   21h
        jmp   salir
		 
errclose:
		mov	dx,msgclose
		mov	ah,9
		int	21h

errread: 
		mov	dx,msgread
		mov	ah,9
		int	21h
		
close:
		mov	bx,[fHandle]	;bx = handle del archivo
		mov	ah,3eh		;ah = servicio para cerrar archivo: 3eh
		int	21h
		jc	errclose
		jmp	salir		
fin:	ret