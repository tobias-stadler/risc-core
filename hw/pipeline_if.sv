interface pipeline_if();
   logic valid;
   logic stall;

   modport Downstream (input stall, output valid);
   modport Upstream (input valid, output stall);
endinterface
