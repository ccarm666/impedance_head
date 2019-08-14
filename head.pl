#!/usr/bin/perl -w
#perl2exe_include Tk::Canvas
use Tk;
use Config::IniFiles;
use Getopt::Long;
use Win32::Process(STILL_ACTIVE,NORMAL_PRIORITY_CLASS);
use Win32;
use File::Basename;
$version="V1.1";
$demo=0;
$go_color='green';
$nogo_color='red';
$fill_color="tan";
$outline_color="black";
$bg_color="PapayaWhip" if(!$bg_color);
$ohm_threshold_green=10000;
$ohm_threshold_yellow=20000;
$allgreencounter=2;
$xloc=1300; # default location

#$ohm_threshold_orange=20000;
$ohm_threshold_red=30000;
$imp_prog="C:\\BCIHomeSystemFiles\\BCIAddons\\bin\\imped.exe";
$data_file="C:\\BCIHomeSystemFiles\\BCIAddons\\bin\\imp.dat";
$last_full_imp="C:\\BCIHomeSystemFiles\\BCIAddons\\bin\\last_full_imp.dat";
system("del $last_full_imp") if(-e $last_full_imp); # delete file so as not to mistake a leftover for a new
$imp_prog_basename=basename($imp_prog);
$electrode_size=.1; #fraction of head_width or head_height(which ever is smaller)
# coordinates are in fractions of X head_width or Y head_height with the origin at the center of head
#$electrode{FZ}{x}=0;$electrode{FZ}{y}=-.2;$electrode{FZ}{channel}=1; $echannel{1}='FZ';
#$electrode{CZ}{x}=0;$electrode{CZ}{y}=-0;$electrode{CZ}{channel}=2;$echannel{2}='CZ';
#$electrode{PZ}{x}=0;$electrode{PZ}{y}=.2;$electrode{PZ}{channel}=3;$echannel{3}='PZ';
#$electrode{P3}{x}=-.15;$electrode{P3}{y}=.25;$electrode{P3}{channel}=4;$echannel{4}='P3';
#$electrode{P4}{x}=.15;$electrode{P4}{y}=.25;$electrode{P4}{channel}=5;$echannel{5}='P4';
#$electrode{PO7}{x}=-.25;$electrode{PO7}{y}=.35;$electrode{PO7}{channel}=6;$echannel{6}='PO7';
#$electrode{PO8}{x}=.25;$electrode{PO8}{y}=.35;$electrode{PO8}{channel}=7;$echannel{7}='PO8';
#$electrode{Oz}{x}=0;$electrode{Oz}{y}=.4;$electrode{Oz}{channel}=8;$echannel{8}='Oz';
#$gnd{x}=.45;$gnd{y}=.1;$gnd{color}='white';
#$ref{x}=-.45;$ref{y}=.1;$ref{color}='white';

for($i=1;$i<9;$i++){$ohm[$i]= int rand(50000);} # for demo mode
&options();
$imp_location="+$xloc+0";
foreach $a(keys %electrode){$electrode{$a}{color}=$nogo_color;} # init all electrodes to nogo
foreach $a(keys %electrode){$electrode{$a}{value}=1000000;}
foreach $a(keys %electrode){
    $electrode{$a}{ohm_threshold_yellow}=$ohm_threshold_yellow if(!exists ($electrode{$a}{ohm_threshold_yellow}));
	$electrode{$a}{ohm_threshold_red}=$ohm_threshold_red if(!exists($electrode{$a}{ohm_threshold_red}));
}
#print "xloc=$xloc $imp_location\n";
#exit();
&run_impedance();
$canvas_width=750 if (!$canvas_width);
$canvas_height=850 if (!$canvas_height);
###########################################################################################################################

my $window = MainWindow->new(-background => $bg_color);
$window->geometry($imp_location);
$drawing = $window->Canvas(-width => $canvas_width, -height => $canvas_height, -background => $bg_color,
                           -relief => 'sunken',-borderwidth => 3) ->grid(-row=>0,-column=>0);
$imp_frame=$window->Frame(-background => $bg_color, -relief=>'sunken')->grid(-row=>0,-column=>1);
&create_imp_text();
$drawing->Tk::bind("<Configure>",[sub {
#                             print "H: $_[1], W: $_[2]\n";
			 if(($drawing->Height != $canvas_height) or ($drawing->Width != $canvas_width)) {
				 $canvas_height= $drawing->Height;
				 $canvas_width= $drawing->Width;
				 &redraw_head($canvas_width,$canvas_height);
			  }
			       },Ev('h'),Ev('w') ]);
    $window->repeat(500 => \&read_file);


