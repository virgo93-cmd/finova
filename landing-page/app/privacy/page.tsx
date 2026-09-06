import Image from "next/image";
import Link from "next/link";

export const metadata = {
  title: "Privacy Policy — Finova",
  description: "How Finova stores local app data and uses third-party advertising services.",
};

export default function PrivacyPage() {
  return (
    <main className="legal-page">
      <nav className="legal-nav container">
        <Link className="brand" href="/">
          <span className="brand-mark"><Image src="/brand/finova-icon.png" alt="" width={40} height={40} /></span>
          <span>Finova</span>
        </Link>
      </nav>
      <div className="legal-content">
        <h1>Privacy Policy</h1>
        <p className="legal-updated">Effective September 2, 2026</p>
        <article>
          <h2>Overview</h2>
          <p>Finova is a personal finance and productivity app. Core information you enter—including transactions, categories, budgets, debts, goals, tasks, habits, and preferences—is stored locally on your device. An account is optional.</p>

          <h2>Data storage and deletion</h2>
          <p>Your records remain in the app&apos;s private device storage until you delete them, use the Reset all data feature, clear the app&apos;s storage, or uninstall Finova. These actions may permanently remove your information.</p>

          <h2>Google account and Drive backup</h2>
          <p>If you choose Google sign-in, Finova uses Supabase Auth to maintain your account identity and premium status. Finova requests the limited Google Drive app-data permission. Only when you press Backup does Finova upload a copy of your local records to its private application folder in your Google Drive. That folder is not shared with other Drive apps. You can replace the backup, restore it, or revoke Finova&apos;s Google access.</p>

          <h2>Premium payments</h2>
          <p>Premium checkout is provided by Lemon Squeezy. Finova sends your account identifier and pre-fills your email so a verified payment webhook can activate 30 days of ad-free access. Payment details are processed by Lemon Squeezy and are not stored inside the Finova app.</p>

          <h2>Advertising and consent</h2>
          <p>The free version of Finova uses the Google Mobile Ads SDK and mediation partners, including Meta Audience Network, to show banner, interstitial, and optional rewarded ads. Google, Meta, and their partners may process an advertising identifier, IP address, device information, ad interactions, diagnostics, approximate network-based location, and consent choices under their own policies. Finova uses Google&apos;s consent mechanism where required. Active Premium access disables all ads.</p>

          <h2>Notifications</h2>
          <p>If you enable reminders, Finova requests notification permission and schedules reminders locally on your device. You can disable them through Finova or Android system settings.</p>

          <h2>Security and children</h2>
          <p>Finova uses private storage provided by the Android platform, but no storage method is entirely risk-free. Finova is not specifically directed to children. The publisher is responsible for keeping audience and advertising configuration aligned with its intended users.</p>

          <h2>Changes and contact</h2>
          <p>This policy may be updated when the app changes. For privacy questions, contact <a href="mailto:support@finova.ailooma.biz.id">support@finova.ailooma.biz.id</a>.</p>
        </article>
      </div>
    </main>
  );
}
