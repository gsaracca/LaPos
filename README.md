# LaPos — Wrapper DLL para POS Integrado

Biblioteca dinámica (DLL) escrita en Delphi que actúa como capa de integración entre una aplicación host (típicamente Clarion) y terminales POS Ingenico que implementan el protocolo **IngStore / VPI PC** con la aplicación VISA de POS Integrado.

---

## Arquitectura

```
Aplicación host (Clarion / Delphi / cualquier lenguaje con FFI)
        │  lapos.dll  (cdecl, este repositorio)
        ▼
    VPIPC.DLL  (C — cargada dinámicamente vía LoadLibrary)
        │  protocolo IngStore
        ▼
  Terminal POS Ingenico  ←→  Host adquirente (online)
       (RS-232 / COMx)
```

`lapos.dll` es una façade: simplifica la API de `VPIPC.DLL` unificando la apertura/cierre del puerto serie en cada llamada y exponiendo funciones con convención `cdecl` listas para consumir desde Clarion u otros entornos.

---

## Dependencias en tiempo de ejecución

| Archivo | Descripción |
|---|---|
| `VPIPC.DLL` | Biblioteca C de comunicaciones VPI PC. Debe estar en el mismo directorio que `lapos.dll` o en el `PATH`. |
| `ingstore.dll` | Implementación del protocolo IngStore. Cargada internamente por `VPIPC.DLL`. |

Ambas DLLs son provistas por el fabricante/integrador del POS y **no se generan** durante la compilación de este proyecto.

---

## Proyectos Delphi incluidos

| Proyecto | Tipo | Descripción |
|---|---|---|
| `lapos.dproj` | Library (DLL) | Proyecto principal. Genera `lapos.dll`. |
| `cmd_lapos.dproj` | Application | Proyecto de prueba / host de desarrollo. |

---

## Archivos fuente

| Archivo | Descripción |
|---|---|
| `lapos.pas` | Implementación de todas las funciones exportadas. Punto de entrada de la DLL. |
| `VpiPC.pas` | Wrapper Delphi del header C de `VPIPC.DLL`. Declaraciones de tipos, constantes de retorno y carga dinámica de la DLL mediante `LoadLibrary` / `GetProcAddress`. Generado originalmente por HeadConv 4.0. |
| `vpipc.c` | Fuente C original del header de `VPIPC.DLL` (referencia). No se compila en este proyecto. |
| `lapos.inc` | Definición del tipo `comParams_t` en sintaxis Clarion para uso del consumidor. |
| `lapos.dfm` | Formulario vacío del proyecto `cmd_lapos` (host de prueba). |

---

## Requisitos de compilación

- **RAD Studio / Delphi** XE2 o superior (Win32)
- Configuración de compilación por defecto: `Debug | Win32`
- El artefacto de salida se genera en `Win32\Debug\lapos.dll`

Para compilar en Release, agregar una configuración `Release` en el Project Manager y ajustar la ruta de salida si es necesario.

---

## Configuración del comercio

Antes de ejecutar cualquier operación transaccional, la aplicación host debe configurar los datos del comercio mediante los siguientes procedimientos:

```delphi
// Establecer el número de puerto COM (rango válido: 1–32)
lapos_setCom(com: Integer);

// Razón social del comercio (PAnsiChar, máx. 256 bytes)
lapos_setName(_name: PAnsiChar);

// CUIT del comercio (PAnsiChar, máx. 256 bytes)
lapos_setCUIT(_cuit: PAnsiChar);
```

El puerto COM se configura con los siguientes parámetros fijos: `19200 bps, 8 bits, sin paridad, 1 bit de parada`.

> **Nota:** Si el número de COM está fuera del rango 1–32, la biblioteca lo reemplaza automáticamente por `COM9` y muestra un mensaje al usuario.

---

## API exportada

Todas las funciones siguen la convención de llamada `cdecl`. Los strings se pasan y reciben como `PAnsiChar` con buffers pre-asignados de 256 bytes. Los valores de retorno son códigos enteros definidos en `VpiPC.pas`.

### Consultas de configuración del POS

#### `lapos_get_tarjeta`
Recupera un registro de la tabla de tarjetas habilitadas en el POS. Para obtener todas las tarjetas, iterar desde el índice 0 mientras el retorno sea `VPI_MORE_REC`.

