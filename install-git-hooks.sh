
# Create test directory
mkdir -p tests tests/hooks tests/non-ui tests/ui

# Write test hook
cat > tests/hooks/non-ui-test-hook << EOM
#!/bin/sh
#Colors
RED='\033[0;31m'
NC='\033[0m' # No Color
GREEN='\033[0;32m'

spinner(){   
    local -r PID=\$!
    #echo \$PID #debugging printing process id
    while kill -0 \$PID 2> /dev/null; do 
       chars=(" (O.O)"  " (-.-)" " (O.O)")       #animation array.
        for i in "\${chars[@]}"; do
        sleep 0.25  #animation duration.
        #echo -en "  " #only if u are not refreshing enough spaces and only spaces that are needed.
        echo -en \$"\$i" "\r\r"  #printing the array.
        done
    done
    printf "done      \n"
}

npm install  #checking and installing the node packages.
#PHP linting report
bash tests/hooks/phpLintTest.sh & spinner 
wait \$!
RESULT1=\$?
# JSlisting
bash tests/hooks/grunt_jshint.sh & spinner
wait \$!
RESULT2=\$?
#Qunit test reports.
bash tests/hooks/gruntQunitTask.sh & spinner
wait \$!
RESULT3=\$?
# echo $RESULT1
# echo $RESULT2   #debugging printing now commented .
# echo $RESULT3
if [ \$RESULT1 -ne 0 ] 
then
    echo -e "\${RED}Commit failed." && exit 1
elif [ \$RESULT2 -ne 0 ] 
then
    echo -e "\${RED}Commit failed." && exit 1
elif [ \$RESULT3 -ne 0 ] 
then
    echo -e "\${RED}Commit failed." && exit 1
else 
    echo -e "\${GREEN}All test cases passed. Commit Passed. \n" && exit 0
fi

EOM
chmod +x tests/hooks/non-ui-test-hook

cat > tests/hooks/gruntQunitTask.sh << EOM
RED='\033[0;31m'
NC='\033[0m' # No Color
GREEN='\033[0;32m'
resqunit=\$(grunt qunit)
RESULT=\$? 
touch qunitResult.txt
echo "\$resqunit" > qunitResult.txt
[ \$RESULT -ne 0 ] && echo -e "\$resqunit \${RED}\nSome Qunit TestCase did not pass. Please check your code.\${NC}" && exit 1 
echo -e "\${GREEN}All test cases passed..\${NC}\n"
exit 0

EOM
chmod +x tests/hooks/gruntQunitTask.sh

cat > tests/hooks/grunt_jshint.sh << EOM
RED='\033[0;31m'
NC='\033[0m' # No Color
GREEN='\033[0;32m'
res=\$(grunt jshint)
RESULT=\$?
[ \$RESULT -ne 0 ] && echo -e "\$res \${RED}\nSome JS Lint did not pass. Please check your code.\${NC}" && exit 1 
echo -e "\${GREEN}All JS Lint passed..\${NC}\n"
exit 0


EOM
chmod +x tests/hooks/grunt_jshint.sh

cat > tests/hooks/phpLintTest.sh << EOM
RED='\033[0;31m'
NC='\033[0m' # No Color
GREEN='\033[0;32m'
res=\$(grunt phplint)
RESULT=\$? 
touch phpLintResult.txt
echo "\$res" > phpLintResult.txt
[ \$RESULT -ne 0 ] && echo -e "\$res \${RED}\nSome PHP Lint did not pass. Please check your code.\${NC}" && exit 1 
echo -e "\${GREEN}All PHP Lint passed..\${NC}\n"
exit 0

EOM
chmod +x tests/hooks/phpLintTest.sh

cat > sendTestLogsToServer.py << EOM
import re
import json
import httplib
import urllib
import datetime
# inputs the file that we get from the output of the Qunit output
# output from the test may vary from different test to test.


def fetchAndRefineFile(fileName):
    resultFile = open(fileName, "r")
    x = ""
    for f in resultFile:
        x = x + f
    array = re.findall(r'\{([^}]*)\}', x)
    # print array[1]  #test printing
    resultFile.close()
    # return the array that seprates the unnecessary information.
    return array


def getTestIdName(dict, moduleName, version):
    testId = ''
    testId = dict["Module name"]
    tempString = dict["Test name"]
    # temparray =
    list1 = tempString.split("***")
    index = 1
    default = ""
    # print temparray
    tempString = list1[index] if len(list1) > index else default
    testId = testId + "#" + tempString + "#" + moduleName + "#" + version
    # print(testId)  #Printing Test
    return testId, tempString


