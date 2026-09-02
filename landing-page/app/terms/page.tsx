import Image from "next/image";
import Link from "next/link";

export const metadata = {
  title: "Terms of Use — Finova",
  description: "Terms governing use of the Finova Android app.",
};

export default function TermsPage() {
  return (
    <main className="legal-page">
      <nav className="legal-nav container">
        <Link className="brand" href="/">
          <span className="brand-mark"><Image src="/brand/finova-icon.png" alt="" width={40} height={40} /></span>
          <span>Finova</span>
        </Link>
      </nav>
      <div className="legal-content">
        <h1>Terms of Use</h1>
        <p className="legal-updated">Effective September 2, 2026</p>
        <article>
          <h2>Purpose of the app</h2>
          <p>Finova provides tools for personal finance tracking, budgets, tasks, habits, and informational summaries. Finova is not a bank, accounting service, financial adviser, investment adviser, tax adviser, medical provider, or emergency service.</p>

          <h2>No professional advice</h2>
          <p>Calculations and insights depend on the information you enter and may contain errors or omissions. Do not use Finova as the sole basis for financial, legal, tax, medical, or other important decisions.</p>

          <h2>Your responsibilities</h2>
          <p>You are responsible for the accuracy of your data, the security of your device, any backups you need, and lawful use of the app. You must not manipulate advertisements, interfere with app operation, or use Finova to violate the rights of others.</p>

          <h2>Local data and availability</h2>
          <p>Data may be lost if the app is reset, storage is cleared, Finova is uninstalled, the device is lost, or a failure occurs. Features may change or be discontinued. We do not guarantee uninterrupted or error-free operation.</p>

          <h2>Advertising and third-party services</h2>
          <p>The free version may show banner ads, interstitial ads, and user-initiated rewarded ads through Google. Core tracking features remain available without watching rewarded ads. Third-party services are governed by their own terms and policies.</p>

          <h2>Disclaimer and limitation of liability</h2>
          <p>To the extent permitted by law, Finova is provided “as is” and “as available.” Consumer rights that cannot lawfully be excluded remain unaffected. Finova is not liable for indirect loss, lost data, lost profits, or decisions made using the app to the extent permitted by law.</p>

          <h2>Contact</h2>
          <p>Questions about these terms may be sent to <a href="mailto:support@finova.ailooma.biz.id">support@finova.ailooma.biz.id</a>.</p>
        </article>
      </div>
    </main>
  );
}
