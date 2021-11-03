# FluidX

FluidX aims to be a decentralized automated market maker (AMM) with native
support for super tokens, an augmentation on ERC20 and ERC777 pioneered by
Superfluid Finance.

---

## 1 - Abstract

Traditional AMMs like Uniswap and Sushi facilitate the exchange of ERC20 tokens
on some Ethereum Virtual Machine (EVM) compatible blockchains.

The Superfluid protocol upgrades ERC20 tokens by wrapping them 1 to 1, offering
novel functionality such as streaming via Constant Flow Agreements (CFA), highly
scalable distributions via Instant Distribution Agreements (IDA), and modular
function call batching via batch calls.

In existing ERC20 AMMs, there are many redundant transcations, increasing
network congestion, increased transaction fees, long wait times, and poor user
experience.

A CFMM that natively supports super tokens can offer novel exchange interactions
including, but not limited to:

-   on-swap token distributions to liquidity providers
-   one-transaction swaps and liquidity providing
-   interoperability with existing AMMs via upgrading and downgrading
-   novel token governance
-   user experience optimizations
-   per-second dollar cost averaging

---

## 2 - Automated Market Makers

Fundamentally, FluidX functions like other constant function AMMs such as
Uniswap and Sushiswap. The codebase for FluidX is a modified version of Uniswap,
optimizing for super token compatibility.

The following section outlines the existing AMM functionality and drawbacks.

---

### 2.1 - Pairs and Pools

A token pair is a contract that manages a pool of two different token assets,
provided by liquidity providers. The exchange rate of the two assets is
calculated by a constant product function, `x * y = k`.

---

### 2.2 - Liquidity Providers

Liquidity providers deposit both assets in a pair, in turn receiving LP tokens
representing their stake in the pair's liquidity pool. Each swap includes a fee
from the trader, which is distributed to liquidity providers based on their
stake in the liquidity pool. However, profits are only realized once LP tokens
are burned and the token assets withdrawn from the pair. There is also a concern
of divergent (impermanent) loss, where the exchange rate divergence between the
two token assets negatively imacts liquidity providers.

---

### 2.3 - Swapping

Swapping involves the transferring of one token asset of the two to the pair
contract, changing the exchange rate via the constant product function,
collecting a fee for liquidity providers, and finally providing the other token
asset in the pair.

---

### 2.4 - Constant Product Function

As mentioned above, when a swap is executed, or a disproportional amount of
token assets are provided to a pair, the constant product function creates a new
exchange rate. The exchange rates between markets creates imbalances, and thus,
opportunities in the market discussed below.

---

### 2.5 - Arbitrage

Arbitrageurs are market actors that aggregate exchange rates between markets and
seek a profit in exchange for balancing the prices between markets.

---

### 2.6 - Divergent Loss

Divergent loss, or commonly referred to as impermanent loss, is the liquidity
providers' loss of value due to exchange rate divergence from their initial
pair deposit.

Generally, transaction fees are meant to offset divergent loss, but AMMs like
Uniswap offer a flat 0.3% swap fee, regardless of asset volatility. This often
leads to liquidity providers rapidly moving assets in and out of pairs based on
expected price divergence to avoid the loss.

---

## 3 - FluidX Augmented Functionality

### 3.1 - Instant Distribution Agreement Rewards

Liquidity providers, as mentioned above, provide liqudiity for a pair in
exchange for LP tokens. No profits are realized until their LP tokens are
burned, and their token assets withdrawn from the contract.

The Superfluid protocol facilitates and Instant Distribution Agreement (IDA),
which are highly scalable super token distribution mechanisms. Users, or
subscribers, are assigned shares, which entitle them to a proportional amount of
super tokens that get distributed by the publisher. These distributions can be a
one-time function call or recurring function calls, however, the IDA is best
suited for recurring function calls due to gas fees.

At the time of writing, Ricochet Exchange is the only exchange taking advantage
of the IDA for their real-time dollar cost averaging architecture.

In the case of FluidX, a liquidity provider can stake their LP tokens for a
proportional number of shares in an IDA. Each pair deployed by FluidX, and thus
the FluidX Factory, includes an on-swap hook that, if rewards are activated by
governance, distributes governance super tokens to the staked liquidity
providers.

Rewarding governance tokens to those that provide liquidity and stake their
positions in the FluidX contract allows those most involved with the protocol to
have direct access to the asset that influences protocol parameters, research
and development fund allocation, among other vital decisions. Assuming the
governance super tokens are eventually exchanged over the FluidX or any other
exchagne, the value of the governance token creates an automated take-profit
mechanism for liquidity providers, who otherwise wouldn't recognize any profits
automatically.

---

### 3.2 - One Transaction Interaction

In an ERC20 AMM, a swap, by default, consists of two transactions, one for
approving the contract to transfer on behalf of the token holder, another to
execute the swap.

Swapping two non-native super tokens, or super tokens tied to an underlying
ERC20, requires three more transactions, one for downgrading the initial token,
the two required for a swap, another to approve the received token to be
upgraded, and finally another to upgrade the token.

Providing liquidity while holding both tokens requires three transactions, one
for each asset, approving a contract to transfer them on the holder's behalf,
and another to provide the liquidity.

Providing liquidity requires the steps for a swap plus the steps for otherwise
providing liquidity.

Each of these can be solved by supporting super tokens natively.

A swap on FluidX can be handled in a single transaction via the ERC777 `send`
method and a router contract implementing `IERC777Recipient`, using a
`tokensReceived` hook with encoded data as swap parameters.

Super Token swaps are handled natively, therefore negating the need for
upgrade and downgrade transactions.

Providing liquidity from both assets can be handled in a single transaction by
using batch calls in the user interface.

Providing liquidity from a single asset can be handled in a single transaction
by batching the one-transaction swap with the provide liquidity calls.

Liquidity position staking can also be handled in the same transaction, once
again, by batch calls.

| Action                       | Uniswap TX Count | FluidX TX Count | Uniswap Seconds | FluidX Seconds |
| ---------------------------- | ---------------- | --------------- | --------------- | -------------- |
| Swap                         | 2                | 1               | 40              | 20             |
| Swap Super Token             | 5                | 1               | 100             | 20             |
| Provide Liquidity (has both) | 3                | 1               | 60              | 20             |
| Provide Liquidity (has one)  | 5                | 1               | 100             | 20             |

Note: tansaction time is assuming an average of 20 seconds for a transaction to be
confirmed.

---

### 3.3 Per-second Dollar Cost Averaging

As mentioned above, Ricochet Exchange is the only exchange at the time of
writing that facilitates a real-time, automated dollar cost averaging platform.
The architecture of Ricochet requires off-chain bots to facilitate the autonomy
of dollar cost averaging.

To date, Superfluid has only created two agreements, the CFA that facilitates
open ended token streaming between two addresses and the IDA that facilitates
a one-to-many distribution of tokens. There is discussion about a one-to-many
token stream, which would facilitate a more autonomous stream swapping, but it
is yet to be implemented.

Other architectures exist, but none have proven to be sufficiently autonomous
and cost effective to implement in FluidX yet. Proposals will be made to fund
research and development in this field, and there will exist a mutable document
for any discoveries or implementations in regards to per-second dollar cost
averaging.

---

## 3.4 Novel Governance

// TODO, more research in progress

---

## Conclusion

There are many optimizations that FluidX can implement to reduce network
congestion, reduce redundant transactions, improve user experience, faciliate
automated profit-taking mechanisms for liquidity providers, and innovate on
token governance. The upward trend of salary streaming among DAOs presents a
growing opportunity to create protocols with native super token support.
