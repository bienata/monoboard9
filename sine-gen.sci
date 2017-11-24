samples = 256;
N = [ 0 : 1 : samples-1 ];
S = floor( 128 + 128 * sind ( 360*N/(samples-1) ) );
plot( S );
unix('rm -f waves.inc'); 
f = mopen( 'waves.inc','wt' );
mfprintf( f, 'SINE_WAVE_%d:\n', samples );
mfprintf( f, '\t.db ' );
for n = 1 : samples-1
  mfprintf( f, '%d', S(n) );  
  if modulo( n, 10 ) == 0  then 
    mfprintf( f, '\n\t.db ' );
  else
    if n ~= samples-1 then mfprintf( f, ','  ); end;  
  end;
end;
mfprintf( f, '\n' );
mclose( f );


