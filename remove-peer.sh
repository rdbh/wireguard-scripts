#!/bin/bash

if [ $# -eq 0 ]
then
	echo "must have peer public key as arg: remove-peer.sh <asdf123=>"
	wg show
else
	echo "Removing" $1
	sudo wg set wg0 peer $1 remove
	sudo wg show
fi
