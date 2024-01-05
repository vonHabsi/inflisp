(*----------------------------------------------------------------------------*)
(* Author: Joachim Pimiskern, 1994-2004                                       *)
(*----------------------------------------------------------------------------*)
unit lspinit;
{$O+,F+}

interface
uses
   lspglobl;

const
   (*-------------------------------------------------------------------------*)
   (* Folgende variablen Konstanten haben den Zweck, Zeiger auf Symbolknoten  *)
   (* aufzunehmen. Zwei Symbolknoten sind genau dann gleich, wenn sie die     *)
   (* gleiche Adresse haben. Dies ist wichtig. Es genuegt nicht, dass die     *)
   (* Symbolnamen uebereinstimmen. Zu einem Symbolstring darf es deshalb nur  *)
   (* genau einen einzigen Knoten geben. Dies hat den Vorteil, dass effizient *)
   (* geprueft werden kann, ob ein Knoten ein eingebautes Symbol (z.B CAR)    *)
   (* ist, denn es muss nur mit der variablen Konstanten verglichen werden.   *)
   (*-------------------------------------------------------------------------*)
   cLspT             : pNode = nil;
   cLspCar           : pNode = nil;
   cLspCdr           : pNode = nil;
   cLspCadr          : pNode = nil;
   cLspCdar          : pNode = nil;
   cLspCaar          : pNode = nil;
   cLspCddr          : pNode = nil;
   cLspCadar         : pNode = nil;
   cLspCaddr         : pNode = nil;
   cLspCdddr         : pNode = nil;
   cLspCaadr         : pNode = nil;
   cLspCaddar        : pNode = nil;
   cLspCadddr        : pNode = nil;
   cLspCons          : pNode = nil;
   cLspLast          : pNode = nil;
   cLspMakeList      : pNode = nil;
   cLspAppend        : pNode = nil;
   cLspCopy          : pNode = nil;
   cLspReverse       : pNode = nil;
   cLspRplaca        : pNode = nil;
   cLspRplacd        : pNode = nil;
   cLspAtom          : pNode = nil;
   cLspNull          : pNode = nil;
   cLspNot           : pNode = nil;
   cLspAnd           : pNode = nil;
   cLspOr            : pNode = nil;
   cLspMember        : pNode = nil;
   cLspConsp         : pNode = nil;
   cLspListp         : pNode = nil;
   cLspBoundp        : pNode = nil;
   cLspEq            : pNode = nil;
   cLspEql           : pNode = nil;
   cLspEqual         : pNode = nil;
   cLspQuote         : pNode = nil;
   cLspBackQuote     : pNode = nil;
   cLspComma         : pNode = nil;
   cLspCommaAt       : pNode = nil;
   cLspCond          : pNode = nil;
   cLspIf            : pNode = nil;
   cLspDoList        : pNode = nil;
   cLspDoTimes       : pNode = nil;
   cLspProgn         : pNode = nil;
   cLspMapCar        : pNode = nil;
   cLspSetq          : pNode = nil;
   cLspDefun         : pNode = nil;
   cLspDefmacro      : pNode = nil;
   cLspLet           : pNode = nil;
   cLspLambda        : pNode = nil;
   cLspMacro         : pNode = nil;
   cLspClosure       : pNode = nil;
   cLspAssoc         : pNode = nil;
   cLspPlus          : pNode = nil;
   cLspMinus         : pNode = nil;
   cLspTimes         : pNode = nil;
   cLspDivided       : pNode = nil;
   cLspEinsMinus     : pNode = nil;
   cLspEinsPlus      : pNode = nil;
   cLspExp           : pNode = nil;
   cLspLn            : pNode = nil;
   cLspSqr           : pNode = nil;
   cLspSqrt          : pNode = nil;
   cLspMathEqual     : pNode = nil;
   cLspMathNotEqual  : pNode = nil;
   cLspLess          : pNode = nil;
   cLspGreater       : pNode = nil;
   cLspGreaterOrEqual: pNode = nil;
   cLspLessOrEqual   : pNode = nil;
   cLspPrint         : pNode = nil;
   cLspPrin1         : pNode = nil;
   cLspPrinc         : pNode = nil;
   cLspTerpri        : pNode = nil;
   cLspFlatSize      : pNode = nil;
   cLspFlatc         : pNode = nil;
   cLspLoad          : pNode = nil;
   cLspExit          : pNode = nil;
   cLspEval          : pNode = nil;
   cLspApply         : pNode = nil;
   cLspFunCall       : pNode = nil;
   cLspGC            : pNode = nil;
   cLspSymbolp       : pNode = nil;
   cLspNumberp       : pNode = nil;
   cLspIntegerp      : pNode = nil;
   cLspFloatp        : pNode = nil;
   cLspStringp       : pNode = nil;
   cLspArrayp        : pNode = nil;
   cLspFilep         : pNode = nil;
   cLspSymbolName    : pNode = nil;
   cLspMakeSymbol    : pNode = nil;
   cLspGenSym        : pNode = nil;
   cLspAref          : pNode = nil;
   cLspSetf          : pNode = nil;
   cLspMakeArray     : pNode = nil;
   cLspOpenI         : pNode = nil;
   cLspOpenO         : pNode = nil;
   cLspClose         : pNode = nil;
   cLspFilepos       : pNode = nil;
   cLspSeek          : pNode = nil;
   cLspRead          : pNode = nil;
   cLspReadLine      : pNode = nil;
   cLspReadChar      : pNode = nil;
   cLspWriteChar     : pNode = nil;
   cLspStandardInput : pNode = nil;
   cLspStandardOutput: pNode = nil;
   cLspOptional      : pNode = nil;
   cLspRest          : pNode = nil;
   cLspChar          : pNode = nil;
   cLspString1       : pNode = nil;
   cLspStrCat        : pNode = nil;
   cLspSubStr        : pNode = nil;
   cLspTypeOf        : pNode = nil;
   cLspDPSymbol      : pNode = nil;
   cLspDPCons        : pNode = nil;
   cLspDPFloat       : pNode = nil;
   cLspDPInteger     : pNode = nil;
   cLspDPString      : pNode = nil;
   cLspDPArray       : pNode = nil;
   cLspDPFile        : pNode = nil;
   (*--- Nicht zu Common-Lisp gehoerig ---*)
   cLspIsVariable    : pNode = nil;
   cLspMatch         : pNode = nil;
   cLspEvaluated     : pNode = nil;
   cLspGetVariables  : pNode = nil;

   cLspError         : pNode = nil;
   cLspEnvironment     : pNode = nil;
   cLspGlobalSymbolList: pNode = nil;
   cLspSpecialList     : pNode = nil;
   cLspWhile        : pNode = nil;
   cLspMem          : pNode = nil;
   cLspMemavail     : pNode = nil;
   cLspMaxavail     : pNode = nil;
   cLspLength       : pNode = nil;
   cLspNth          : pNode = nil;
   cLspNthCdr       : pNode = nil;
   cLspRandomize    : pNode = nil;
   cLspRandom       : pNode = nil;
   cLspTime         : pNode = nil;
   cLspAssert       : pNode = nil;
   cLspRetract      : pNode = nil;
   cLspGetFirst     : pNode = nil;
   cLspGetNext      : pNode = nil;
   cLspForall       : pNode = nil;
   cLspFZA          : pNode = nil;
   cLspFZB          : pNode = nil;
   cLspFZC          : pNode = nil;
   cLspFZD          : pNode = nil;
   cLspFZE          : pNode = nil;
   cLspFZF          : pNode = nil;
   cLspFZG          : pNode = nil;
   cLspFZH          : pNode = nil;
   cLspFZI          : pNode = nil;
   cLspFZJ          : pNode = nil;
   cLspFZK          : pNode = nil;
   cLspFZL          : pNode = nil;
   cLspFZM          : pNode = nil;
   cLspFZN          : pNode = nil;
   cLspFZO          : pNode = nil;
   cLspFZP          : pNode = nil;
   cLspFZQ          : pNode = nil;
   cLspFZR          : pNode = nil;
   cLspFZS          : pNode = nil;
   cLspFZT          : pNode = nil;
   cLspFZU          : pNode = nil;
   cLspFZV          : pNode = nil;
   cLspFZW          : pNode = nil;
   cLspFZX          : pNode = nil;
   cLspFZY          : pNode = nil;
   cLspFZZ          : pNode = nil;
   cLspInternalError: pNode = nil;
   cLspErrorNumber  : pNode = nil;
