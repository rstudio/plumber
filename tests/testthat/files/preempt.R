#* @filter testFun
function(){ }

#* @filter testFun2
function(){ }

#* @filter testFun3
function(){ }

#* @preempt testFun
#* @get /
function(){

}

#* @preempt test
#* Excluded
function(){

}

#* @preempt testFun2
#* @get /
#*

function(){

}

#*@preempt testFun3
#*@post /
function(){

}
