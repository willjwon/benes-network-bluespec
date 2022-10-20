package Fred8;

import FredNetwork::*;

(* synthesize *)
module mkFred8(FredNetwork#(8));
    FredNetwork#(8) fred <- mkFredNetwork;
    return fred;
endmodule

endpackage