MainLoop;
########################################
sub user_input {
$ARG=<>;
print "input is $ARG\n";
$electrode{Oz}{color}=$go_color;
&redraw_head($drawing->Width,$drawing->Height);
}
#########################################################################
sub read_file {
   my($line);

   $ProcessObj->GetExitCode($exit_code);
   if ($exit_code != STILL_ACTIVE) {
    my($allgreen)=1;
    open(DAT, "$data_file") || die("Could not open $data_file!\n");
	system("copy $data_file $last_full_imp"); # copy the last full data file somewhere we can get to it from the diagnostics program 01/13/2012
	while($line=<DAT>) {
      print "line is $line\n";
      ($chn,$ohmc)=$line=~/channel\s+(\d+)\s+(\S+)\s+Ohms\n/;
	  $ohmc= 99999999 if($line=~/QNAN/);
	  $ohmc=abs($ohmc); # correct problem with new amps
	  if(exists $echannel{$chn}) {
		 if($demo) {
		    print "In demo and channel is $chn\n";
			if($chn ==1) {$ohmc=1200};
			if($chn ==2) {$ohmc=12645};
			if($chn ==3) {$ohmc=34987};
			if($chn ==4) {$ohmc=8765};
			if($chn ==13) {$ohmc=52789};
			if($chn ==14) {$ohmc=39769};
			if($chn ==15) {$ohmc=9745};
			if($chn ==16) {$ohmc=68567};
		 }
	     $electrode{$echannel{$chn}}{value}=sprintf("%8s",int $ohmc);
#		  $electrode{$echannel{$chn}}{value}=&commify($electrode{$echannel{$chn}}{value});
	     if(&get_color($ohmc,$echannel{$chn}) ne 'green'){$allgreen=0;}
	     if($electrode{$echannel{$chn}}{color} ne &get_color($ohmc,$echannel{$chn})) {
	       $electrode{$echannel{$chn}}{color}=&get_color($ohmc,$echannel{$chn});
	       &redraw_head($drawing->Width,$drawing->Height);
	      }
	    }
		}
       if($allgreen){
         $allgreencounter--;
         print "allgreencounter is  $allgreencounter\n";
		 if(!$allgreencounter) {
		  exit(1);
		 }
		} else {$allgreencounter=2;} # twice in a row
	  &run_impedance();
	  &redraw_head($drawing->Width,$drawing->Height);
	 }

}
#######################################################################
sub redraw_head {
my($c_width,$c_height)=@_;
my $o;
foreach $o ($drawing->find("all")){$drawing->delete($o);} # delete all canvas items so that we can redraw them
my $head_width=$c_width*.75;
my $head_height=$c_height*.75;
my $head_xcenter=$c_width/2;
my $head_ycenter=$c_height/2;

my $ear_width=$head_width*.05;
my $ear_height=$head_height/6;
my $left_ear_xcenter=$head_xcenter-($ear_width/2)-($head_width/2)+($ear_width*.1);
my $left_ear_ycenter=$head_ycenter;
my $right_ear_xcenter=$head_xcenter+($ear_width/2)+($head_width/2)-($ear_width*.1);
my $right_ear_ycenter=$head_ycenter;

my $nose_width=$head_width/5;
my $nose_height=$head_height*.08;
my $nose_ybase=$head_ycenter-($head_height/2)+($nose_height*.1);
$window->title("P300 montage");
#$window->Label(-text => "This is a chunk of descriptive text")->pack;


$drawing->createOval($left_ear_xcenter-($ear_width/2),$left_ear_ycenter-($ear_height/2),
                     $left_ear_xcenter+($ear_width/2),$left_ear_ycenter+($ear_height/2),
					 -fill=>$fill_color); # left ear

$drawing->createOval($right_ear_xcenter-($ear_width/2),$right_ear_ycenter-($ear_height/2),
                     $right_ear_xcenter+($ear_width/2),$right_ear_ycenter+($ear_height/2),
					 -fill=>$fill_color); # right ear

$drawing->createPolygon($head_xcenter-($nose_width/2),$nose_ybase,
                        $head_xcenter,$nose_ybase-($nose_height),
						$head_xcenter+($nose_width/2),$nose_ybase,-fill=>$fill_color,-outline=>$outline_color);

$drawing->createOval($head_xcenter-($head_width/2),$head_ycenter-($head_height/2),
                      $head_xcenter+($head_width/2),$head_ycenter+($head_height/2),-fill=>$fill_color);#head

foreach my $k (keys %electrode) {
&draw_electrode($electrode{$k}{x},$electrode{$k}{y},$electrode_size,$electrode{$k}{color},"$k",$head_xcenter,$head_ycenter,$head_width,$head_height);
}
#gnd and Ref
&draw_electrode($gnd{x},$gnd{y},$electrode_size,$gnd{color},"Gnd",$head_xcenter,$head_ycenter,$head_width,$head_height);
&draw_electrode($ref{x},$ref{y},$electrode_size,$ref{color},"Ref",$head_xcenter,$head_ycenter,$head_width,$head_height);
# legend
&draw_legend($electrode_size,$head_width,$head_height);
# numeric display
&update_imp_text();

}

