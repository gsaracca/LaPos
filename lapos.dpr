library lapos;

{ Important note about DLL memory management: ShareMem must be the
  first unit in your library's USES clause AND your project's (select
  Project-View Source) USES clause if your DLL exports any procedures or
  functions that pass strings as parameters or function results. This
  applies to all strings passed to and from your DLL--even those that
  are nested in records and classes. ShareMem is the interface unit to
  the BORLNDMM.DLL shared memory manager, which must be deployed along
  with your DLL. To avoid using BORLNDMM.DLL, pass string information
  using PChar or ShortString parameters. }

uses
//  System.Classes,
//  System.AnsiStrings,
  System.SysUtils,
  Vcl.Dialogs,
  ActiveX,
  VpiPC;

const
  timeOut = 1000;
  nl = chr(10) + chr(13);

Type LaPosType = record
        com :integer;
        cName :pAnsiChar;
        CUIT :pAnsiChar;
    end;

var
  LaPosRec :LaPosType;

procedure lapos_setCom( com :integer ); cdecl;
begin
    LaPosRec.com := com;
end;

procedure lapos_setName( _name :pAnsiChar ); cdecl;
begin
    StrPCopy( LaPosRec.cName, _name );
end;

procedure lapos_setCUIT( _cuit :pAnsiChar ); cdecl;
begin
    StrPCopy( LaPosRec.CUIT, _cuit );
end;

