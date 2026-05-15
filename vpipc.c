#ifndef _VPIPC_H_
#define _VPIPC_H_
/**
* VpiPc.h
* Contiene la declaración de la sunciones que implementan la comunicación
* utilizando el protocolo IngStore, entre una PC y un POS Ingenico con la
* aplicación de VISA con POS Integrado.
*/

/**
* Codigos de retorno de las funciones
*/
#define VPI_OK				0	// Operacion exitosa
#define VPI_MORE_REC		1	// Operacion exitosa, pero faltan registros

#define VPI_FAIL			11	// El comando no pudo ser enviado
#define VPI_TIMEOUT_EXP		12	// Tiempo de espera agotado.

#define VPI_INVALID_ISSUER	101	// El código de tarjeta no existe.
#define VPI_INVALID_TICKET  102 // El número de cupón no existe.
#define VPI_INVALID_PLAN	103 // El código de plan no existe.
#define VPI_INVALID_INDEX	104	// No existe el indice
#define VPI_EMPTY_BATCH		105	// El lote del POS se encuentra vacío.

#define VPI_TRX_CANCELED	201 // Transacción cancelada por el usuario.
#define VPI_DIF_CARD		202 // La tarjeta deslizada por el usuario no coincide con la pedida.
#define VPI_INVALID_CARD	203 // La tarjeta deslizada no es válida.
#define VPI_EXPIRED_CARD	204 // La tarjeta deslizada está vencida.
#define VPI_INVALID_TRX		205 // La transacción original no existe. 

#define VPI_ERR_COM			301 // El POS no pudo comunicarse con el host.
#define VPI_ERR_PRINT		302 // El POS no pudo imprimir el ticket.

#define VPI_INVALID_IN_CMD		901 // Nombre del comando inexistente.
#define VPI_INVALID_IN_PARAM	902 // Formato de algún parámetro de entrada no es correcto.
#define VPI_INVALID_OUT_CMD		903 // El comando enviado por 

#define VPI_GENERAL_FAIL		909 // Error general en la operación.

/**
* Codigos de las operaciones
*/
#define VPI_PURCHASE		1	// Venta
#define VPI_VOID			2	// Anulación de venta
#define VPI_REFUND			3	// Devolución
#define VPI_REFUND_VOID		4	// Anulación de devolución

/**
* Timeouts
*/
#define VPI_TIMEOUT_STD		3000	// Timeout mínimo 3 segundos
#define VPI_TIMEOUT_HIG		60000	// Timeout alto 60 segundos
#define VPI_TIMEOUT_LOW		10000	// Timeout bajo 10 segundos

/**
* Parámetros de configuración del puerto serial.
*/
typedef struct COM_PARAMS{

	LPSTR com;			// Nombre del puerto. Ej: "COM1", "COM2", etc.
	WORD  baudRate;		// Velocidad de transmición: Ej: 19200
	WORD byteSize;		// Largo del byte. Ej: 7, 8
	char  parity;		// Paridad. Ej: 'N' ninguna, 'E' par, 'O' impar
	WORD  stopBits;		// Bits de parada. Ej: 1, 2
	
}comParams_t;

/**
* Parametros de entrada para la funcion de Venta
*/
typedef struct PURCHASE_IN{

	LPSTR amount;			// Monto *100  
	LPSTR receiptNumber;	// Número de factura  
	LPSTR instalmentCount;	// Cant. de cuotas  
	LPSTR issuerCode;		// Código de tarjeta  
	LPSTR planCode;			// Código de plan  
	LPSTR tip;				// Propina *100
	LPSTR merchantCode;		// Código de comercio a utilizar
	LPSTR merchantName;		// Razon social del comercio
	LPSTR cuit;				// CUIT del comercio
	char  linemode;			// transaccion Online(1) o Offline(0) 

}vpiPurchaseIn_t;

