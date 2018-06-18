RED='\033[0;31m'
NC='\033[0m' # No Color
GREEN='\033[0;32m'
res=$(grunt phplint)
RESULT=$? 
touch phpLintResult.txt
echo "$res" > phpLintResult.txt
[ $RESULT -ne 0 ] && echo -e "$res ${RED}\nSome PHP Lint did not pass. Please check your code.${NC}" && exit 1 
echo -e "${GREEN}All PHP Lint passed..${NC}\n"
exit 0