```delphi
function lapos_get_tarjeta(
  i: Integer;
  _adq, _tarCode, _tarName, _cuotas, _term: PAnsiChar
): Integer; cdecl;
```

#### `lapos_get_plan`
Recupera un registro de la tabla de planes disponibles en el POS. Misma lógica de iteración que `lapos_get_tarjeta`.

```delphi
function lapos_get_plan(
  i: Integer;
  _tarjeta, _planCode, _planLabel, _term: PAnsiChar
): Integer; cdecl;
```

### Operaciones transaccionales

#### `lapos_purchase` — Venta

```delphi
function lapos_purchase(
  _monto, _vuelto, _cuotas, _tarjeta, _plan, _ticket,
  _mCode, _mName, _mCUIT,
  _hostRespCode, _hostMessage,
  _authCode, _ticketNumber,
  _batchNumber, _customerName,
  _panFirst6, _panLast4,
  _date, _time,
  _terminalID: PAnsiChar
): Integer; cdecl;
```

| Parámetro | Dirección | Descripción |
|---|---|---|
| `_monto` | Entrada | Monto en centavos (ej: `"10050"` = $100,50) |
| `_vuelto` | Entrada | Propina/vuelto en centavos |
| `_cuotas` | Entrada | Cantidad de cuotas |
| `_tarjeta` | Entrada | Código de tarjeta (issuerCode) |
| `_plan` | Entrada | Código de plan |
| `_ticket` | Entrada | Número de recibo/ticket de la venta |
| `_mCode` | Entrada | Código de comercio |
| `_mName` | Entrada | Razón social del comercio |
| `_mCUIT` | Entrada | CUIT del comercio |
| `_hostRespCode` … `_terminalID` | Salida | Datos de respuesta completados por el POS |

#### `lapos_purchase_extra_cash` — Venta con extracción de efectivo

Misma firma que `lapos_purchase`. Envía el comando `vpiPurchaseExtraCash` al terminal.

#### `lapos_void` — Anulación de venta

```delphi
function lapos_void(
  _ticket, _tarjeta, _cName, _cCUIT,
  _hostRespCode, _hostMessage,
  _authCode, _ticketNumber,
  _batchNumber, _customerName,
  _panFirst6, _panLast4,
  _date, _time, _terminalID: PAnsiChar
): Integer; cdecl;
```

Requiere el número de ticket de la transacción original (`_ticket`) y el código de tarjeta (`_tarjeta`).

#### `lapos_refund` — Devolución

```delphi
function lapos_refund(
  _monto, _cuotas, _tarjeta, _plan, _ticket,
  _factura, _mCode, _mName, _mCUIT,
  _hostRespCode, _hostMessage,
  _authCode, _ticketNumber,
  _batchNumber, _customerName,
  _panFirst6, _panLast4,
  _date, _time,
  _terminalID: PAnsiChar
): Integer; cdecl;
```

Requiere además `_factura` (número de factura) y `_date` (fecha de la transacción original).

#### `lapos_refund_void` — Anulación de devolución

Misma firma que `lapos_refund`.

### Gestión de lote

#### `lapos_batch_close` — Cierre de lote

```delphi
function lapos_batch_close(
  _hostRespCode, _date, _time, _terminalID: PAnsiChar
): Integer; cdecl;
```

#### `lapos_get_batch` — Totales por tarjeta del último cierre

```delphi
function lapos_get_batch(
  i: Integer;
  _adquirente, _batch, _tarjeta,
  _purchCount, _purchAmount,
  _voidCount, _voidAmount,
  _refCount, _refAmount,
  _refVoidCount, _refVoidAmount,
  _date, _time, _term: PAnsiChar
): Integer; cdecl;
```

Iterar desde 0 mientras el retorno sea `VPI_MORE_REC`.

### Recuperación de datos y reimpresión

#### `lapos_get_last_data` — Datos de la última transacción

```delphi
function lapos_get_last_data(
  _oper: Integer;
  _hostRespCode, _hostMessage,
  _authCode, _ticketNumber,
  _batchNumber, _customerName,
  _panFirst6, _panLast4,
  _date, _time,
  _terminalID: PAnsiChar
): Integer; cdecl;
```

`_oper` acepta las constantes de operación: `VPI_PURCHASE (1)`, `VPI_VOID (2)`, `VPI_REFUND (3)`, `VPI_REFUND_VOID (4)`.

#### `lapos_print_ticket` — Reimpresión del último ticket

