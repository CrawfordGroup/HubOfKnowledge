#!/usr/bin/perl 

########################################
#           Original Author:           #
#           Micah Abrams               #
#                                      #
#           Edited By:                 #
#           Kirk Pearce                # 
#           11/08/2016                 #
########################################

#Band width at 1/e peak height
# eV - 0.2
# nm - 2
# cm-1 - 50

use Cwd;
use Math::Trig;

my $PWD = cwd();                            #Define pwd variable
my $INPUT = "data.txt";                     #input file
my $SPECTRUM = "spectrum.txt";              #output file
my $NPOINTS = 2000;                         #Number of points in simulated spectra
my $DELTAG = 0.2;                           #Band width at 1/e peak height
my @EX;                                     #Define array to hold energies (or wavelengths) of excited states
my @PROP;                                   #Define array to hold oscillator strengths (or rotatory strengths)
my $NSTATES;                                #Define variable for number of excited states
my $LINESHAPE = "gaussian";                 #Use for Gaussian curve fitting
#my $LINESHAPE = "lorentzian";              #Use for Lorentzian curve fitting
my $i = 0;

#cd to present working directory
chdir ("$PWD");                     

#Read excited state data from file "data.txt"
open(IN, "$INPUT") || die "cannot open $INPUT $!";
while(<IN>) {
  chomp($_);
  @data = split(/[ \t]+/, $_);
  @EX[$i] = $data[0];
  @PROP[$i++] = $data[1];
}
close(IN);

#Set variable to be equal to the total number of computed excited states
$NSTATES = @EX;

#Calculate the minimum and maximum excited state energies (x-values)
my $MIN = min_el_array(\@EX);
my $MAX = max_el_array(\@EX);

print "MIN X $MIN\n";
print "MAX X $MAX\n";

#Discretize energies (or wavelengths) based on range of values and number of points
my @X = energy_range($MIN,$MAX,$DELTAG,$NPOINTS);


#Perform Gaussian or Lorentzian curve fitting on computed excited states
my @I; my @Y;
my @J; my @Z;

for($i=0; $i < $NSTATES; $i++) {
  if($LINESHAPE eq "gaussian") {
    @I = gaussian(\@X,$EX[$i],$PROP[$i],$DELTAG);
  }
  elsif($LINESHAPE eq "lorentzian") {
    @I = lorenz(\@X,$EX[$i],$PROP[$i],$DELTAG);
  }
  for($j=0; $j < $NPOINTS; $j++) {
    $Y[$j] += $I[$j];
  }
}


#Calculate the minimum and maximum oscillator strengths (or rotatory strengths) (y-values)
my $MIN = min_el_array(\@Y);
my $MAX = max_el_array(\@Y);

print "MIN Y $MIN\n";
print "MAX Y $MAX\n";


#Print simulated spectrum data to file "spectrum.txt"
open(OUT, ">$SPECTRUM") || die "cannot open $SPECTRUM $!";
seek(OUT,0,0);
for($i=0; $i < $NPOINTS; $i++) {
  printf (OUT "%8.4f %10.8f\n",$X[$i],$Y[$i]);
}
close(OUT);


#Subroutine to calculate maximum value in an array
sub max_el_array
{
  my $A = $_[0];
  my $dim = @$A;
  my $max = @$A[0];
  
  for($i=1; $i < $dim; $i++) {
    if(@$A[$i] > $max) {
      $max = @$A[$i];
    }
  } 
  
  return $max;
}

#Subroutine to calculate minimum value in an array
sub min_el_array
{
  my $A = $_[0];
  my $dim = @$A;
  my $min = @$A[0];
  
  for($i=1; $i < $dim; $i++) {
    if(@$A[$i] < $min) {
      $min = @$A[$i];
    }
  } 
  
  return $min;
}

#Subroutine to discretize energy values based on energy range and number of desired points
sub energy_range
{
  my $fwhm = $_[2];                     #Set band width to be third argument in the subroutine call
  #my $fwhm = 20;                       #Set band width to be a specific value
  my $np = $_[3];                       #Set number of points to be fourth argument in the subroutine call

  #Set x-value range for simulated spectrum:
  my $min = $_[0]-$fwhm*2;              #Set minimum x-value to be (2*band width) less than the lowest energy excited state
  my $max = $_[1]+$fwhm*2;              #Set maximum x-value to be (2*band width) greater than the highest energy excited state
  #my $min = 150;                       #Set minimum x-value to be specific value
  #my $max = 400;                       #Set maximum x-value to be specific value
  print "MIN X $min\n";
  print "MAX X $max\n";

  my $spacing = ($max-$min)/$np;        #Calculate spacing between simulated x-values

  #Calculate x-values for simulated spectrum points
  $range[0] = $min;
  for($i=1; $i < $np; $i++) {
    $range[$i] = $min + $i * $spacing;
  } 

  return @range;
}

#Subroutine to calculate Lorentzian curve
sub lorenz
{
  my $pi = acos(-1);                    #Define accurate variable for pi
  my $x = $_[0];                        #Assign array of x-values to variable
  my $dim = @$x;                        #Define variable to be the number of x-values
  my $ex = $_[1];                       #Assign array of excited state energies (or wavelengths)        
  my $ab = $_[2];                       #Assign array of rotatory strengths (or oscillator strengths)
  my $fwhm = $_[3];                     #Assign variable for user specified band width
  my $scale = $ab / (4/(2*$pi*$fwhm));

  my $i; my $t1; my $t2; my $t3;
  my @y;

  for($i=0; $i < $dim; $i++) {
    $t1 = $fwhm/(2*$pi);
    $t2 = (@$x[$i]-$ex)**2;
    $t3 = ($fwhm/2)**2;
    $y[$i] = $scale*($t1/($t2 + $t3));
  }

  return @y;
}

#Subroutine to calculate Gaussian curve according to equation 8c from Philip J. Stephens' paper (DOI: 10.1002/chir.20733)
sub gaussian
{
  my $pi = acos(-1);                    #Define accurate variable for pi
  my $x = $_[0];                        #Assign array of x-values to variable
  my $dim = @$x;                        #Define variable to be the number of x-values
  my $ex = $_[1];                       #Assign array of excited state energies (or wavelengths)        
  my $ab = $_[2];                       #Assign array of rotatory strengths (or oscillator strengths)
  my $fwhm = $_[3];                     #Assign variable for user specified band width
  my @y;
  my $i = 0;
  my $tmp = 0;
  my $constant = 1/(2.296e-39);         #Constant used in calculation of rotatory strengths [ 3 h c (10^3) ln(10) / 32 (pi)^3 N_A ] in cgs units(from Stephens' paper as well)
  
  #Programmed equation (8c) from Philip J. Stephens' paper (DOI: 10.1002/chir.20733)
  for($i=0; $i < $dim; $i++) {
    $tmp = (-(2*(@$x[$i]-$ex)/$fwhm)**2);
    $y[$i] = 2 * $constant * (1/(sqrt($pi)*$fwhm)) * $ex * $ab * exp($tmp);
  }

  return @y;
}
