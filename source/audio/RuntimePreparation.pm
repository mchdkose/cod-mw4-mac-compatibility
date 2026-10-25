package RuntimePreparation;
use strict;
use warnings;
use File::Basename qw(basename);
use File::Path qw(make_path);
use File::Copy qw(copy);

# Extracted compatibility-runtime preparation. Supply the release resources
# directory explicitly.
sub read_file { my($p)=@_;open my $f,'<:raw',$p or die "Cannot read file: $p\n";local $/;return <$f>; }
sub write_file { my($p,$s)=@_;open my $f,'>:raw',$p or die "Cannot write file: $p\n";print $f $s;close $f or die "Cannot save file: $p\n"; }
sub run { my @a=@_;system(@a)==0 or die "Operation failed: ".basename($a[0])."\n"; }

sub ntdll_with_dependency {
 my($nt)=@_;die "The runtime file format could not be recognized.\n" unless length($nt)>=32;
 my@h=unpack('V8',substr($nt,0,32));my$end=32+$h[5];
 die "The runtime file format could not be recognized.\n" unless $h[0]==0xfeedfacf && $h[1]==0x1000007 && $end<=length($nt);
 my$at=32;my$first=length($nt);my$dep='@loader_path/sp26.dylib'.chr(0);
 for(1..$h[4]){
  die "The runtime header is incomplete.\n" if $at+8>$end;
  my($cmd,$size)=unpack('V2',substr($nt,$at,8));
  die "The runtime header is incomplete.\n" if $size<8 || $at+$size>$end;
  if($cmd==12 && $size>=24){my$name=unpack('V',substr($nt,$at+8,4));
   return $nt if $name<$size && substr($nt,$at+$name,length($dep)) eq $dep;
  }
  if($cmd==0x19){
   die "The runtime segment is incomplete.\n" if $size<72;
   my$fileoff=unpack('Q<',substr($nt,$at+40,8));$first=$fileoff if $fileoff>0 && $fileoff<$first;
   my$sections=unpack('V',substr($nt,$at+64,4));
   die "The runtime sections are incomplete.\n" if 72+$sections*80>$size;
   for my$i(0..$sections-1){my$offset=unpack('V',substr($nt,$at+72+$i*80+48,4));$first=$offset if $offset>0 && $offset<$first;}
  }
  $at+=$size;
 }
 die "The runtime header size is inconsistent.\n" unless $at==$end;
 my$size=(24+length($dep)+7)&~7;
 die "The runtime has no spare header space for the compatibility component.\n" unless $end+$size<=$first && substr($nt,$end,$size) eq chr(0)x$size;
 substr($nt,$end,$size)=pack('V6',12,$size,24,0,0,0).$dep.chr(0)x($size-24-length($dep));
 substr($nt,16,8)=pack('V2',$h[4]+1,$h[5]+$size);return $nt;
}
sub prepare_runtime {
 my($cx,$out,$resources)=@_;my$r="$cx/lib/wine";my$overlay="$out/runtime";my$native="$overlay/lib/wine/x86_64-unix";make_path($native);
 for my $spec([$cx,$overlay,'lib'],["$cx/lib","$overlay/lib",'wine'],[$r,"$overlay/lib/wine",'x86_64-unix'],["$r/x86_64-unix",$native,'ntdll.so','wine']){
  my($from,$to,@exclude)=@$spec;my%excluded=map{$_=>1}@exclude;opendir my$dir,$from or die "Could not read the runtime.\n";
  for my$n(readdir $dir){next if $n eq '.' || $n eq '..' || $excluded{$n};symlink("$from/$n","$to/$n") or die "Could not prepare the local runtime.\n";}
  closedir $dir;
 }
 copy("$r/x86_64-unix/wine","$native/wine") or die "Could not copy the local loader.\n";chmod 0755,"$native/wine";
 write_file("$native/ntdll.so",ntdll_with_dependency(read_file("$r/x86_64-unix/ntdll.so")));
 copy("$resources/sp26.dylib","$native/sp26.dylib") or die "Could not copy the compatibility component.\n";
 run('/usr/bin/codesign','--force','--sign','-','--identifier','ntdll-55554944adc455845ef73829b5b976d2d9b8e0d4',"$native/ntdll.so");
 my$audio=read_file("$r/x86_64-unix/winecoreaudio.so");
 my$old='@rpath/winecoreaudio.so'.chr(0);my$new='@rpath/sp26audio.so'.chr(0);
 # Locate the cmova fix site by its surrounding instructions instead of a fixed
 # offset, so CrossOver builds where the code moved are still supported.
 my($site,$hits,$pos,$cmova)=(-1,0,0,pack('H*','0f47c6'));
 while(($pos=index($audio,$cmova,$pos))>=0){
  if($pos>=8 && substr($audio,$pos-8,2) eq pack('H*','3953') && substr($audio,$pos-5,5) eq pack('H*','b800000000')
   && substr($audio,$pos+3,4) eq pack('H*','01d08943') && substr($audio,$pos-6,1) eq substr($audio,$pos+7,1)){$site=$pos;$hits++;}
  $pos++;
 }
 print STDERR sprintf("AUDIO_FIX_SITE=0x%x HITS=%d\n",$site,$hits);
 die "Audio preparation could not recognize this CrossOver runtime (fix sites found: $hits).\n" unless substr($audio,0x608,length($old)) eq $old && $hits==1;
 substr($audio,0x608,length($old))=$new.chr(0)x(length($old)-length($new));substr($audio,$site,3)=pack('H*','909090');
 write_file("$out/sp26coreaudio.so",$audio);
 run('/usr/bin/codesign','--force','--sign','-','--identifier','winecoreaudio_probe-55554944af16194c7dbd392a9b3d362eb19d601d',"$out/sp26coreaudio.so");
 for my$p("$native/ntdll.so","$native/sp26.dylib","$out/sp26coreaudio.so"){run('/usr/bin/codesign','--verify','--strict',$p);}
 symlink("$native/ntdll.so","$out/ntdll.so") or die "Could not create the local runtime link.\n";
 copy("$resources/MW4-Compatibility.exe","$out/MW4-Compatibility.exe") or die "Could not copy the compatibility helper.\n";
 return $native;
}

1;