#################################################################
sub draw_electrode {
my($xp,$yp,$size,$color,$text,$h_xcenter,$h_ycenter,$h_width,$h_height)=@_;
my $abs_size;
 if($h_height > $h_width){$abs_size=$size*$h_width}else{$abs_size=$size*$h_height}
$drawing->createOval($h_xcenter+($xp*$h_width)-($abs_size/2),
                     $h_ycenter+($yp*$h_height)-($abs_size/2),
                     $h_xcenter+($xp*$h_width)+($abs_size/2),
					 $h_ycenter+($yp*$h_height)+($abs_size/2),-fill=>$color,-outline=>$outline_color);
$drawing->createOval($h_xcenter+($xp*$h_width)-($abs_size/4),
                     $h_ycenter+($yp*$h_height)-($abs_size/4),
                     $h_xcenter+($xp*$h_width)+($abs_size/4),
					 $h_ycenter+($yp*$h_height)+($abs_size/4),-fill=>$color,-outline=>$outline_color);
 if($text) {
     $drawing->createText($h_xcenter+($xp*$h_width),$h_ycenter+($yp*$h_height),
                          ,-text=>"$text",-anchor=>"center");
}

}
###################################################################
sub draw_legend {
my($size,$h_width,$h_height)=@_;
my $abs_size;
my($canvas_width)=$drawing->Width;
if($h_height > $h_width){$abs_size=$size*$h_width}else{$abs_size=$size*$h_height}
my $leftx_red_oval = 2*($abs_size/4)-($abs_size/4);
my $topy_red_oval = 1.3*($h_height)-($abs_size/4);
my $rightx_red_oval =  2*($abs_size/4)+($abs_size/4);
my $bottomy_red_oval = 1.3*($h_height)+($abs_size/4);
$drawing->createOval($leftx_red_oval,
                     $topy_red_oval,
                     $rightx_red_oval,
					 $bottomy_red_oval,-fill=>'red',-outline=>$outline_color);
my $leftx_yellow_oval = ($canvas_width/2)+2*($abs_size/4)-($abs_size/4);
my $topy_yellow_oval = 1.3*($h_height)-($abs_size/4);
my $rightx_yellow_oval =  ($canvas_width/2)+2*($abs_size/4)+($abs_size/4);
my $bottomy_yellow_oval = 1.3*($h_height)+($abs_size/4);
					 
$drawing->createOval($leftx_yellow_oval,
                     $topy_yellow_oval,
                     $rightx_yellow_oval,
					 $bottomy_yellow_oval,-fill=>'yellow',-outline=>$outline_color);
my $leftx_green_oval = ($canvas_width-7*($abs_size/4))+2*($abs_size/4)-($abs_size/4);
my $topy_green_oval = 1.3*($h_height)-($abs_size/4);
my $rightx_green_oval = ($canvas_width-7*($abs_size/4))+2*($abs_size/4)+($abs_size/4);
my $bottomy_green_oval = 1.3*($h_height)+($abs_size/4);	
my $t_font=	"Arial 8 normal";
$t_font = "Arial 7 normal" if ($canvas_width < 700);
$drawing->createOval($leftx_green_oval,
                     $topy_green_oval,
                     $rightx_green_oval,
					 $bottomy_green_oval,-fill=>'green',-outline=>$outline_color);
$drawing->createText($rightx_red_oval,1.3*($h_height),
                          ,-text=>" Very High > $GlobalRedThresh",-font=>$t_font,-anchor=>'w');
$drawing->createText($rightx_yellow_oval,1.3*($h_height),
                          ,-text=>" High > $GlobalYellowThresh",-font=>$t_font,-anchor=>'w');
$drawing->createText($rightx_green_oval,1.3*($h_height),
                          ,-text=>" Correct",-font=>$t_font,-anchor=>'w');
$drawing->createText(4*($abs_size/5),.05*($h_height),
                          ,-text=>"Impedance Check $version",-font=>"Arial 22 normal",-anchor=>'w');
}
#####################################################################
sub add_electrode_coord {
my($ename,$loc)=@_;
  my($x,$y)=$loc=~/([-|+]*\d+)x([-|+]*\d+)/;
   if(!(defined($x) and defined($y))) {
      print "error in $parmfile in section electrode placement parameter $ename  value is $loc\n";
    } else {
      print "x=$x and y=$y\n";
      $electrode{$ename}{x}=$x*.01;$electrode{$ename}{y}=$y*.01;$electrode{$ename}{color}=$go_color;
     }
}
#####################################################################
sub add_reference_coord {
my($ename,$loc)=@_;
  my($x,$y)=$loc=~/([-|+]*\d+)x([-|+]*\d+)/;
   if(!(defined($x) and defined($y))) {
      print "error in $parmfile in section reference_placment parameter $ename  value is $loc\n";
    } else {
      print "x=$x and y=$y\n";
      $ref{x}=$x*.01;$ref{y}=$y*.01;$ref{color}='white';
     }
}
#####################################################################
sub add_ground_coord {
my($ename,$loc)=@_;
  my($x,$y)=$loc=~/([-|+]*\d+)x([-|+]*\d+)/;
   if(!(defined($x) and defined($y))) {
      print "error in $parmfile in section ground_placement parameter $ename  value is $loc\n";
    } else {
      print "x=$x and y=$y\n";
      $gnd{x}=$x*.01;$gnd{y}=$y*.01;$gnd{color}='white';
     }
}

