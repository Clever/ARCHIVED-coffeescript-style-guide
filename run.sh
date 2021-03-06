#!/usr/bin/env bash
dir='node_modules/clever-coffeescript-style-guide/'
coffeelint=$dir'node_modules/.bin/coffeelint'
coffeejshint=$dir'node_modules/.bin/coffee-jshint'
exit_code=0

function report {
  if [ $1 -eq 0 ]; then
    echo -e $2
  fi
}

function update_exit {
  if [ $exit_code -ne 0 ] || [ $1 -ne $2 ]; then
    exit_code=1
  fi
}

if [ $# -eq 0 ]; then
  if [ -d ".git" ]; then
    files=`git ls-files | grep -E .coffee$`
  else
    files=`find . -type f -path "*.coffee" | grep -v node_modules`
  fi
else
  files=$@
fi

for file in $files; do
  echo -e "\n$(tput setaf 5)$file$(tput sgr0)"
  # lint
  $coffeelint -f $dir'coffeelint-config.json' $file ; update_exit $? 0

  # coffee-jshint
  # Test files
  echo $file | egrep '^test/' | xargs $coffeejshint -o node,mocha,evil ; update_exit $? 0
  # Frontend files
  echo $file | egrep 'assets/' | xargs $coffeejshint -o browser ; update_exit $? 0
  # Non test non frontend files
  echo $file | egrep -v '^test/' | egrep -v 'assets/' | xargs $coffeejshint -o node,evil ; update_exit $? 0

  # it.only, describe.only etc in test
  line=`echo $file | egrep '^test/' | xargs egrep -nv '^ *#' | egrep \(it\|describe\).\(only\|skip\)`
  status=$?
  update_exit $status 1
  report $status "$(tput setaf 1)ERROR: $(tput sgr0)$file contains an it.only, it.skip, describe.only, or describe.skip\n$line"

  # console.log
  line=`egrep -nv '^ *#' $file | grep 'console.log'`
  report $? "$(tput setaf 3)WARNING: $(tput sgr0)$file contains a console.log\n$line"
done

exit $exit_code