```delphi
function lapos_print_ticket(): Integer; cdecl;
```

#### `lapos_batch_print` — Reimpresión del último cierre de lote

```delphi
function lapos_batch_print(): Integer; cdecl;
```

### Diagnóstico

#### `lapos_test` — Test de conectividad

```delphi
function lapos_test(): Integer; cdecl;
```

Verifica que el POS responde en el puerto COM configurado.

### Exportación

#### `lapos_export` — Exportar tablas del POS a CSV

Exporta la tabla de tarjetas a `lapos_tarjetas.csv` y la de planes a `lapos_planes.csv` en el directorio de trabajo actual.

```delphi
procedure lapos_export(); cdecl;
```

---

## Códigos de retorno

Definidos en `VpiPC.pas`. Los más relevantes:

| Constante | Valor | Descripción |
|---|---|---|
| `VPI_OK` | 0 | Operación exitosa |
| `VPI_MORE_REC` | 1 | Éxito, pero quedan más registros por leer |
| `VPI_FAIL` | 11 | El comando no pudo enviarse |
| `VPI_TIMEOUT_EXP` | 12 | Tiempo de espera agotado |
| `VPI_INVALID_ISSUER` | 101 | Código de tarjeta inexistente |
| `VPI_INVALID_TICKET` | 102 | Número de cupón inexistente |
| `VPI_INVALID_PLAN` | 103 | Código de plan inexistente |
| `VPI_INVALID_INDEX` | 104 | Índice fuera de rango |
| `VPI_EMPTY_BATCH` | 105 | El lote del POS está vacío |
| `VPI_TRX_CANCELED` | 201 | Transacción cancelada por el usuario |
| `VPI_DIF_CARD` | 202 | La tarjeta deslizada no coincide con la solicitada |
| `VPI_INVALID_CARD` | 203 | Tarjeta no válida |
| `VPI_EXPIRED_CARD` | 204 | Tarjeta vencida |
| `VPI_INVALID_TRX` | 205 | Transacción original inexistente |
| `VPI_ERR_COM` | 301 | Error de comunicación del POS con el host adquirente |
| `VPI_ERR_PRINT` | 302 | Error de impresión en el POS |
| `VPI_GENERAL_FAIL` | 909 | Error general |

---

## Ejemplo de uso desde Delphi

El enfoque recomendado es cargar `lapos.dll` dinámicamente con `LoadLibrary`, lo que permite distribuir la DLL junto a la aplicación sin necesidad de una unidad de importación estática.

### Unidad de integración (`LaPos.Client.pas`)

La unidad [`LaPos.Client.pas`](LaPos.Client.pas) del repositorio contiene la implementación completa y documentada con XMLDoc. A continuación se muestra su interfaz pública resumida:

```delphi
unit LaPos.Client;

interface

const
  VPI_OK         = 0;
  VPI_MORE_REC   = 1;
  VPI_FAIL       = 11;
  VPI_TIMEOUT_EXP = 12;
  VPI_TRX_CANCELED = 201;

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
  TLaPosVoid = function(
    _ticket, _tarjeta, _cName, _cCUIT,
    _hostRespCode, _hostMessage,
    _authCode, _ticketNumber,
    _batchNumber, _customerName,
    _panFirst6, _panLast4,
    _date, _time, _terminalID: PAnsiChar): Integer; cdecl;
  TLaPosBatchClose = function(
    _hostRespCode, _date, _time, _terminalID: PAnsiChar): Integer; cdecl;

  TLaPosClient = class
  private
    FHandle: THandle;
    FSetCom:      TLaPosSetCom;
    FSetName:     TLaPosSetName;
    FSetCUIT:     TLaPosSetCUIT;
    FTest:        TLaPosTest;
    FPurchase:    TLaPosPurchase;
    FVoid:        TLaPosVoid;
    FBatchClose:  TLaPosBatchClose;
    procedure LoadProc(var Proc; const Name: string);
  public
    constructor Create(const DLLPath: string);
    destructor Destroy; override;

    procedure Configure(ComPort: Integer; const MerchantName, CUIT: string);
    function TestConnection: Boolean;
    function Purchase(const Monto, Vuelto, Cuotas, Tarjeta, Plan,
      Ticket, MCode, MName, MCUIT: string;
      out RespCode, Message, AuthCode, TicketNum,
          BatchNum, CustomerName, PanFirst6, PanLast4,
          Date, Time, TerminalID: string): Integer;
    function VoidTrx(const Ticket, Tarjeta, MName, MCUIT: string;
      out RespCode, Message, AuthCode, TicketNum,
          BatchNum, CustomerName, PanFirst6, PanLast4,
          Date, Time, TerminalID: string): Integer;
    function BatchClose(out RespCode, Date, Time, TerminalID: string): Integer;
  end;

implementation

uses
  Winapi.Windows, System.SysUtils;

const
  BUF = 256;

procedure TLaPosClient.LoadProc(var Proc; const Name: string);
begin
  TFarProc(Proc) := GetProcAddress(FHandle, PChar(Name));
  if TFarProc(Proc) = nil then
    raise Exception.CreateFmt('lapos.dll: función "%s" no encontrada.', [Name]);
end;

constructor TLaPosClient.Create(const DLLPath: string);
begin
  FHandle := LoadLibrary(PChar(DLLPath));
  if FHandle = 0 then
    raise Exception.CreateFmt(
      'No se pudo cargar lapos.dll desde "%s". Código: %d',
      [DLLPath, GetLastError]);

  LoadProc(FSetCom,     'lapos_setCom');
  LoadProc(FSetName,    'lapos_setName');
  LoadProc(FSetCUIT,    'lapos_setCUIT');
  LoadProc(FTest,       'lapos_test');
  LoadProc(FPurchase,   'lapos_purchase');
  LoadProc(FVoid,       'lapos_void');
  LoadProc(FBatchClose, 'lapos_batch_close');
end;

destructor TLaPosClient.Destroy;
begin
  if FHandle <> 0 then
    FreeLibrary(FHandle);
  inherited;
end;

procedure TLaPosClient.Configure(ComPort: Integer;
  const MerchantName, CUIT: string);
begin
  FSetCom(ComPort);
  FSetName(PAnsiChar(AnsiString(MerchantName)));
  FSetCUIT(PAnsiChar(AnsiString(CUIT)));
end;

function TLaPosClient.TestConnection: Boolean;
begin
  Result := FTest = VPI_OK;
end;

function TLaPosClient.Purchase(
  const Monto, Vuelto, Cuotas, Tarjeta, Plan,
        Ticket, MCode, MName, MCUIT: string;
  out RespCode, Message, AuthCode, TicketNum,
      BatchNum, CustomerName, PanFirst6, PanLast4,
      Date, Time, TerminalID: string): Integer;
var
  bRespCode, bMessage, bAuthCode, bTicketNum,
  bBatchNum, bCustomerName, bPanFirst6, bPanLast4,
  bDate, bTime, bTerminalID: array[0..BUF - 1] of AnsiChar;
begin
  FillChar(bRespCode,    SizeOf(bRespCode),    0);
  FillChar(bMessage,     SizeOf(bMessage),     0);
  FillChar(bAuthCode,    SizeOf(bAuthCode),    0);
  FillChar(bTicketNum,   SizeOf(bTicketNum),   0);
  FillChar(bBatchNum,    SizeOf(bBatchNum),    0);
  FillChar(bCustomerName,SizeOf(bCustomerName),0);
  FillChar(bPanFirst6,   SizeOf(bPanFirst6),   0);
  FillChar(bPanLast4,    SizeOf(bPanLast4),    0);
  FillChar(bDate,        SizeOf(bDate),        0);
  FillChar(bTime,        SizeOf(bTime),        0);
  FillChar(bTerminalID,  SizeOf(bTerminalID),  0);

  Result := FPurchase(
    PAnsiChar(AnsiString(Monto)),   PAnsiChar(AnsiString(Vuelto)),
    PAnsiChar(AnsiString(Cuotas)),  PAnsiChar(AnsiString(Tarjeta)),
    PAnsiChar(AnsiString(Plan)),    PAnsiChar(AnsiString(Ticket)),
    PAnsiChar(AnsiString(MCode)),   PAnsiChar(AnsiString(MName)),
    PAnsiChar(AnsiString(MCUIT)),
    bRespCode,  bMessage,    bAuthCode,    bTicketNum,
    bBatchNum,  bCustomerName, bPanFirst6, bPanLast4,
    bDate,      bTime,       bTerminalID);

  RespCode     := string(AnsiString(bRespCode));
  Message      := string(AnsiString(bMessage));
  AuthCode     := string(AnsiString(bAuthCode));
  TicketNum    := string(AnsiString(bTicketNum));
  BatchNum     := string(AnsiString(bBatchNum));
  CustomerName := string(AnsiString(bCustomerName));
  PanFirst6    := string(AnsiString(bPanFirst6));
  PanLast4     := string(AnsiString(bPanLast4));
  Date         := string(AnsiString(bDate));
  Time         := string(AnsiString(bTime));
  TerminalID   := string(AnsiString(bTerminalID));
end;

function TLaPosClient.VoidTrx(
  const Ticket, Tarjeta, MName, MCUIT: string;
  out RespCode, Message, AuthCode, TicketNum,
      BatchNum, CustomerName, PanFirst6, PanLast4,
      Date, Time, TerminalID: string): Integer;
var
  bRespCode, bMessage, bAuthCode, bTicketNum,
  bBatchNum, bCustomerName, bPanFirst6, bPanLast4,
  bDate, bTime, bTerminalID: array[0..BUF - 1] of AnsiChar;
begin
  FillChar(bRespCode,    SizeOf(bRespCode),    0);
  FillChar(bMessage,     SizeOf(bMessage),     0);
  FillChar(bAuthCode,    SizeOf(bAuthCode),    0);
  FillChar(bTicketNum,   SizeOf(bTicketNum),   0);
  FillChar(bBatchNum,    SizeOf(bBatchNum),    0);
  FillChar(bCustomerName,SizeOf(bCustomerName),0);
  FillChar(bPanFirst6,   SizeOf(bPanFirst6),   0);
  FillChar(bPanLast4,    SizeOf(bPanLast4),    0);
  FillChar(bDate,        SizeOf(bDate),        0);
  FillChar(bTime,        SizeOf(bTime),        0);
  FillChar(bTerminalID,  SizeOf(bTerminalID),  0);

  Result := FVoid(
    PAnsiChar(AnsiString(Ticket)),  PAnsiChar(AnsiString(Tarjeta)),
    PAnsiChar(AnsiString(MName)),   PAnsiChar(AnsiString(MCUIT)),
    bRespCode,  bMessage,    bAuthCode,    bTicketNum,
    bBatchNum,  bCustomerName, bPanFirst6, bPanLast4,
    bDate,      bTime,       bTerminalID);

  RespCode     := string(AnsiString(bRespCode));
  Message      := string(AnsiString(bMessage));
  AuthCode     := string(AnsiString(bAuthCode));
  TicketNum    := string(AnsiString(bTicketNum));
  BatchNum     := string(AnsiString(bBatchNum));
  CustomerName := string(AnsiString(bCustomerName));
  PanFirst6    := string(AnsiString(bPanFirst6));
  PanLast4     := string(AnsiString(bPanLast4));
  Date         := string(AnsiString(bDate));
  Time         := string(AnsiString(bTime));
  TerminalID   := string(AnsiString(bTerminalID));
end;

function TLaPosClient.BatchClose(
  out RespCode, Date, Time, TerminalID: string): Integer;
var
  bRespCode, bDate, bTime, bTerminalID: array[0..BUF - 1] of AnsiChar;
begin
  FillChar(bRespCode,   SizeOf(bRespCode),   0);
  FillChar(bDate,       SizeOf(bDate),       0);
  FillChar(bTime,       SizeOf(bTime),       0);
  FillChar(bTerminalID, SizeOf(bTerminalID), 0);

  Result     := FBatchClose(bRespCode, bDate, bTime, bTerminalID);
  RespCode   := string(AnsiString(bRespCode));
  Date       := string(AnsiString(bDate));
  Time       := string(AnsiString(bTime));
  TerminalID := string(AnsiString(bTerminalID));
end;

end.
```

