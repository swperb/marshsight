import type { Metadata } from "next";

export const metadata: Metadata = {
  title: "Install MarshSight (Beta)",
  description: "Install the MarshSight beta on your iPhone.",
  robots: { index: false, follow: false },
};

// OTA install manifest (hosted on Supabase storage). iOS reads this via the
// itms-services scheme; the link only works in Safari on an iPhone whose UDID
// is registered on the ad-hoc provisioning profile.
const MANIFEST =
  "https://gxafxkcvyjozmbsqimtb.supabase.co/storage/v1/object/public/media/app/manifest.plist";
const INSTALL_URL = `itms-services://?action=download-manifest&url=${encodeURIComponent(MANIFEST)}`;

export default function Install() {
  return (
    <main className="mx-auto max-w-xl px-5 py-16 text-ink-800">
      <a href="/" className="text-sm font-medium text-pine-700 transition hover:text-pine-800">
        ← MarshSight
      </a>
      <h1 className="mt-6 font-serif text-4xl font-bold tracking-tight">
        Install MarshSight
      </h1>
      <p className="mt-2 text-sm text-ink-500">Beta build for invited testers</p>

      <div className="mt-8 space-y-6 leading-relaxed text-ink-600">
        <p>
          This installs the MarshSight beta directly on your iPhone - no App Store
          needed. It works only on devices that have been added to the tester
          list.
        </p>

        <a
          href={INSTALL_URL}
          className="block rounded-2xl bg-pine-700 px-6 py-4 text-center text-lg font-semibold text-paper-50 transition hover:bg-pine-800"
        >
          Tap to Install
        </a>

        <ol className="list-decimal space-y-3 pl-5 text-sm">
          <li>
            <strong>Open this page in Safari on your iPhone.</strong> The button
            won&apos;t work in Chrome or an in-app browser.
          </li>
          <li>Tap <strong>Tap to Install</strong>, then tap <strong>Install</strong> when iOS asks.</li>
          <li>Go to your home screen and wait for <strong>MarshSight</strong> to finish downloading.</li>
          <li>
            The first time you open it, iOS may say <strong>&ldquo;Developer Mode
            Required.&rdquo;</strong>{" "}That&apos;s normal for a beta - turn it on
            once (steps below), then open MarshSight again.
          </li>
        </ol>

        <div className="rounded-xl border border-pine-700/30 bg-pine-700/5 p-4 text-sm">
          <p className="font-semibold text-ink-800">If you see &ldquo;Developer Mode Required&rdquo;</p>
          <p className="mt-1 text-ink-600">A one-time setup on this phone:</p>
          <ol className="mt-2 list-decimal space-y-1.5 pl-5 text-ink-700">
            <li>Open <strong>Settings → Privacy &amp; Security</strong></li>
            <li>Scroll to the bottom and tap <strong>Developer Mode</strong></li>
            <li>Turn <strong>Developer Mode ON</strong>, then tap <strong>Restart</strong></li>
            <li>After it reboots and you unlock it, tap <strong>Turn On</strong> and enter your passcode</li>
            <li>Open <strong>MarshSight</strong> - it&apos;ll run now</li>
          </ol>
        </div>

        <div className="rounded-xl border border-line bg-paper-50 p-4 text-sm">
          <p className="font-medium text-ink-800">&ldquo;Integrity could not be verified&rdquo; / won&apos;t install?</p>
          <p className="mt-1 text-ink-600">
            Your device isn&apos;t on the tester list yet. Get your iPhone&apos;s{" "}
            <strong>UDID</strong> at <span className="text-pine-700">get.udid.io</span>{" "}
            in Safari, send it to whoever invited you, and reopen this page once they&apos;ve added it.
          </p>
        </div>

        <div className="space-y-2 border-t border-line pt-5 text-xs text-ink-400">
          <p className="font-medium text-ink-500">Before you rely on it:</p>
          <ul className="list-disc space-y-1.5 pl-5">
            <li>
              This is an <strong>early beta for invited testers</strong> - expect
              rough edges, and things may change or break between updates.
            </li>
            <li>
              MarshSight is a <strong>navigation aid, not a survey instrument or an
              authority.</strong> GPS, compass, and boundary data have real error
              and can be out of date. Always verify land access, boundaries,
              regulations, and hazards yourself, carry a backup, and use your own
              judgment on the water.
            </li>
            <li>
              It installs only on phones added to the tester list, and this beta
              build expires after about a year.
            </li>
            <li>
              When MarshSight launches on the App Store, install it there instead -
              no Developer Mode, no tester list, automatic updates.
            </li>
          </ul>
        </div>
      </div>
    </main>
  );
}
