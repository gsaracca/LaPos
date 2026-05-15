/// <summary>
///   Unidad de integración para <c>lapos.dll</c>.
///   Encapsula la carga dinámica de la DLL y expone un objeto orientado a
///   objetos con tipos nativos de Delphi (string / Integer), ocultando la
///   gestión manual de buffers PAnsiChar requerida por la API de bajo nivel.
/// </summary>
/// <remarks>
///   <para>
///     Dependencias en tiempo de ejecución (deben estar en el mismo directorio
///     que <c>lapos.dll</c> o en el PATH del sistema):
///   </para>
///   <list type="bullet">
///     <item><c>lapos.dll</c>  — esta biblioteca (wrapper Delphi)</item>
///     <item><c>VPIPC.DLL</c>  — comunicaciones VPI PC (protocolo IngStore)</item>
///     <item><c>ingstore.dll</c> — protocolo IngStore subyacente</item>
///   </list>
///   <para>
///     Todas las funciones de la DLL usan convención de llamada <c>cdecl</c>
///     y strings como <c>PAnsiChar</c> con buffers de 256 bytes.
///   </para>
/// </remarks>
unit LaPos.Client;

interface

// ---------------------------------------------------------------------------
// Códigos de retorno de lapos.dll / VPIPC.DLL
// ---------------------------------------------------------------------------

const
  /// <summary>Versión de la biblioteca LaPos.</summary>
  LAPOS_VERSION      = '1.0.0';

  /// <summary>Operación exitosa.</summary>
  VPI_OK             = 0;
  /// <summary>Operación exitosa, pero quedan más registros por leer.</summary>
  VPI_MORE_REC       = 1;

  /// <summary>El comando no pudo ser enviado al POS.</summary>
  VPI_FAIL           = 11;
  /// <summary>Tiempo de espera agotado sin respuesta del POS.</summary>
  VPI_TIMEOUT_EXP    = 12;

  /// <summary>El código de tarjeta (issuerCode) no existe en el POS.</summary>
  VPI_INVALID_ISSUER = 101;
  /// <summary>El número de cupón (ticket) no existe en el POS.</summary>
  VPI_INVALID_TICKET = 102;
  /// <summary>El código de plan no existe en el POS.</summary>
  VPI_INVALID_PLAN   = 103;
  /// <summary>El índice de iteración está fuera de rango.</summary>
  VPI_INVALID_INDEX  = 104;
  /// <summary>El lote del POS se encuentra vacío.</summary>
  VPI_EMPTY_BATCH    = 105;

  /// <summary>El cliente canceló la transacción en el terminal.</summary>
  VPI_TRX_CANCELED   = 201;
  /// <summary>La tarjeta deslizada no coincide con la solicitada.</summary>
  VPI_DIF_CARD       = 202;
  /// <summary>La tarjeta deslizada no es válida.</summary>
  VPI_INVALID_CARD   = 203;
  /// <summary>La tarjeta deslizada está vencida.</summary>
  VPI_EXPIRED_CARD   = 204;
  /// <summary>La transacción original referenciada no existe.</summary>
  VPI_INVALID_TRX    = 205;

  /// <summary>El POS no pudo comunicarse con el host adquirente.</summary>
  VPI_ERR_COM        = 301;
  /// <summary>El POS no pudo imprimir el ticket.</summary>
  VPI_ERR_PRINT      = 302;

  /// <summary>Error general en la operación.</summary>
  VPI_GENERAL_FAIL   = 909;

  /// <summary>Código de operación: Venta.</summary>
  VPI_PURCHASE       = 1;
  /// <summary>Código de operación: Anulación de venta.</summary>
  VPI_VOID           = 2;
  /// <summary>Código de operación: Devolución.</summary>
  VPI_REFUND         = 3;
  /// <summary>Código de operación: Anulación de devolución.</summary>
  VPI_REFUND_VOID    = 4;

// ---------------------------------------------------------------------------
// Tipos para los punteros a función exportados por lapos.dll
// ---------------------------------------------------------------------------

