#/bin/bash
allLenght=80
allLenght=$[ $allLenght -  $[$allLenght % 2] ]

printLine() {
line='';
for i in $(seq $allLenght)
  do  line=$line"#"
done
echo $line
}

printMsg() {
line='#'
msg="$1"
spaces=$[($allLenght-2-${#msg})/2]
for i in $(seq $[($allLenght-2-${#msg})/2])
do
  line+=' '
done
line+="$msg"
for i in $(seq $[($allLenght-2-${#msg})/2])
do
  line+=' '
done
[[ $[ ${#msg} % 2] == 1 ]] && line+=' '
echo "$line#"
}

echo -e "\n"
printLine
msg="Welcome"
printMsg "${msg}"
msg="All connections are monitored and recorded"
printMsg "${msg}"
msg="Disconnect IMMEDIATELY if you are not an authorized user!"
printMsg "${msg}"
printLine
echo " "
echo " "
