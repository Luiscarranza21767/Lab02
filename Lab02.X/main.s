;*******************************************************************************
; Universidad del Valle de Guatemala
; IE2023 Programación de Microcontroladores
; Autor: Luis Pablo Carranza
; Compilador: PIC-AS (v2.4), MPLAB X IDE (v6.00)
; Proyecto: Laboratorio 2 Timer0 y botones
; Hardware PIC16F887
; Creado: 31/07/22
; Última Modificación: 08/08/22
; ******************************************************************************

PROCESSOR 16F887
#include <xc.inc> 
; ******************************************************************************
; Palabra de configuración
; ******************************************************************************
; CONFIG1
  CONFIG  FOSC = INTRC_NOCLKOUT ; Oscillator Selection bits (INTOSC oscillator 
				; without clock out)
  CONFIG  WDTE = OFF            ; Watchdog Timer Enable bit (WDT disabled and 
				; can be enabled by SWDTEN bit of the WDTCON 
				; register)
  CONFIG  PWRTE = OFF           ; Power-up Timer Enable bit (PWRT disabled)
  CONFIG  MCLRE = OFF           ; RE3/MCLR pin function select bit (RE3/MCLR 
				; pin function is digital input, MCLR internally 
				; tied to VDD)
  CONFIG  CP = OFF              ; Code Protection bit (Program memory code 
				; protection is disabled)
  CONFIG  CPD = OFF             ; Data Code Protection bit (Data memory code 
				; protection is disabled)
  CONFIG  BOREN = OFF           ; Brown Out Reset Selection bits (BOR disabled)
  CONFIG  IESO = OFF            ; Internal External Switchover bit (Internal/
				; External Switchover mode is disabled)
  CONFIG  FCMEN = OFF           ; Fail-Safe Clock Monitor Enabled bit 
				; (Fail-Safe Clock Monitor is disabled)
  CONFIG  LVP = OFF             ; Low Voltage Programming Enable bit (RB3 pin 
				; has digital I/O, HV on MCLR must be used for 
				; programming)

; CONFIG2
  CONFIG  BOR4V = BOR40V        ; Brown-out Reset Selection bit (Brown-out Reset 
				; set to 4.0V)
  CONFIG  WRT = OFF             ; Flash Program Memory Self Write Enable bits 
				; (Write protection off)

; ******************************************************************************
; Variables
; ******************************************************************************
PSECT udata_shr
 bandera1:  ; Variable que sirve para el antirrebote
    DS 1
 CONT1S:    ; Variable que sirve para el contador de 1 segundo
    DS 1
 COMP:	    ; Variable que sirve para comparar display con contador de 1s
    DS 1    
 ALARMA:    ; Variable para activar la alarma
    DS 1
 ALARMA1:
    DS 1
PSECT udata_bank0
 CONTHEX:   ; Variable utilizada para controlar el display
    DS 1
; ******************************************************************************
; Vector Reset
; ******************************************************************************
PSECT CODE, delta=2, abs
 ORG 0x0000
    GOTO MAIN
; ******************************************************************************
; Código Principal
; ******************************************************************************
PSECT CODE, delta=2, abs
 ORG 0x0100
    
MAIN:
BANKSEL OSCCON
    ; SE CONFIGURA EL OSCILADOR A 2MHz
    BSF OSCCON, 6   ; IRCF2
    BCF OSCCON, 5   ; IRCF1
    BSF OSCCON, 4   ; IRCF0
    
    BSF OSCCON, 0   ; SE UTILIZA RELOJ INTERNO

BANKSEL ANSEL
    CLRF ANSEL
    CLRF ANSELH	; TODAS LAS I/O SON DIGITALES
    
BANKSEL TRISB
    CLRF TRISB  ; REGISTRO TRISB PARA CONFIGURAR PUERTO B COMO SALIDA
    CLRF TRISC	; REGISTRO TRISC CONFIGURADO COMO SALIDA
    BSF TRISA, 0
    BSF TRISA, 1
    CLRF TRISD	; REGISTRO TRISD CONFIGURADO COMO SALIDA
    CLRF TRISE	; REGISTRO TRISE CONFIGURADO COMO SALIDA

BANKSEL OPTION_REG
    BCF OPTION_REG, 5   ; T0CS COMO FOSC/4
    BCF OPTION_REG, 3   ; ASIGNAR AL TIMER0 EL PRESCALER
    
; SELECCIÓN DEL PREESCALER EN TIMER0
    BSF OPTION_REG, 2
    BSF OPTION_REG, 1
    BSF OPTION_REG, 0   ; PRESCALER DE 1:256

BANKSEL PORTB
    CLRF PORTB	; SE INICIA PUERTO B EN 0
    CLRF PORTA	; SE INICIA PUERTO A EN 0
    CLRF PORTC	; SE INICIA PUERTO C EN 0
    CLRF PORTD	; SE INICIA PUERTO D EN 0
    CLRF TRISE	; SE INICIA PUERTO E EN 0
    CLRF CONT1S	; INICIA LA VARIABLE EN 0
    MOVLW 61
    MOVWF TMR0	; SE CARGA EL VALOR DE N=195 PARA OBTENER 100ms
    CLRF CONTHEX
    CLRF ALARMA
    CLRF ALARMA1
    CLRF COMP
    BSF COMP, 0
    
;*******************************************************************************
; Inicio del LOOP
;*******************************************************************************
    