/**
* Parametros de entrada para la funcion de Anulacion
*/
typedef struct VOID_IN{  
	
	LPSTR originalTicket; // Número de cupón de trx. original  
	LPSTR issuerCode;     // Código de tarjeta
	LPSTR merchantName;		// Razon social del comercio
	LPSTR cuit;				// CUIT del comercio

}vpiVoidIn_t;

/**
* Parametros de entrada para la funcion de Devolucion
*/
typedef struct REFUND_IN{  
	
	LPSTR amount;			// Monto *100  
	LPSTR instalmentCount;	// Cant. de cuotas  
	LPSTR issuerCode;		// Código de tarjeta  
	LPSTR planCode;			// Código de plan  
	LPSTR originalTicket;	// Nro. ticket de la trx. original  
	LPSTR originalDate;		// Fecha de la trx. original
    LPSTR receiptNumber;	// Número de factura 
	LPSTR merchantCode;		// Código de comercio a utilizar
	LPSTR merchantName;		// Razon social del comercio
	LPSTR cuit;				// CUIT del comercio
	char  linemode;			// transaccion Online(1) o Offline(0) 
}vpiRefundIn_t;

/**
* Parametros de salida para las funciones de Venta, Anulacion y Devolucion
*/
typedef struct TRX_OUT{   
	
	LPSTR hostRespCode;	// Código de respuesta del host   
	LPSTR hostMessage;  // Mensaje de respuesta del host   
	LPSTR authCode;     // Número de autorización   
	LPSTR ticketNumber; // Número de cupón   
	LPSTR batchNumber;  // Número de lote   
	LPSTR customerName; // Nombre del tarjeta-habiente   
	/* Eldar MOD ---> */
  	LPSTR panFirst6;      	// Primeros 6 digitos de la tarjeta
  	/* <--- Eldar MOD */
	LPSTR panLast4;     // Ultimo 4 digitos de la tarjeta   
	LPSTR date;         // Fecha de la transacción   
	LPSTR time;         // Hora de la transaccion
	LPSTR terminalID;

}vpiTrxOut_t;

/**
* Parametros de salida de la funcion de Cierre de lote.
*/
typedef struct BATCHCLOSE_OUT{  

	LPSTR hostRespCode;	// Codigo de respuesta del host  
	LPSTR date;			// Fecha ("DD/MM/AAAA")  
	LPSTR time;			// Hora ("HH:MM:SS")
	LPSTR terminalID;

}vpiBatchCloseOut_t;

/**
* Registro con los totales por tarjeta del Cierre de lote.
*/
typedef struct BATCHCLOSEDATA_OUT{   
	
	WORD index;				// Índice del registro.   
	LPSTR acquirerCode;		// Código de procesador.   
	LPSTR batchNumber;		// Número de lote.   
	LPSTR issuerCode;		// Código de tarjeta   
	LPSTR purchaseCount;	// Cantidad de ventas.   
	LPSTR purchaseAmount;	// Monto total de ventas.   
	LPSTR voidCount;		// Cantidad anulaciones de venta.   
	LPSTR voidAmount;		// Monto total de anulaciones.   
	LPSTR refundCount;		// Cantidad de devoluciones venta.   
	LPSTR refundAmount;		// Monto total de devoluciones.   
	LPSTR refvoidCount;		// Cantidad anulaciones devolución.   
	LPSTR refvoidAmount;	// Monto total anul. devolución.
	LPSTR date;				// Fecha ("DD/MM/AAAA")  
	LPSTR time;				// Hora ("HH:MM:SS")
	LPSTR terminalID;

}vpiBatchCloseDataOut_t;

/**
*/
typedef struct ISSUER_OUT{   

	WORD index;              //Índice del registro.   
	LPSTR acquirerCode;   //Código de procesador.   
	LPSTR issuerCode;    //Código de tarjeta   
	LPSTR issuerName;   //Nombre de la tarjeta   
	LPSTR maxInstCount;  //Maxima cantidad de cuotas
	LPSTR terminalID;

}vpiIssuerOut_t;

