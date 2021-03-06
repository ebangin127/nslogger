{
                Mersenne Twister for Delphi

** Legal Notice in Original MT 2002 Version

  Until 2001/4/6, MT had been distributed under GNU Public License,
  but after 2001/4/6, we decided to let MT be used for any purpose,
  including commercial use.
  2002-versions mt19937ar.c, mt19937ar-cok.c are considered to be usable freely.

** Information for This Implementation

   Usage of this Module is free as you follow above original legal notice.
   I DO NOT WARRANTY ANYTHING, USE AT YOUR OWN RISK.

   Implemented by ebangin127
   email : ebangin127 @ gmail.com (remove space)
}

unit Mersenne;

interface
type
  TMersenne = class
  public
    function genrand_int32(): Cardinal;
    function genrand_int31(): Integer;
    function genrand_real1(): Double;
    function genrand_real2(): Double;
    function genrand_real3(): Double;
    function genrand_res53(): Double;
    function genrand_res64(): Extended;
    procedure init_genrand(s: Cardinal);
    constructor Create(s: Cardinal); overload;
  private
    const
      N = 624;
  private
    mt: Array[0..N-1] of Cardinal; { the array for the state vector  }
    mti: Integer; { mti==N+1 means mt[N] is not initialized }
  end;

implementation

{ Period parameters }
const
  N = 624;
  M = 397;
  MATRIX_A = $9908b0df;   { constant vector a }
  UPPER_MASK = $80000000; { most significant w-r bits }
  LOWER_MASK = $7fffffff; { least significant r bits }

{ initializes mt[N] with a seed }
procedure TMersenne.init_genrand(s: Cardinal);
var
  mti_local: Cardinal;
begin
  mt[0] := s and $ffffffff;
  for mti_local := 1 to (N - 1) do
  begin
    mt[mti_local] :=
      (1812433253 * (mt[mti_local - 1] xor (mt[mti_local - 1] shr 30))
        + mti_local);
    { See Knuth TAOCP Vol2. 3rd Ed. P.106 for multiplier. }
    { In the previous versions, MSBs of the seed affect   }
    { only MSBs of the array mt[].                        }
    { 2002/01/09 modified by Makoto Matsumoto             }
    mt[mti_local] := mt[mti_local] and $ffffffff;
    { for >32 bit machines }
  end;
  mti := N;
end;

{ generates a random number on [0,0xffffffff]-interval }
function TMersenne.genrand_int32(): Cardinal;
const
  mag01: Array[0..1] of Cardinal = (0, MATRIX_A);
var
  y: Cardinal;
  kk: Integer;
begin
  { mag01[x] = x * MATRIX_A  for x=0,1 }

  if mti >= N then { generate N words at one time }
  begin
    if mti = N+1 then  { if init_genrand() has not been called, }
      init_genrand(5489); { a default initial seed is used }

    for kk := 0 to (N - M - 1) do
    begin
      y := (mt[kk] and UPPER_MASK) or (mt[kk + 1] and LOWER_MASK);
      mt[kk] := mt[kk + M] xor (y shr 1) xor mag01[y and 1];
    end;
    for kk := (N - M - 1) to N-1 do
    begin
      y := (mt[kk] and UPPER_MASK) or (mt[kk + 1] and LOWER_MASK);
      mt[kk] := mt[kk + (M - N)] xor (y shr 1) xor mag01[y and 1];
    end;

    y := (mt[N - 1] and UPPER_MASK) or (mt[0] and LOWER_MASK);
    mt[N - 1] := mt[M - 1] xor (y shr 1) xor mag01[y and 1];

    mti := 0;
  end;

  y := mt[mti];
  mti := mti + 1;

  { Tempering }
  y := y xor (y shr 11);
  y := y xor (y shl 7) and $9d2c5680;
  y := y xor (y shl 15) and $efc60000;
  y := y xor (y shr 18);

  result := y;
end;

{ generates a random number on [0,0x7fffffff]-interval }
function TMersenne.genrand_int31(): Integer;
begin
  result := (genrand_int32() shr 1);
end;

{ generates a random number on [0,1]-real-interval }
function TMersenne.genrand_real1(): Double;
begin
  result := genrand_int32()*(1.0/4294967295.0);
  { divided by 2^32-1 }
end;

{ generates a random number on [0,1)-real-interval }
function TMersenne.genrand_real2(): Double;
begin
  result := genrand_int32()*(1.0/4294967296.0);
  { divided by 2^32 }
end;

{ generates a random number on (0,1)-real-interval }
function TMersenne.genrand_real3(): Double;
begin
  result := ((genrand_int32()) + 0.5)*(1.0/4294967296.0);
  { divided by 2^32 }
end;

{ generates a random number on [0,1) with 64-bit resolution }
function TMersenne.genrand_res53(): Double;
var
  a, b: Cardinal;
begin
  a := genrand_int32() shr 5;
  b := genrand_int32() shr 6;

  result := (a*67108864.0 + b) * (1.0/9007199254740992.0);
end;
{ These real versions are due to Isaku Wada, 2002/01/09 added }

{ generates a random number on [0,1) with 80-bit resolution, Extended precision }
function TMersenne.genrand_res64(): Extended;
var
  a: Cardinal;
  b: UINT64;
  ExtConst: Extended;
begin
  a := genrand_int32();
  b := (Int64(genrand_int32()) shl 32) + a;
  ExtConst := 1.0/1.844674407370955e+19;
  result := b * ExtConst;
end;

constructor TMersenne.Create(s: Cardinal);
begin
  mti :=  N+1;
  init_genrand(s);
end;
end.
