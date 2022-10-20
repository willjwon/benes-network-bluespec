package FredNetworkTest;

import FredNetwork::*;

typedef 8 PortsCount;

(* synthesize *)
module mkFredNetworkTest();
    Reg#(Bit#(32)) cycle <- mkReg(0);
    FredNetwork#(PortsCount) fredNetwork <- mkFredNetwork;

    rule countUp;
        cycle <= cycle + 1;
    endrule

    rule insert if (cycle == 10);
        fredNetwork.inPort[0].put(3);
    endrule

    rule insert2 if (cycle == 15);
        fredNetwork.inPort[3].put(7);
    endrule

    for (Integer i = 0; i < valueOf(PortsCount); i = i + 1) begin
        rule printReceived;
            let value <- fredNetwork.outPort[i].get();
            $display("OutPort %d: %d (at cycle %d)", i, value, cycle);
        endrule
    end

    rule finish if (cycle >= 100);
        $display("Finished at cycle: %d", cycle);
        $finish(0);
    endrule
endmodule

endpackage
