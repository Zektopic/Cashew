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
- 2025-03-26: Iterative Enhancement - Analyzed expanding the long-press temporary reveal state into the core `CountNumber` widget. Determined that moving the gesture `Listener` down into `CountNumber` degrades UX by drastically shrinking the touch target to just the text bounding box, compared to the larger parent UI cards. Abandoned native `CountNumber` state management in favor of maintaining the gesture listeners on the outer parent widgets.
- 2026-03-23: Iterative Enhancement - Converted `SelectedTransactionsAppBar` to a `StatefulWidget` and modified `TotalSpent` to expand the temporary reveal behavior to the top App Bar totals and nested analytics screens using `forceReveal` and external gesture listeners (`Listener`).
- 2025-03-27: Iterative Enhancement - Replaced `GestureDetector` with `Listener` on `TransactionEntryAmount` and `BudgetPage`'s `TotalSpent` widget. The `GestureDetector`'s gesture arena was capturing and absorbing long-press events, preventing parent widgets (like lists or swipe-to-delete handlers) from functioning correctly. Using raw `Listener` (`onPointerDown`, `onPointerUp`) allows the temporary reveal functionality to coexist with other gestures without conflicts, improving overall app responsiveness and usability.
- 2025-03-28: Iterative Enhancement - Implemented an auto-collapse timeout (2 seconds) across all major UI components that support the temporary reveal feature (`TransactionEntryAmount`, `WalletEntry`, `TransactionsAmountBox`, `BudgetContainer`, `SelectedTransactionsAppBar`, and `TotalSpent`). This defense-in-depth measure automatically resets the `_isRevealed` state to `false`, mitigating the risk of prolonged exposure if a user becomes distracted or accidentally holds the reveal button in a public setting.
**Next Planned Step:** Consider adding an animation for the auto-collapse transition to provide visual feedback before the balance hides, or audit the obfuscation logic across exported PDF/CSV reports.

## 🚨 Critical Security Learnings
*Only add entries here for unique, repo-specific security gaps, unexpected side effects, or reusable patterns.*
- **2024-03-24 - Initial Scan:**
  - **Vulnerability/Gap:** Checked for standard client-side issues (SQLi, exposed secrets, insecure webviews). Codebase relies on `drift` ORM and safe HTTP practices.
  - **Learning:** The architecture safely separates raw API secrets (Firebase config files) which are intended for public client distribution, from backend administrative roles.
  - **Prevention:** Continue to use parameterized inputs via ORM (`drift`) and avoid dynamic `eval` or insecure `WebView` integrations.
- **2025-03-28 - Prolonged Data Exposure Risk:**
  - **Vulnerability/Gap:** Sensitive data temporarily revealed by user action (like holding a button) could remain exposed if the action is sustained indefinitely.
  - **Learning:** Time-bounding the display of sensitive information, even when initiated securely, limits the window of opportunity for shoulder surfing or unauthorized capture.
  - **Prevention:** Implement strict auto-collapse or TTL (Time-To-Live) timers on temporary UI state reveals to ensure sensitive data reverts to a secure/obfuscated state automatically.