/**
*/
typedef struct PLAN_OUT{   
	
	WORD index;            //Índice del registro.   
	LPSTR issuerCode;  //Código de tarjeta   
	LPSTR planCode;    //Código de plan   
	LPSTR planLabel;  //Nombre del plan
	LPSTR terminalID;

}vpiPlanOut_t;

/**
* Abre el puerto serial de comunicaciones para poder enviar y recibir
* los comandos.El puerto debe estar cerrado para que la ejecución sea 
* exitosa.Es necesario para ejecutar el resto de los comandos.
* @param params Parámetros de configuracion del puerto serial.
*
* @return VPI_OK Puerto abierto exitosamente	
* @return VPI_FAIL El puerto se encontraba abierto o no se pudo abrir.
*/
WORD __stdcall vpiOpenPort (comParams_t* params);

/**
* Cierra el puerto serial de comunicaciones y lo deja libre para otras
* aplicaciones. El puerto debe estar abierto para que la ejecución sea 
* exitosa.Luego de ejecutar este comando, no se puede ejecutar ningun 
* otro comando.
* @return VPI_OK Puerto cerrado exitosamente
* @return VPI_FAIL El puerto no se encontraba abierto o no se pudo cerrar.
*/
WORD __stdcall vpiClosePort(void);

/**
* Envía un mensaje por el puerto y espera la respuesta al mismo en forma 
* sincrónica, para verificar que la conexión con el POS esté OK.La 
* aplicación queda esperando hasta tenga la respuesta o bien expire el
* timeout default.El puerto debe estar abierto para que la ejecución sea exitosa.
* @return VPI_OK Conexión exitosa.
* @return VPI_FAIL No se pudo enviar el comando posiblemente el puerto esté cerrado.
* @return VPI_TIMEOUT_EXP Timeout de respuesta expirado sin respuesta.
*/
WORD __stdcall vpiTestConnection(void);

/**
* Envía la orden de realizar una venta y espera la respuesta de la misma en forma
* sincrónica.La aplicación queda esperando hasta tenga la respuesta o bien expire
* el timeout especificado.El puerto debe estar abierto para que la ejecución sea 
* exitosa.
* @param input Estructura con los datos de entrada de la venta.
* @param output Estructura con los datos de respuesta de la venta. 
*               Se completa dentro de la función
* @param timeout Tiempo de espera de respuesta en segundos.
*
* @return VPI_OK
* @return VPI_FAIL
* @return VPI_TIMEOUT_EXP
* @return VPI_INVALID_ISSUER
* @return VPI_INVALID_PLAN
* @return VPI_TRX_CANCELED
* @return VPI_DIF_CARD
* @return VPI_INVALID_CARD
* @return VPI_EXPIRED_CARD
* @return VPI_ERR_COM
* @return VPI_ERR_PRINT
* @return VPI_INVALID_IN_CMD
* @return VPI_INVALID_IN_PARAM
* @return VPI_INVALID_OUT_CMD
* @return VPI_GENERAL_FAIL
*/
WORD __stdcall vpiPurchase(vpiPurchaseIn_t* intput, vpiTrxOut_t* output, LONG timeout);

/**
* Envía la orden de realizar una anulación de venta y espera la respuesta de la misma
* en forma sincrónica.La aplicación queda esperando hasta tenga la respuesta o bien 
* expire el timeout especificado.El puerto debe estar abierto para que la ejecución 
* sea exitosa.
* @param input Estructura con los datos de entrada de la anulación.
* @param output Estructura con los datos de respuesta de la anulación. 
*               Se completa dentro de la función.
* @param timeout Tiempo de espera de respuesta en segundos.
*
* @return 	VPI_OK
* @return 	VPI_FAIL
* @return 	VPI_TIMEOUT_EXP
* @return 	VPI_INVALID_IN_CMD
* @return 	VPI_INVALID_IN_PARAM
* @return 	VPI_INVALID_OUT_CMD
* @return 	VPI_GENERAL_FAIL
* @return 	VPI_INVALID_ISSUER
* @return 	VPI_INVALID_TICKET
* @return 	VPI_EMPTY_BATCH
* @return 	VPI_TRX_CANCELED
* @return 	VPI_DIF_CARD
* @return 	VPI_INVALID_CARD
* @return 	VPI_EXPIRED_CARD
* @return 	VPI_INVALID_TRX 
* @return 	VPI_ERR_COM
* @return 	VPI_ERR_PRINT

*/
WORD __stdcall vpiVoid(vpiVoidIn_t* intput, vpiTrxOut_t* output, LONG timeout);

