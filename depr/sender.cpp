#include <iostream>
#include <fstream>
#include <cstdlib>
#include <string>
#include <vector>
using namespace std;
int main()
{
string number;
string body;
char ask;
do {
    cout <<"number : ";
    cin >> number;
    cout <<"\ntext : ";
    cin.ignore();
    getline(cin,body);
    ofstream myfile;
    myfile.open("sms.sh");
    myfile <<"#! /bin/bash\n\n"
    <<"script_dir=$(dirname $0)\n"
    <<"ADB=$(cat < $script_dir/adb_location)\n"
    <<"$ADB shell am start -a android.intent.action.SENDTO -d sms:"<<number<<" --es sms_body \""<<body<<"\" --ez exit_on_sent true\n"
    <<"sleep 1\n"
    <<"$ADB shell input keyevent 22\n"
    <<"sleep 1\n"
    <<"$ADB shell input keyevent 66\n"
    ;
    myfile.close();
    system("sh sms.sh");
    cout << "press :\n1 to repeat\nanything else to exit"<<endl;
    cin >> ask;
}while(ask == '1');
cin.ignore().get();
return 0;
}