(* cLspObject       : pNode = nil; *)
   cLspMakeInstance : pNode = nil;
   cLspIsA          : pNode = nil;
   cLspDefvar       : pNode = nil;
   cLspDefmethod    : pNode = nil;
   cLspObjectp      : pNode = nil;
   cLspSend         : pNode = nil;
   cLspMethodNotFound: pNode = nil;
   cLspCursorOn     : pNode = nil;
   cLspCursorOff    : pNode = nil;
   cLspClearScreen  : pNode = nil;
   cLspGotoXY       : pNode = nil;
   cLspKeypressed   : pNode = nil;
   cLspGetKey       : pNode = nil;
   cLspDos          : pNode = nil;
   cLspWriteScreen  : pNode = nil;
   cLspScreenBegin  : pNode = nil;
   cLspScreenEnd    : pNode = nil;
   cLspScreenPush   : pNode = nil;
   cLspScreenPop    : pNode = nil;
   cLspQuickSort    : pNode = nil;
   cLspBubbleSort   : pNode = nil;
   (*--- Tricks fuer den Parser ---*)
   cLspKlammerZu    : pNode = nil;
   cLspEndOfLine    : pNode = nil;
   cLspEndOfFile    : pNode = nil;
   (*------------------------------*)




procedure LspInitSymbols(var Umgebung: pNode);