##########################################################################
sub add_electrode_channel {
my($ename,$ch)=@_;
print "got $ename and $ch\n";
if($ch=~/\D+/) {
print "error in $parmfile in section electrode_channel parameter $ename value $ch\n";
print "non digit in channel number\n";
} else {
$electrode{$ename}{'channel'}=$ch;
$echannel{$ch}=$ename;
}
}
##########################################################################
sub add_ohm_threshold_yellow {
my($ename,$thresh)=@_;
print "got $ename and $thresh\n";
if($thresh=~/\D+/) {
print "error in $parmfile in section ohm_threshold_yellow parameter $ename value $thresh\n";
print "non digit in threshold number\n";
} else {
$electrode{$ename}{ohm_threshold_yellow}=$thresh;
$GlobalYellowThresh=&commify($thresh);
}
}
##########################################################################
sub add_ohm_threshold_red {
my($ename,$thresh)=@_;
print "got $ename and $thresh\n";
if($thresh=~/\D+/) {
print "error in $parmfile in section ohm_threshold_red parameter $ename value $thresh\n";
print "non digit in threshold number\n";
} else {
$electrode{$ename}{ohm_threshold_red}=$thresh;
$GlobalRedThresh=&commify($thresh);
}
}
##########################################################################
sub get_color {
my($impedance,$elec_name)=@_;
if($impedance > $electrode{$elec_name}{ohm_threshold_red}) {return ('red')}
if($impedance > $electrode{$elec_name}{ohm_threshold_yellow}) {return ('yellow')}
return ('green');
}
############################################################################
sub ErrorReport{
   print "error report ",Win32::FormatMessage( Win32::GetLastError() );
}
#############################################################################
sub create_imp_text {
my ($a); my($i);
$i=0;
foreach $a(sort keys %electrode) {
 $electrode{$a}{label}=$imp_frame->Label(-text=>"$a",-font=>"Arial 18 normal",-background => $bg_color,-justify => 'right',-padx => 3)->grid(-row=>$i,-column=>0,-sticky =>"nsew");
 $electrode{$a}{label_value}=$imp_frame->Label(-text=>"",-font=>"Arial 18 normal",-background => $bg_color,-justify => 'right',-padx => 3,-relief => 'sunken')->grid(-row=>$i,-column=>1,-sticky =>"nsew");
 print "electrode value is $electrode{$a}{value}\n";
 $i++;
 }
 }
############################################################################
sub update_imp_text {
my ($a); my($i);
$i=0;
foreach $a(sort keys %electrode) {
 $electrode{$a}{label}=$imp_frame->Label(-text=>"$a",-font=>"Arial 18 normal",-background => $electrode{$a}{color},-justify => 'right',-padx => 3)->grid(-row=>$i,-column=>0,-sticky =>"nsew");
 $electrode{$a}{label_value}=$imp_frame->Label(-text=>&commify($electrode{$a}{value}),-font=>"Arial 18 normal",-background => $electrode{$a}{color},-justify => 'right',-padx => 3,-relief => 'sunken')->grid(-row=>$i,-column=>1,-sticky=>'nsew');
 #print "electrode value is $electrode{$a}{value}\n";
 $i++;
 }
 }
