#!/bin/bash
#
eval $DeBug
# ------------------------------------------------------------------------------
cmd_base=$(dirname $0)
source $cmd_base/funcs.sh
# ------------------------------------------------------------------------------
pushd $cmd_base
slist=$(ls -1 *.rb | grep -v helper | grep -v 1method)
for rbf in $slist
do
	echo "ruby -I ../lib ${rbf}"
	ruby -I ../lib $rbf
done
# ------------------------------------------------------------------------------
popd
set +x
exit
