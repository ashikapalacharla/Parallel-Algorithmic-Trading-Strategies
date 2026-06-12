// Ashika Palacharla
// EE478
// Parallel Architecture for Low-Latency Multi-Strategy Trading Execution

// moving_average
// Moving Average trading strategy, based on comparing current price to moving average over the last 4 prices
// 		Produces a BUY=2'b01 if current price is greater than average
// 		Produces a SELL=2'b10 if current price is less than average
// 		Produces a HOLD=2'b00 otherwise

module moving_average
  (
	// Market data inputs
   input logic [31:0] curr_price_i
  , input logic [33:0] rolling_sum_i // sum of prices
  , input logic        window_full_i //flags when count is 4

	// Strategy outputs
  , output logic [1:0] decision_o // 00=HOLD, 01=BUY, 10=SELL
  , output logic v_o
  
  );


  always_comb begin
    // Wait until window is filled to start producing valid decisions
    if (window_full_i) begin
      v_o      		<= 1'b1; 

      // Current is greater than average, so buy
      if (curr_price_i > (rolling_sum_i >> 2)) begin
        decision_o <= 2'b01;

      // Current is less than average, so sell
      end else if (curr_price_i < (rolling_sum_i >> 2)) begin 
        decision_o <= 2'b10;

      // Otherwise hold
      end else begin
        decision_o <= 2'b00;
      end
      
    // Otherwise, send invalid and hold
    end else begin // before window filled
      v_o <= 1'b0;
      decision_o <= 2'b00;
    end
  end 

endmodule