### Uso en un formulario o servicio

```delphi
procedure TFormPOS.EjecutarVenta;
var
  POS: TLaPosClient;
  Ret: Integer;
  RespCode, Msg, AuthCode, TicketNum, BatchNum,
  CustomerName, PanFirst6, PanLast4, Date, Time, TerminalID: string;
begin
  POS := TLaPosClient.Create(ExtractFilePath(Application.ExeName) + 'lapos.dll');
  try
    // 1. Configurar comercio y puerto
    POS.Configure(
      {ComPort=} 9,
      {MerchantName=} 'MI COMERCIO SA',
      {CUIT=} '30-12345678-9'
    );

    // 2. Verificar conectividad con el POS antes de operar
    if not POS.TestConnection then
    begin
      ShowMessage('El terminal POS no responde. Verifique el cable y el puerto COM.');
      Exit;
    end;

    // 3. Ejecutar venta
    //    Monto: en centavos sin separador  →  $1.250,00 = '125000'
    //    Cuotas: '1' para contado
    //    Tarjeta y Plan: obtenidos previamente con lapos_get_tarjeta / lapos_get_plan
    Ret := POS.Purchase(
      {Monto=}   '125000',
      {Vuelto=}  '0',
      {Cuotas=}  '1',
      {Tarjeta=} '01',
      {Plan=}    '001',
      {Ticket=}  '00042',
      {MCode=}   '9876543',
      {MName=}   'MI COMERCIO SA',
      {MCUIT=}   '30-12345678-9',
      RespCode, Msg, AuthCode, TicketNum,
      BatchNum, CustomerName, PanFirst6, PanLast4,
      Date, Time, TerminalID
    );

    // 4. Interpretar resultado
    case Ret of
      VPI_OK:
        ShowMessage(Format(
          'Venta aprobada' + sLineBreak +
          'Autorización : %s' + sLineBreak +
          'Ticket        : %s' + sLineBreak +
          'Lote          : %s' + sLineBreak +
          'Titular       : %s' + sLineBreak +
          'Tarjeta       : %s...%s' + sLineBreak +
          'Fecha/Hora    : %s %s' + sLineBreak +
          'Terminal      : %s',
          [AuthCode, TicketNum, BatchNum, CustomerName,
           PanFirst6, PanLast4, Date, Time, TerminalID]));

      VPI_TRX_CANCELED:
        ShowMessage('El cliente canceló la operación en el terminal.');

      VPI_FAIL:
        ShowMessage('No se pudo enviar el comando al POS. Verifique la conexión.');

      VPI_TIMEOUT_EXP:
        ShowMessage('El POS no respondió en el tiempo esperado.');
    else
      ShowMessage(Format('Error del POS (código %d): %s', [Ret, Msg]));
    end;

  finally
    POS.Free;
  end;
end;
```

