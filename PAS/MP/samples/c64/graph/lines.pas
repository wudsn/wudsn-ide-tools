uses crt, graph;

const maxLines     =16;
      maxDrawLines =500;

type  LineDescr  = array [0..3] of smallint;

var   Ball,
      Vel,
      max          : LineDescr;
      Lines        : array [0..maxLines, 0..3] of smallint;

      t, GraphDriver, GraphMode : smallint;

      count: word;

      i, new, old: byte;

begin
  randomize;

  GraphDriver := VGA;
  GraphMode := VGAHi;
  InitGraph(GraphDriver,GraphMode,'');

  SetColor(15);

  max[0]:=ScreenWidth;
  max[2]:=ScreenWidth;

  max[3]:=ScreenHeight;
  max[1]:=ScreenHeight;

  for i := 3 downto 0 do begin
      Vel[i] :=(random(0) and 7) shl 1 + 2;
      Ball[i]:=random(smallint(max[i])) - 160;
  end;

  new   := 0;
  old   := 0;
  count := 0;

  repeat

    pause;

    for i := 3 downto 0 do begin

        t:=Ball[i]+Vel[i];

	if t >= max[i] then begin
            t := (max[i] shl 1)  - Vel[i] - Ball[i];
            Vel[i] := -Vel[i];
	end;

	if t<0 then begin
            t := -t;
            Vel[i] := -Vel[i];
	end;

        Ball[i] := t;
    end;

    if (count >= maxLines) then begin
        SetColor(0);

        Line (lines[old, 0], lines[old, 1], lines[old, 2], lines[old, 3]);

        old:=byte(old+1) mod maxLines;
    end;

    Lines[new, 0] := Ball[0];
    Lines[new, 1] := Ball[1];
    Lines[new, 2] := Ball[2];
    Lines[new, 3] := Ball[3];

    new:=byte(new+1) mod maxLines;

    SetColor(1);
    Line (ball[0], ball[1], ball[2], ball[3]);

    inc(count);

    until count = MaxDrawLines;

end.
