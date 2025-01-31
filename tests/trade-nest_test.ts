import {
  Clarinet,
  Tx,
  Chain,
  Account,
  types
} from 'https://deno.land/x/clarinet@v1.0.0/index.ts';
import { assertEquals } from 'https://deno.land/std@0.90.0/testing/asserts.ts';

Clarinet.test({
  name: "Ensure users can create listings",
  async fn(chain: Chain, accounts: Map<string, Account>) {
    const wallet_1 = accounts.get("wallet_1")!;
    
    let block = chain.mineBlock([
      Tx.contractCall(
        "trade-nest",
        "create-listing",
        [
          types.utf8("Vintage Guitar"),
          types.utf8("1970s Fender Stratocaster in good condition"),
          types.utf8("Musical Instruments"),
          types.utf8("New York, NY")
        ],
        wallet_1.address
      )
    ]);
    
    assertEquals(block.receipts.length, 1);
    assertEquals(block.height, 2);
    
    const [receipt] = block.receipts;
    receipt.result.expectOk().expectUint(1);
  }
});

Clarinet.test({
  name: "Ensure users can make and accept offers",
  async fn(chain: Chain, accounts: Map<string, Account>) {
    const wallet_1 = accounts.get("wallet_1")!;
    const wallet_2 = accounts.get("wallet_2")!;
    
    let block = chain.mineBlock([
      Tx.contractCall(
        "trade-nest",
        "create-listing",
        [
          types.utf8("Vintage Guitar"),
          types.utf8("1970s Fender Stratocaster in good condition"),
          types.utf8("Musical Instruments"),
          types.utf8("New York, NY")
        ],
        wallet_1.address
      ),
      Tx.contractCall(
        "trade-nest",
        "make-offer",
        [
          types.uint(1),
          types.list([
            types.utf8("Gibson Les Paul 2015"),
            types.utf8("Cash: $500"),
          ])
        ],
        wallet_2.address
      )
    ]);
    
    assertEquals(block.receipts.length, 2);
    block.receipts[1].result.expectOk().expectUint(1);
    
    let acceptBlock = chain.mineBlock([
      Tx.contractCall(
        "trade-nest",
        "accept-offer",
        [types.uint(1)],
        wallet_1.address
      )
    ]);
    
    acceptBlock.receipts[0].result.expectOk().expectBool(true);
  }
});

Clarinet.test({
  name: "Ensure users can rate trading partners",
  async fn(chain: Chain, accounts: Map<string, Account>) {
    const wallet_1 = accounts.get("wallet_1")!;
    const wallet_2 = accounts.get("wallet_2")!;
    
    let block = chain.mineBlock([
      Tx.contractCall(
        "trade-nest",
        "rate-user",
        [
          types.principal(wallet_2.address),
          types.uint(5)
        ],
        wallet_1.address
      )
    ]);
    
    assertEquals(block.receipts.length, 1);
    block.receipts[0].result.expectOk().expectBool(true);
  }
});