type
  TLaPosSetCom   = procedure(com: Integer); cdecl;
  TLaPosSetName  = procedure(name: PAnsiChar); cdecl;
  TLaPosSetCUIT  = procedure(cuit: PAnsiChar); cdecl;
  TLaPosTest     = function: Integer; cdecl;

  TLaPosPurchase = function(
    _monto, _vuelto, _cuotas, _tarjeta, _plan, _ticket,
    _mCode, _mName, _mCUIT,
    _hostRespCode, _hostMessage,
    _authCode, _ticketNumber,
    _batchNumber, _customerName,
    _panFirst6, _panLast4,
    _date, _time,
    _terminalID: PAnsiChar): Integer; cdecl;

  TLaPosPurchaseExtraCash = TLaPosPurchase;

  TLaPosVoid = function(
    _ticket, _tarjeta, _cName, _cCUIT,
    _hostRespCode, _hostMessage,
    _authCode, _ticketNumber,
    _batchNumber, _customerName,
    _panFirst6, _panLast4,
    _date, _time, _terminalID: PAnsiChar): Integer; cdecl;

  TLaPosRefund = function(
    _monto, _cuotas, _tarjeta, _plan, _ticket,
    _factura, _mCode, _mName, _mCUIT,
    _hostRespCode, _hostMessage,
    _authCode, _ticketNumber,
    _batchNumber, _customerName,
    _panFirst6, _panLast4,
    _date, _time,
    _terminalID: PAnsiChar): Integer; cdecl;

  TLaPosRefundVoid = TLaPosRefund;

  TLaPosBatchClose = function(
    _hostRespCode, _date, _time, _terminalID: PAnsiChar): Integer; cdecl;

  TLaPosBatchPrint  = function: Integer; cdecl;
  TLaPossPrintTicket = function: Integer; cdecl;

  TLaPosGetLastData = function(
    _oper: Integer;
    _hostRespCode, _hostMessage,
    _authCode, _ticketNumber,
    _batchNumber, _customerName,
    _panFirst6, _panLast4,
    _date, _time,
    _terminalID: PAnsiChar): Integer; cdecl;

  TLaPosGetBatch = function(
    i: Integer;
    _adquirente, _batch, _tarjeta,
    _purchCount, _purchAmount,
    _voidCount, _voidAmount,
    _refCount, _refAmount,
    _refVoidCount, _refVoidAmount,
    _date, _time, _term: PAnsiChar): Integer; cdecl;

  TLaPosGetTarjeta = function(
    i: Integer;
    _adq, _tarCode, _tarName, _cuotas, _term: PAnsiChar): Integer; cdecl;

  TLaPosGetPlan = function(
    i: Integer;
    _tarjeta, _planCode, _planLabel, _term: PAnsiChar): Integer; cdecl;

// ---------------------------------------------------------------------------
// Registro de respuesta de transacción
// ---------------------------------------------------------------------------

  /// <summary>
  ///   Datos devueltos por el POS al completar una transacción
  ///   (venta, anulación o devolución).
  /// </summary>
  TTrxResponse = record
    /// <summary>Código de respuesta del host adquirente (ej: "00" = aprobado).</summary>
    HostRespCode: string;
    /// <summary>Mensaje de respuesta del host.</summary>
    HostMessage: string;
    /// <summary>Código de autorización otorgado por el host.</summary>
    AuthCode: string;
    /// <summary>Número de ticket generado por el POS.</summary>
    TicketNumber: string;
    /// <summary>Número de lote activo al momento de la transacción.</summary>
    BatchNumber: string;
    /// <summary>Nombre del titular de la tarjeta.</summary>
    CustomerName: string;
    /// <summary>Primeros 6 dígitos del PAN (BIN de la tarjeta).</summary>
    PanFirst6: string;
    /// <summary>Últimos 4 dígitos del PAN.</summary>
    PanLast4: string;
    /// <summary>Fecha de la transacción (formato AAAAMMDD).</summary>
    Date: string;
    /// <summary>Hora de la transacción (formato HHMMSS).</summary>
    Time: string;
    /// <summary>Identificador del terminal POS.</summary>
    TerminalID: string;
  end;

  /// <summary>
  ///   Datos devueltos por el POS al completar un cierre de lote.
  /// </summary>
  TBatchCloseResponse = record
    /// <summary>Código de respuesta del host adquirente.</summary>
    HostRespCode: string;
    /// <summary>Fecha del cierre (formato AAAAMMDD).</summary>
    Date: string;
    /// <summary>Hora del cierre (formato HHMMSS).</summary>
    Time: string;
    /// <summary>Identificador del terminal POS.</summary>
    TerminalID: string;
  end;

  /// <summary>
  ///   Totales por tarjeta del último cierre de lote.
  /// </summary>
  TBatchRecord = record
    /// <summary>Código del adquirente.</summary>
    AcquirerCode: string;
    /// <summary>Número de lote.</summary>
    BatchNumber: string;
    /// <summary>Código de tarjeta (issuerCode).</summary>
    IssuerCode: string;
    /// <summary>Cantidad de ventas en el lote.</summary>
    PurchaseCount: string;
    /// <summary>Monto total de ventas en el lote (en centavos).</summary>
    PurchaseAmount: string;
    /// <summary>Cantidad de anulaciones de venta.</summary>
    VoidCount: string;
    /// <summary>Monto total de anulaciones (en centavos).</summary>
    VoidAmount: string;
    /// <summary>Cantidad de devoluciones.</summary>
    RefundCount: string;
    /// <summary>Monto total de devoluciones (en centavos).</summary>
    RefundAmount: string;
    /// <summary>Cantidad de anulaciones de devolución.</summary>
    RefVoidCount: string;
    /// <summary>Monto total de anulaciones de devolución (en centavos).</summary>
    RefVoidAmount: string;
    /// <summary>Fecha del cierre.</summary>
    Date: string;
    /// <summary>Hora del cierre.</summary>
    Time: string;
    /// <summary>Identificador del terminal POS.</summary>
    TerminalID: string;
  end;

  /// <summary>
  ///   Datos de una tarjeta habilitada en el POS.
  /// </summary>
  TIssuerRecord = record
    /// <summary>Código del adquirente.</summary>
    AcquirerCode: string;
    /// <summary>Código interno de la tarjeta (issuerCode).</summary>
    IssuerCode: string;
    /// <summary>Nombre de la tarjeta (ej: "VISA", "MASTERCARD").</summary>
    IssuerName: string;
    /// <summary>Máximo de cuotas permitido.</summary>
    MaxInstCount: string;
    /// <summary>Identificador del terminal POS.</summary>
    TerminalID: string;
  end;

  /// <summary>
  ///   Datos de un plan de financiación habilitado en el POS.
  /// </summary>
  TPlanRecord = record
    /// <summary>Código de tarjeta al que pertenece el plan.</summary>
    IssuerCode: string;
    /// <summary>Código interno del plan.</summary>
    PlanCode: string;
    /// <summary>Descripción del plan (ej: "3 cuotas sin interés").</summary>
    PlanLabel: string;
    /// <summary>Identificador del terminal POS.</summary>
    TerminalID: string;
  end;

