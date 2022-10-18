package AdderTest;

import Adder::*;

(* synthesize *)
module mkAdderTest();
    Reg#(Bit#(32)) cycle <- mkReg(0);
    Adder#(Bit#(32)) adder <- mkAdder;

    rule countUp;
        cycle <= cycle + 1;
    endrule

    rule start if (cycle == 1);
        adder.putA(10);
        adder.putB(20);
    endrule

    rule print;
        let result <- adder.get();
        $display("Result: %d at cycle %d", result, cycle);
    endrule

    rule finish if (cycle >= 30);
        $display("Finished");
        $finish(0);
    endrule
endmodule

endpackage