implementation
uses
   lspcreat, lsplists, lspinout, lspmain, otherobj;



(*--- Diverse globale variable Konstanten belegen ---*)
procedure LspInitSymbols(var Umgebung: pNode);
begin
  cLspT              := LspMakeSymbol('t');
  cLspCar            := LspMakeSymbol('car');
  cLspCdr            := LspMakeSymbol('cdr');
  cLspCaar           := LspMakeSymbol('caar');
  cLspCadr           := LspMakeSymbol('cadr');
  cLspCdar           := LspMakeSymbol('cdar');
  cLspCddr           := LspMakeSymbol('cddr');
  cLspCaadr          := LspMakeSymbol('caadr');
  cLspCadar          := LspMakeSymbol('cadar');
  cLspCaddr          := LspMakeSymbol('caddr');
  cLspCdddr          := LspMakeSymbol('cdddr');
  cLspCaddar         := LspMakeSymbol('caddar');
  cLspCadddr         := LspMakeSymbol('cadddr');
  cLspCons           := LspMakeSymbol('cons');
  cLspLast           := LspMakeSymbol('last');
  cLspMakeList       := LspMakeSymbol('list');
  cLspAppend         := LspMakeSymbol('append');
  cLspCopy           := LspMakeSymbol('copy');
  cLspReverse        := LspMakeSymbol('reverse');
  cLspRplaca         := LspMakeSymbol('rplaca');
  cLspRplacd         := LspMakeSymbol('rplacd');
  cLspAtom           := LspMakeSymbol('atom');
  cLspNull           := LspMakeSymbol('null');
  cLspNot            := LspMakeSymbol('not');
  cLspAnd            := LspMakeSymbol('and');
  cLspOr             := LspMakeSymbol('or');
  cLspMember         := LspMakeSymbol('member');
  cLspConsp          := LspMakeSymbol('consp');
  cLspListp          := LspMakeSymbol('listp');
  cLspBoundp         := LspMakeSymbol('boundp');
  cLspEq             := LspMakeSymbol('eq');
  cLspEql            := LspMakeSymbol('eql');
  cLspEqual          := LspMakeSymbol('equal');
  cLspQuote          := LspMakeSymbol('quote');
  cLspBackQuote      := LspMakeSymbol('backquote');
  cLspComma          := LspMakeSymbol('comma');
  cLspCommaAt        := LspMakeSymbol('comma-at');
  cLspCond           := LspMakeSymbol('cond');
  cLspIf             := LspMakeSymbol('if');
  cLspDoList         := LspMakeSymbol('dolist');
  cLspDoTimes        := LspMakeSymbol('dotimes');
  cLspProgn          := LspMakeSymbol('progn');
  cLspMapCar         := LspMakeSymbol('mapcar');
  cLspSetq           := LspMakeSymbol('setq');
  cLspDefun          := LspMakeSymbol('defun');
  cLspDefmacro       := LspMakeSymbol('defmacro');
  cLspLet            := LspMakeSymbol('let');
  cLspLambda         := LspMakeSymbol('lambda');
  cLspMacro          := LspMakeSymbol('macro');
  cLspClosure        := LspMakeSymbol('closure');
  cLspAssoc          := LspMakeSymbol('assoc');
  cLspPlus           := LspMakeSymbol('+');
  cLspMinus          := LspMakeSymbol('-');
  cLspTimes          := LspMakeSymbol('*');
  cLspDivided        := LspMakeSymbol('/');
  cLspEinsPlus       := LspMakeSymbol('1+');
  cLspEinsMinus      := LspMakeSymbol('1-');
  cLspExp            := LspMakeSymbol('exp');
  cLspLn             := LspMakeSymbol('ln');
  cLspSqr            := LspMakeSymbol('sqr');
  cLspSqrt           := LspMakeSymbol('sqrt');
  cLspMathEqual      := LspMakeSymbol('=');
  cLspMathNotEqual   := LspMakeSymbol('<>');
  cLspLess           := LspMakeSymbol('<');
  cLspGreater        := LspMakeSymbol('>');
  cLspGreaterOrEqual := LspMakeSymbol('>=');
  cLspLessOrEqual    := LspMakeSymbol('<=');
  cLspPrint          := LspMakeSymbol('print');
  cLspPrin1          := LspMakeSymbol('prin1');
  cLspPrinc          := LspMakeSymbol('princ');
  cLspTerpri         := LspMakeSymbol('terpri');
  cLspFlatSize       := LspMakeSymbol('flatsize');
  cLspFlatc          := LspMakeSymbol('flatc');
  cLspLoad           := LspMakeSymbol('load');
  cLspExit           := LspMakeSymbol('exit');
  cLspEval           := LspMakeSymbol('eval');
  cLspApply          := LspMakeSymbol('apply');
  cLspFunCall        := LspMakeSymbol('funcall');
  cLspSymbolp        := LspMakeSymbol('symbolp');
  cLspNumberp        := LspMakeSymbol('numberp');
  cLspIntegerp       := LspMakeSymbol('integerp');
  cLspFloatp         := LspMakeSymbol('floatp');
  cLspStringp        := LspMakeSymbol('stringp');
  cLspArrayp         := LspMakeSymbol('arrayp');
  cLspFilep          := LspMakeSymbol('filep');
  cLspGC             := LspMakeSymbol('gc');
  cLspSymbolName     := LspMakeSymbol('symbol-name');
  cLspMakeSymbol     := LspMakeSymbol('make-symbol');
  cLspGenSym         := LspMakeSymbol('gensym');
  cLspAref           := LspMakeSymbol('aref');
  cLspSetf           := LspMakeSymbol('setf');
  cLspMakeArray      := LspMakeSymbol('make-array');
  cLspOpenI          := LspMakeSymbol('openi');
  cLspOpenO          := LspMakeSymbol('openo');
  cLspClose          := LspMakeSymbol('close');
  cLspFilepos        := LspMakeSymbol('file-pos');
  cLspSeek           := LspMakeSymbol('seek');
  cLspRead           := LspMakeSymbol('read');
  cLspReadLine       := LspMakeSymbol('read-line');
  cLspReadChar       := LspMakeSymbol('read-char');
  cLspWriteChar      := LspMakeSymbol('write-char');
  cLspStandardInput  := LspMakeSymbol('*standard-input*');
  cLspStandardOutput := LspMakeSymbol('*standard-output*');
  cLspOptional       := LspMakeSymbol('&optional');
  cLspRest           := LspMakeSymbol('&rest');
  cLspChar           := LspMakeSymbol('char');
  cLspString1        := LspMakeSymbol('string');
  cLspStrCat         := LspMakeSymbol('strcat');
  cLspSubStr         := LspMakeSymbol('substr');
  cLspTypeOf         := LspMakeSymbol('type-of');
  cLspDPSymbol       := LspMakeSymbol(':symbol');
  cLspDPCons         := LspMakeSymbol(':cons');
  cLspDPFloat        := LspMakeSymbol(':float');
  cLspDPInteger      := LspMakeSymbol(':integer');
  cLspDPString       := LspMakeSymbol(':string');
  cLspDPArray        := LspMakeSymbol(':array');
  cLspDPFile         := LspMakeSymbol(':file');
  (*--- Nicht zu Common-Lisp gehoerig ---*)
  cLspIsVariable     := LspMakeSymbol('is-variable');
  cLspMatch          := LspMakeSymbol('match');
  cLspEvaluated      := LspMakeSymbol('evaluated');
  cLspGetVariables   := LspMakeSymbol('get-variables');

  cLspError          := LspMakeSymbol('error');
  cLspEnvironment      := LspMakeSymbol('*environment*');
  cLspGlobalSymbolList := LspMakeSymbol('*globalsymbollist*');
  cLspSpecialList      := LspMakeSymbol('*speciallist*');
  cLspWhile          := LspMakeSymbol('while');
  cLspLength         := LspMakeSymbol('length');
  cLspNth            := LspMakeSymbol('nth');
  cLspNthCdr         := LspMakeSymbol('nthcdr');
  cLspRandomize      := LspMakeSymbol('randomize');
  cLspRandom         := LspMakeSymbol('random');
  cLspTime           := LspMakeSymbol('time');
  cLspAssert         := LspMakeSymbol('assert');
  cLspRetract        := LspMakeSymbol('retract');
  cLspGetFirst       := LspMakeSymbol('get-first');
  cLspGetNext        := LspMakeSymbol('get-next');
  cLspForall         := LspMakeSymbol('forall');
  cLspFZA            := LspMakeSymbol('?A');
  cLspFZB            := LspMakeSymbol('?B');
  cLspFZC            := LspMakeSymbol('?C');
  cLspFZD            := LspMakeSymbol('?D');
  cLspFZE            := LspMakeSymbol('?E');
  cLspFZF            := LspMakeSymbol('?F');
  cLspFZG            := LspMakeSymbol('?G');
  cLspFZH            := LspMakeSymbol('?H');
  cLspFZI            := LspMakeSymbol('?I');
  cLspFZJ            := LspMakeSymbol('?J');
  cLspFZK            := LspMakeSymbol('?K');
  cLspFZL            := LspMakeSymbol('?L');
  cLspFZM            := LspMakeSymbol('?M');
  cLspFZN            := LspMakeSymbol('?N');
  cLspFZO            := LspMakeSymbol('?O');
  cLspFZP            := LspMakeSymbol('?P');
  cLspFZQ            := LspMakeSymbol('?Q');
  cLspFZR            := LspMakeSymbol('?R');
  cLspFZS            := LspMakeSymbol('?S');
  cLspFZT            := LspMakeSymbol('?T');
  cLspFZU            := LspMakeSymbol('?U');
  cLspFZV            := LspMakeSymbol('?V');
  cLspFZW            := LspMakeSymbol('?W');
  cLspFZX            := LspMakeSymbol('?X');
  cLspFZY            := LspMakeSymbol('?Y');
  cLspFZZ            := LspMakeSymbol('?Z');
  cLspInternalError  := LspMakeSymbol('internal-error');