/**
* Envía la orden de realizar una devolución y espera la respuesta de la misma en 
* forma sincrónica.La aplicación queda esperando hasta tenga la respuesta o bien
* expire el timeout especificado.El puerto debe estar abierto para que la ejecución
* sea exitosa.
* @param input Estructura con los datos de entrada de la devolución.
* @param output Estructura con los datos de respuesta de la devolución. 
*               Se completa dentro de la función.
* @param timeout Tiempo de espera de respuesta en segundos.
*
* @return VPI_OK Conexión exitosa.
* @return VPI_FAIL No se pudo enviar el comando.
* @return VPI_TIMEOUT_EXP Timeout de respuesta expirado sin respuesta.
* @return VPI_INVALID_ISSUER El código de tarjeta no existe.
* @return VPI_INVALID_PLAN El código de plan no existe.
* @return VPI_TRX_CANCELED Transacción cancelada por el usuario.
* @return VPI_DIF_CARD La tarjeta deslizada por el usuario no coincide con la pedida.
* @return VPI_INVALID_CARD La tarjeta deslizada no es válida.
* @return VPI_EXPIRED_CARD La tarjeta deslizada está vencida.
* @return VPI_ERR_COM El POS no pudo comunicarse con el host.
* @return VPI_ERR_PRINT El POS no pudo imprimir el ticket.
* @return VPI_INVALID_IN_CMD Nombre del comando inexistente.
* @return VPI_INVALID_IN_LEN Largo de los parámetros inválido para este comando.
* @return VPI_INVALID_IN_PARAM Formato de algún parámetro no es correcto.
* @return VPI_INVALID_OUT_CMD Nombre del comando devuelto no coincide con el enviado.
* @return VPI_INVALID_OUT_LEN Largo de los parámetros devueltos inválido para este comando.
* @return VPI_INVALID_OUT_PARAM Formato de algún parámetro devuelto no es correcto.
* @return VPI_GENERAL_FAIL Error general en la operación.
*/
WORD __stdcall vpiRefund (vpiRefundIn_t* input, vpiTrxOut_t* output, LONG timeout);

/**
* Envía la orden de realizar una anulación de devolución y espera la respuesta
* de la misma en forma sincrónica.La aplicación queda esperando hasta tenga la 
* respuesta o bien expire el timeout especificado.El puerto debe estar abierto 
* para que la ejecución sea exitosa.
* @param input Estructura con los datos de entrada de la anulación.
* @param output Estructura con los datos de respuesta de la anulación. 
*               Se completa dentro de la función.
* @param timeout Tiempo de espera de respuesta en segundos.
*
* @return 	VPI_OK
* @return 	VPI_FAIL
* @return 	VPI_TIMEOUT_EXP
* @return 	VPI_INVALID_IN_CMD
* @return 	VPI_INVALID_IN_PARAM
* @return 	VPI_INVALID_OUT_CMD
* @return 	VPI_GENERAL_FAIL
* @return 	VPI_INVALID_ISSUER
* @return 	VPI_INVALID_TICKET
* @return 	VPI_EMPTY_BATCH
* @return 	VPI_TRX_CANCELED
* @return 	VPI_DIF_CARD
* @return 	VPI_INVALID_CARD
* @return 	VPI_EXPIRED_CARD
* @return 	VPI_INVALID_TRX 
* @return 	VPI_ERR_COM
* @return 	VPI_ERR_PRINT
*/
WORD __stdcall vpiRefundVoid(vpiVoidIn_t* intput, vpiTrxOut_t* output, LONG timeout); 

