// Ashika Palacharla
// EE478
// Parallel Architecture for Low-Latency Multi-Strategy Trading Execution

// momentum
// Momentum trading strategy, based on short-term price changes
// 		Produces a BUY=2'b01 if prices are rising (current price is greater than previous)
// 		Produces a SELL=2'b10 if prices are falling (current price is less than previous)
// 		Produces a HOLD=2'b00 otherwise

module momentum
  (
	// Market data inputs
    input logic [31:0] prev_price_i
  , input logic [31:0] curr_price_i

	// Strategy outputs
  , output logic [1:0] decision_o // 00=HOLD, 01=BUY, 10=SELL
  , output logic v_o
  
  );


  always_comb begin
	// Make decision always valid for momentum
    v_o               <= 1'b1;

	// Rising price, so buy
	if (curr_price_i > prev_price_i) begin
		decision_o <= 2'b01;

	// Falling price, so sell
	end else if (curr_price_i < prev_price_i) begin
		decision_o <= 2'b10;
		
	// Hold
	end else begin
		decision_o <= 2'b00;
	end
  end 

endmodule