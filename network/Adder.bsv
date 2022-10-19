package Adder;

import Fifo::*;

interface Adder#(type opType);
    method Action putA(opType value);
    method Action putB(opType value);
    method ActionValue#(opType) get();
endinterface

module mkAdder(Adder#(opType)) provisos (
    Bits#(opType, opTypeLen),
    Arith#(opType)
);
    Fifo#(1, opType) opA <- mkBypassFifo;
    Fifo#(1, opType) opB <- mkBypassFifo;
    Fifo#(1, opType) opResult <- mkBypassFifo;

    rule doAddition if (opA.notEmpty() && opB.notEmpty());
        let a = opA.first();
        opA.deq();

        let b = opB.first();
        opB.deq();

        let result = a + b;
        opResult.enq(result);
    endrule

    method Action putA(opType value) if (opA.notFull());
        opA.enq(value);
    endmethod

    method Action putB(opType value) if (opB.notFull());
        opB.enq(value);
    endmethod

    method ActionValue#(opType) get() if (opResult.notEmpty);
        opResult.deq();
        return opResult.first;
    endmethod
endmodule

endpackage