############################################################################
sub run_impedance {
   print "about to run $imp_prog\n";
   Win32::Process::Create($ProcessObj,
                                $imp_prog,
                                "$imp_prog_basename -f $data_file",
                                0,
                                NORMAL_PRIORITY_CLASS,
                                ".")|| die ErrorReport();
}
#############################################################################
sub options () {
	my $help = 0;		# handled locally
	my $parmfile = 0;
	# Process options.
	if ( @ARGV > 0 ) {
	    GetOptions('xsize:i'	=> \$canvas_width,
		       'ysize:i'	=> \$canvas_height,
		       'bg_color:s'           =>\$bg_color,
		       'help|?'	=> \$help,
		       'parmfile:s' => \$parmfile,
			   'imp_prog:s'=> \$imp_prog,
			   'demo' =>\$demo,
			   'data_file:s'=>\$data_file);
	}
	if ( $help ) {
	  &usage();
      exit;
	}
	if ($parmfile) {
	   my $cfg=Config::IniFiles->new( -file => $parmfile );
	   foreach $s ($cfg->Sections) {
	         print "section is $s\n";
		 foreach $p ($cfg->Parameters($s)) {
		    print "    parameter is  $p \n";
		    print "        value is ",$cfg->val($s,$p),"\n";
		    &add_electrode_coord($p,$cfg->val($s,$p))  if($s eq 'electrode_placement');
			&add_electrode_channel($p,$cfg->val($s,$p))  if($s eq 'electrode_channel');
			&add_reference_coord($p,$cfg->val($s,$p))  if($s eq 'reference_placement');
			&add_ground_coord($p,$cfg->val($s,$p))  if($s eq 'ground_placement');
			&add_ohm_threshold_yellow($p,$cfg->val($s,$p))  if($s eq 'ohm_threshold_yellow');
            &add_ohm_threshold_red($p,$cfg->val($s,$p))  if($s eq 'ohm_threshold_red');
			$xloc=$cfg->val($s,'xloc') if($s eq 'geometry' && $p eq 'xloc');
		 }
             }
         }
    }
###########################################################################

 sub commify {
	local $_  = shift;
	my $unit;
	if($_ < 1000){
		$unit=" ";
	}else {
		$unit = "k";
		$_= $_/1000;# measure in kilo ohms
	}
	1 while s/^([-+]?\d+)(\d{3})/$1,$2/; # put in commas
	s/\.\d*$//; #remove decimal digits and point
	return $_  . " $unit" . "\x{03A9}"; # add kilo ohm symbol
}
################################################################################
sub usage {
print "usage:\nhead5 [--xsize size:800] [--ysize size:920] [--demo] [--parmfile filename] [--imp_prog progname] [--data_file datafile] [--bg_color color]";
print 'perl head5.pl --parmfile c:\\BCIHomeSystemFiles\\BCIAddons\\config\\head.ini --imp_prog c:\\BCIHomeSystemFiles\\BCIAddons\\bin\\demo_imp.exe  --data_file c:\\BCIHomeSystemFiles\\BCIAddons\\bin\\imp.dat',"\n";
print 'perl head5.pl --parmfile c:\\BCIHomeSystemFiles\\BCIAddons\\config\\head.ini --imp_prog c:\\BCIHomeSystemFiles\\BCIAddons\\bin\\imp.exe --data_file c:\\BCIHomeSystemFiles\\BCIAddons\\bin\\imp.dat',"\n";
print "\nThe parameter file uses the standard ini file format eg: \n";
print <<ENDOFEXAMPLE
[electrode_placement]
# standard 8 electrode cap
FZ=0x-20
CZ=0x0
PZ=0x20
P3=-15x25
P4=15x25
PO7=-25x35
PO8=25x35
OZ=0x40
#TZ=-10x10
[electrode_channel]
FZ=1
CZ=2
PZ=3
P3=4
P4=5
PO7=6
PO8=7
OZ=8
[reference_placement]
REF=45x10
[ground_placement]
GND=-45x10
[ohm_threshold_yellow]
FZ=10000
PZ=1000
[ohm_threshold_red]
FZ=40000
PZ=10000

ENDOFEXAMPLE

}