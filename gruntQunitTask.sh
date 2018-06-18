RED='\033[0;31m'
NC='\033[0m' # No Color
GREEN='\033[0;32m'
resqunit=$(grunt qunit)
RESULT=$? 
touch qunitResult.txt
echo "$resqunit" > qunitResult.txt
[ $RESULT -ne 0 ] && echo -e "$resqunit ${RED}\nSome Qunit TestCase did not pass. Please check your code.${NC}" && exit 1 
echo -e "${GREEN}All test cases passed..${NC}\n"
exit 0

