import Image from "next/image";
import Link from "next/link";
import {
  ArrowDownToLine,
  ArrowRight,
  BarChart3,
  Check,
  CheckCircle2,
  ChevronRight,
  Coins,
  EyeOff,
  Globe2,
  LayoutDashboard,
  LockKeyhole,
  Menu,
  ShieldCheck,
  Sparkles,
  Target,
  WalletCards,
} from "lucide-react";

const downloadUrl = "/downloads/finova-android-v1.0.0.apk";

const currencies = ["IDR", "USD", "EUR", "GBP", "SGD", "MYR"];

export default function Home() {
  return (
    <main className="site-shell">
      <div className="hero-wrap" id="top">
        <div className="hero-orb hero-orb-one" />
        <div className="hero-orb hero-orb-two" />

        <nav className="nav container" aria-label="Main navigation">
          <Link className="brand" href="#top" aria-label="Finova home">
            <span className="brand-mark">
              <Image src="/brand/finova-icon.png" alt="" width={40} height={40} priority />
            </span>
            <span>Finova</span>
          </Link>

          <div className="nav-links">
            <Link href="#features">Features</Link>
            <Link href="#currencies">Currencies</Link>
            <Link href="#privacy">Privacy</Link>
          </div>

          <Link className="button button-small button-light" href={downloadUrl} download>
            Download APK
            <ArrowDownToLine size={16} />
          </Link>
          <button className="mobile-menu" type="button" aria-label="Open navigation menu">
            <Menu size={22} />
          </button>
        </nav>

        <section className="hero container">
          <div className="hero-copy">
            <div className="eyebrow">
              <span className="pulse-dot" />
              Android app · Direct download
            </div>
            <h1>
              Money clarity.
              <span> Everyday momentum.</span>
            </h1>
            <p className="hero-lead">
              Finova brings personal finance and daily productivity into one calm,
              private workspace—so you can understand your money and move your plans forward.
            </p>

            <div className="hero-actions">
              <Link className="button button-primary" href={downloadUrl} download>
                <ArrowDownToLine size={19} />
                Download for Android
              </Link>
              <Link className="button button-ghost" href="#features">
                Explore features
                <ArrowRight size={18} />
              </Link>
            </div>

            <div className="hero-trust">
              <span><CheckCircle2 size={17} /> No sign-up</span>
              <span><CheckCircle2 size={17} /> Local-first data</span>
              <span><CheckCircle2 size={17} /> Multi-currency</span>
            </div>
          </div>

          <div className="product-stage" aria-label="Finova app preview">
            <div className="stage-grid" />
            <div className="floating-card currency-float">
              <div className="floating-icon"><Globe2 size={20} /></div>
              <div>
                <span>Display currency</span>
                <strong>IDR · Rupiah</strong>
              </div>
              <ChevronRight size={18} />
            </div>

            <div className="phone-shell">
              <div className="phone-camera" />
              <div className="phone-screen">
                <div className="phone-topbar">
                  <div>
                    <small>Good morning</small>
                    <strong>Your overview</strong>
                  </div>
                  <span className="avatar">FH</span>
                </div>

                <div className="balance-card">
                  <div className="balance-label"><EyeOff size={14} /> Total balance</div>
                  <strong>Rp 12,480,000</strong>
                  <span><Sparkles size={13} /> 8.4% saved this month</span>
                </div>

                <div className="quick-stats">
                  <div><span>Income</span><strong>Rp 8.2M</strong></div>
                  <div><span>Expenses</span><strong>Rp 4.9M</strong></div>
                </div>

                <div className="phone-section-head">
                  <strong>Spending insight</strong>
                  <span>September</span>
                </div>
                <div className="mini-chart" aria-hidden="true">
                  {[45, 62, 50, 78, 58, 86, 72].map((height, index) => (
                    <i key={index} style={{ height: `${height}%` }} />
                  ))}
                </div>

                <div className="today-card">
                  <div className="today-head"><strong>Today</strong><span>3 of 5 done</span></div>
                  <div><Check size={14} /> Review weekly budget</div>
                  <div><Check size={14} /> Complete morning focus</div>
                </div>
              </div>
            </div>

            <div className="floating-card goal-float">
              <div className="goal-ring">72%</div>
              <div><span>Savings goal</span><strong>On track</strong></div>
            </div>
          </div>
        </section>
      </div>

      <section className="signal-strip">
        <div className="container signal-grid">
          <div><strong>One app</strong><span>Money and productivity together</span></div>
          <div><strong>6 currencies</strong><span>Choose the format that fits you</span></div>
          <div><strong>0 accounts</strong><span>Start without creating a profile</span></div>
        </div>
      </section>

      <section className="section container" id="features">
        <div className="section-heading">
          <div>
            <span className="section-kicker">Designed for real life</span>
            <h2>Everything important,<br />without the clutter.</h2>
          </div>
          <p>
            A focused toolkit for the numbers you need to understand and the actions
            you want to complete.
          </p>
        </div>

        <div className="bento-grid">
          <article className="bento-card bento-large bento-dark">
            <div className="bento-icon"><WalletCards size={24} /></div>
            <span>Personal finance</span>
            <h3>See where your money goes.</h3>
            <p>Record income and expenses, organize categories, and monitor your balance at a glance.</p>
            <div className="transaction-demo">
              <div><span className="transaction-icon">☕</span><div><strong>Coffee</strong><small>Food & drink</small></div><b>− Rp 28K</b></div>
              <div><span className="transaction-icon">↗</span><div><strong>Monthly income</strong><small>Income</small></div><b className="positive">+ Rp 8.2M</b></div>
            </div>
          </article>

          <article className="bento-card bento-mint">
            <div className="bento-icon"><Globe2 size={24} /></div>
            <span>Multi-currency</span>
            <h3>Your currency, your view.</h3>
            <p>Select a display currency that matches the way you manage money.</p>
            <div className="currency-stack">
              {currencies.slice(0, 4).map((currency, index) => (
                <span key={currency} className={index === 0 ? "active" : ""}>{currency}</span>
              ))}
            </div>
          </article>

          <article className="bento-card">
            <div className="bento-icon"><Target size={24} /></div>
            <span>Daily productivity</span>
            <h3>Turn intention into progress.</h3>
            <p>Keep tasks, habits, and daily priorities close to your financial goals.</p>
            <div className="progress-demo"><i /><span>Weekly focus</span><strong>78%</strong></div>
          </article>

          <article className="bento-card">
            <div className="bento-icon"><BarChart3 size={24} /></div>
            <span>Clear insights</span>
            <h3>Patterns you can act on.</h3>
            <p>Simple summaries help you spot spending trends and make better next decisions.</p>
            <div className="sparkline"><i/><i/><i/><i/><i/><i/></div>
          </article>

          <article className="bento-card bento-wide">
            <div className="bento-icon"><LayoutDashboard size={24} /></div>
            <div>
              <span>A calmer system</span>
              <h3>Built to help you check in, not get stuck configuring.</h3>
            </div>
            <p>Finova keeps finance and focus in one lightweight Android experience.</p>
          </article>
        </div>
      </section>

      <section className="currency-section" id="currencies">
        <div className="container currency-layout">
          <div className="currency-copy">
            <span className="section-kicker light">Multi-currency selection</span>
            <h2>Make every number feel familiar.</h2>
            <p>
              Choose the currency used to format balances and transactions across Finova.
              Switch it anytime from settings—no new account or setup required.
            </p>
            <div className="currency-note">
              <Coins size={20} />
              <span>Currency selection controls display formatting; it does not convert exchange rates.</span>
            </div>
          </div>

          <div className="currency-picker-card">
            <div className="picker-header"><span>Select currency</span><small>Settings</small></div>
            {[
              ["IDR", "Indonesian Rupiah", "Rp"],
              ["USD", "US Dollar", "$"],
              ["EUR", "Euro", "€"],
              ["GBP", "British Pound", "£"],
              ["SGD", "Singapore Dollar", "S$"],
              ["MYR", "Malaysian Ringgit", "RM"],
            ].map(([code, name, symbol], index) => (
              <div className={`currency-row ${index === 0 ? "selected" : ""}`} key={code}>
                <span className="currency-symbol">{symbol}</span>
                <div><strong>{code}</strong><small>{name}</small></div>
                {index === 0 && <CheckCircle2 size={19} />}
              </div>
            ))}
          </div>
        </div>
      </section>

      <section className="privacy-section container" id="privacy">
        <div className="privacy-card">
          <div className="privacy-visual">
            <div className="shield-ring"><ShieldCheck size={50} /></div>
            <div className="privacy-chip chip-one"><LockKeyhole size={15} /> Local-first</div>
            <div className="privacy-chip chip-two"><EyeOff size={15} /> No sign-up</div>
          </div>
          <div className="privacy-copy">
            <span className="section-kicker">Privacy by design</span>
            <h2>Your personal records stay personal.</h2>
            <p>
              Finova is designed to work without an account. Your financial entries and
              productivity data are stored on your device, while ads use Google AdMob.
            </p>
            <Link href="/privacy">Read our Privacy Policy <ArrowRight size={17} /></Link>
          </div>
        </div>
      </section>

      <section className="download-section container" id="download">
        <div className="download-card">
          <div className="download-glow" />
          <div className="download-brand">
            <Image src="/brand/finova-icon.png" alt="Finova app icon" width={76} height={76} />
          </div>
          <span className="section-kicker light">Available now for Android</span>
          <h2>A clearer day starts<br />with one small check-in.</h2>
          <p>Download the official Finova APK directly and install it on your Android device.</p>
          <Link className="button button-white" href={downloadUrl} download>
            <ArrowDownToLine size={20} />
            Download Finova APK
          </Link>
          <small>Version 1.0.0 · Android only · 62 MB</small>
        </div>
      </section>

      <footer className="footer container">
        <div className="footer-brand">
          <Image src="/brand/finova-icon.png" alt="" width={34} height={34} />
          <span>Finova</span>
        </div>
        <p>Money clarity. Everyday momentum.</p>
        <div className="footer-links">
          <Link href="/privacy">Privacy</Link>
          <Link href="/terms">Terms</Link>
          <Link href="/app-ads.txt">app-ads.txt</Link>
        </div>
        <small>© 2026 Finova. All rights reserved.</small>
      </footer>
    </main>
  );
}
