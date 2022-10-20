/* Double-Precision Floating-Point */
/* 1-bit Sign, 11-bit Exponent, 52-bit Mantissa */
typedef Bit#(64) FP64;

/* FP64 Breakdown */
typedef Bit#(1) FP64Sign;
typedef Bit#(11) FP64Exponent;
typedef Bit#(52) FP64Mantissa;

/* Types for Computation */
typedef Bit#(12) FP64ExponentAdded;  // Adding two 11-bit values yields a 12-bit value.

// Even though mantissa is represented as a 52-bit value,
// It's actually 53-bit (1.xxx or 0.xxx).
typedef Bit#(54) FP64MantissaAdded;  // Adding two 53-bit values yields a 54-bit value.
typedef Bit#(106) FP64MantissaMultiplied;  // Multiplying two 53-bit values yields a 106-bit value.


/* Latency Insensitive Interface */
interface LI_FP64ALU;
    method Action putArgA(FP64 argA_);
    method Action putArgB(FP64 argB_);
    method ActionValue#(FP64) getResult();
endinterface
