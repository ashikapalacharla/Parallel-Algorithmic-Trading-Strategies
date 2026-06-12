// Ashika Palacharla
// EE478
// Parallel Architecture for Low-Latency Multi-Strategy Trading Execution

// trading_core
// Top-level trading core that inputs financial market data and outputs trade decisions (buy, sell, hold

module trading_core
  ( 
    // Clock and reset inputs
    input               clk_i    
  , input               reset_i  

    // Market data inputs
  , input        [31:0] price_i    // 32 bit price
  , input        [31:0] volume_i   // 32 bit volume
  , input               v_i       // valid input data

  , input               yumi_i    // valid/ready handshake acknowledgement
  , output              ready_o   // ready for new input data
  
    // Final decision outputs
  , output logic [1:0]  decision_o // 00=HOLD, 01=BUY, 10=SELL
  , output logic        v_o       // valid output data
  );

  // Internal Registers
  // Market Data outputs
  logic [31:0] prev_price, curr_price;

  logic [33:0] rolling_sum;
  logic        window_full;

  logic [63:0] rolling_product, rolling_vol;

  // Trading Strategy outputs
  logic [1:0] mom_decision, avg_decision, vwap_decision, arbiter_decision;
  logic       mom_v, avg_v, vwap_v, arbiter_v;


  // Instantiate Market Data
  //    Extracts prices outputs and rolling sums for strategies
  market_data md
  (
    .clk_i               (clk_i)
  , .reset_i             (reset_i)  

  , .price_i             (price_i)
  , .volume_i            (volume_i)
  , .v_i                 (v_i)

  , .arbiter_v           (arbiter_v)
  , .arbiter_decision    (arbiter_decision)
  , .decision_o          (decision_o)
  , .v_o                 (v_o)

  , .ready_o             (ready_o)
  , .yumi_i              (yumi_i)

  , .prev_price_o        (prev_price)
  , .curr_price_o        (curr_price)
  , .rolling_sum_o       (rolling_sum)
  , .window_full_o       (window_full)
  , .rolling_product_o   (rolling_product)
  , .rolling_vol_o       (rolling_vol)
  );


  // Instantiate Momentum Trading Strategy
  momentum mom_strat
  (
    .prev_price_i        (prev_price)
  , .curr_price_i        (curr_price)

  , .decision_o          (mom_decision)
  , .v_o                 (mom_v)
  );

  // Instantiate Moving Average Trading Strategy
  moving_average avg_strat
  (
    .curr_price_i        (curr_price)
  , .rolling_sum_i       (rolling_sum)
  , .window_full_i       (window_full)

  , .decision_o          (avg_decision)
  , .v_o                 (avg_v)
  );


  // Instantiate Volume Weighted Average Price Trading Strategy
  vwap vwap_strat
  (
    .curr_price_i        (curr_price)
  , .rolling_product_i   (rolling_product)
  , .rolling_vol_i       (rolling_vol)

  , .decision_o          (vwap_decision)
  , .v_o                 (vwap_v)
  );


  // Instantiate Arbiter
  final_trade_arbiter arbiter
  (
    .mom_decision_i      (mom_decision) // Momentum decision and valid
  , .mom_v_i             (mom_v)

  , .avg_decision_i      (avg_decision) // Moving average decision and valid
  , .avg_v_i             (avg_v)
  
  , .vwap_decision_i     (vwap_decision) // VWAP decision and valid
  , .vwap_v_i            (vwap_v)

  , .arbiter_decision_o  (arbiter_decision)
  , .arbiter_v_o         (arbiter_v)
  );


endmodule