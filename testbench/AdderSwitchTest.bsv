package AdderSwitchTest;

import AdderSwitch::*;

(* synthesize *)
module mkAdderSwitchTest();
    Reg#(Bit#(32)) cycle <- mkReg(0);
    AdderSwitch#(Bit#(64)) switch <- mkAdderSwitch;

    rule countUp;
        cycle <= cycle + 1;
    endrule
    
    rule startNoSwitch if (cycle == 1);
        switch.inPort[0].put(11);
        switch.inPort[1].put(19);
        switch.controlPort.setControl(NoSwitch);
    endrule

    rule startAddUp if (cycle == 10);
        switch.inPort[0].put(12);
        switch.inPort[1].put(21);
        switch.controlPort.setControl(AddUp);
    endrule

    rule startSwitch if (cycle == 20);
        switch.inPort[0].put(37);
        switch.inPort[1].put(31);
        switch.controlPort.setControl(Switch);
    endrule

    rule startAddBroadcast if (cycle == 30);
        switch.inPort[0].put(65);
        switch.inPort[1].put(12);
        switch.controlPort.setControl(AddBroadcast);
    endrule

    rule startBroadcast if (cycle == 40);
        switch.inPort[0].put(5);
        switch.controlPort.setControl(Broadcast);
    endrule

    rule startAddDown if (cycle == 50);
        switch.inPort[0].put(17);
        switch.inPort[1].put(31);
        switch.controlPort.setControl(AddDown);
    endrule

    rule printPort0;
        let data0 <- switch.outPort[0].get();
        $display("OutPort0: %d (at cycle %d)", data0, cycle);
    endrule

    rule printPort1;
        let data1 <- switch.outPort[1].get();
        $display("OutPort1: %d (at cycle %d)", data1, cycle);
    endrule

    rule finish if (cycle >= 100);
        $display("Finished");
        $finish(0);
    endrule
endmodule

endpackage