// ---------------------------------------------------------------------------
// Clase principal
// ---------------------------------------------------------------------------

  /// <summary>
  ///   Fachada orientada a objetos sobre <c>lapos.dll</c>.
  /// </summary>
  /// <remarks>
  ///   <para>
  ///     Carga la DLL dinámicamente en el constructor y la libera en el
  ///     destructor. Una instancia por sesión de caja es suficiente; no es
  ///     thread-safe (la DLL subyacente mantiene estado global del puerto COM).
  ///   </para>
  ///   <para>
  ///     Uso mínimo:
  ///     <code>
  ///       POS := TLaPosClient.Create('lapos.dll');
  ///       try
  ///         POS.Configure(9, 'MI COMERCIO SA', '30-12345678-9');
  ///         if POS.TestConnection then
  ///           Ret := POS.Purchase(...);
  ///       finally
  ///         POS.Free;
  ///       end;
  ///     </code>
  ///   </para>
  /// </remarks>
  TLaPosClient = class
  private
    FHandle:          THandle;
    FSetCom:          TLaPosSetCom;
    FSetName:         TLaPosSetName;
    FSetCUIT:         TLaPosSetCUIT;
    FTest:            TLaPosTest;
    FPurchase:        TLaPosPurchase;
    FPurchaseXCash:   TLaPosPurchaseExtraCash;
    FVoid:            TLaPosVoid;
    FRefund:          TLaPosRefund;
    FRefundVoid:      TLaPosRefundVoid;
    FBatchClose:      TLaPosBatchClose;
    FBatchPrint:      TLaPosBatchPrint;
    FPrintTicket:     TLaPossPrintTicket;
    FGetLastData:     TLaPosGetLastData;
    FGetBatch:        TLaPosGetBatch;
    FGetTarjeta:      TLaPosGetTarjeta;
    FGetPlan:         TLaPosGetPlan;

    procedure LoadProc(var Proc; const Name: string);
    function  ToStr(const Buf: array of AnsiChar): string;
    procedure CopyTrxResponse(
      const bRespCode, bMessage, bAuthCode, bTicketNum,
            bBatchNum, bCustomerName, bPanFirst6, bPanLast4,
            bDate, bTime, bTerminalID: array of AnsiChar;
      out Response: TTrxResponse);
  public
    /// <summary>
    ///   Carga <c>lapos.dll</c> desde la ruta indicada y resuelve todos los
    ///   símbolos exportados. Lanza una excepción si la DLL o algún símbolo
    ///   no se encuentra.
    /// </summary>
    /// <param name="DLLPath">
    ///   Ruta completa o nombre de archivo de <c>lapos.dll</c>.
    ///   Si solo se pasa el nombre, Windows lo buscará según el orden estándar
    ///   de búsqueda de DLLs (directorio del ejecutable, PATH, etc.).
    /// </param>
    /// <exception cref="Exception">
    ///   Si <c>LoadLibrary</c> falla o algún <c>GetProcAddress</c> devuelve nil.
    /// </exception>
    constructor Create(const DLLPath: string);

    /// <summary>Libera el handle de la DLL.</summary>
    destructor Destroy; override;

    // -----------------------------------------------------------------------
    // Configuración
    // -----------------------------------------------------------------------

    /// <summary>
    ///   Establece el puerto COM y los datos del comercio que se usarán en
    ///   todas las operaciones posteriores. Debe llamarse antes de cualquier
    ///   transacción.
    /// </summary>
    /// <param name="ComPort">
    ///   Número de puerto serie (1–32). Si está fuera de rango, la DLL lo
    ///   reemplaza por COM9 y muestra un diálogo de advertencia.
    /// </param>
    /// <param name="MerchantName">Razón social del comercio (máx. 255 bytes ANSI).</param>
    /// <param name="CUIT">CUIT del comercio sin guiones (ej: <c>"30123456789"</c>).</param>
    procedure Configure(ComPort: Integer;
      const MerchantName, CUIT: string);

    // -----------------------------------------------------------------------
    // Diagnóstico
    // -----------------------------------------------------------------------

    /// <summary>
    ///   Envía un mensaje de test al POS y verifica que responda correctamente.
    ///   Usar antes de la primera transacción del día o ante sospechas de
    ///   desconexión.
    /// </summary>
    /// <returns>
    ///   <c>True</c> si el POS respondió <c>VPI_OK</c>; <c>False</c> en
    ///   cualquier otro caso.
    /// </returns>
    function TestConnection: Boolean;

    // -----------------------------------------------------------------------
    // Operaciones transaccionales
    // -----------------------------------------------------------------------

    /// <summary>
    ///   Ejecuta una venta con tarjeta en el terminal POS. La operación es
    ///   sincrónica: bloquea hasta recibir respuesta del host o que expire el
    ///   timeout interno de la DLL (1000 ms por defecto).
    /// </summary>
    /// <param name="Monto">
    ///   Importe en centavos sin separador decimal.
    ///   Ejemplo: $1.250,00 → <c>'125000'</c>.
    /// </param>
    /// <param name="Vuelto">Propina o extracción de efectivo en centavos. Usar <c>'0'</c> si no aplica.</param>
    /// <param name="Cuotas">Cantidad de cuotas. Usar <c>'1'</c> para contado.</param>
    /// <param name="Tarjeta">Código de tarjeta (issuerCode) obtenido con <see cref="GetIssuers"/>.</param>
    /// <param name="Plan">Código de plan obtenido con <see cref="GetPlans"/>.</param>
    /// <param name="Ticket">Número de recibo de la venta en el sistema del comercio.</param>
    /// <param name="MCode">Código de comercio asignado por el adquirente.</param>
    /// <param name="MName">Razón social del comercio.</param>
    /// <param name="MCUIT">CUIT del comercio.</param>
    /// <param name="Response">
    ///   Registro con todos los datos de respuesta completados por el POS.
    ///   Solo es válido cuando el retorno es <c>VPI_OK</c>.
    /// </param>
    /// <returns>Código de retorno VPI_*. <c>VPI_OK</c> indica aprobación.</returns>
    function Purchase(
      const Monto, Vuelto, Cuotas, Tarjeta, Plan,
            Ticket, MCode, MName, MCUIT: string;
      out   Response: TTrxResponse): Integer;

    /// <summary>
    ///   Venta con extracción de efectivo (cash-back). Mismos parámetros que
    ///   <see cref="Purchase"/>; el campo <c>Vuelto</c> indica el monto de
    ///   efectivo a devolver al cliente.
    /// </summary>
    function PurchaseExtraCash(
      const Monto, Vuelto, Cuotas, Tarjeta, Plan,
            Ticket, MCode, MName, MCUIT: string;
      out   Response: TTrxResponse): Integer;

    /// <summary>
    ///   Anula una venta previamente aprobada dentro del mismo lote.
    /// </summary>
    /// <param name="Ticket">Número de ticket de la transacción original a anular.</param>
    /// <param name="Tarjeta">Código de tarjeta de la transacción original.</param>
    /// <param name="MName">Razón social del comercio.</param>
    /// <param name="MCUIT">CUIT del comercio.</param>
    /// <param name="Response">Datos de respuesta del POS.</param>
    /// <returns>Código de retorno VPI_*.</returns>
    function VoidTrx(
      const Ticket, Tarjeta, MName, MCUIT: string;
      out   Response: TTrxResponse): Integer;

    /// <summary>
    ///   Realiza una devolución (acredita el importe al portador de la tarjeta).
    /// </summary>
    /// <param name="Monto">Monto a devolver en centavos.</param>
    /// <param name="Cuotas">Cuotas de la transacción original.</param>
    /// <param name="Tarjeta">Código de tarjeta de la transacción original.</param>
    /// <param name="Plan">Código de plan de la transacción original.</param>
    /// <param name="Ticket">Número de ticket de la transacción original.</param>
    /// <param name="Factura">Número de factura del comercio asociada a la devolución.</param>
    /// <param name="MCode">Código de comercio.</param>
    /// <param name="MName">Razón social del comercio.</param>
    /// <param name="MCUIT">CUIT del comercio.</param>
    /// <param name="OriginalDate">
    ///   Fecha de la transacción original (formato AAAAMMDD), tal como la
    ///   devolvió el campo <c>Date</c> de la respuesta original.
    /// </param>
    /// <param name="Response">Datos de respuesta del POS.</param>
    /// <returns>Código de retorno VPI_*.</returns>
    function Refund(
      const Monto, Cuotas, Tarjeta, Plan, Ticket,
            Factura, MCode, MName, MCUIT, OriginalDate: string;
      out   Response: TTrxResponse): Integer;

    /// <summary>
    ///   Anula una devolución previamente aprobada. Mismos parámetros que
    ///   <see cref="Refund"/>.
    /// </summary>
    function RefundVoid(
      const Monto, Cuotas, Tarjeta, Plan, Ticket,
            Factura, MCode, MName, MCUIT, OriginalDate: string;
      out   Response: TTrxResponse): Integer;

    // -----------------------------------------------------------------------
    // Gestión de lote
    // -----------------------------------------------------------------------

    /// <summary>
    ///   Ejecuta el cierre de lote. Envía al host adquirente los totales del
    ///   día y reinicia el contador de lote en el POS.
    /// </summary>
    /// <param name="Response">Datos de respuesta del cierre.</param>
    /// <returns>Código de retorno VPI_*.</returns>
    function BatchClose(out Response: TBatchCloseResponse): Integer;

    /// <summary>
    ///   Recupera los totales por tarjeta del último cierre de lote realizado.
    ///   Iterar desde <c>Index = 0</c> mientras el retorno sea <c>VPI_MORE_REC</c>.
    /// </summary>
    /// <param name="Index">Índice del registro a recuperar (base 0).</param>
    /// <param name="Rec">Registro con los totales de la tarjeta.</param>
    /// <returns>
    ///   <c>VPI_MORE_REC</c> mientras queden registros; <c>VPI_OK</c> al llegar
    ///   al último; otro código indica error.
    /// </returns>
    function GetBatchRecord(Index: Integer; out Rec: TBatchRecord): Integer;

    /// <summary>
    ///   Reimprime el ticket de la última transacción en el POS.
    /// </summary>
    /// <returns>Código de retorno VPI_*.</returns>
    function PrintTicket: Integer;

    /// <summary>
    ///   Reimprime el comprobante del último cierre de lote.
    /// </summary>
    /// <returns>Código de retorno VPI_*.</returns>
    function PrintBatchClose: Integer;

    // -----------------------------------------------------------------------
    // Recuperación de datos históricos
    // -----------------------------------------------------------------------

    /// <summary>
    ///   Obtiene los datos de la última transacción del tipo indicado.
    ///   Útil para recuperar datos ante una caída de comunicación entre el POS
    ///   y el sistema del comercio.
    /// </summary>
    /// <param name="OperType">
    ///   Tipo de operación: <c>VPI_PURCHASE</c>, <c>VPI_VOID</c>,
    ///   <c>VPI_REFUND</c> o <c>VPI_REFUND_VOID</c>.
    /// </param>
    /// <param name="Response">Datos de la última transacción del tipo solicitado.</param>
    /// <returns>Código de retorno VPI_*.</returns>
    function GetLastTransactionData(OperType: Integer;
      out Response: TTrxResponse): Integer;

    // -----------------------------------------------------------------------
    // Consultas de configuración del POS
    // -----------------------------------------------------------------------

    /// <summary>
    ///   Recupera todas las tarjetas habilitadas en el POS iterando
    ///   internamente hasta que el código de retorno deja de ser
    ///   <c>VPI_MORE_REC</c>.
    /// </summary>
    /// <returns>
    ///   Array con los registros de tarjetas. Vacío si ocurre un error en la
    ///   primera lectura.
    /// </returns>
    function GetIssuers: TArray<TIssuerRecord>;

    /// <summary>
    ///   Recupera todos los planes de financiación habilitados en el POS.
    ///   Misma lógica de iteración que <see cref="GetIssuers"/>.
    /// </summary>
    /// <returns>Array con los registros de planes.</returns>
    function GetPlans: TArray<TPlanRecord>;
  end;

