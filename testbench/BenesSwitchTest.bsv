package BenesSwitchTest;

import BenesSwitch::*;

(* synthesize *)
module mkBenesSwitchTest();
    Reg#(Bit#(32)) cycle <- mkReg(0);
    BenesSwitch#(Bit#(64)) switch <- mkBenesSwitch;

    rule countUp;
        cycle <= cycle + 1;
    endrule
    
    rule startNoSwitch if (cycle == 1);
        switch.inPort[0].put(11);
        switch.inPort[1].put(19);
        switch.controlPort.setControl(NoSwitch);
    endrule

    rule startSwitch if (cycle == 10);
        switch.inPort[0].put(37);
        switch.inPort[1].put(31);
        switch.controlPort.setControl(Switch);
    endrule

    rule print;
        let data0 <- switch.outPort[0].get();
        let data1 <- switch.outPort[1].get();
        
        $display("OutPort0: %d (at cycle %d)", data0, cycle);
        $display("OutPort1: %d (at cycle %d)", data1, cycle);
    endrule

    rule finish if (cycle >= 30);
        $display("Finished");
        $finish(0);
    endrule
endmodule

endpackage
