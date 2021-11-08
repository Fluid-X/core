# Contracts

This outlines the contract structure, and their place within the FluidX
ecosystem.

## FluidXPair

Fundamental pair contract.

Handled the reserves of superToken0 and superToken1, minting and burning of
liquidity tokens, and calling an onSwap hook for the rewards.

Is a native super token.

## FluidXFactory

Creates pair contracts.

Handles the creation and fetching of pairs by address.

## FluidXParams

Core parameters of the FluidX exchange.

Handles fetching of all relevant params including governance address. All state
modifiers MUST be handled by governance ONLY.

For the sake of getting a product to market as soon as possible, the governance
is an address, which will default to the contract deployer. This comes with the
usual risks of heavily centralized power, so there MUST be a clear, open, and 
public roadmap with an immutable date for the transfer of governance from the
deployer to a proper governance contract. If no governance contract is built or
deployed by the immutable date, the governance address will be burned to the
zero address. This leaves the exchange dead in the water in terms of governance,
as there would be no parameter adjustment because of the lack of a governor,
but the FluidX protocol MUST optimize against centralization at literally any
cost. Thank you for attending this Ted Talk.

## FluidXRewards

Pair liquidity staking rewards.

Handles Instant Distribution Agreement subscriptions based on staked liquidity,
distributes tokens when called by a pair's onSwap function, implements
IERC777Recipient to allow for `IERC777.send()` staking. Calling send is
optional, you can still use the legacy `IERC20.transferFrom()` function, but the
UI SHOULD optimize for the most gas efficient and best UX option possible.

Is a super app and IERC777Recipient.

## FluidXGovernance

In research, no file yet.

SHOULD handle super token voting. SHOULD directly change FluidXParams when a
relevant vote is successful. SHOULD include multiple vote types including, but
not limited to, parameter tweaking and treasury allocation for research and
development, bounties, hackathon rewards, consistent contributor salary
streaming. CAN include vote for diversification of treasury tokens.

## FluidXRouter

In research, no file yet.

SHOULD handle UX improvements around the FluidX core contracts. SHOULD implement
IERC777Recipient to handle 1 transaction swapping without batch calls. CAN be a
super app, for the sake of Superfluid batch calls. 
