(*----------------------------------------------------------------------------*)
(* Ein- und Ausgabefunktionen                                                 *)
(*----------------------------------------------------------------------------*)
(* Author: Joachim Pimiskern, 1994-2004                                       *)
(*----------------------------------------------------------------------------*)
unit lspinout;
{$O+,F+,E+,N+}

interface
uses
   lspglobl;



function ReadString(fp: pNode): pNode;
function LspTerpri(Datei: pNode) : pNode;
function LspPrint(p, Datei: pNode): pNode;
function LspPrin1(p, Datei: pNode): pNode;
function LspPrinc(p, Datei: pNode): pNode;
function LspFlatSize(Args,Umgebung: pNode): pNode;
function LspFlatc(Args,Umgebung: pNode): pNode;
function LspLoad(p:pNode)        : pNode;
function LspClearScreen          : pNode;
function LspGetKey               : pNode;

function LspOpenI(Filename: pNode): pNode;
function LspOpenO(Filename: pNode): pNode;
function LspClose(Datei: pNode): pNode;
function LspFilepos(Datei: pNode): pNode;
function LspSeek(Datei, Ort: pNode): pNode;

function LspRead(fp: pNode): pNode;
function LspReadLine(Args,Umgebung: pNode): pNode;
function LspReadChar(Args,Umgebung: pNode): pNode;
function LspWriteChar(Args,Umgebung: pNode): pNode;

var
   Klammerebene: integer;

implementation
uses
   lsppredi, lsperr, lspbasic, linestrm, lsplex, lsppars, lspmath, lspinit,
   lspmain, lspstrng, lspcreat, lspexpct, lspkeybd, lsplists, lsparray,
   lsplock,
   strng, dialogs;

(*----------------------------------------------------------------------------*)
(* Ein Zeichen in einen Stream schreiben. Ein Stream ist e. Cons-Zelle, deren *)
(* CAR auf eine Liste zeigt und deren CDR auf die letzte Cons-Zelle der Liste *)
(* zeigt.                                                                     *)
(*----------------------------------------------------------------------------*)
procedure WriteCharToStream(c: char; var stream: pNode);
var h: pNode;
begin
  h := LspCons(LspMakeInteger(ord(c)),nil);
  if (LspConsp(Stream^.CdrVal)) then
     Stream^.CdrVal^.CdrVal := h
  else
     Stream^.CarVal := h;
  Stream^.CdrVal := h;
end;



(*----------------------------------------------------------------------------*)
(* Ein Zeichen aus einem Stream lesen                                         *)
(*----------------------------------------------------------------------------*)
function GetCharFromStream(var stream: pNode): pNode;
begin
  if (Stream^.Typ = cLspList) then
     begin
       if (LspCar(stream) <> nil) then
          begin
            result := LspCaar(stream);
            stream^.CarVal := stream^.CarVal^.CdrVal;
          end
       else
          result := nil;

       if (stream^.CarVal = nil) then
          stream^.CdrVal := nil;
     end
  else
     result := nil;
end;




