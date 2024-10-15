module package_addr::calculator {
	public struct Output has key, store{
        id: UID,
        result: u64,
    }
		
    public entry fun start(ctx: &mut TxContext){    let output = Output{
            id: object::new(ctx),
            result: 0,
        }; 
        transfer::public_transfer(output, tx_context::sender(ctx));  
    }
		
  public entry fun add(a: u64, b: u64, ctx: &mut TxContext) {
        let output = Output{
            id: object::new(ctx),
            result: a + b,
        };
        transfer::public_transfer(output, tx_context::sender(ctx));  
  }
  public entry fun sub(a: u64, b: u64, ctx: &mut TxContext) {
        let output = Output{
            id: object::new(ctx),
            result: a - b,
        };
        transfer::public_transfer(output, tx_context::sender(ctx));
  }
  public entry fun mul(a: u64, b: u64, ctx: &mut TxContext) {
        let output = Output{
            id: object::new(ctx),
            result: a * b,
        };
        transfer::public_transfer(output, tx_context::sender(ctx));
  }
  public entry fun div(a: u64, b: u64, ctx: &mut TxContext) {
        let output = Output{
            id: object::new(ctx),
            result: a / b,
        };
        transfer::public_transfer(output, tx_context::sender(ctx));
  }
}