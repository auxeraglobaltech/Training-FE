class txn;

  rand int num;

  function automatic bit is_prime(int n);
    if(n < 2)
      return 0;

    for(int i=2; i<=n-1; i++)
      if(n%i == 0)
        return 0;

    return 1;
  endfunction

  constraint prime_c {
    num inside {[2:100]};
    is_prime(num) == 1;
  }

endclass

module tb;
  txn t;

  initial begin
    t = new();

    repeat (10) begin
      assert(t.randomize());
      $display("Prime Number = %0d", t.num);
    end
  end
endmodule
