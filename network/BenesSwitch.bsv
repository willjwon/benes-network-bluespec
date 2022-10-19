package BenesSwitch;

import Vector::*;
import Fifo::*;
import Adder::*;

typedef enum {
    NoSwitch,
    Switch
} BenesSwitchControl deriving (
    Bits, Eq
);

interface BenesSwitchIngressPort#(type dataType);
    method Action put(dataType data);
endinterface

interface BenesSwitchEgressPort#(type dataType);
    method ActionValue#(dataType) get;
endinterface

interface BenesSwitchControlPort;
    method Action setControl(BenesSwitchControl newControl);
endinterface

interface BenesSwitch#(type dataType);
    interface Vector#(2, BenesSwitchIngressPort#(dataType)) inPort;
    interface Vector#(2, BenesSwitchEgressPort#(dataType)) outPort;
    interface BenesSwitchControlPort controlPort;
endinterface

module mkBenesSwitch(BenesSwitch#(dataType)) provisos (
    Bits#(dataType, dataTypeBitLength),
    Arith#(dataType)
);
    Vector#(2, Fifo#(1, dataType)) inputs <- replicateM(mkBypassFifo);
    Vector#(2, Fifo#(1, dataType)) outputs <- replicateM(mkPipelineFifo);
    Fifo#(1, BenesSwitchControl) control <- mkBypassFifo;

    rule putOutputPort0 if (outputs[0].notFull);
        if (control.first == NoSwitch) begin
            outputs[0].enq(inputs[0].first);
        end else begin
            outputs[0].enq(inputs[1].first);
        end
    endrule

    rule putOutputPort1 if (outputs[1].notFull);
        if (control.first == NoSwitch) begin
            outputs[1].enq(inputs[1].first);
        end else begin
            outputs[1].enq(inputs[0].first);
        end
    endrule

    rule deqInputPort0 if (inputs[0].notEmpty);
        inputs[0].deq();
    endrule

    rule deqInputPort1 if (inputs[1].notEmpty);
        inputs[1].deq();
    endrule

    rule deqControl if (control.notEmpty());
        control.deq();
    endrule

    // Interfaces
    Vector#(2, BenesSwitchIngressPort#(dataType)) inPortDef;
    for (Integer i = 0; i < 2; i = i + 1) begin
        inPortDef[i] = interface BenesSwitchIngressPort
            method Action put(dataType data) if (inputs[i].notFull());
                inputs[i].enq(data);
            endmethod
        endinterface;
    end

    Vector#(2, BenesSwitchEgressPort#(dataType)) outPortDef;
    for (Integer i = 0; i < 2; i = i + 1) begin
        outPortDef[i] = interface BenesSwitchEgressPort
            method ActionValue#(dataType) get if (outputs[i].notEmpty());
                outputs[i].deq();
                return outputs[i].first();
            endmethod
        endinterface;
    end

    interface inPort = inPortDef;
    interface outPort = outPortDef;
    interface controlPort = interface BenesSwitchControlPort
        method Action setControl(BenesSwitchControl newControl);
            control.enq(newControl);
        endmethod
    endinterface;
endmodule

endpackage
