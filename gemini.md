# Sentinel Evolution Ledger 🛡️

## 📈 Feature Iteration Track
**Currently Improving:** Privacy Obfuscation (Hide Balances)
**Growth Context:** As the app scales and users carry their devices into more public spaces, they need a way to protect sensitive financial data from shoulder surfers. Competitors often offer a "Privacy Mode" or "Hide Balances" toggle.
**Iteration History:**
- 2024-03-24: Implementing initial base: added `obscureAmounts` setting and tied it to the `convertToMoney` core formatting function so that global balances and amounts display as "•••". Added a basic toggle in the settings.
- 2024-05-14: Iterative Enhancement - Added an eye-icon quick-toggle button on the main dashboard. This allows users to quickly obscure balances in public spaces without opening settings, reducing the window of exposure.
- 2024-05-15: Iterative Enhancement - Added a toast notification (Snackbar) when the privacy mode is toggled from the dashboard to improve user feedback.
- 2024-05-24: Iterative Enhancement - Allowed users to customize the character used for obscure amounts via a dropdown in the settings menu, creating a personalized experience.
- 2025-03-17: Iterative Enhancement - Added an option to scale the length of the obfuscated character sequence with the magnitude (number of integer digits) of the amount.
- 2025-03-24: Iterative Enhancement - Added a long-press temporary reveal function directly to individual transaction amounts in the main UI list (`TransactionEntryAmount`), bypassing obfuscation by passing a local state flag `forceReveal` down to `convertToMoney`.
- 2025-03-25: Iterative Enhancement - Extended the long-press temporary reveal function to major amount displays (`WalletEntry`, `TransactionsAmountBox`, and `BudgetContainer`). Each component was refactored into a `StatefulWidget` to maintain a local boolean `_isRevealed` tied to gesture detectors, which gets passed as the `forceReveal` flag to `convertToMoney` for dynamic de-obfuscation.
- 2026-03-23: Iterative Enhancement - Continued expanding the temporary reveal feature deep into the budget history and transaction selection UI. Converted `PastBudgetContainer`, `CategoryAverageSpent`, and `SelectedTransactionsAppBar` into `StatefulWidget`s. Added `Listener`s tracking `_isRevealed` on their respective interactive elements to pass the `forceReveal` flag down to their `convertToMoney` calls.
**Next Planned Step:** Expand this behavior to the top App Bar totals, search filters, and nested analytics screens where large aggregations of obfuscated numbers reside.

## 🚨 Critical Security Learnings
*Only add entries here for unique, repo-specific security gaps, unexpected side effects, or reusable patterns.*
- **2024-03-24 - Initial Scan:**
  - **Vulnerability/Gap:** Checked for standard client-side issues (SQLi, exposed secrets, insecure webviews). Codebase relies on `drift` ORM and safe HTTP practices.
  - **Learning:** The architecture safely separates raw API secrets (Firebase config files) which are intended for public client distribution, from backend administrative roles.
  - **Prevention:** Continue to use parameterized inputs via ORM (`drift`) and avoid dynamic `eval` or insecure `WebView` integrations.- **2024-05-30 - Android Build CI Flake / Gradle Inconsistent JVM Targets:**
  - **Vulnerability/Gap:** Older packages relying on Flutter v1 embedding (requiring Java 8) and newer packages (requiring Java 11/17) triggered unresolvable `Inconsistent JVM-target compatibility` errors in Gradle, failing builds across the CI platform.
  - **Learning:** Bypassing Gradle `Project.afterEvaluate` inside a `subprojects` block while explicitly upgrading old plugins (`in_app_purchase`, `quick_actions`, `path_provider`, etc.) to versions supporting Java 17 and AGP 8+ resolves the JVM constraints.
  - **Prevention:** Centralize global build compilation constraints in `build.gradle` using `tasks.withType(JavaCompile)` and force constraints for legacy libraries (like pinning older `androidx.core:core:1.13.1`) dynamically rather than manually tweaking `.pubspec.yaml` without constraint matching.
