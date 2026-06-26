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
          <li>Open it and accept the safety notice. That&apos;s it.</li>
        </ol>

        <div className="rounded-xl border border-line bg-paper-50 p-4 text-sm">
          <p className="font-medium text-ink-800">Won&apos;t install?</p>
          <p className="mt-1 text-ink-600">
            Your device probably isn&apos;t on the tester list yet. Send your
            iPhone&apos;s <strong>UDID</strong> to whoever invited you and they&apos;ll add it.
            (Get your UDID at <span className="text-pine-700">get.udid.io</span> in Safari.)
          </p>
        </div>

        <p className="text-xs text-ink-400">
          Requires an iPhone, iOS, and Safari. This is a navigation aid, not a
          survey instrument - always carry a backup and check local regulations.
        </p>
      </div>
    </main>
  );
}
