/**
 * BSG Test Node Client
 */
module  bsg_test_node_client #(parameter ring_width_p="inv"
                              ,parameter master_p="inv"
                              ,parameter master_id_p="inv"
                              ,parameter client_id_p="inv")
  (input  clk_i
  ,input  reset_i
  ,input  en_i

  ,input                     v_i
  ,input  [ring_width_p-1:0] data_i
  ,output                    ready_o
  
  ,output                    v_o
  ,output [ring_width_p-1:0] data_o
  ,input                     yumi_i
  );


  logic [1:0] trade_output;

  assign data_o  = { 4'(client_id_p), 73'b0, trade_output };

  /** INSTANTIATE NODE 0 **/
  if ( client_id_p == 0 ) begin

    trading_core node
      (.clk_i   ( clk_i   )
      ,.reset_i ( reset_i )
      ,.volume_i     ( data_i[31:0] )
      ,.price_i     ( data_i[63:32] )
      ,.v_i     ( v_i     )
      ,.ready_o ( ready_o )
      ,.v_o     ( v_o     )
      ,.decision_o  ( trade_output )
      ,.yumi_i  ( yumi_i  ));

  end

  /** INSTANTIATE NODE 1 **/
  //  else if ( client_id_p == 1 ) begin
  //
  //    <INSTANTIATE NODE MODULE>
  //
  //  end

endmodule

