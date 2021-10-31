#!/bin/bash

#------------------------------------------------------------------------
# Create MP.
#------------------------------------------------------------------------
function makeMPs() {

function makeMP($EXTENSION){
	compileWithFPC("MP", "mp", $EXTENSION)
}

	cd MP

	#makeMP $EXTI32
	makeMP $EXTI64
	makeMP $EXTA64
 
	cd ..

}



function makeAll(){
	makeMPs
	displayExecutables MP /
}
