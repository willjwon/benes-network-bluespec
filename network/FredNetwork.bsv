package FredNetwork;

import Vector::*;
import Fifo::*;
import Connectable::*;
import BenesSwitch::*;
import AdderSwitch::*;

interface FredNetworkIngressPort#(type dataType);
    method Action put(dataType data);
endinterface

interface FredNetworkEgressPort#(type dataType);
    method ActionValue#(dataType) get;
endinterface

interface FredNetwork#(numeric type portsCount, type dataType);
    interface Vector#(portsCount, FredNetworkIngressPort#(dataType)) inPort;
    interface Vector#(portsCount, FredNetworkEgressPort#(dataType)) outPort;
endinterface

module mkFredNetwork(FredNetwork#(portsCount, dataType)) provisos (
    Bits#(dataType, dataTypeBitLength),
    Arith#(dataType),
    NumAlias#(TDiv#(portsCount, 2), switchesPerLevel),
    NumAlias#(TLog#(portsCount), adderLevelsCount),
    NumAlias#(TSub#(adderLevelsCount, 1), benesLevelsCount)
);
    Integer benesLastLevel = valueOf(benesLevelsCount) - 1;
    Integer adderLastLevel = valueOf(adderLevelsCount) - 1;

    // switches
    Vector#(adderLevelsCount, Vector#(switchesPerLevel, AdderSwitch#(dataType)))
        adderSwitches <- replicateM(replicateM(mkAdderSwitch));
    Vector#(benesLevelsCount, Vector#(switchesPerLevel, BenesSwitch#(dataType)))
        benesSwitches <- replicateM(replicateM(mkBenesSwitch));

    // connect adder switches
    Integer offset = valueOf(switchesPerLevel) / 2;
    for (Integer level = 0; level < 2; level = level + 1) begin
    // for (Integer level = 0; level < valueOf(adderLevelsCount) - 1; level = level + 1) begin
        for (Integer i = 0; i < valueOf(switchesPerLevel); i = i + 2) begin
            Integer dest1 = i / offset;
            Integer dest2 = dest1 + offset;

            // connect switch i
            mkConnection(adderSwitches[level][i].outPort[0].get, adderSwitches[level + 1][dest1].inPort[0].put);
            mkConnection(adderSwitches[level][i].outPort[1].get, adderSwitches[level + 1][dest2].inPort[0].put);


            // connect switch i + 1
            mkConnection(adderSwitches[level][i + 1].outPort[0].get, adderSwitches[level + 1][dest1].inPort[1].put);
            mkConnection(adderSwitches[level][i + 1].outPort[1].get, adderSwitches[level + 1][dest2].inPort[1].put);
        end
        offset = offset / 2;
    end

    // adder-to-benes
    for (Integer i = 0; i < valueOf(switchesPerLevel); i = i + 2) begin
        Integer dest1 = i;
        Integer dest2 = i + 1;

        // connect switch i
        mkConnection(adderSwitches[adderLastLevel][i].outPort[0].get, benesSwitches[0][dest1].inPort[0].put);
        mkConnection(adderSwitches[adderLastLevel][i].outPort[1].get, benesSwitches[0][dest2].inPort[0].put);


        // connect switch i + 1
        mkConnection(adderSwitches[adderLastLevel][i + 1].outPort[0].get, benesSwitches[0][dest1].inPort[1].put);
        mkConnection(adderSwitches[adderLastLevel][i + 1].outPort[1].get, benesSwitches[0][dest2].inPort[1].put);
    end

    // connect benes
    offset = valueOf(switchesPerLevel) / 2;
    for (Integer level = 1; level < valueOf(benesLevelsCount); level = level + 1) begin
        for (Integer i = 0; i < valueOf(switchesPerLevel); i = i + 2) begin
            Integer src1 = i / offset;
            Integer src2 = src1 + offset;

            // connect switch i
            mkConnection(benesSwitches[level - 1][src1].outPort[0].get, benesSwitches[level][i].inPort[0].put);
            mkConnection(benesSwitches[level - 1][src2].outPort[0].get, benesSwitches[level][i].inPort[1].put);

            // connect switch i + 1
            mkConnection(benesSwitches[level - 1][src1].outPort[1].get, benesSwitches[level][i + 1].inPort[0].put);
            mkConnection(benesSwitches[level - 1][src2].outPort[1].get, benesSwitches[level][i + 1].inPort[1].put);
        end
        offset = offset / 2;
    end

    rule broadcast;
        for (Integer i = 0; i < valueOf(switchesPerLevel); i = i + 1) begin
            for (Integer j = 0; j < valueOf(benesLevelsCount); j = j + 1) begin
                benesSwitches[j][i].controlPort.setControl(Switch);
            end

            for (Integer j = 0; j < valueOf(adderLevelsCount); j = j + 1) begin
                adderSwitches[j][i].controlPort.setControl(Switch);
            end
        end
    endrule

    // Interfaces
    Vector#(portsCount, FredNetworkIngressPort#(dataType)) inPortDef;
    for (Integer i = 0; i < valueOf(portsCount); i = i + 2) begin
        Integer switchIndex = i / 2;

        inPortDef[i] = interface FredNetworkIngressPort
            method Action put(dataType data);
                adderSwitches[0][switchIndex].inPort[0].put(data); 
            endmethod
        endinterface;

        inPortDef[i + 1] = interface FredNetworkIngressPort
            method Action put(dataType data);
                adderSwitches[0][switchIndex].inPort[1].put(data); 
            endmethod
        endinterface;
    end

    Vector#(portsCount, FredNetworkEgressPort#(dataType)) outPortDef;
    for (Integer i = 0; i < valueOf(portsCount); i = i + 2) begin
        Integer switchIndex = i / 2;

        outPortDef[i] = interface FredNetworkEgressPort
            method ActionValue#(dataType) get();
                let result <- benesSwitches[benesLastLevel][switchIndex].outPort[0].get(); 
                return result;
            endmethod
        endinterface;

        outPortDef[i + 1] = interface FredNetworkEgressPort
            method ActionValue#(dataType) get();
                let result <- benesSwitches[benesLastLevel][switchIndex].outPort[1].get(); 
                return result;
            endmethod
        endinterface;
    end

    interface inPort = inPortDef;
    interface outPort = outPortDef;
endmodule

endpackage
