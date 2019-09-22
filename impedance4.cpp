// impedance4.cpp : Defines the entry point for the console application.
// program to print the impedance values of a gUSBamp to stdout
// 09/22/2019 steve i tried to reset to normal mode before I close
#include "stdafx.h"
#include <windows.h>
#include "gUSBamp.h"
#include <iostream>
#include <fstream>
#include <string>
using namespace std;

bool fexists(const char *filename)
{
  ifstream ifile(filename);
  cout << "looking for " << filename;
  if(ifile) {
	  cout << "found it\n";
  }
 //  return (ifile);
 return (bool) ifile;
}

int main(int argc, char* argv[])
{
int i = 0;
int ch = 0;
HANDLE hdev = NULL;
double Impedance;
char *filename ="c:\\BCIHomeSystemFiles\\BCIAddons\\bin\\imp.dat"; //default file 
/*char *filename =".\\imp.dat"; //current directory*/
cout << "impedance Version 1.2\n";
if(argc > 1) {
	if(strncmp(argv[1],"-f",100)) {
		cout << "Unknown option " << argv[1] << " only valid option is -f\n";
		exit(1);
	}
  filename=argv[2]; //replace default with command line
  cout << "Output file is " << filename << "\n";
}
for(i=1;i<11;i++){
  hdev = GT_OpenDevice(i);
  if(hdev != NULL) break; // found a valid amp
}
ofstream myfile(filename);
if(myfile.is_open()) { // write them out to a file
  if(hdev == NULL){
	myfile << "Error! No gUSBamp device found\n";
	cout << "Error! No gUSBamp device found\n";
	exit(1);
  }

  for(ch=1;ch<17;ch++) {
	if(fexists("c:\\stopImpedance.txt")) break;
    GT_GetImpedance(hdev,ch,&Impedance);
//    if(Impedance < 0.0)Impedance=0.0;
    myfile << "channel " << ch << "   " << Impedance << " Ohms\n";
     cout << "channel " << ch << "   " << Impedance << " Ohms\n";
     // printf("channel %d %.0f Ohms\n",ch,Impedance);//yes,  old school IO
  }
  GT_Stop(hdev);
  GT_ResetTransfer(hdev);
  GT_SetMode(hdev, M_NORMAL);
  GT_CloseDevice(&hdev);
}else { 
	cout << "Unable to open " << filename;
    GT_ResetTransfer(hdev);
	GT_CloseDevice(&hdev);
	exit(1);
}
 		return 0;
}