### Notas importantes sobre el manejo de buffers

Los parámetros de salida de `lapos.dll` son `PAnsiChar` que apuntan a buffers proporcionados por el **llamador**. La unidad del ejemplo usa arrays estáticos en el stack (`array[0..255] of AnsiChar`) inicializados con `FillChar` antes de cada llamada. Esto es equivalente al patrón `AnsiStrAlloc` / `StrDispose` que usa la propia DLL internamente.

> **No pasar punteros `nil`** en los parámetros de salida: `lapos.dll` escribe en ellos con `StrPCopy` sin validar el puntero.

---

## Uso desde Clarion

El archivo `lapos.inc` contiene la definición del tipo `comParams_t` en sintaxis Clarion. Para consumir la DLL desde un módulo Clarion:

```clarion
  MODULE('lapos.dll')
    lapos_setCom(LONG com),PASCAL
    lapos_setName(*CSTRING name),PASCAL
    lapos_setCUIT(*CSTRING cuit),PASCAL
    lapos_test(),LONG,PASCAL
    lapos_purchase(*CSTRING monto, *CSTRING vuelto, ...),LONG,PASCAL
    ! ... resto de funciones
  END
```

> Los buffers de salida (`PAnsiChar`) se corresponden con `*CSTRING` en Clarion, y deben declararse con tamaño suficiente (`CSTRING(256)`) antes de la llamada.

---

## Comportamiento interno

Cada función de operación sigue este patrón:

1. **Abrir puerto** (`vpiOpenPort`) con los parámetros del registro `LaPosRec`.
2. **Ejecutar comando** contra la DLL `VPIPC.DLL`.
3. **Copiar resultados** de las estructuras de salida a los buffers del llamador.
4. **Liberar memoria** de las estructuras temporales (`AnsiStrAlloc` / `StrDispose`).
5. **Cerrar puerto** (`vpiClosePort`).

La DLL `VPIPC.DLL` se carga en la inicialización de la unit `VpiPC` mediante `LoadLibrary`. Si la carga falla, `DLLLoaded` queda en `False` y la inicialización de `lapos.dll` muestra un mensaje de error informando que no fue posible cargar `VPIPC.DLL`.
