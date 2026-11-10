# PaceVault

PaceVault is an Injective EVM vault that applies on-chain order policies before an AI trading agent submits derivative orders.

## Contract policy

- One configured agent address can submit orders.
- Orders are restricted to one configured derivative market and subaccount.
- Each order is checked against a configured notional cap.
- A block-window counter limits how many orders can be submitted in each window.
- The contract deposits funds into its own Injective Exchange subaccount before trading.

The contract checks these rules before calling Injective's Exchange Precompile.

## Testnet proof

- EVM chain ID: `1439`
- Deployed contract: [GuardedVaultProbe](https://testnet.blockscout.injective.network/address/0x717370CdC6863225ADFe41B35Bb36da7cD6f3B78)
- Deployment transaction: [0x3dd9c109…3b58731](https://testnet.blockscout.injective.network/tx/0x3dd9c109e1da94f4729aad62ea59444ffa217382a4335cbcc6c9478143b58731)
- Accepted INJ/USDC post-only order: [0xed58551f…6eac16](https://testnet.blockscout.injective.network/tx/0xed58551fe500462902c8b15d38f8a41dd53302a25e42adcb54222469dd6eac16)
- Order hash: `0x32070c2403bc50a0f90c01be86ce5307d678dfc2c30b56fcba0506778ac956c4`
- Injective's order query returned that order as a one-INJ buy order with one INJ fillable.
- Deployed policy calls rejected a different market, an order above the notional cap, and a second order within the 100-block window. Each rejection returned its expected contract reason.

The invalid-order checks use read-only calls against the deployed contract. They do not submit invalid transactions.

## Build

```sh
forge build
```

Source: [`src/GuardedVaultProbe.sol`](src/GuardedVaultProbe.sol)
