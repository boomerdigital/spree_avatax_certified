# 2.4.2
- [Refactored code and added final commit of tax in payment](https://github.com/railsdog/spree_avatax_certified/pull/57). (acreilly)
- Added model SpreeAvataxCertified::Address to handle formatting addresses for tax calculation
- Added model SpreeAvataxCertified::Line to handle formatting lines for tax calculation
- Removed commit avatax finalize from order state to complete and moved it from payment state to complete
- Added cancel tax to payment state to void

# 2.4.1

- [Refactored cart adjustments out in favor of a `TaxCalculator` class](https://github.com/railsdog/spree_avatax_certified/pull/45). (acreilly)
- Added a gem versioning system to match branch names.  Spree branch `2-4-stable` is tracked by gem branch `2-4-stable` and point releases within that branch are semantically versioned.

# 2.4

- Inital release tracking Spree `2-4-stable`.