implementation

uses
  Winapi.Windows,
  System.SysUtils;

const
  BUF = 256;

// ---------------------------------------------------------------------------
// Helpers privados
// ---------------------------------------------------------------------------

procedure TLaPosClient.LoadProc(var Proc; const Name: string);
begin
  TFarProc(Proc) := GetProcAddress(FHandle, PChar(Name));
  if TFarProc(Proc) = nil then
    raise Exception.CreateFmt(
      'lapos.dll: símbolo exportado "%s" no encontrado.', [Name]);
end;

function TLaPosClient.ToStr(const Buf: array of AnsiChar): string;
begin
  Result := string(AnsiString(PAnsiChar(@Buf[0])));
end;

procedure TLaPosClient.CopyTrxResponse(
  const bRespCode, bMessage, bAuthCode, bTicketNum,
        bBatchNum, bCustomerName, bPanFirst6, bPanLast4,
        bDate, bTime, bTerminalID: array of AnsiChar;
  out Response: TTrxResponse);
begin
  Response.HostRespCode  := ToStr(bRespCode);
  Response.HostMessage   := ToStr(bMessage);
  Response.AuthCode      := ToStr(bAuthCode);
  Response.TicketNumber  := ToStr(bTicketNum);
  Response.BatchNumber   := ToStr(bBatchNum);
  Response.CustomerName  := ToStr(bCustomerName);
  Response.PanFirst6     := ToStr(bPanFirst6);
  Response.PanLast4      := ToStr(bPanLast4);
  Response.Date          := ToStr(bDate);
  Response.Time          := ToStr(bTime);
  Response.TerminalID    := ToStr(bTerminalID);