(*----------------------------------------------------------------------------*)
(* Einen String in ein untypisiertes File schreiben                           *)
(* Falls PrincFlag false ist, wird der String derart aufbereitet, daß er als  *)
(* Lisp-Quellcode interpretiert werden kann, z.B. Backslash verdoppeln.       *)
(*----------------------------------------------------------------------------*)
procedure WriteString(var fp: pNode; s: ShortString; PrincFlag: boolean);
   var i    : integer;
       tempS: ShortString;
   begin
     (*--- Sonderzeichen aufbereiten ---*)
     if (not PrincFlag) then
        begin
          tempS := '';
          for i := 1 to length(s) do
              begin
                if (s[i] = '\') then
                   tempS := tempS + '\\'
                else
                if (s[i] = '"') then
                   tempS := tempS + '\"'
                else
                   tempS := tempS + s[i];
              end;
          s := tempS;
        end;


     if (fp^.Typ = cLspFile) then
        (*--- Unterscheidung nach OUTPUT oder FILE ---*)
        begin
          if (fp = MainTask.LspStandardOutput) then
             write(s)
          else
             blockwrite(fp^.FileVal^,s[1],length(s));
        end
     else
     (*--- Lisp-Stream: Eine Liste ---*)
     if (fp^.Typ = cLspList) then
        begin
          for i := 1 to length(s) do
              WriteCharToStream(s[i],fp);
        end
     else
     (*--- Delphi-Stream ---*)
     if (fp^.Typ = cLspStream) then
        begin
          (* bis 12.7.1997
          for i := 1 to length(s) do
              fp^.StreamVal.Write(s[i],1); *)
          fp^.StreamVal.Write(s[1],length(s));
        end;
   end;



(*----------------------------------------------------------------------------*)
(* Einen String aus einem untypisierten File oder aus Stream lesen oder von   *)
(* der Tastatur lesen                                                         *)
(*----------------------------------------------------------------------------*)
function ReadString(fp: pNode): pNode;
var c: char;
    p: pNode;
    s: ShortString;
begin
  result := nil;

  s := '';
  c := ' ';
  (*--- Fall 1: Von der Tastatur lesen ---*)
  if (fp = nil) then
     begin
       readln(s);
       result := LspMakeString(s);
     end
  else
  (*--- Fall 2: Aus File lesen ---*)
  if (fp^.Typ = cLspFile) then
     begin
       if (not eof(fp^.FileVal^)) then
          begin
            while (not eof(fp^.FileVal^) and (c <> chr(10))) do
               begin
                 blockread(fp^.FileVal^,c,1);
                 if ((c <> chr(10)) and (c <> chr(13)) and (c <> chr(26))) then
                    s := s + c;
               end;
            result := LspMakeString(s);
          end
     end
  else
  (*--- Fall 3: Aus Stream lesen ---*)
  if (fp^.Typ = cLspList) then
     begin
     if (not LspEqual(fp,LspCons(nil,nil))) then
        begin
          while (LspConsp(fp) and (c <> chr(10)) and (c <> chr(26))) do
             begin
               p := GetCharFromStream(fp);
               if (p <> nil) then
                  c := chr(LspGetIntegerVal(p))
               else
                  c := chr(26);
               if ((c <> chr(10)) and (c <> chr(13)) and (c <> chr(26))) then
                  s := s + c;
             end;
          result := LspMakeString(s);
        end;
     end
  else
  (*--- Fall 4: Aus Pascal-Stream lesen ---*)
  if (fp^.Typ = cLspStream) then
     begin
       if (fp^.StreamVal.Position < fp^.StreamVal.Size - 1) then
          begin
            while ((c <> chr(10)) and
                   (fp^.Streamval.Position < fp^.StreamVal.Size -1)) do
               begin
                 fp^.StreamVal.Read(c,1);
                 if ((c <> chr(10)) and (c <> chr(13)) and (c <> chr(26))) then
                    s := s + c;
               end;
            result := LspMakeString(s);
          end
     end
end;


(*----------------------------------------------------------------------------*)
(* Einen Zeilenvorschub ausgeben, z.B. auf Bildschirm, Stream oder Datei      *)
(*----------------------------------------------------------------------------*)
function LspTerpri(Datei: pNode): pNode;
begin
  if (Datei = nil) then
     Datei := MainTask.LspStandardOutput;

  if (not LspFilep(Datei) and not LspConsp(Datei) and not LspStreamp(Datei)) then
     raise ELispException.Create('ErrFileOrStreamExpected','')
  else
     WriteString(Datei,chr(13)+chr(10),false);
  result :=  nil;
end;



(*----------------------------------------------------------------------------*)
(* Ein einzelnes Atom ausgeben. Das PrincFlag ist für saubere Ausgabe, falls  *)
(* es false ist, wird Quellcode ausgegeben.                                   *)
(*----------------------------------------------------------------------------*)
procedure LspPrintAtom(p: pNode; var fp: pNode; PrincFlag: boolean);
   var tempS: ShortString;
   begin
     if (p = nil) then
        writeString(fp,'NIL',PrincFlag)
     else
        begin
          case p^.Typ of
             (*---------------------------------------------------------------*)
             cLspSymbol:
             begin
               writeString(fp,p^.SymbolVal^,PrincFlag);
             end;
             (*---------------------------------------------------------------*)
             cLspString:
             begin
               if (PrincFlag) then
                  writeString(fp,p^.StringVal^,PrincFlag)
               else
                  begin
                    writeString(fp,'"',true);
                    writeString(fp,p^.StringVal^,false);
                    writeString(fp,'"',true);
                  end;
             end;
             (*---------------------------------------------------------------*)
             cLspInteger:
             begin
               writeString(fp,l2s0(p^.IntegerVal,0),PrincFlag);
             end;
             (*---------------------------------------------------------------*)
             cLspFloat:
             begin
               Str(p^.FloatVal:0:30,tempS);
               writeString(fp,EntferneFolgendeNullen(tempS),PrincFlag);
             end;
             (*---------------------------------------------------------------*)
             cLspFile:
             begin
               tempS := '#<FILE $' + p2s(p^.FileVal) + '>';
               writeString(fp,fstrupr(tempS),PrincFlag);
      (* ???   writeString(fp,EntferneFolgendeNullen(tempS)); *)
             end;
             (*---------------------------------------------------------------*)
             cLspObject:
             begin
               tempS := '#<OBJECT $' + p2s(p^.ObjectVal) + '>';
               writeString(fp,fstrupr(tempS),PrincFlag);
             end;
             (*---------------------------------------------------------------*)
             cLspNodeAddress:
             begin
               tempS := '#<ADDRESS $' + p2s(p^.NodeAddressVal) + '>';
               writeString(fp,fstrupr(tempS),PrincFlag);
             end;
             (*---------------------------------------------------------------*)
             cLspStream:
             begin
               tempS := '#<STREAM $' + p2s(p^.StreamVal) + '>';
               writeString(fp,fstrupr(tempS),PrincFlag);
             end;
             (*---------------------------------------------------------------*)
             else raise ELispException.Create('ErrAtomExpected','');
          end;
        end;
   end;



function LspPrintAux(p: pNode; var fp: pNode; PrincFlag: boolean): pNode;
var laeufer: pNode;
    i      : longint;
begin
  (*--------------------------------------------------------------------------*)
  if LspAtom(p) then
     LspPrintAtom(p,fp,PrincFlag)
  else
  (*--------------------------------------------------------------------------*)
  if (p^.Typ = cLspNodeAddress) then
     LspPrintAtom(p,fp,PrincFlag)
  else
  (*--------------------------------------------------------------------------*)
  if (p^.Typ = cLspStream) then
     LspPrintAtom(p,fp,PrincFlag)
  else
  (*--------------------------------------------------------------------------*)
  if LspConsp(p) then
     begin
       writeString(fp,'(',PrincFlag);
       if LspPrintAux(LspCar(p),fp,PrincFlag) = nil then ;
       if LspNull(LspCdr(p)) then
          writeString(fp,')',PrincFlag)
       else
          if LspAtom(LspCdr(p)) then
             begin
               writeString(fp,' . ',PrincFlag);
               LspPrintAtom(LspCdr(p),fp,PrincFlag);
               writeString(fp,')',PrincFlag);
             end
       else
          begin
            laeufer := LspCdr(p);
            while not LspNull(laeufer) do
               begin
                 if LspAtom(laeufer) then
                    begin
                      writeString(fp,' . ',PrincFlag);
                      LspPrintAtom(laeufer,fp,PrincFlag);
                      laeufer := nil;
                    end
                 else
                    begin
                      writeString(fp,' ',PrincFlag);
                      if LspPrintAux(LspCar(laeufer),fp,PrincFlag) = nil then;
                      Laeufer := LspCdr(laeufer);
                    end;
               end;
            writeString(fp,')',PrincFlag);
          end;
     end
  else
  (*--------------------------------------------------------------------------*)
  if (LspArrayp(p)) then
     begin
       writeString(fp,'#(',PrincFlag);
       for i := 0 to p^.Size - 1 do
           begin
(*             if (LspPrintAux(tLispArray(p^.ArrayVal^)[i],fp,PrincFlag) = nil) then; *)
             if (LspPrintAux(LspAref(p,LspMakeInteger(i)),fp,PrincFlag) = nil) then;
             if (i <> p^.Size - 1) then
                writeString(fp,' ',PrincFlag);
           end;
       writeString(fp,')',PrincFlag);
     end
  else
     raise ELispException.Create('ErrUnknownDataType','');
  Result := p;
end;



function LspPrint(p,Datei: pNode): pNode;
begin
  if (Datei = nil) then
     Datei := MainTask.LspStandardOutput;

  if (not LspFilep(Datei) and
      not LspConsp(Datei) and
      not LspStreamp(Datei)) then
     raise ELispException.Create('ErrFileOrStreamExpected','PRINT');

  result := LspPrintAux(p,Datei,false);
  LspTerpri(Datei);
end;



function LspPrin1(p,Datei: pNode): pNode;
begin
  if (Datei = nil) then
     Datei := MainTask.LspStandardOutput;

  if (not LspFilep(Datei) and not LspConsp(Datei) and not LspStreamp(Datei)) then
     raise ELispException.Create('ErrFileOrStreamExpected','PRIN1');

  result := LspPrintAux(p,Datei,false);
end;



function LspPrinc(p,Datei: pNode): pNode;
begin
  if (Datei = nil) then
     Datei := MainTask.LspStandardOutput;

  if (not LspFilep(Datei) and not LspConsp(Datei) and not LspStreamp(Datei)) then
     raise ELispException.Create('ErrFileOrStreamExpected','PRINC');

  result := LspPrintAux(p,Datei,true);
end;


(*----------------------------------------------------------------------------*)
(* Die Laenge eines als String gedruckten Ausdruckes (PRIN1) liefern          *)
(*----------------------------------------------------------------------------*)
function LspFlatSize(Args,Umgebung: pNode): pNode;
var e     : pNode;
    Stream: pNode;
begin
  e := evaluated(Args,Umgebung);

  Stream := LspCons(nil,nil);
  LspPrin1(LspCar(e),Stream);
  result := LspLength(LspCar(Stream));
end;


(*----------------------------------------------------------------------------*)
(* Die Laenge eines als String gedruckten Ausdruckes (PRINC) liefern          *)
(*----------------------------------------------------------------------------*)
function LspFlatc(Args,Umgebung: pNode): pNode;
var e     : pNode;
    Stream: pNode;
begin
  e := evaluated(Args,Umgebung);

  Stream := LspCons(nil,nil);
  LspPrinc(LspCar(e),Stream);
  result := LspLength(LspCar(Stream));
end;



(*----------------------------------------------------------------------------*)
(* Eine Ascii-Datei (Lisp-Programm) lesen und dabei jeden Ausdruck auswerten  *)
(*----------------------------------------------------------------------------*)
function LspLoad(p: pNode): pNode;
var Eingabe : tLS_obj;
    lex     : tLex_obj;
    filename: ShortString;
    fp      : pNode;
    temp    : pNode;
begin
  if (not LspSymbolp(p) and not LspStringp(p)) then
     raise ELispException.Create('ErrSymbolOrStringExpected','LOAD');

  result := nil;
  fp     := nil;
  temp   := nil;
  LspLockNodeAddress(@result);
  LspLockNodeAddress(@p);
  LspLockNodeAddress(@fp);
  LspLockNodeAddress(@temp);

  try
     if (LspStringp(p)) then
        Filename := LspGetStringVal(p)
     else
        Filename := LspGetStringVal(LspSymbolName(p)) + '.lsp';


     fp := LspOpenI(LspMakeString(filename));

     try
        if (fp = nil) then
           raise ELispException.Create('ErrCannotOpenFile','LOAD: ' + filename);

        Eingabe.Init(fp);

        try
           if (Eingabe.FileIsOpen) then
              begin
                result := cLspT;
                lex.init(@Eingabe);
                try
                   repeat
                     temp := GetExpression(@lex);

                     if (not LspFilep(fp)) then
                        raise ELispException.Create('ErrFileExpected','LOAD');

                     LspEval(temp,MainTask.Environment);
                   until (lex.lookahead.token = cLspEndOfFileToken);
                finally
                   lex.Done;
                end;
              end;
        finally
           Eingabe.Done;
        end;
     finally
        LspClose(fp);
     end;
  finally
     LspUnlockNodeAddress(@temp);
     LspUnlockNodeAddress(@fp);
     LspUnlockNodeAddress(@p);
     LspUnlockNodeAddress(@result);
  end;
end;







(*----------------------------------------------------------------------------*)
(* Den Bildschirm loeschen                                                    *)
(*----------------------------------------------------------------------------*)
function LspClearScreen: pNode;
begin
  result := nil;
  (* Cls zu-tun *)
end;


(*----------------------------------------------------------------------------*)
(* Abfragen, ob eine Taste gedrueckt wurde                                    *)
(*----------------------------------------------------------------------------*)
function LspKeypressed: boolean;
begin
  result := false;
(*                zu-tun
  LspKeypressed := MainTask.Terminal.Keypressed;
  *)
end;



(*----------------------------------------------------------------------------*)
(* Auf einen Tastendruck warten und dann diesen lesen                         *)
(*----------------------------------------------------------------------------*)
function LspGetKey: pNode;
begin
(*              zu-tun
  result := LspMakeInteger(ord(MainTask.Terminal.Getc));
  *)
  result := nil;
end;



(*----------------------------------------------------------------------------*)
(* Eine Datei zum Input oeffnen                                               *)
(*----------------------------------------------------------------------------*)
function LspOpenI(Filename: pNode): pNode;
var fn   : ShortString;
    h    : pFile;
    iores: integer;
begin
  result := nil;

  if (not LspStringp(Filename)) then
     raise ELispException.Create('ErrStringExpected','OPENI');

  fn := LspGetStringVal(Filename);

  new(h);
  assign(h^,fn);
  {$i-}
  reset(h^,1);
  {$i+}

  iores := ioresult;
  if (iores = 0) then
     begin
       LspNew(result);
       result^.Typ     := cLspFile;
       result^.FileVal := h;
     end
  else
     dispose(h);
end;




(*----------------------------------------------------------------------------*)
(* Eine Datei zum Output oeffnen bzw. neu erstellen                           *)
(*----------------------------------------------------------------------------*)
function LspOpenO(Filename: pNode): pNode;
var _Filename: ShortString;
    h        : pFile;
    res      : pNode;
begin
  result := nil;

  if (not LspStringp(Filename)) then
     raise ELispException.Create('ErrStringExpected','OPENO');

  _Filename := LspGetStringVal(Filename);

  LspNew(Res);
  new(h);
  Res^.Typ       := cLspFile;
  Res^.FileVal   := h;

  assign(h^,_filename);
  {$i-}
  rewrite(h^,1);
  {$i+}

  if (ioresult = 0) then
     result := Res;
end;


(*----------------------------------------------------------------------------*)
(* Eine (zuvor geoeffnete) Datei schliessen                                   *)
(*----------------------------------------------------------------------------*)
function LspClose(Datei: pNode): pNode;
begin
  if (not LspFilep(Datei)) then
     raise ELispException.Create('ErrFileExpected','CLOSE');

  {$i-}
  close(Datei^.FileVal^);
  {$i+}
  result := nil;
end;



(*----------------------------------------------------------------------------*)
(* Die Dateiposition liefern                                                  *)
(*----------------------------------------------------------------------------*)
function LspFilepos(Datei: pNode): pNode;
begin
  if (not LspFilep(Datei)) then
     raise ELispException.Create('ErrFileExpected','FILEPOS');

  result := LspMakeInteger(Filepos(Datei^.FileVal^));
end;



(*----------------------------------------------------------------------------*)
(* Eine Dateiposition aufsuchen                                               *)
(*----------------------------------------------------------------------------*)
function LspSeek(Datei, Ort: pNode): pNode;
var o: longint;
begin
  if (not LspFilep(Datei)) then
     raise ELispException.Create('ErrFileExpected','SEEK, first argument');

  if (not LspIntegerp(Ort)) then
     raise ELispException.Create('ErrIntegerExpected','SEEK, second argument');

  o := LspGetIntegerVal(Ort);
  seek(Datei^.FileVal^,o);

  result := nil;
end;


























(*----------------------------------------------------------------------------*)
(* Einen Lisp-Ausdruck einlesen. Quelle: Tastatur, Datei oder Stream          *)
(*----------------------------------------------------------------------------*)
function LspRead(fp: pNode): pNode;
var lex      : tLex_obj;
    Eingabe  : tLS_Obj;
begin
  Eingabe.Init(fp);
  lex.init(@Eingabe);

  LspRead := GetExpression(@lex);

  lex.done;
  Eingabe.Done;
end;






(*----------------------------------------------------------------------------*)
(* Eine Zeile einlesen und als String zurueckgeben                            *)
(*----------------------------------------------------------------------------*)
function LspReadLine(Args,Umgebung: pNode): pNode;
var e : pNode;
    fp: pNode;
    s : ShortString;
begin
  if (Args = nil) then
     begin
       readln(s);
       result := LspMakeString(s);
     end
  else
     begin
       e := evaluated(Args,Umgebung);
       if (expect(fp,e,cTypFileOrStream)) then
          result := ReadString(fp)
       else
          result := nil;
     end;
end;



(*----------------------------------------------------------------------------*)
(* Ein Zeichen einlesen und als Integer zurueckgeben                          *)
(*----------------------------------------------------------------------------*)
function LspReadChar(Args,Umgebung: pNode): pNode;
   var e : pNode;
       fp: pNode;
       c : char;
   begin
     if (Args = nil) then
        begin
        (*
          c := MainTask.Terminal.GetC;
          zu-tun
          *)
c := 'A';          
          result := LspMakeInteger(Ord(c));
          exit;
        end;

     e := evaluated(Args,Umgebung);
     if expect(fp,e,cTypFileOrStream) then
        begin
          (*--- Von Datei lesen ---*)
          if (fp^.Typ = cLspFile) then
             begin
               if not eof(fp^.FileVal^) then
                  begin
                    blockread(fp^.FileVal^,c,1);
                    result := LspMakeInteger(Ord(c));
                  end
               else
                  result := nil;
             end
          else
          (*--- Von Stream lesen ---*)
          if (fp^.Typ = cLspList) then
             begin
               if (LspCar(fp) <> nil) then
                  begin
                    result := LspCaar(fp);
                    fp^.CarVal := fp^.CarVal^.CdrVal;
                  end
               else
                  result := nil;

               if (fp^.CarVal = nil) then
                  fp^.CdrVal := nil;
             end
          else
             result := nil;
        end
     else
        result := nil;
   end;


(*----------------------------------------------------------------------------*)
(* Ein Zeichen (Integer-ASCII-Wert) in ein File schreiben                     *)
(*----------------------------------------------------------------------------*)
function LspWriteChar(Args,Umgebung: pNode): pNode;
var e : pNode;
    i : pNode;
    fp: pNode;
    c : char;
begin
  e := evaluated(Args,Umgebung);

  if (not expect(i,e,cTypInteger)) then
     begin
       result := nil;
       exit;
     end;

  if (e = nil) then
     begin
       result := i;
       write(chr(LspGetIntegerVal(i)));
       exit;
     end;

  if (not expect(fp,e,cTypFile)) then
     begin
       result := nil;
       exit;
     end;


  result := i;
  c := chr(LspGetIntegerVal(i));
  blockwrite(fp^.FileVal^,c,1);
end;



end.
