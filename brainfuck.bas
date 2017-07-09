NEW
CLEAR 255

100 DIM tap(1023)
110 DIM prg(2047)
120 LET tp = 0
130 LET ip = 0

200 REM LOAD PROGRAM
205 LET j = 0
210 INPUT "Program";pss$
220 FOR i=0 TO LEN(pss$)-1
240 LET c = ASC(RIGHT$(LEFT$(pss$, i+1), 1))
245 LET prln = i + j
250 IF c = 59 THEN GOTO 400:REM ;
260 LET prg(i + j) = c
265 REM PRINT "prln: ";prln;" i: ";i;" j: ";j;" c: ";chr$(c)
270 NEXT i
280 LET j = i + j
290 GOTO 210

400 REM INIT TAPE
405 PRINT "Loaded";prln;"byte long BF program..."
410 FOR i=0 TO 1023
420 LET tap(i) = 0
430 NEXT i
440 PRINT "Cleared 1024 byte tape."

1000 REM MAIN INTERPRETER LOOP
1010 LET inst = prg(ip)
1015 REM PRINT "** ip: ";ip;" inst: ";chr$(inst);" tp: ";tp;" d: ";tap(tp);" **"
1020 IF inst = 46 THEN PRINT CHR$(tap(tp));
1025 IF inst = 44 THEN GOSUB 5000:REM ,
1030 IF inst = 43 THEN LET tap(tp) = tap(tp) + 1:REM +
1040 IF inst = 45 THEN LET tap(tp) = tap(tp) - 1:REM -
1050 IF inst = 62 THEN LET tp = tp + 1:REM >
1060 IF inst = 60 THEN LET tp = tp - 1:REM <
1070 IF inst = 91 THEN GOSUB 3000:REM [
1080 IF inst = 93 THEN GOSUB 4000:REM ]
1090 LET ip = ip + 1
1095 IF tp < 0 THEN LET tp = 0
1096 IF tp > 1023 THEN LET tp = 1023
1100 IF ip >= prln THEN GOTO 1120
1110 GOTO 1000
1120 PRINT ""
1130 STOP

3000 REM [ Go to matching ] if current cell is zero
3010 IF tap(tp) <> 0 THEN RETURN
3020 LET depth = 1
3030 FOR i = ip + 1 TO prln
3040 IF prg(i) = 91 THEN LET depth = depth + 1
3050 IF prg(i) = 93 THEN LET depth = depth - 1
3060 IF depth = 0 THEN GOTO 3100
3070 NEXT i
3080 PRINT "PRG ERR MISMATCH"
3090 RETURN
3100 LET ip = i
3110 RETURN

4000 REM ] GO to matching [ if current cell is non-zero
4010 IF tap(tp) = 0 THEN RETURN
4020 LET depth = 1
4030 FOR i = ip - 1 TO 0 STEP -1
4040 IF prg(i) = 91 THEN LET depth = depth - 1
4050 IF prg(i) = 93 THEN LET depth = depth + 1
4060 IF depth = 0 THEN GOTO 4100
4070 NEXT i
4080 PRINT "PRG ERR MISMATCH"
4090 RETURN
4100 LET ip = i
4110 RETURN

5000 REM , Handle input
5010 RETURN
