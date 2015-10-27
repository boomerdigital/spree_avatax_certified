# 3.0.2
- [Refactored code and added final commit of tax in payment](https://github.com/railsdog/spree_avatax_certified/pull/58). (acreilly)
- Added model SpreeAvataxCertified::Address to handle formatting addresses for tax calculation
- Added model SpreeAvataxCertified::Line to handle formatting lines for tax calculation
- Removed commit avatax finalize from order state to complete and moved it from payment state to complete
- Added cancel tax to payment state to void

# 3.0.1

- [Refactored cart adjustments out in favor of a `TaxCalculator` class](https://github.com/railsdog/spree_avatax_certified/pull/47). (acreilly)
- Added a gem versioning system to match branch names.  Spree branch `3-0-stable` is tracked by gem branch `3-0-stable` and point releases within that branch are semantically versioned.

# 3.0

- Inital release tracking Spree `3-0-stable`.
