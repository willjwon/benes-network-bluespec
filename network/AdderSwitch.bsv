package AdderSwitch;

import Vector::*;
import Fifo::*;
import FP64::*;
import FP64Adder::*;
import Connectable::*;

typedef enum {
    NoSwitch,
    Switch,
    Broadcast,
    AddUp,
    AddDown,
    AddBroadcast
} AdderSwitchControl deriving (
    Bits, Eq
);

interface AdderSwitchIngressPort;
    method Action put(Bit#(64) data);
endinterface

interface AdderSwitchEgressPort;
    method ActionValue#(Bit#(64)) get;
endinterface

interface AdderSwitchControlPort;
    method Action setControl(AdderSwitchControl newControl);
endinterface

interface AdderSwitch;
    interface Vector#(2, AdderSwitchIngressPort) inPort;
    interface Vector#(2, AdderSwitchEgressPort) outPort;
    interface AdderSwitchControlPort controlPort;
endinterface

module mkAdderSwitch(AdderSwitch);
    Vector#(2, Fifo#(1, Bit#(64))) inputs <- replicateM(mkBypassFifo);
    Vector#(2, Fifo#(1, Bit#(64))) outputs <- replicateM(mkPipelineFifo);
    Fifo#(1, AdderSwitchControl) control <- mkBypassFifo;

    // instantiate adder
    let adder <- mkLI_FP64Adder;
    Fifo#(1, Bit#(64)) adderResult <- mkBypassFifo;
    mkConnection(adder.getResult, adderResult.enq);

    rule doAddition if (inputs[0].notEmpty && inputs[1].notEmpty);
        adder.putArgA(inputs[0].first);
        adder.putArgB(inputs[1].first);
    endrule

    rule doOperation if (control.notEmpty);
        case (control.first)
            Broadcast: begin
                if (inputs[0].notEmpty) begin
                    let data = inputs[0].first;
                    // not defined: when inputs[1] is also valid
                    outputs[0].enq(data);
                    outputs[1].enq(data);
                end else begin
                    let data = inputs[1].first;
                    // not defined: when inputs[1] is also valid
                    outputs[0].enq(data);
                    outputs[1].enq(data);
                end
            end

            NoSwitch: begin
                if (inputs[0].notEmpty) begin
                    outputs[0].enq(inputs[0].first);
                end

                if (inputs[1].notEmpty) begin
                    outputs[1].enq(inputs[1].first);
                end
            end

            Switch: begin
                if (inputs[0].notEmpty) begin
                    outputs[1].enq(inputs[0].first);
                end

                if (inputs[1].notEmpty) begin
                    outputs[0].enq(inputs[1].first);
                end
            end

            AddUp: begin
                outputs[0].enq(adderResult.first);
            end

            AddDown: begin
                outputs[1].enq(adderResult.first);
            end

            AddBroadcast: begin
                outputs[0].enq(adderResult.first);
                outputs[1].enq(adderResult.first); 
            end
        endcase
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

    rule deqAdderResult if (adderResult.notEmpty);
        adderResult.deq();
    endrule

    // Interfaces
    Vector#(2, AdderSwitchIngressPort) inPortDef;
    for (Integer i = 0; i < 2; i = i + 1) begin
        inPortDef[i] = interface AdderSwitchIngressPort
            method Action put(Bit#(64) data) if (inputs[i].notFull());
                inputs[i].enq(data);
            endmethod
        endinterface;
    end

    Vector#(2, AdderSwitchEgressPort) outPortDef;
    for (Integer i = 0; i < 2; i = i + 1) begin
        outPortDef[i] = interface AdderSwitchEgressPort
            method ActionValue#(Bit#(64)) get if (outputs[i].notEmpty());
                outputs[i].deq();
                return outputs[i].first();
            endmethod
        endinterface;
    end

    interface inPort = inPortDef;
    interface outPort = outPortDef;
    interface controlPort = interface AdderSwitchControlPort
        method Action setControl(AdderSwitchControl newControl);
            control.enq(newControl);
        endmethod
    endinterface;
endmodule

endpackage