/**
* Envía la orden de realizar un cierre de lote. La aplicación queda esperando hasta
* tenga la respuesta o bien expire el timeout especificado. El puerto debe estar 
* abierto para que la ejecución sea exitosa.
* @param output Estructura con el resultado de la operación contra el host. 
*               Se completa dentro de la función.
* @param timeout Tiempo de espera de respuesta en segundos.
* 
* @return 	VPI_OK
* @return 	VPI_FAIL
* @return 	VPI_TIMEOUT_EXP
* @return 	VPI_INVALID_IN_CMD
* @return 	VPI_INVALID_IN_PARAM
* @return 	VPI_INVALID_OUT_CMD
* @return 	VPI_GENERAL_FAIL
* @return 	VPI_TRX_CANCELED
* @return 	VPI_ERR_COM
* @return 	VPI_ERR_PRINT
*/
WORD __stdcall vpiBatchClose(vpiBatchCloseOut_t* output, LONG timeout);

/**
* Envía la orden de obtener la información de la última transacción realizada 
* y espera la respuesta de la misma en forma sincrónica.La aplicación queda 
* esperando hasta tenga la respuesta o bien expire el timeout especificado.
* El puerto debe estar abierto para que la ejecución sea exitosa.
* @param trxCode Código del tipo de transacción: VPI_PURCHASE, VPI_VOID, 
                                                 VPI_REFUND, VPI_REFUND_VOID
*
* @param output Estructura con los datos de respuesta de la última transacción realizada. 
*               Se completa dentro de la función.
*
* @return 	VPI_OK
* @return 	VPI_FAIL
* @return 	VPI_TIMEOUT_EXP
* @return 	VPI_INVALID_IN_CMD
* @return 	VPI_INVALID_IN_PARAM
* @return 	VPI_INVALID_OUT_PARAM
* @return 	VPI_GENERAL_FAIL
* @return 	VPI_INVALID_ISSUER
* @return 	VPI_INVALID_TICKET
* @return 	VPI_INVALID_PLAN
* @return 	VPI_EMPTY_BATCH
* @return 	VPI_TRX_CANCELED
* @return 	VPI_DIF_CARD
* @return 	VPI_INVALID_CARD
* @return 	VPI_EXPIRED_CARD
* @return 	VPI_ERR_COM
* @return 	VPI_ERR_PRINT
*/
WORD __stdcall vpiGetLastTrxData(WORD* trxCode, vpiTrxOut_t* output);


/**
* Envía la orden de obtener un determinado registro, con los totales por tarjeta 
* del último cierre realizado y espera la respuesta de la misma en forma 
* sincrónica.Para obtener todos los registros se debe hacer un ciclo desde 0  
* hasta que el código de respuesta sea distinto de VPI_MORE_REC. La aplicación queda esperando 
* hasta tenga la respuesta o bien expire el timeout especificado. El puerto debe 
* estar abierto para que la ejecución sea exitosa.
*
* @param index Indice del registro que deseo recuperar
* @param output Estructura con la información del registro que quiero.
*
* @return VPI_OK Fin de registros.
* @return VPI_MORE_REC Quedan registros.
* @return VPI_FAIL No se pudo enviar el comando
* @return VPI_TIMEOUT_EXP Timeout de respuesta expirado sin respuesta.
* @return VPI_INVALID_INDEX El indice del registro no existe. 
* @return VPI_TRX_CANCELED Transacción cancelada por el usuario.
* @return VPI_INVALID_TRX No se realizo el cierre.
* @return VPI_INVALID_IN_CMD 
* @return VPI_INVALID_IN_LEN
* @return VPI_INVALID_IN_PARAM
* @return VPI_INVALID_OUT_CMD
* @return VPI_INVALID_OUT_LEN
* @return VPI_INVALID_OUT_PARAM
* @return VPI_GENERAL_FAIL
*/
WORD __stdcall vpiGetBatchCloseData(WORD index, vpiBatchCloseDataOut_t* output);

