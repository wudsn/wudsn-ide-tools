program palindrom;
uses crt;

const
  vdec = 2;                // sta�a liczbowa w kodzie dziesi�tnym
  vhex = $ff;              // sta�a liczbowa w kodzie szesnastkowym
  vbin = %10110001;        // sta�a liczbowa w kodzie binarnym
  e = 2.7182818;           // sta�a zmiennoprzecinkowa

  d = (2 * pi * 12.4);      // sta�e z u�yciem operator�w
  ls = SizeOf(cardinal);   // sta�a zawieraj�ca rozmiar zmiennej typu cardinal
  x: word = 5;             // wymuszenie typu sta�ej
  a = ord('A');            // sta�a zawieraj�ca kod ATASCII znaku A
  b = '4';                 // sta�a znakowa
  c = chr(65);             // sta�a zawieraj�ca znak o kodzie 65

  ts = 'atari';             // �a�cuch znak�w
  t: array [0..3] of byte = (16, 24, 48, 64);  // tablica

var
  s: string;
  i: byte;

begin

    Write('Podaj wyraz: ');
    Readln(s);
    Writeln;
    for i := byte(s[0]) - 1 downto 1 do begin
        Inc(s[0]);
        //SetLength(s, Length(s) + 1);
        s[byte(s[0])] := s[i];
    end;
    Writeln('Palindrom: ', s);
    Readkey;
end.
