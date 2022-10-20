package BenesSwitchTest;

import BenesSwitch::*;

(* synthesize *)
module mkBenesSwitchTest();
    Reg#(Bit#(32)) cycle <- mkReg(0);
    let switch <- mkBenesSwitch;

    rule countUp;
        cycle <= cycle + 1;
    endrule
    
    rule startNoSwitch if (cycle == 1);
        switch.inPort[0].put(11);
        switch.inPort[1].put(19);
        switch.controlPort.setControl(Switch);
    endrule

    rule startSwitch if (cycle == 10);
        switch.inPort[0].put(37);
        switch.inPort[1].put(31);
        switch.controlPort.setControl(Switch);
    endrule

    rule startBroadcast if (cycle == 20);
        switch.inPort[0].put(5);
        switch.controlPort.setControl(Broadcast);
    endrule

    rule print;
        let data0 <- switch.outPort[0].get();
        let data1 <- switch.outPort[1].get();
        
        $display("OutPort0: %d (at cycle %d)", data0, cycle);
        $display("OutPort1: %d (at cycle %d)", data1, cycle);
    endrule

    rule finish if (cycle >= 100);
        $display("Finished at cycle: %d", cycle);
        $finish(0);
    endrule
endmodule

endpackage