end;

// ---------------------------------------------------------------------------
// Constructor / Destructor
// ---------------------------------------------------------------------------

constructor TLaPosClient.Create(const DLLPath: string);
begin
  inherited Create;
  FHandle := LoadLibrary(PChar(DLLPath));
  if FHandle = 0 then
    raise Exception.CreateFmt(
      'No se pudo cargar "%s". Código de error Windows: %d.',
      [DLLPath, GetLastError]);

  LoadProc(FSetCom,        'lapos_setCom');
  LoadProc(FSetName,       'lapos_setName');
  LoadProc(FSetCUIT,       'lapos_setCUIT');
  LoadProc(FTest,          'lapos_test');
  LoadProc(FPurchase,      'lapos_purchase');
  LoadProc(FPurchaseXCash, 'lapos_purchase_extra_cash');
  LoadProc(FVoid,          'lapos_void');
  LoadProc(FRefund,        'lapos_refund');
  LoadProc(FRefundVoid,    'lapos_refund_void');
  LoadProc(FBatchClose,    'lapos_batch_close');
  LoadProc(FBatchPrint,    'lapos_batch_print');
  LoadProc(FPrintTicket,   'lapos_print_ticket');
  LoadProc(FGetLastData,   'lapos_get_last_data');
  LoadProc(FGetBatch,      'lapos_get_batch');
  LoadProc(FGetTarjeta,    'lapos_get_tarjeta');
  LoadProc(FGetPlan,       'lapos_get_plan');
