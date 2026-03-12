# Sentinel Evolution Ledger 🛡️

## 📈 Feature Iteration Track
**Currently Improving:** Privacy Obfuscation (Hide Balances)
**Growth Context:** As the app scales and users carry their devices into more public spaces, they need a way to protect sensitive financial data from shoulder surfers. Competitors often offer a "Privacy Mode" or "Hide Balances" toggle.
**Iteration History:**
- 2024-03-24: Implementing initial base: added `obscureAmounts` setting and tied it to the `convertToMoney` core formatting function so that global balances and amounts display as "•••". Added a basic toggle in the settings.
**Next Planned Step:** Add a quick-toggle button (an "eye" icon) on the main dashboard for easier access without navigating to the settings menu.

## 🚨 Critical Security Learnings
*Only add entries here for unique, repo-specific security gaps, unexpected side effects, or reusable patterns.*
- **2024-03-24 - Initial Scan:**
  - **Vulnerability/Gap:** Checked for standard client-side issues (SQLi, exposed secrets, insecure webviews). Codebase relies on `drift` ORM and safe HTTP practices.
  - **Learning:** The architecture safely separates raw API secrets (Firebase config files) which are intended for public client distribution, from backend administrative roles.
  - **Prevention:** Continue to use parameterized inputs via ORM (`drift`) and avoid dynamic `eval` or insecure `WebView` integrations.