#!/bin/sh
#Colors
RED='\033[0;31m'
NC='\033[0m' # No Color
#installing all dependecies
npm install
# Runing test cases
jslintResult=$(grunt jshint)
phplintResult=$(grunt phplint)
touch phplintReport.txt
echo "$phplintResult" > phplintReport.txt
res=$(grunt qunit)
RESULT=$? 
touch result.txt
echo "$res" > result.txt
[ $RESULT -ne 0 ] && echo -e "$res ${RED}\nSome TestCase did not pass. Please check your code.${NC}" && python sendTestLogsToServer.py && exit 1 
python sendTestLogsToServer.py       
echo "All test cases passed.\n"
exit 0