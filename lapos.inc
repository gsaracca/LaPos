! -----------------------------------------------------------------------------------

comParams_t     group,type
com                 long        !; // Nombre del puerto. Ej: "COM1", "COM2", etc.
baudRate            WORD        !; // Velocidad de transmición: Ej: 19200
byteSize            WORD        !; // Largo del byte. Ej: 7, 8
parity              char        !; // Paridad. Ej: 'N' ninguna, 'E' par, 'O' impar
stopBits            WORD        !; // Bits de parada. Ej: 1, 2
                end !* end *

! end