end;

destructor TLaPosClient.Destroy;
begin
  if FHandle <> 0 then
    FreeLibrary(FHandle);
  inherited;
end;

// ---------------------------------------------------------------------------
// Configuración
// ---------------------------------------------------------------------------

procedure TLaPosClient.Configure(ComPort: Integer;
  const MerchantName, CUIT: string);
begin
  FSetCom(ComPort);
  FSetName(PAnsiChar(AnsiString(MerchantName)));
  FSetCUIT(PAnsiChar(AnsiString(CUIT)));
end;

// ---------------------------------------------------------------------------
// Diagnóstico
// ---------------------------------------------------------------------------

function TLaPosClient.TestConnection: Boolean;
begin
  Result := (FTest() = VPI_OK);
end;

// ---------------------------------------------------------------------------
// Operaciones transaccionales — helpers de buffer
// ---------------------------------------------------------------------------

type
  TBuf = array[0..BUF - 1] of AnsiChar;

procedure ClearBufs(var Bufs: array of TBuf);
var
  I: Integer;
begin
  for I := Low(Bufs) to High(Bufs) do
    FillChar(Bufs[I], SizeOf(TBuf), 0);
end;

// ---------------------------------------------------------------------------
// Purchase / PurchaseExtraCash
// ---------------------------------------------------------------------------

function TLaPosClient.Purchase(
  const Monto, Vuelto, Cuotas, Tarjeta, Plan,
        Ticket, MCode, MName, MCUIT: string;
  out   Response: TTrxResponse): Integer;
var
  bOut: array[0..10] of TBuf;
begin
  ClearBufs(bOut);
  Result := FPurchase(
    PAnsiChar(AnsiString(Monto)),   PAnsiChar(AnsiString(Vuelto)),
    PAnsiChar(AnsiString(Cuotas)),  PAnsiChar(AnsiString(Tarjeta)),
    PAnsiChar(AnsiString(Plan)),    PAnsiChar(AnsiString(Ticket)),
    PAnsiChar(AnsiString(MCode)),   PAnsiChar(AnsiString(MName)),
    PAnsiChar(AnsiString(MCUIT)),
    bOut[0], bOut[1], bOut[2], bOut[3], bOut[4],
    bOut[5], bOut[6], bOut[7], bOut[8], bOut[9], bOut[10]);
  CopyTrxResponse(
    bOut[0], bOut[1], bOut[2], bOut[3], bOut[4],
    bOut[5], bOut[6], bOut[7], bOut[8], bOut[9], bOut[10], Response);
end;

function TLaPosClient.PurchaseExtraCash(
  const Monto, Vuelto, Cuotas, Tarjeta, Plan,
        Ticket, MCode, MName, MCUIT: string;
  out   Response: TTrxResponse): Integer;
var
  bOut: array[0..10] of TBuf;
