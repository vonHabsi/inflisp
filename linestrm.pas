(*----------------------------------------------------------------------------*)
(* Einen Zeilenstrom zur Verfuegung stellen                                   *)
(*----------------------------------------------------------------------------*)
(* Author: Joachim Pimiskern, 1994-2004                                       *)
(*----------------------------------------------------------------------------*)
unit linestrm;
{$O+,F+}

interface
uses
   lspglobl;


type
   tLS_obj = object
                filepointer: pNode;
                EndOfFile  : boolean;
                FileIsOpen : boolean;
                constructor  Init(fp: pNode);
                destructor   Done; virtual;
                (*
                procedure    fOpen(filename: string); virtual;
                procedure    fClose; virtual;
                *)
                function     getLine: ShortString; virtual;
             end;
   pLS_obj = ^tLS_obj;


implementation
uses
   lspinout, lspstrng;


constructor tLS_obj.Init(fp: pNode);
   begin
     filepointer := fp;
     FileIsOpen  := true;
     EndOfFile   := false;
   end;

destructor tLS_obj.Done;
   begin
   end;

(*
procedure tLS_obj.fopen(filename: string);
   begin
     assign(fp,filename);
     {$i-}
     reset(fp);
     {$i+}

     FileIsOpen := (ioresult = 0);

     if FileIsOpen then
        EndOfFile := eof(fp)
     else
        EndOfFile := true;
   end;


procedure tLS_obj.fclose;
   begin
     if FileIsOpen then
        close(fp);
   end;
*)



function tLS_obj.getLine: ShortString;
   var temp: pNode;
   begin
     temp := readstring(filepointer);
     if (temp <> nil) then
        begin
          getLine   := LspGetStringVal(temp);
          EndOfFile := false
        end
     else
        begin
          getLine   := '';
          EndOfFile := true
        end;
   end;





end.
