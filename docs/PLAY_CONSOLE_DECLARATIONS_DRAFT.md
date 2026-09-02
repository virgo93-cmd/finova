# Google Play Console Declarations Draft

Review every answer against the final release and current Google Play definitions before submitting.

## App access

- All functionality is available without login or special access.

## Ads

- Yes, the app contains ads.
- Provider: Google Mobile Ads SDK.
- Rewarded ads are optional and unlock an extra insight; core tracking is never gated behind ads.

## Intended audience

- Recommended target audience: adults/general audience, not designed for children.
- Do not select child age groups unless the product, content, SDK configuration, and advertising treatment are redesigned for that audience.

## Data safety — current implementation

Core transactions, budgets, tasks, habits, and preferences are stored locally and are not sent to a Finova-operated server. However, the Google Mobile Ads SDK may collect or share device identifiers, app interactions, diagnostics, approximate location, and advertising data. The exact declaration must match the AdMob SDK version, consent configuration, selected ad modes, and Google's current Data Safety disclosure documentation at submission time.

Suggested review points:

- Data encrypted in transit: verify Google SDK behavior and answer per Play guidance.
- Data deletion request: core data is deleted locally through **Reset all data** or uninstall; no Finova account exists.
- Advertising or marketing purpose: applicable to Mobile Ads data.
- Analytics, fraud prevention, security, and compliance purposes: verify against Google's current SDK disclosure.
- Optional local notification permission does not by itself transmit reminder content.

## Financial features declaration

- Finova is a personal budget and expense-recording utility.
- It does not provide banking, lending, money transfer, investment execution, cryptocurrency trading, tax filing, or financial advice.

## Content rating

- No violence, sexual content, gambling, controlled substances, or user-generated social content is built into the app.
- Advertisements must be configured with an appropriate maximum content rating in AdMob.

## Permissions

- `INTERNET`: required for Google Mobile Ads.
- `POST_NOTIFICATIONS`: requested only when the user enables reminders.
- `RECEIVE_BOOT_COMPLETED`: allows scheduled local reminders to survive device restart through the notifications plugin.