begin
  ClearBufs(bOut);
  Result := FPurchaseXCash(
    PAnsiChar(AnsiString(Monto)),   PAnsiChar(AnsiString(Vuelto)),
    PAnsiChar(AnsiString(Cuotas)),  PAnsiChar(AnsiString(Tarjeta)),
    PAnsiChar(AnsiString(Plan)),    PAnsiChar(AnsiString(Ticket)),
    PAnsiChar(AnsiString(MCode)),   PAnsiChar(AnsiString(MName)),
    PAnsiChar(AnsiString(MCUIT)),
    bOut[0], bOut[1], bOut[2], bOut[3], bOut[4],
    bOut[5], bOut[6], bOut[7], bOut[8], bOut[9], bOut[10]);
  CopyTrxResponse(
    bOut[0], bOut[1], bOut[2], bOut[3], bOut[4],
    bOut[5], bOut[6], bOut[7], bOut[8], bOut[9], bOut[10], Response);
end;

// ---------------------------------------------------------------------------
// Void
// ---------------------------------------------------------------------------

function TLaPosClient.VoidTrx(
  const Ticket, Tarjeta, MName, MCUIT: string;
  out   Response: TTrxResponse): Integer;
var
  bOut: array[0..10] of TBuf;
begin
  ClearBufs(bOut);
  Result := FVoid(
    PAnsiChar(AnsiString(Ticket)),  PAnsiChar(AnsiString(Tarjeta)),
    PAnsiChar(AnsiString(MName)),   PAnsiChar(AnsiString(MCUIT)),
    bOut[0], bOut[1], bOut[2], bOut[3], bOut[4],
    bOut[5], bOut[6], bOut[7], bOut[8], bOut[9], bOut[10]);
  CopyTrxResponse(
    bOut[0], bOut[1], bOut[2], bOut[3], bOut[4],
    bOut[5], bOut[6], bOut[7], bOut[8], bOut[9], bOut[10], Response);
end;

// ---------------------------------------------------------------------------
// Refund / RefundVoid
// ---------------------------------------------------------------------------

function TLaPosClient.Refund(
  const Monto, Cuotas, Tarjeta, Plan, Ticket,
        Factura, MCode, MName, MCUIT, OriginalDate: string;
  out   Response: TTrxResponse): Integer;
var
  bOut: array[0..10] of TBuf;
begin
  ClearBufs(bOut);
  Result := FRefund(
    PAnsiChar(AnsiString(Monto)),        PAnsiChar(AnsiString(Cuotas)),
    PAnsiChar(AnsiString(Tarjeta)),      PAnsiChar(AnsiString(Plan)),
    PAnsiChar(AnsiString(Ticket)),       PAnsiChar(AnsiString(Factura)),
    PAnsiChar(AnsiString(MCode)),        PAnsiChar(AnsiString(MName)),
    PAnsiChar(AnsiString(MCUIT)),
    bOut[0], bOut[1], bOut[2], bOut[3], bOut[4],
    bOut[5], bOut[6], bOut[7], bOut[8], bOut[9], bOut[10]);
  CopyTrxResponse(
    bOut[0], bOut[1], bOut[2], bOut[3], bOut[4],
    bOut[5], bOut[6], bOut[7], bOut[8], bOut[9], bOut[10], Response);
end;

function TLaPosClient.RefundVoid(
  const Monto, Cuotas, Tarjeta, Plan, Ticket,
        Factura, MCode, MName, MCUIT, OriginalDate: string;
  out   Response: TTrxResponse): Integer;
var
  bOut: array[0..10] of TBuf;
begin
  ClearBufs(bOut);
  Result := FRefundVoid(
    PAnsiChar(AnsiString(Monto)),        PAnsiChar(AnsiString(Cuotas)),
    PAnsiChar(AnsiString(Tarjeta)),      PAnsiChar(AnsiString(Plan)),
    PAnsiChar(AnsiString(Ticket)),       PAnsiChar(AnsiString(Factura)),
    PAnsiChar(AnsiString(MCode)),        PAnsiChar(AnsiString(MName)),
    PAnsiChar(AnsiString(MCUIT)),
    bOut[0], bOut[1], bOut[2], bOut[3], bOut[4],
    bOut[5], bOut[6], bOut[7], bOut[8], bOut[9], bOut[10]);
  CopyTrxResponse(
    bOut[0], bOut[1], bOut[2], bOut[3], bOut[4],
    bOut[5], bOut[6], bOut[7], bOut[8], bOut[9], bOut[10], Response);
end;

// ---------------------------------------------------------------------------
// Lote
// ---------------------------------------------------------------------------

function TLaPosClient.BatchClose(out Response: TBatchCloseResponse): Integer;
var
  bRespCode, bDate, bTime, bTermID: TBuf;
begin
  FillChar(bRespCode, SizeOf(TBuf), 0);
  FillChar(bDate,     SizeOf(TBuf), 0);
  FillChar(bTime,     SizeOf(TBuf), 0);
  FillChar(bTermID,   SizeOf(TBuf), 0);

  Result := FBatchClose(bRespCode, bDate, bTime, bTermID);

  Response.HostRespCode := ToStr(bRespCode);
  Response.Date         := ToStr(bDate);
  Response.Time         := ToStr(bTime);
  Response.TerminalID   := ToStr(bTermID);