def getJsonFromRefinedArray(arr):  # converts into the json file.
    jsonArry = {}
    secondJsonArray = []

    pack = open("package.json", 'r')
    packageString = ''
    for line in pack:
        packageString = packageString + line
    package = json.loads(packageString)

    tempDict2 = {}
    tempDict2["ModuleName"] = "CDSS_Editor"
    tempDict2["date"] = str(datetime.date.today())
    tempDict2["version"] = package["version"]
    secondJsonArray.append(tempDict2)
    jsonDict = {}
    for i in arr:

        # adding brackets because it needs to be json.
        jsonString = '{' + i + '}'
        jsonDict = json.loads(jsonString)
        boolValue = jsonDict["Passed"]
        if(boolValue):
            jsonDict["passedValue"] = 1
        else:
            jsonDict["failedValue"] = 1
        testId , testName = getTestIdName(jsonDict, tempDict2[
                               "ModuleName"], package["version"])
        jsonDict["TestId"] = testId
        if(jsonArry.__contains__(testId)):
            boolValue1 = jsonDict["Passed"]
            dict1 = jsonArry[testId]
            if(boolValue1):
                intValue = dict1["passedValue"]
                dict1["passedValue"] = intValue + 1
            else:  
                intValue=dict1["failedValue"]
                dict1["failedValue"] = intValue + 1
            jsonDict = dict1
        jsonDict["Test name"] = testName
        jsonArry[testId]=jsonDict
        # print jsonString  # test Printing
    temp={}
    temp["information"]=jsonArry
    secondJsonArray.append(temp)
    print(json.dumps(secondJsonArray))
    return json.dumps(secondJsonArray)
    # Find the type of issue.



dataToSend=(getJsonFromRefinedArray(fetchAndRefineFile("result.txt")))
#print dataToSend
fetchAndRefineFile("result.txt")
URL = "http://cpms.bbinfotech.com/cicd_results/controller/controller.readJsonData.php"
params = urllib.urlencode({'testCaseReport': dataToSend})  # adding data yo URL
headers = {"Content-type": "application/x-www-form-urlencoded",
           "Accept": "text/plain"}
conn = httplib.HTTPConnection("cpms.bbinfotech.com")   # connection to URL
conn.request("POST", "/cicd_results/controller/controller.readJsonData.php",
             params, headers)  # connection formed and data sent
response = conn.getresponse()  # collecting response.
print response.read()
print response.status, response.reason

EOM
chmod +x sendTestLogsToServer.py

cat > tests/hooks/ui-test-hook << EOM
#!/bin/sh
#Colors
RED='\033[0;31m'
NC='\033[0m' # No Color

# Runing test cases
res=\$(mocha \$(find "tests/ui" -name "*.js"))
RESULT=\$?
[ \$RESULT -ne 0 ] && echo -e "\$res \${RED}\nSome TestCase did not pass. Please check your code.\${NC}" && exit 1
echo "All test cases passed.\n"
exit 0
EOM
chmod +x tests/hooks/ui-test-hook

touch tests/hooks/post-pull
chmod +x tests/hooks/post-pull

# Check if pre-commit file exists
PRE_COMMIT_FILE=.git/hooks/pre-commit 
if [ -e "$PRE_COMMIT_FILE" ]; then
# Take backup of pre-commit file
mv $PRE_COMMIT_FILE "$PRE_COMMIT_FILE.backup"
fi
# ========

# Check if post-update file exists
POST_COMMIT_FILE=.git/hooks/pre-commit 
if [ -e "$POST_COMMIT_FILE" ]; then
# Take backup of pre-commit file
mv $POST_COMMIT_FILE "$POST_COMMIT_FILE.backup"
fi
# ========

# write code to pre-commit file
cat > .git/hooks/pre-commit << EOM
#!/bin/sh
# Javascript unit tests 
bash tests/hooks/non-ui-test-hook
RESULT=\$?
#echo \$res
[ \$RESULT -ne 0 ] && exit 1
exit 0
EOM

chmod +x .git/hooks/pre-commit

cat > .git/hooks/post-update << EOM
#!/bin/sh
# Javascript unit tests 
res=\$(./tests/hooks/post-pull)
RESULT=\$?
echo \$res
[ \$RESULT -ne 0 ] && exit 1
exit 0
EOM
chmod +x .git/hooks/post-update

echo "Hooks installed successfully."