(*----------------------------------------------------------------------------*)
(* Globale Variablen von Inflisp                                              *)
(*----------------------------------------------------------------------------*)
(* Author: Joachim Pimiskern, 1994-2004                                       *)
(*----------------------------------------------------------------------------*)
unit lspglobl;
{$O+,F+}

interface
uses
   Classes;

const
   cVersion      = '???';


   cLspSymbol       = 1;
   cLspList         = 2;
   cLspFloat        = 3;
   cLspInteger      = 4;
   cLspString       = 5;
   cLspArray        = 6;
   cLspFile         = 7;
   cLspObject       = 8;
   cLspStream       = 9;
   cLspNodeAddress  = 10;



type
   pFile = ^file;

   tLspString = string[128];
   pLspString = ^tLspString;

   pNode  = ^tNode;
   ppNode = ^pNode;
   tNode  = record
   LaufendeNummer: integer;
              Typ   : byte;
              Flags : byte; {Bit 0 fuer GC, Bit 1 fuer Tests}
              AllObj: pNode;
              case integer of
                 cLspSymbol      : (SymbolVal      : pLspString);
                 cLspFloat       : (FloatVal       : double);
                 cLspInteger     : (IntegerVal     : longint);
                 cLspString      : (StringVal      : pLspString);
                 cLspList        : (CarVal         : pNode;
                                    CdrVal         : pNode);
                 cLspArray       : (Size           : longint;
                                    ArrayVal       : TMemoryStream);
                 cLspObject      : (ObjectVal      : TObject);
                 cLspFile        : (FileVal        : pFile);
                 cLspStream      : (StreamVal      : TStream);
                 cLspNodeAddress : (NodeAddressVal : ppNode);
           end;


   tLispArray = array[0..16000] of pNode;



TLispTask = class
   public
      AllObjects       : pNode;     (* Alle bekannten Lisp-Objekte       *)
      Environment      : pNode;     (* Alle globalen Variablen-Bindungen *)
      GlobalSymbolList : pNode;
      LockedNodes      : pNode;     (* Knoten, gegen GC geschuetzt       *)

      LspStandardInput : pNode;     (* Tastatur-Eingabe-Datei            *)
      LspStandardOutput: pNode;     (* Konsolen-Ausgabe-Datei            *)
      LspLogfile       : pNode;

      GensymNumber     : longint;   (* Neue Nummer fuer GENSYM-Funktion  *)
      constructor Create; 
      destructor  Destroy; override;
      procedure   InitSymbols;
end;



var
   MainTask: TLispTask;







implementation
uses
   lspinit, lspcreat, lspinout;

constructor TLispTask.Create;
begin
  inherited Create;

  AllObjects       := nil; {Liste aller Objekte}
  GlobalSymbollist := nil; {Fuer eindeutige Symbol-Strings}
  LockedNodes      := nil; {Liste mit Zeigern auf geschuetzte Knoten}

  GenSymNumber     := 0;   {Startwert fuer Gensym}
end;



destructor TLispTask.Destroy;
begin
  DestroyAllObjects;
  inherited Destroy;
end;



procedure TLispTask.InitSymbols;
begin
  LspInitSymbols(Environment);
end;

initialization

  MainTask := TLispTask.Create;
  MainTask.InitSymbols;

finalization

  MainTask.Free;
  MainTask := nil;

end.