//  cLspErrorNumber    := LspMakeSymbol('*error-number*');
  (*   cLspObject         := LspMakeSymbol('object'); *)
  cLspMakeInstance   := LspMakeSymbol('make-instance');
  cLspIsA            := LspMakeSymbol('is-a');
  cLspDefvar         := LspMakeSymbol('defvar');
  cLspDefmethod      := LspMakeSymbol('defmethod');
  cLspObjectp        := LspMakeSymbol('objectp');
  cLspSend           := LspMakeSymbol('send');
  cLspMethodNotFound := LspMakeSymbol('method-not-found');
  cLspCursorOn       := LspMakeSymbol('cursor-on');
  cLspCursorOff      := LspMakeSymbol('cursor-off');
  cLspClearScreen    := LspMakeSymbol('clear-screen');
  cLspGotoXY         := LspMakeSymbol('gotoxy');
  cLspKeypressed     := LspMakeSymbol('keypressed');
  cLspGetKey         := LspMakeSymbol('get-key');
  cLspDos            := LspMakeSymbol('dos');
  cLspWriteScreen    := LspMakeSymbol('write-screen');
  cLspScreenBegin    := LspMakeSymbol('screen-begin');
  cLspScreenEnd      := LspMakeSymbol('screen-end');
  cLspScreenPush     := LspMakeSymbol('screen-push');
  cLspScreenPop      := LspMakeSymbol('screen-pop');
  cLspQuickSort      := LspMakeSymbol('quick-sort');
  cLspBubbleSort     := LspMakeSymbol('bubble-sort');
  (*--- Tricks fuer den Parser ---*)
  cLspKlammerZu      := LspMakeSymbol(')');
  cLspEndOfLine      := LspMakeSymbol('end-of-line');
  cLspEndOfFile      := LspMakeSymbol('end-of-file');
  (*------------------------------*)

  Umgebung := LspList2(LspList2(cLspT, cLspT),
                       LspList2(nil  , nil  ));

  MainTask.LspStandardOutput := LspOpenO(LspMakeString(''));
  MainTask.LspStandardInput  := LspOpenI(LspMakeString(''));

  LspSetq(cLspStandardInput ,MainTask.LspStandardInput ,Umgebung);
  LspSetq(cLspStandardOutput,MainTask.LspStandardOutput,Umgebung);

  LspSetq(cLspEndOfLine,nil,Umgebung);
  LspSetq(cLspEndOfFile,nil,Umgebung);
  (*-----------------------------------------------------------------------*)
  (* Saemtliche anderen globalen Objekte initialisieren                    *)
  (*-----------------------------------------------------------------------*)
  OtherObj.LspInitSymbols(Umgebung);
end;




end.
