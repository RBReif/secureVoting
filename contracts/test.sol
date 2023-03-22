contract C {
  struct MarketSale { 
      uint testint;
   }
  MarketSale[] storage saleHistory;
  function f() public {
    MarketSale[] storage _saleHistory = saleHistory; // now the local variable points to an actual state variables in storage.
    MarketSale memory sale = MarketSale(4);
    _saleHistory.push(sale);
  }
}