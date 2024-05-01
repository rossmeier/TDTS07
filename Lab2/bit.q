//This file was generated from UPPAAL 4.0.6 (rev. 2987), March 2007

/*

*/
R.recv0 --> (C.rrack0 or C.rrack1)

/*

*/
R.recv0 --> C.ssack0

/*

*/
S.send0 --> R.recv0

/*

*/
A[] not deadlock
