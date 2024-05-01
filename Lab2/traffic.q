//This file was generated from UPPAAL 4.0.6 (rev. 2987), March 2007

/*

*/
A[] not deadlock\


/*

*/
E<> LightE.Green

/*

*/
E<> LightW.Green

/*

*/
E<> LightS.Green\


/*

*/
E<> LightN.Green

/*
two opposing lights may never be green
*/
A[] not ((LightN.Green or LightS.Green) and (LightW.Green or LightE.Green))
