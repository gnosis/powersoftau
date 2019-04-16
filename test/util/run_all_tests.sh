#!/bin/bash
#
# runs all tests
for i in /app/test/*.sh ; do
	echo "=====================\nExecute Test $i\n=====================\n"
	. "$i"
done
