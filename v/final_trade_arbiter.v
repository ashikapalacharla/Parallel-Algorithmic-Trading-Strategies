// Ashika Palacharla
// EE478
// Parallel Architecture for Low-Latency Multi-Strategy Trading Execution

// final trade arbiter
// Arbiter to produce the final decision for a requested trade
// 		Produces a BUY=2'b01, SELL=2'b10, or HOLD=2'b00
//      Arbitrates decisions from multiple trading strategies: momentum, moving average, volume weighted average price

module final_trade_arbiter
  (
    // Valids and decisions from each trading strategy
    input logic mom_v_i
  , input logic [1:0] mom_decision_i
  
  , input logic avg_v_i
  , input logic [1:0] avg_decision_i
  
  , input logic vwap_v_i
  , input logic [1:0] vwap_decision_i

	// Final trade decisions
  , output logic [1:0] arbiter_decision_o // 00=HOLD, 01=BUY, 10=SELL
  , output logic arbiter_v_o
  
  );

  // Fixed priority logic
  always_comb begin
    // VWAP valid given highest priority because safest decision, cumulative weighting
    if (vwap_v_i) begin
      arbiter_decision_o <= vwap_decision_i;
      arbiter_v_o <= vwap_v_i;

    end else if (avg_v_i) begin
      arbiter_decision_o <= avg_decision_i;
      arbiter_v_o <= avg_v_i;

    end else begin
      arbiter_decision_o <= mom_decision_i;
      arbiter_v_o <= mom_v_i;
    end
  end

endmodule