procedure freeTrx( var _trx :vpiTrxOut_T );
begin
    StrDispose( _trx.hostRespCode );
    StrDispose( _trx.hostMessage );
    StrDispose( _trx.authCode );
    StrDispose( _trx.ticketNumber );
    StrDispose( _trx.batchNumber );
    StrDispose( _trx.customerName );
    StrDispose( _trx.panFirst6 );      { +// Eldar MOD --->*/ }
    StrDispose( _trx.panLast4 );       { +// <--- Eldar MOD*/ }
    StrDispose( _trx.date );
    StrDispose( _trx.time );
    StrDispose( _trx.terminalID  );
end;

procedure newTrx( var _trx :vpiTrxOut_T );
begin
  _trx.hostRespCode := AnsiStrAlloc(256); StrPCopy( _trx.hostRespCode, '');
  _trx.hostMessage := AnsiStrAlloc(256);  StrPCopy( _trx.hostMessage, '');
  _trx.authCode := AnsiStrAlloc(256);     StrPCopy( _trx.authCode, '');
  _trx.ticketNumber := AnsiStrAlloc(256); StrPCopy( _trx.ticketNumber, '');
  _trx.batchNumber := AnsiStrAlloc(256);  StrPCopy( _trx.batchNumber, '');
  _trx.customerName := AnsiStrAlloc(256); StrPCopy( _trx.customerName, '');
  _trx.panFirst6 := AnsiStrAlloc(256);    StrPCopy( _trx.panFirst6, '');    { +// Eldar MOD --->*/ }
  _trx.panLast4 := AnsiStrAlloc(256);     StrPCopy( _trx.panLast4, '');     { +// <--- Eldar MOD*/ }
  _trx.date := AnsiStrAlloc(256);         StrPCopy( _trx.date, '');
  _trx.time := AnsiStrAlloc(256);         StrPCopy( _trx.time, '');
  _trx.terminalID := AnsiStrAlloc(256);   StrPCopy( _trx.terminalID, '');
end;

function check_error( errCode :integer ) :boolean;
var ret :boolean;
    msg :string;
begin
  ret := false;
  case errCode of
    VPI_OK             : ret := true;              { // Operacion exitosa }
    VPI_MORE_REC       : ret := true;              { // Operacion exitosa, pero faltan registros }
    VPI_FAIL           : msg := 'FAIL - El comando no pudo ser enviado';
    VPI_TIMEOUT_EXP    : msg := 'TIMEOUT_EXP - Tiempo de espera agotado';

    VPI_INVALID_ISSUER : msg := 'INVALID_ISSUER - El código de tarjeta no existe';
    VPI_INVALID_TICKET : msg := 'INVALID_TICKET - El número de cupón no existe';
    VPI_INVALID_PLAN   : msg := 'INVALID_PLAN - El código de plan no existe';
    VPI_INVALID_INDEX  : msg := 'INVALID_INDEX - No existe el indice';
    VPI_EMPTY_BATCH    : msg := 'EMPTY_BATCH - El lote del POS se encuentra vacío';

    VPI_TRX_CANCELED   : msg := 'TRX_CANCELED - Transacción cancelada por el usuario';
    VPI_DIF_CARD       : msg := 'DIF_CARD - La tarjeta deslizada por el usuario no coincide con la pedida';
    VPI_INVALID_CARD   : msg := 'INVALID_CARD - La tarjeta deslizada no es válida';
    VPI_EXPIRED_CARD   : msg := 'EXPIRED_CARD - La tarjeta deslizada está vencida';
    VPI_INVALID_TRX    : msg := 'INVALID_TRX - La transacción original no existe';

    VPI_ERR_COM        : msg := 'ERR_COM -  El POS no pudo comunicarse con el host';
    VPI_ERR_PRINT      : msg := 'ERR_PRINT - El POS no pudo imprimir el ticket';

    VPI_INVALID_IN_CMD : msg := 'INVALID_IN_CMD - Nombre del comando inexistente';
    VPI_INVALID_IN_PARAM:msg := 'INVALID_IN_PARAM - Formato de algún parámetro de entrada no es correcto';
    VPI_INVALID_OUT_CMD: msg := 'INVALID_OUT_CMD - El comando enviado por el sistema no es correcto';
    VPI_GENERAL_FAIL   : msg := 'GENERAL_FAIL - Error general en la operación';

    else                 msg := 'UNKNOW - Error desconocido del sistema'

  end;
//  if not ret then
//    ShowMessage( errStr + nl + msg + nl + 'Código #' + System.SysUtils.intToStr(errCode) );

  check_error := ret;
end;

function lapos_openCom() :boolean;
  var
    sCom: pAnsiChar;
    params :PCOMPARAMS_T;
    int_code: integer;

  procedure newParams();
  var iCom :String;
  begin
    iCom := System.SysUtils.intToStr(LaPosRec.Com);
    if (LaPosRec.Com < 1) or (LaPosRec.Com > 32) then begin
      LaPosRec.Com := 9;
      ShowMessage( 'Puerto Seleccionado por Defecto [COM' + iCom + '].');
    end;
    sCom := AnsiStrAlloc(256); StrPCopy( sCom, 'COM' + iCom );
    params.com := sCom;
    params.baudRate := 19200;
    params.byteSize := 8;
    params.parity := 'N';
    params.stopBits := 1;
  end;

  procedure freeParams();
  begin
    StrDispose( sCom );
  end;

begin
  newParams();
  int_code := vpiOpenPort( params );
  freeParams();

  lapos_openCom := check_error( int_code );
end; // openCom

function lapos_closeCom() :boolean;
var
  int_code: integer;
begin
  int_code := vpiClosePort();

  lapos_closeCom := check_error( int_code );
end; // closeCom

function lapos_get_tarjeta( i: integer;
                            _adq, _tarCode, _tarName, _cuotas,
                            _term :PAnsiChar ) :integer; cdecl;
var
  int_code: integer;
  issuer: vpiIssuerOut_T;

  procedure assign_values();
  begin
    StrPCopy( _adq, issuer.acquirerCode );
    StrPCopy( _tarCode, issuer.issuerCode );
    StrPCopy( _tarName, issuer.issuerName );
    StrPCopy( _cuotas, issuer.maxInstCount );
    StrPCopy( _term, issuer.terminalID )
  end;

  procedure newIssuer();
  begin
    issuer.index := i;
    issuer.acquirerCode := AnsiStrAlloc(256);  StrPCopy(issuer.acquirerCode, '');
    issuer.issuerCode := AnsiStrAlloc(256);    StrPCopy(issuer.issuerCode, '');
    issuer.issuerName := AnsiStrAlloc(256);    StrPCopy(issuer.issuerName, '');
    issuer.maxInstCount := AnsiStrAlloc(256);  StrPCopy(issuer.maxInstCount, '');
    issuer.terminalID := AnsiStrAlloc(256);    StrPCopy(issuer.terminalID, '');
  end;

  procedure freeIssuer();
  begin
    StrDispose(issuer.acquirerCode);
    StrDispose(issuer.issuerCode);
    StrDispose(issuer.issuerName);
    StrDispose(issuer.maxInstCount);
    StrDispose(issuer.terminalID);
  end;

begin
  if lapos_openCom() then begin
      newIssuer();

      int_code := vpiGetIssuer( i, issuer );
      if check_error( int_code ) then begin
          assign_values();
      end;

      freeIssuer();
      lapos_closeCom();
  end;
  lapos_get_tarjeta := int_code;
end;

function lapos_get_plan( i :integer;
                      _tarjeta, _planCode,
                      _planLabel, _term :pAnsiChar )  :integer; cdecl;
var
  int_code: integer;
  plan: VPIPLANOUT_T;

  procedure NewPlan();
  begin
      plan.index := i;
      plan.issuerCode := AnsiStrAlloc(256);   StrPCopy(plan.issuerCode, '');
      plan.planCode := AnsiStrAlloc(256);     StrPCopy(plan.planCode, '');
      plan.planLabel := AnsiStrAlloc(256);    StrPCopy(plan.planLabel, '');
      plan.terminalID := AnsiStrAlloc(256);   StrPCopy(plan.terminalID, '');
  end;

  procedure freePlan();
  begin
      StrDispose(plan.issuerCode);
      StrDispose(plan.planCode);
      StrDispose(plan.planLabel);
      StrDispose(plan.terminalID);
  end;

  procedure assing_values();
  begin
      StrPCopy( _tarjeta, plan.issuerCode );
      StrPCopy( _planCode, plan.planCode );
      StrPCopy( _planLabel, plan.planLabel );
      StrPCopy( _term, plan.terminalID );
  end;

begin
  if lapos_openCom() then begin

      newPlan();

      int_code := vpiGetPlan(i, plan);
      if check_error( int_code ) then begin
          assing_values();
      end;

      freePlan();
      lapos_closeCom();

  end;
  lapos_get_plan := int_code;
end; // GetPlan

function lapos_test() :integer; cdecl;
var
  int_code: integer;
begin
  if lapos_openCom() then begin

    int_code := vpiTestConnection();

    if check_error( int_code ) then begin
    end;

    lapos_closeCom();
  end;
  lapos_test := int_code;
end;

function lapos_purchase(  _monto, _vuelto, _cuotas, _tarjeta, _plan, _ticket,
                          _mCode, _mName, _mCUIT,
                          _hostRespCode, _hostMessage,
                          _authCode, _ticketNumber,
                          _batchNumber, _customerName,
                          _panFirst6, _panLast4,
                          _date, _time,
                          _terminalID :pAnsiChar ) :integer; cdecl;
var
  Purch: vpiPurchaseIn_t;
  TrxOut: vpiTrxOut_T;
  int_code: integer;

  procedure newPurch();
  begin
    Purch.amount := AnsiStrAlloc(256);            	StrPCopy(Purch.amount, _monto);
    Purch.instalmentCount := AnsiStrAlloc(256);     StrPCopy(Purch.instalmentCount, _cuotas );
    Purch.issuerCode := AnsiStrAlloc(256);          StrPCopy(Purch.issuerCode, _tarjeta );
    Purch.planCode := AnsiStrAlloc(256);            StrPCopy(Purch.planCode, _plan );
    Purch.receiptNumber := AnsiStrAlloc(256);       StrPCopy(Purch.receiptNumber, _ticket );
    Purch.tip := AnsiStrAlloc(256);                 StrPCopy(Purch.tip, _vuelto );
    Purch.merchantCode := AnsiStrAlloc(256);        StrPCopy(Purch.merchantCode, _mCode );
    Purch.merchantName := AnsiStrAlloc(256);        StrPCopy(Purch.merchantName, _mName );
    Purch.cuit := AnsiStrAlloc(256);                StrPCopy(Purch.cuit, _mCUIT );
    Purch.linemode := 1;                            // transaccion Online(1) o Offline(0)
  end;

  procedure freePurch();
  begin
    StrDispose( Purch.amount );
    StrDispose( Purch.instalmentCount );
    StrDispose( Purch.issuerCode );
    StrDispose( Purch.planCode );
    StrDispose( Purch.receiptNumber );
    StrDispose( Purch.merchantCode );
    StrDispose( Purch.merchantName );
    StrDispose( Purch.cuit );
  end;

  procedure assign_value();
  begin
      StrPCopy( _hostRespCode, TrxOut.hostRespCode );
      StrPCopy( _hostMessage, TrxOut.hostMessage );
      StrPCopy( _authCode, TrxOut.authCode );
      StrPCopy( _ticketNumber, TrxOut.ticketNumber );
      StrPCopy( _batchNumber, TrxOut.batchNumber );
      StrPCopy( _customerName, TrxOut.customerName );
      StrPCopy( _panFirst6, TrxOut.panFirst6 );
      StrPCopy( _panLast4, TrxOut.panLast4 );
      StrPCopy( _date, TrxOut.date );
      StrPCopy( _time, TrxOut.time );
      StrPCopy( _terminalID, TrxOut.terminalID );
  end;

begin
  if lapos_openCom() then begin

    newPurch();
    newTrx( TrxOut );

    int_code := vpiPurchase( Purch, TrxOut, timeOut);
    if check_error( int_code ) then begin
        assign_value();
    end;

    freePurch();
    freeTrx( TrxOut );

    lapos_closeCom();

  end;
  lapos_purchase := int_code;
end;

function lapos_purchase_extra_cash(  _monto, _vuelto, _cuotas, _tarjeta, _plan, _ticket,
                          _mCode, _mName, _mCUIT,
                          _hostRespCode, _hostMessage,
                          _authCode, _ticketNumber,
                          _batchNumber, _customerName,
                          _panFirst6, _panLast4,
                          _date, _time,
                          _terminalID :pAnsiChar ) :integer; cdecl;
var
  Purch: vpiPurchaseIn_t;
  TrxOut: vpiTrxOut_T;
  int_code: integer;

  procedure newPurch();
  begin
    Purch.amount := AnsiStrAlloc(256);            	StrPCopy(Purch.amount, _monto);
    Purch.instalmentCount := AnsiStrAlloc(256);     StrPCopy(Purch.instalmentCount, _cuotas );
    Purch.issuerCode := AnsiStrAlloc(256);          StrPCopy(Purch.issuerCode, _tarjeta );
    Purch.planCode := AnsiStrAlloc(256);            StrPCopy(Purch.planCode, _plan );
    Purch.receiptNumber := AnsiStrAlloc(256);       StrPCopy(Purch.receiptNumber, _ticket );
    Purch.tip := AnsiStrAlloc(256);                 StrPCopy(Purch.tip, _vuelto );
    Purch.merchantCode := AnsiStrAlloc(256);        StrPCopy(Purch.merchantCode, _mCode );
    Purch.merchantName := AnsiStrAlloc(256);        StrPCopy(Purch.merchantName, _mName );
    Purch.cuit := AnsiStrAlloc(256);                StrPCopy(Purch.cuit, _mCUIT );
    Purch.linemode := 1;                            // transaccion Online(1) o Offline(0)
  end;

  procedure freePurch();
  begin
    StrDispose( Purch.amount );
    StrDispose( Purch.instalmentCount );
    StrDispose( Purch.issuerCode );
    StrDispose( Purch.planCode );
    StrDispose( Purch.receiptNumber );
    StrDispose( Purch.merchantCode );
    StrDispose( Purch.merchantName );
    StrDispose( Purch.cuit );
  end;

  procedure assign_value();
  begin
      StrPCopy( _hostRespCode, TrxOut.hostRespCode );
      StrPCopy( _hostMessage, TrxOut.hostMessage );
      StrPCopy( _authCode, TrxOut.authCode );
      StrPCopy( _ticketNumber, TrxOut.ticketNumber );
      StrPCopy( _batchNumber, TrxOut.batchNumber );
      StrPCopy( _customerName, TrxOut.customerName );
      StrPCopy( _panFirst6, TrxOut.panFirst6 );
      StrPCopy( _panLast4, TrxOut.panLast4 );
      StrPCopy( _date, TrxOut.date );
      StrPCopy( _time, TrxOut.time );
      StrPCopy( _terminalID, TrxOut.terminalID );
  end;

begin
  if lapos_openCom() then begin

    newPurch();
    newTrx( TrxOut );

    int_code := vpiPurchaseExtraCash( Purch, TrxOut, timeOut);
    if check_error( int_code ) then begin
        assign_value();
    end;

    freePurch();
    freeTrx( TrxOut );

    lapos_closeCom();

  end;
  lapos_purchase_extra_cash := int_code;
end;


function lapos_void(  _ticket, _tarjeta, _cName, _cCUIT,    // 4
                      _hostRespCode, _hostMessage,          // 2 = 6
                      _authCode, _ticketNumber,             // 2 = 8
                      _batchNumber, _customerName,          // 2 = 10
                      _panFirst6, _panLast4,                // 2 = 12
                      _date, _time, _terminalID             // 3 = 15
                      :pAnsiChar ) :integer; cdecl;
var
  void      :vpiVoidIn_t;
  TrxOut    :vpiTrxOut_T;
  int_code  :integer;

  procedure newVoid();
  begin
    void.originalTicket := AnsiStrAlloc(256); StrPCopy(void.originalTicket, _ticket ); // Nro. ticket de la trx. original
    void.issuerCode := AnsiStrAlloc(256);     StrPCopy(void.issuerCode, _tarjeta); // Código de tarjeta
    void.merchantName := AnsiStrAlloc(256);   StrPCopy(void.merchantName, _cName); // Razon social del comercio
    void.cuit := AnsiStrAlloc(256);           StrPCopy(void.cuit, _cCUIT ); // CUIT del comercio
  end;

  procedure freeVoid();
  begin
    StrDispose(void.originalTicket);  // Nro. ticket de la trx. original
    StrDispose(void.issuerCode);  // Código de tarjeta
    StrDispose(void.merchantName);    // Razon social del comercio
    StrDispose(void.cuit);            // CUIT del comercio
  end;

  procedure assign_value();
  begin
      StrPCopy( _hostRespCode, TrxOut.hostRespCode );
      StrPCopy( _hostMessage, TrxOut.hostMessage );
      StrPCopy( _authCode, TrxOut.authCode );
      StrPCopy( _ticketNumber, TrxOut.ticketNumber );
      StrPCopy( _batchNumber, TrxOut.batchNumber );
      StrPCopy( _customerName, TrxOut.customerName );
      StrPCopy( _panFirst6, TrxOut.panFirst6 );
      StrPCopy( _panLast4, TrxOut.panLast4 );
      StrPCopy( _date, TrxOut.date );
      StrPCopy( _time, TrxOut.time );
      StrPCopy( _terminalID, TrxOut.terminalID );
  end;

begin
  if lapos_openCom() then begin

    newVoid();
    newTrx( TrxOut );

    int_code := vpiVoid( void, TrxOut, timeOut);
    if check_error( int_code ) then begin
        assign_value();
    end;

//    freeTrx( TrxOut );
    freeVoid();

    lapos_closeCom();
  end;
  lapos_void := int_code;
end;

function lapos_refund(  _monto, _cuotas, _tarjeta, _plan, _ticket,
                        _factura, _mCode, _mName, _mCUIT,
                        _hostRespCode, _hostMessage,
                        _authCode, _ticketNumber,
                        _batchNumber, _customerName,
                        _panFirst6, _panLast4,
                        _date, _time,
                        _terminalID :pAnsiChar ) :integer; cdecl;
var
  refund: vpiRefundIn_t;
  TrxOut: vpiTrxOut_T;
  int_code: integer;

  procedure newRefund();
  begin
    refund.amount := AnsiStrAlloc(256);           StrPCopy(refund.amount, _monto ); // Monto *100
    refund.instalmentCount := AnsiStrAlloc(256);  StrPCopy(refund.instalmentCount, _cuotas ); // Cant. de cuotas
    refund.issuerCode := AnsiStrAlloc(256);       StrPCopy(refund.issuerCode, _tarjeta ); // Código de tarjeta
    refund.planCode := AnsiStrAlloc(256);         StrPCopy(refund.planCode, _plan ); // Código de plan
    refund.originalTicket := AnsiStrAlloc(256);   StrPCopy(refund.originalTicket, _ticket ); // Nro. ticket de la trx. original
    refund.originalDate := AnsiStrAlloc(256);     StrPCopy(refund.originalDate, _date ); // Fecha de la trx. original
    refund.receiptNumber := AnsiStrAlloc(256);    StrPCopy(refund.receiptNumber, _factura ); // Número de factura
    refund.merchantCode := AnsiStrAlloc(256);     StrPCopy(refund.merchantCode, _mCode ); // Código de comercio a utilizar
    refund.merchantName := AnsiStrAlloc(256);     StrPCopy(refund.merchantName, _mName ); // Razon social del comercio
    refund.cuit := AnsiStrAlloc(256);             StrPCopy(refund.cuit, _mCUIT); // CUIT del comercio
    refund.linemode := 1;                         // transaccion Online(1) o Offline(0)
  end;

  procedure freeRefund();
  begin
    StrDispose(refund.amount);            // Monto *100
    StrDispose(refund.instalmentCount);   // Cant. de cuotas
    StrDispose(refund.issuerCode);        // Código de tarjeta
    StrDispose(refund.planCode);          // Código de plan
    StrDispose(refund.originalTicket);    // Nro. ticket de la trx. original
    StrDispose(refund.originalDate);      // Fecha de la trx. original
    StrDispose(refund.receiptNumber);     // Número de factura
    StrDispose(refund.merchantCode);      // Código de comercio a utilizar
    StrDispose(refund.merchantName);      // Razon social del comercio
    StrDispose(refund.cuit);              // CUIT del comercio
  end;

  procedure assign_value();
  begin
      StrPCopy( _hostRespCode, TrxOut.hostRespCode );
      StrPCopy( _hostMessage, TrxOut.hostMessage );
      StrPCopy( _authCode, TrxOut.authCode );
      StrPCopy( _ticketNumber, TrxOut.ticketNumber );
      StrPCopy( _batchNumber, TrxOut.batchNumber );
      StrPCopy( _customerName, TrxOut.customerName );
      StrPCopy( _panFirst6, TrxOut.panFirst6 );
      StrPCopy( _panLast4, TrxOut.panLast4 );
      StrPCopy( _date, TrxOut.date );
      StrPCopy( _time, TrxOut.time );
      StrPCopy( _terminalID, TrxOut.terminalID );
  end;

begin
  if lapos_openCom() then begin

    newRefund();
    newTrx( TrxOut );

    int_code := vpiRefund( refund, TrxOut, timeOut );
    if check_error( int_code ) then begin
      assign_value();
    end;

    freeRefund();
    freeTrx( TrxOut );
    lapos_closeCom();

  end;
  lapos_refund := int_code;
end;

function lapos_refund_void( _monto, _cuotas, _tarjeta, _plan, _ticket,
                      _factura, _mCode, _mName, _mCUIT,
                      _hostRespCode, _hostMessage,
                      _authCode, _ticketNumber,
                      _batchNumber, _customerName,
                      _panFirst6, _panLast4,
                      _date, _time,
                      _terminalID :pAnsiChar ) :integer; cdecl;
var
  refVoid: vpiVoidIn_t;
  TrxOut: vpiTrxOut_T;
  int_code: integer;

  procedure newRefundVoid();
  begin
    refVoid.originalTicket := AnsiStrAlloc(256);    StrPCopy(refVoid.originalTicket, ''); // Nro. ticket de la trx. original
    refVoid.issuerCode := AnsiStrAlloc(256);        StrPCopy(refVoid.originalTicket, ''); // Código de tarjeta
    refVoid.merchantName := AnsiStrAlloc(256);      StrPCopy(refVoid.merchantName, ''); // Razon social del comercio
    refVoid.cuit := AnsiStrAlloc(256);              StrPCopy(refVoid.cuit, ''); // CUIT del comercio
  end;

  procedure freeRefundVoid();
  begin
    StrDispose(refVoid.originalTicket); // Nro. ticket de la trx. original
    StrDispose(refVoid.issuerCode); // Código de tarjeta
    StrDispose(refVoid.merchantName);   // Razon social del comercio
    StrDispose(refVoid.cuit);           // CUIT del comercio
  end;

  procedure assign_value();
  begin
      StrPCopy( _hostRespCode, TrxOut.hostRespCode );
      StrPCopy( _hostMessage, TrxOut.hostMessage );
      StrPCopy( _authCode, TrxOut.authCode );
      StrPCopy( _ticketNumber, TrxOut.ticketNumber );
      StrPCopy( _batchNumber, TrxOut.batchNumber );
      StrPCopy( _customerName, TrxOut.customerName );
      StrPCopy( _panFirst6, TrxOut.panFirst6 );
      StrPCopy( _panLast4, TrxOut.panLast4 );
      StrPCopy( _date, TrxOut.date );
      StrPCopy( _time, TrxOut.time );
      StrPCopy( _terminalID, TrxOut.terminalID );
  end;

begin
  if lapos_openCom() then begin

    newRefundVoid();
    newTrx( TrxOut );

    int_code := vpiRefundVoid(refVoid, TrxOut, timeOut);
    if check_error( int_code ) then begin
      assign_value();
    end;

    freeRefundVoid();
    freeTrx( TrxOut );
    lapos_closeCom();

  end;
  lapos_Refund_void := int_code;
end;

function lapos_batch_close( _hostRespCode, _date, _time, _terminalID :pAnsiChar ) :integer; cdecl;
var
  batchOut: vpiBatchCloseOut_t;
  int_code: integer;

  procedure newBatch();
  begin
    batchOut.hostRespCode := AnsiStrAlloc(256);   StrPCopy(batchOut.hostRespCode, '');
    batchOut.date := AnsiStrAlloc(256);           StrPCopy(batchOut.date, '');
    batchOut.time := AnsiStrAlloc(256);           StrPCopy(batchOut.time, '');
    batchOut.terminalID := AnsiStrAlloc(256);     StrPCopy(batchOut.terminalID, '');
  end;

  procedure freeBatch();
  begin
    StrDispose(batchOut.hostRespCode);
    StrDispose(batchOut.date);
    StrDispose(batchOut.time);
    StrDispose(batchOut.terminalID);
  end;

  procedure assign_values();
  begin
    StrPCopy( _hostRespCode, batchOut.hostRespCode );
    StrPCopy( _date, batchOut.date );
    StrPCopy( _time, batchOut.time );
    StrPCopy( _terminalID, batchOut.terminalID );
  end;

begin
  if lapos_openCom() then begin

    newBatch();

    int_code := vpiBatchClose( batchOut, timeOut );
    if check_error( int_code ) then begin
        assign_values();
    end;

    freeBatch();
    lapos_closeCom();

  end;
  lapos_batch_close := int_code;
end;

function lapos_get_last_data( _oper :integer;
                       _hostRespCode, _hostMessage,
                       _authCode, _ticketNumber,
                       _batchNumber, _customerName,
                       _panFirst6, _panLast4,
                       _date, _time,
                       _terminalID :pAnsiChar ) :integer; cdecl;
var
  trxCode :word;
  TrxOut :vpiTrxOut_T;
  int_code :integer;

  procedure assign_value();
  begin
      StrPCopy( _hostRespCode, TrxOut.hostRespCode );
      StrPCopy( _hostMessage, TrxOut.hostMessage );
      StrPCopy( _authCode, TrxOut.authCode );
      StrPCopy( _ticketNumber, TrxOut.ticketNumber );
      StrPCopy( _batchNumber, TrxOut.batchNumber );
      StrPCopy( _customerName, TrxOut.customerName );
      StrPCopy( _panFirst6, TrxOut.panFirst6 );
      StrPCopy( _panLast4, TrxOut.panLast4 );
      StrPCopy( _date, TrxOut.date );
      StrPCopy( _time, TrxOut.time );
      StrPCopy( _terminalID, TrxOut.terminalID );
  end;

begin
  if lapos_OpenCom() then begin

    trxCode := _oper;
    // VPI_PURCHASE
    // VPI_VOID,
    // VPI_REFUND,
    // VPI_REFUND_VOID

    newTrx( TrxOut );

    int_code := vpiGetLastTrxData( trxCode, TrxOut );
    if check_error( int_code ) then begin
        assign_value();
    end;

    freeTrx( TrxOut );
    lapos_closeCom();

  end;
  lapos_get_last_data := int_code;
end;

function lapos_get_batch(   i :integer;
                            _adquirente, _batch, _tarjeta,
                            _purchCount, _purchAmount,
                            _voidCount, _voidAmount,
                            _refCount, _refAmount,
                            _refVoidCount, _refVoidAmount,
                            _date, _time, _term :pAnsiChar ) :integer; cdecl;
var
  batch: vpiBatchCloseDataOut_T;
  int_code: integer;

  procedure newBatch();
  begin
    batch.index := i;
    batch.acquirerCode := AnsiStrAlloc(256);     StrPCopy(batch.acquirerCode, '');
    batch.batchNumber := AnsiStrAlloc(256);      StrPCopy(batch.batchNumber, '');
    batch.issuerCode := AnsiStrAlloc(256);       StrPCopy(batch.issuerCode, '');
    batch.purchaseCount := AnsiStrAlloc(256);    StrPCopy(batch.purchaseCount, '');
    batch.purchaseAmount := AnsiStrAlloc(256);   StrPCopy(batch.purchaseAmount, '');
    batch.voidCount := AnsiStrAlloc(256);        StrPCopy(batch.voidCount, '');
    batch.voidAmount := AnsiStrAlloc(256);       StrPCopy(batch.voidAmount, '');
    batch.refundCount := AnsiStrAlloc(256);      StrPCopy(batch.refundCount, '');
    batch.refundAmount := AnsiStrAlloc(256);     StrPCopy(batch.refundAmount, '');
    batch.refvoidCount := AnsiStrAlloc(256);     StrPCopy(batch.refvoidCount, '');
    batch.refvoidAmount := AnsiStrAlloc(256);    StrPCopy(batch.refvoidAmount, '');
    batch.date := AnsiStrAlloc(256);             StrPCopy(batch.date, '');
    batch.time := AnsiStrAlloc(256);             StrPCopy(batch.time, '');
    batch.terminalID := AnsiStrAlloc(256);       StrPCopy(batch.terminalID, '');
  end;

  procedure freeBatch();
  begin
    StrDispose(batch.acquirerCode);
    StrDispose(batch.batchNumber);
    StrDispose(batch.issuerCode);
    StrDispose(batch.purchaseCount);
    StrDispose(batch.purchaseAmount);
    StrDispose(batch.voidCount);
    StrDispose(batch.voidAmount);
    StrDispose(batch.refundCount);
    StrDispose(batch.refundAmount);
    StrDispose(batch.refvoidCount);
    StrDispose(batch.refvoidAmount);
    StrDispose(batch.date);
    StrDispose(batch.time);
    StrDispose(batch.terminalID);
  end;

  procedure assign_value();
  begin
    StrPCopy( _adquirente,    batch.acquirerCode );
    StrPCopy( _batch,         batch.batchNumber );
    StrPCopy( _tarjeta,       batch.issuerCode );
    StrPCopy( _purchCount,    batch.purchaseCount );
    StrPCopy( _purchAmount,   batch.purchaseAmount );
    StrPCopy( _voidCount,     batch.voidCount );
    StrPCopy( _voidAmount,    batch.voidAmount );
    StrPCopy( _refCount,      batch.refundCount );
    StrPCopy( _refAmount,     batch.refundAmount );
    StrPCopy( _refVoidCount,  batch.refvoidCount );
    StrPCopy( _refVoidAmount, batch.refvoidAmount );
    StrPCopy( _date,          batch.date );
    StrPCopy( _time,          batch.time );
    StrPCopy( _term,          batch.terminalID );
  end;

begin
  if lapos_openCom() then begin

    newBatch();

    int_code := vpiGetBatchCloseData( i, batch);
    if check_error( int_code ) then begin
        assign_value();
    end;

    freeBatch();
    lapos_closeCom();

  end;
  lapos_get_batch := int_code;
end;

function lapos_print_ticket() :integer; cdecl;
var
  int_code: integer;

begin
  if lapos_openCom() then begin

    int_code := vpiPrintTicket();
    if check_error( int_code ) then begin
    end;

    lapos_closeCom();

  end;
  lapos_print_ticket := int_code;
end;

function lapos_batch_print() :integer; cdecl;
var
  int_code: integer;
begin
  if lapos_openCom() then begin

    int_code := vpiPrintBatchClose();
    if check_error( int_code ) then begin
    end;

    lapos_closeCom();

  end;
  lapos_batch_print := int_code;
end;

procedure lapos_export();
var
  myFile: TextFile;
  trj_acquirerCode,
  trj_issuerCode, trj_issuerName,
  trj_maxInstCount, trj_terminalID :pAnsiChar;

  plan_issuerCode,
  plan_planCode, plan_planLabel,
  plan_terminalID :pAnsiChar;

  procedure newTRJ();
  begin
    trj_acquirerCode := AnsiStrAlloc(256);    StrPCopy( trj_acquirerCode, '');
    trj_issuerCode := AnsiStrAlloc(256);      StrPCopy( trj_issuerCode, '');
    trj_issuerName := AnsiStrAlloc(256);      StrPCopy( trj_issuerName, '');
    trj_maxInstCount := AnsiStrAlloc(256);    StrPCopy( trj_maxInstCount, '');
    trj_terminalID := AnsiStrAlloc(256);      StrPCopy( trj_terminalID, '');
  end;

  procedure freeTRJ();
  begin
    StrDispose( trj_acquirerCode );
    StrDispose( trj_issuerCode );
    StrDispose( trj_issuerName );
    StrDispose( trj_maxInstCount );
    StrDispose( trj_terminalID );
  end;

  procedure newPlan();
  begin
    plan_issuerCode := AnsiStrAlloc(256);   StrPCopy( plan_issuerCode, '');
    plan_planCode := AnsiStrAlloc(256);     StrPCopy( plan_planCode, '');
    plan_planLabel := AnsiStrAlloc(256);    StrPCopy( plan_planLabel, '');
    plan_terminalID := AnsiStrAlloc(256);   StrPCopy( plan_terminalID, '');
  end;

  procedure freePlan();
  begin
    StrDispose(plan_issuerCode);
    StrDispose(plan_planCode);
    StrDispose(plan_planLabel);
    StrDispose(plan_terminalID);
  end;

  function GetTarjeta( i :integer ) :integer;
  var rta :integer;
  begin
    rta := lapos_get_tarjeta( i,  trj_acquirerCode,
                              trj_issuerCode, trj_issuerName,
                              trj_maxInstCount, trj_terminalID );
    if (rta = VPI_OK) or (rta = VPI_MORE_REC) then
        WriteLn( myFile,
                intToStr(i) + ';' +
                trj_acquirerCode + ';' +
                trj_issuerCode + ';' +
                trj_issuerName + ';' +
                trj_maxInstCount + ';' +
                trj_terminalID );
    GetTarjeta := rta;
  end; // GetTarjeta

  function GetPlan( i :integer ) :integer;
    var rta :integer;
  begin
    rta := lapos_get_plan( i, plan_issuerCode,
                            plan_planCode, plan_planLabel,
                            plan_terminalID );
    if (rta = VPI_OK) or (rta = VPI_MORE_REC) then
        WriteLn( myFile,
                intToStr(i) + ';' +
                plan_issuerCode + ';' +
                plan_planCode + ';' +
                plan_planLabel + ';' +
                plan_terminalID );
    GetPlan := rta;
  end; // GetPlan

var
  i :integer;
begin
    newTRJ();
    AssignFile(myFile, 'lapos_tarjetas.csv');
    ReWrite(myFile);
    i := 0;
    while GetTarjeta(i) = VPI_MORE_REC do begin
      i := i + 1;
    end;
    CloseFile(myFile);
    freeTRJ();

    newPlan();
    AssignFile(myFile, 'lapos_planes.csv');
    ReWrite(myFile);
    i := 0;
    while GetPlan(i) = VPI_MORE_REC do begin
      i := i + 1;
    end;
    CloseFile(myFile);
    freePlan();
end;

exports
  lapos_setCom,
  lapos_setName,
  lapos_setCUIT,
  lapos_get_tarjeta,
  lapos_get_plan,
  lapos_purchase,
  lapos_purchase_extra_cash,
  lapos_void,
  lapos_refund,
  lapos_refund_void,
  lapos_test,
  lapos_batch_close,
  lapos_batch_print,
  lapos_get_batch,
  lapos_get_last_data,
  lapos_print_ticket,
  lapos_export;

procedure InitLaPos();
begin
  if DLLLoaded then
    begin
    LaPosRec.com   := 0;
    LaPosRec.cName := AnsiStrAlloc(256);
    LaPosRec.CUIT  := AnsiStrAlloc(256);
    StrPCopy( LaPosRec.cName, '' );
    StrPCopy( LaPosRec.CUIT, '' );
    end
  else
    begin
    ShowMessage('No fue posible cargar la DLL de LaPos-Integrado [VPIPC.DLL].')
    end;
end;

begin
  CoInitialize(nil);
  InitLaPos();
end.