/**
* Envía la orden de re-imprimir el ticket de la última transacción.La aplicación queda 
* esperando hasta tenga la respuesta o bien expire el timeout default.El puerto debe 
* estar abierto para que la ejecución sea exitosa.
*
* @param Ninguno
*
* @return 	VPI_OK
* @return 	VPI_FAIL
* @return 	VPI_TIMEOUT_EXP
* @return 	VPI_INVALID_IN_CMD 
* @return 	VPI_INVALID_IN_PARAM
* @return 	VPI_INVALID_OUT_PARAM
* @return 	VPI_GENERAL_FAIL
*/
WORD __stdcall vpiPrintTicket(void);

/**
* Envía la orden de re-imprimir el ticket del último cierre de lote. La aplicación queda
* esperando hasta tenga la respuesta o bien expire el timeout default.El puerto debe estar
* abierto para que la ejecución sea exitosa.
* 
* @param Ninguno
* 
* @return 	VPI_OK
* @return 	VPI_FAIL
* @return 	VPI_TIMEOUT_EXP
* @return 	VPI_INVALID_IN_CMD 
* @return 	VPI_INVALID_IN_PARAM
* @return 	VPI_INVALID_OUT_PARAM
* @return 	VPI_GENERAL_FAIL
*/
WORD __stdcall vpiPrintBatchClose(void);

/**
* Envía el comando para obtener un registro de la tabla de tarjetas del POS y espera 
* la respuesta de la misma en forma sincrónica. Para obtener todos los registros se 
* debe hacer un ciclo desde 0 hasta que el código de respuesta sea distinto de VPI_MORE_REC.
* La aplicación queda  esperando hasta tenga la respuesta o bien expire el timeout especificado. 
* El puerto debe estar abierto para que la ejecución sea exitosa.
*
* @param index Indice del registro a obtener.
* @param output Estructura con los datos de la tarjeta. Se completa dentro de la función.
*
* @return 	VPI_OK
* @return 	VPI_MORE_REC
* @return 	VPI_FAIL
* @return 	VPI_TIMEOUT_EXP
* @return 	VPI_INVALID_IN_CMD 
* @return 	VPI_INVALID_IN_PARAM
* @return 	VPI_INVALID_OUT_CMD
* @return 	VPI_GENERAL_FAIL
* @return 	VPI_INVALID_INDEX
*/
WORD __stdcall vpiGetIssuer(WORD index, vpiIssuerOut_t* output);

/**
* Envía el comando para obtener un registro de la tabla de planes del POS y espera la 
* respuesta de la misma en forma sincrónica. Para obtener todos los registros se debe
* hacer un ciclo desde 0 hasta que el código de respuesta sea distinto de VPI_MORE_REC.
* La aplicación queda esperando hasta tenga la respuesta o bien expire el timeout 
* especificado. El puerto debe estar abierto para que la ejecución sea exitosa.
*
* @param index Indice del registro a obtener.
* @param output Estructura con los datos del plan. Se completa dentro de la función.
*
* @return 	VPI_OK
* @return 	VPI_MORE_REC
* @return 	VPI_FAIL
* @return 	VPI_TIMEOUT_EXP
* @return 	VPI_INVALID_IN_CMD 
* @return 	VPI_INVALID_IN_PARAM
* @return 	VPI_INVALID_OUT_CMD
* @return 	VPI_GENERAL_FAIL
* @return 	VPI_INVALID_INDEX
*/
WORD __stdcall vpiGetPlan(WORD index, vpiPlanOut_t* output);


#endif //_VPIPC_H_