end;

function TLaPosClient.GetBatchRecord(Index: Integer;
  out Rec: TBatchRecord): Integer;
var
  bOut: array[0..14] of TBuf;
begin
  ClearBufs(bOut);
  Result := FGetBatch(
    Index,
    bOut[0],  bOut[1],  bOut[2],  bOut[3],  bOut[4],
    bOut[5],  bOut[6],  bOut[7],  bOut[8],  bOut[9],
    bOut[10], bOut[11], bOut[12], bOut[13], bOut[14]);

  Rec.AcquirerCode  := ToStr(bOut[0]);
  Rec.BatchNumber   := ToStr(bOut[1]);
  Rec.IssuerCode    := ToStr(bOut[2]);
  Rec.PurchaseCount := ToStr(bOut[3]);
  Rec.PurchaseAmount:= ToStr(bOut[4]);
  Rec.VoidCount     := ToStr(bOut[5]);
  Rec.VoidAmount    := ToStr(bOut[6]);
  Rec.RefundCount   := ToStr(bOut[7]);
  Rec.RefundAmount  := ToStr(bOut[8]);
  Rec.RefVoidCount  := ToStr(bOut[9]);
  Rec.RefVoidAmount := ToStr(bOut[10]);
  Rec.Date          := ToStr(bOut[11]);
  Rec.Time          := ToStr(bOut[12]);
  Rec.TerminalID    := ToStr(bOut[14]);
end;

function TLaPosClient.PrintTicket: Integer;
begin
  Result := FPrintTicket();
end;

function TLaPosClient.PrintBatchClose: Integer;
begin
  Result := FBatchPrint();
end;

// ---------------------------------------------------------------------------
// Recuperación histórica
// ---------------------------------------------------------------------------

function TLaPosClient.GetLastTransactionData(OperType: Integer;
  out Response: TTrxResponse): Integer;
var
  bOut: array[0..10] of TBuf;
begin
  ClearBufs(bOut);
  Result := FGetLastData(
    OperType,
    bOut[0], bOut[1], bOut[2], bOut[3], bOut[4],
    bOut[5], bOut[6], bOut[7], bOut[8], bOut[9], bOut[10]);
  CopyTrxResponse(
    bOut[0], bOut[1], bOut[2], bOut[3], bOut[4],
    bOut[5], bOut[6], bOut[7], bOut[8], bOut[9], bOut[10], Response);
end;

// ---------------------------------------------------------------------------
// Consultas de configuración del POS
// ---------------------------------------------------------------------------

function TLaPosClient.GetIssuers: TArray<TIssuerRecord>;
var
  I, Ret: Integer;
  bAdq, bCode, bName, bCuotas, bTerm: TBuf;
  Rec: TIssuerRecord;
begin
  Result := [];
  I := 0;
  repeat
    FillChar(bAdq,    SizeOf(TBuf), 0);
    FillChar(bCode,   SizeOf(TBuf), 0);
    FillChar(bName,   SizeOf(TBuf), 0);
    FillChar(bCuotas, SizeOf(TBuf), 0);
    FillChar(bTerm,   SizeOf(TBuf), 0);

    Ret := FGetTarjeta(I, bAdq, bCode, bName, bCuotas, bTerm);
    if (Ret = VPI_OK) or (Ret = VPI_MORE_REC) then
    begin
      Rec.AcquirerCode := ToStr(bAdq);
      Rec.IssuerCode   := ToStr(bCode);
      Rec.IssuerName   := ToStr(bName);
      Rec.MaxInstCount := ToStr(bCuotas);
      Rec.TerminalID   := ToStr(bTerm);
      Result := Result + [Rec];
    end;
    Inc(I);
  until Ret <> VPI_MORE_REC;
end;

function TLaPosClient.GetPlans: TArray<TPlanRecord>;
var
  I, Ret: Integer;
  bTarjeta, bCode, bLabel, bTerm: TBuf;
  Rec: TPlanRecord;
begin
  Result := [];
  I := 0;
  repeat
    FillChar(bTarjeta, SizeOf(TBuf), 0);
    FillChar(bCode,    SizeOf(TBuf), 0);
    FillChar(bLabel,   SizeOf(TBuf), 0);
    FillChar(bTerm,    SizeOf(TBuf), 0);

    Ret := FGetPlan(I, bTarjeta, bCode, bLabel, bTerm);
    if (Ret = VPI_OK) or (Ret = VPI_MORE_REC) then
    begin
      Rec.IssuerCode := ToStr(bTarjeta);
      Rec.PlanCode   := ToStr(bCode);
      Rec.PlanLabel  := ToStr(bLabel);
      Rec.TerminalID := ToStr(bTerm);
      Result := Result + [Rec];
    end;
    Inc(I);
  until Ret <> VPI_MORE_REC;
end;

end.
