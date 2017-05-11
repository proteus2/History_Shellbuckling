# 
# superopt.bat: Performs multiple execution of 
# combinations of (autochange,optimize,optimize,optimize...)
#
set case = $1
@ optimizes = `echo $2`
echo "Number of OPTIMIZEs for each autochange= $optimizes"
# beg July 19, 2011
# zeroit
# This program resets the total number of iterations to zero.
# There are no input data.
echo ""
echo "Running GENOPT: zeroit, case: $case"
echo ""
'rm' fort.* FOR0*     >>& /dev/null
'rm' ${case}.ERR >>& /dev/null
echo "----------------------------"
echo  Executing zeroit
ln -s ${case}.NAM fort.12
ln -s ${case}.NAM ftn12
./zeroit.${MACHINE} $case
set stat = $status
echo "----------------------------"
if ($stat == 0) then
   echo  Normal termination: zeroit
   echo  still processing... Please wait.
else
   echo  Abnormal termination: zeroit
   echo  "Exit status: $stat"
  'rm' fort.* ftn* >>& /dev/null
   exit 1
   goto nearend
endif
# end July 19, 2011
@ count = 0
#ln -s ${GENOPT}/execute GENOPT
goto start0
start:
@ count = $count + 1
echo -n " Loop thru autochange $count"
# autochange
# This program automatically changes the decision variables x(i).
echo ""
echo "Running GENOPT: autochange, case: $case"
echo ""
'rm' fort.* FOR0*     >>& /dev/null
'rm' ${case}.ERR >>& /dev/null
echo "----------------------------"
echo  Executing autochange
ln -s ${case}.NAM fort.12
ln -s ${case}.NAM ftn12
./autochange.${MACHINE} $case
set stat = $status
echo "----------------------------"
if ($stat == 0) then
   echo  Normal termination: autochange
   echo  still processing... Please wait.
else
   echo  Abnormal termination: autochange
   echo  "Exit status: $stat"
  'rm' fort.* ftn* >>& /dev/null	
   exit 1
   goto nearend
endif
#
start0:
#
# optimize.bat
# This program controls the execution of the GENOPT optimizer.
# It is assumed that all of the interactive input data
# have been stored on a file called {casename}.OPT.
@ countp = 0
optloop:
@ countp = $countp + 1
echo ""
echo "Running GENOPT: optimize, case: $case"
echo ""
'rm' ${case}.OPM >& /dev/null
'rm' ${case}.ERR >& /dev/null
'rm' ${case}.WAV >& /dev/null
'rm' ${case}.BLK >& /dev/null
'rm' ${case}.OUT >& /dev/null
'rm' ${case}.LAB >& /dev/null
'rm' ${case}.PLT2 >& /dev/null
'rm' ${case}.ALL >& /dev/null
'rm' ${case}.RES >& /dev/null
'rm' ${case}.DOC >& /dev/null
'rm' ${case}.RAN >& /dev/null
'rm' fort.* FOR0* >& /dev/null
if (-e PROMPT4.DAT) 'rm' PROMPT4.DAT
if (-e PROMPT.DAT) 'rm' PROMPT.DAT
if (-e PROMPT2.DAT) 'rm' PROMPT2.DAT
if (-e PROMPT3.DAT) 'rm' PROMPT3.DAT
if (-e URPROMPT.DAT) 'rm' URPROMPT.DAT
ln -s ${case}.RAN fort.11
ln -s ${case}.NAM fort.12
ln -s ${case}.RAN ftn11
ln -s ${case}.NAM ftn12
if ($cwd == ${GENOPT}) then
   echo "GENOPT= ${GENOPT}"
   echo "case  = ${case}"
   echo "Bad error: about to copy to self."
   exit 1
endif
cp ${GENOPT}/execute/PROMPT4.DAT .
cp ${GENOPT}/execute/PROMPT.DAT . 
cp ${GENOPT}/execute/PROMPT2.DAT . 
cp ${GENOPT}/execute/PROMPT3.DAT . 
cp ${GENOPT}/execute/URPROMPT.DAT . 
#ln -s ${GENOPT}/execute GENOPT
echo  Executing optimize
#exit 99
./optimize.${MACHINE} $case < ${case}.OPT >& ${case}.ERR
set stat = $status
if ($stat == 0) then
   echo  Normal termination: main
   echo  still processing... Please wait.
else
   echo  Abnormal termination: main
   echo  "Exit status: $stat"
   exit $stat
   goto nearend:
endif
cat ${case}.OPT ${case}.OPM > ${case}.TOT
'mv' ${case}.TOT ${case}.OPM
echo  Executing store
./store.${MACHINE} $case
set stat = $status
if ($stat == 0) then
   echo  Normal termination: store
   echo  still processing... Please wait.
else if ($stat == 2) then
   echo Maximum allowable number of design iterations reached.
   echo "Inspect ${case}.OPP and execute CHOOSEPLOT and DIPLOT next."
else
   echo  Abnormal termination: store
   echo  "Exit status: $stat"
   exit $stat
   goto nearend
endif
#/bin/rm GENOPT >>& /dev/null
/bin/rm fort.* ftn* >>& /dev/null	
if (-e PROMPT4.DAT) 'rm' PROMPT4.DAT
if (-e PROMPT.DAT) 'rm' PROMPT.DAT
if (-e PROMPT2.DAT) 'rm' PROMPT2.DAT
if (-e PROMPT3.DAT) 'rm' PROMPT3.DAT
if (-e URPROMPT.DAT) 'rm' URPROMPT.DAT
if (-e ${case}.RAN) 'rm' ${case}.RAN
echo "${case} mainprocessor run completed successfully."
echo ""
if ($stat == 2) then
   goto nearend
endif
if ($countp == $optimizes) then
   echo "Number of executions of optimize for each execution of autochange"
   echo "equals that specified by user. Next, execute autochange again."
   goto start
else
   echo "Number of executions of optimize since last autochange= $countp"
   goto optloop
endif
nearend:
# end of script
