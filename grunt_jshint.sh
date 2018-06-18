RED='\033[0;31m'
NC='\033[0m' # No Color
GREEN='\033[0;32m'
res=$(grunt jshint)
RESULT=$?
[ $RESULT -ne 0 ] && echo -e "$res ${RED}\nSome JS Lint did not pass. Please check your code.${NC}" && exit 1 
echo -e "${GREEN}All JS Lint passed..${NC}\n"
exit 0


