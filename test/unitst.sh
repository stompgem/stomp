#!/bin/bash
#
eval $DeBug
# ------------------------------------------------------------------------------
cmd_base=$(dirname $0)
source $cmd_base/funcs.sh
# ------------------------------------------------------------------------------
pushd $cmd_base
RUN=${RUBY:-ruby}
slist=$(ls -1 *.rb | grep -v helper | grep -v 1method)
for rbf in $slist
do
	echo "${RUN} -I ../lib ${rbf}"
	$RUN -I ../lib $rbf
done
# ------------------------------------------------------------------------------
popd
set +x
exit