LOOP:
    INCF PORTC		; Incrementa el contador del timer0
    BTFSC PORTA, 0	; Revisa si se presionó RA1
    CALL Antirrebote1
    BTFSS PORTA, 0	
    CALL Incremento
    BTFSC PORTA, 1	; Revisa si se presionó RA1
    CALL Antirrebote2
    BTFSS PORTA, 1
    CALL Decremento
    
;*******************************************************************************
; Timer0
;*******************************************************************************  
    
REVT0IF:
    BTFSS INTCON, 2 ; Revisa si TOIF está en 1 por overflow
    GOTO $-1	    ; Si está en 0 vuelve a revisar
    BCF INTCON, 2   ; Si está en uno borra la bandera de T0IF
    MOVLW 61	    ; Vuelve a cargar 61 como valor de n
    MOVWF TMR0	    ; Carga el valor a TMR0
    
;*******************************************************************************
; Contador de 1 segundo
;******************************************************************************* 
CONTADORSEGUNDOS: 
    CLRF STATUS
    INCF CONT1S, F  ; Después de 100ms incrementa CONT1S
    MOVF CONT1S, W  ; Mueve el valor a W
    SUBLW 10	    ; Resta el valor de CONT1S a 10
    BTFSS STATUS, 2 ; Verifica si el resultado es 0
    GOTO LOOP	    ; Si no es 0 regresa al LOOP
    CLRF CONT1S	    ; Si es 0 limpia la variable
    INCF PORTD	    ; Incrementa PORTD
    MOVLW 61	    ; Reinicia el TMR0
    MOVWF TMR0
    
;*******************************************************************************
; Comparación del display con contador de 1 segundo
;*******************************************************************************     
COMPDISP:   
    CLRF STATUS	    ; Limpia el bit 2 de STATUS
    MOVF COMP, W    ; Mueve el valor del comparador a W
    ANDLW 0x0F	    ; Se asegura de que el valor es de 0-15 con un AND
    MOVWF COMP	    ; Mueve el valor nuevo de W a COMPMOVF PORTD, W
    MOVF COMP, W
    MOVWF ALARMA1
    MOVF PORTD, W   ; Mueve el valor del puerto D a W
    ANDLW 0x0F	    ; Se asegura de que está entre 0-15
    SUBWF COMP, W   ; Le resta el valor de PORTD a COMP
    BTFSS STATUS, 2 ; Verifica si el resultado es 0
    GOTO ALARM	    ; Si no es 0 no son iguales y regresa al loop   
    CLRF PORTD	    ; Si es 0 el contador y el display son iguales, entonces
		    ; Reinicia el puerto D
    BSF ALARMA, 0
    GOTO LOOP
    
ALARM:
    BTFSC ALARMA, 0 ; Revisa si el bit de alarma está en 1
    INCF PORTE, F   ; Si está en 1 incrementa puerto E
    CLRF STATUS	    ; Si está en 0 limpia status
    MOVF ALARMA1, W ; Mueve el valor de alarma1 a W
    SUBLW 1	    ; Le resta 1 al valor de W
    SUBWF PORTD, W  ; Le resta el valor nuevo de alarma1 a PORTD
    BTFSS STATUS, 2 ; Si el restultado es 0 salta
    BCF ALARMA, 0   ; Si el resutlado es 1 es porque debe parar
    GOTO LOOP

;*******************************************************************************
; Tabla para Display
;*******************************************************************************
Table:
    CLRF PCLATH
    BSF PCLATH, 0
    ANDLW 0x0F
    ADDWF PCL
    RETLW 00111111B ; Regresa 0
    RETLW 00000110B ; Regresa 1
    RETLW 01011011B ; Regresa 2
    RETLW 01001111B ; Regresa 3
    RETLW 01100110B ; Regresa 4
    RETLW 01101101B ; Regresa 5
    RETLW 01111101B ; Regresa 6
    RETLW 00000111B ; Regresa 7
    RETLW 01111111B ; Regresa 8
    RETLW 01101111B ; Regresa 9
    RETLW 01110111B ; Regresa A
    RETLW 01111111B ; Regresa B
    RETLW 00111001B ; Regresa C
    RETLW 00111111B ; Regresa D
    RETLW 01111001B ; Regresa E
    RETLW 01110001B ; Regresa F
    
;*******************************************************************************
; Subrutinas contador Display
;*******************************************************************************  
    
Antirrebote1:
    BSF bandera1, 0	; Si se presionó enciende el primer bit de bander1
    RETURN
    
Incremento:
    BTFSS bandera1, 0	;Si no está presionado ejecuta la siguiente instrucción
    RETURN
    INCF CONTHEX, F	; Si está en 1 incrementa 1 la variable
    MOVF CONTHEX, W	; Mueve el valor de la variable a W
    CALL Table		; Llama a la tabla
    MOVWF PORTB		; Registra el valor de la tabla en PORTB
    CLRF bandera1	
    INCF COMP		; Incrementa la variable que sirve para comparar
    RETURN

Antirrebote2:
    BSF bandera1, 1	; Si se presionó enciente el segundo bit de bandera1
    RETURN
    
Decremento:
    BTFSS bandera1, 1	; Si no está presionado ejecuta la siguiente instrucción
    RETURN
    DECF CONTHEX, F	; Si está en 1 decrementa la variable
    MOVF CONTHEX, W
    CALL Table		; Llama a la tabla
    MOVWF PORTB		; Registra el valor de la tabla en PORTB
    CLRF bandera1
    DECF COMP		; Decrementa la variable que sirve para la comparación
    RETURN

;*******************************************************************************
; FIN DEL CÓDIGO
;******************************************************************************* 
END





