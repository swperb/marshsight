import type { Metadata } from "next";

export const metadata: Metadata = {
  title: "Terms of Use - MarshSight",
  description: "The agreement for using MarshSight, including community rules.",
};

export default function Terms() {
  return (
    <main className="mx-auto max-w-3xl px-5 py-16 text-ink-800">
      <a
        href="/"
        className="text-sm font-medium text-pine-700 transition hover:text-pine-800"
      >
        ← Back to MarshSight
      </a>
      <h1 className="mt-6 font-serif text-4xl font-bold tracking-tight">
        Terms of Use
      </h1>
      <p className="mt-2 text-sm text-ink-500">Last updated: June 2026</p>

      <div className="mt-8 space-y-8 leading-relaxed text-ink-600">
        <p>
          By downloading or using MarshSight, you agree to these terms. If you do
          not agree, do not use the app.
        </p>

        <section>
          <h2 className="font-serif text-xl font-semibold">Navigation aid, not an authority</h2>
          <p className="mt-3">
            MarshSight is a navigation and mapping aid built on public data. GPS,
            compass, boundaries, and chart data all have real error and can be
            out of date or wrong. You are responsible for verifying land access,
            boundaries, regulations, and hazards yourself, and for hunting and
            boating legally and safely. Do not rely on this app alone for safety.
            The app is provided &ldquo;as is,&rdquo; without warranties, and we
            are not liable for losses arising from your use of it.
          </p>
        </section>

        <section>
          <h2 className="font-serif text-xl font-semibold">Community rules</h2>
          <p className="mt-3">
            The feed and public spots are user-generated. There is{" "}
            <strong>zero tolerance for objectionable content or abusive users.</strong>{" "}
            By posting, you agree not to submit content that is unlawful,
            harassing, hateful, threatening, obscene, or that encourages
            trespassing, poaching, or illegal harvest. You are solely
            responsible for what you post.
          </p>
          <p className="mt-3">
            You can report content and block users in the app. We review reports
            and remove violating content within 24 hours, and we may suspend or
            ban users who break these rules. We may remove content at our
            discretion.
          </p>
        </section>

        <section>
          <h2 className="font-serif text-xl font-semibold">MarshSight+</h2>
          <p className="mt-3">
            The core app is free. MarshSight+ is an optional subscription or
            one-time purchase that unlocks additional features and supports the
            project. Purchases are processed by Apple and governed by the App
            Store terms. Subscriptions renew until cancelled; manage or cancel in
            your Apple account settings.
          </p>
        </section>

        <section>
          <h2 className="font-serif text-xl font-semibold">Your content</h2>
          <p className="mt-3">
            You keep ownership of what you post. By sharing content publicly, you
            grant us a license to host and display it within MarshSight so the
            community can see it. You can delete your shared content as described
            in our{" "}
            <a className="text-pine-700 underline" href="/privacy">Privacy Policy</a>.
          </p>
        </section>

        <section>
          <h2 className="font-serif text-xl font-semibold">Contact</h2>
          <p className="mt-3">
            Questions? Email{" "}
            <a className="text-pine-700 underline" href="mailto:stephenproctor291@gmail.com">
              stephenproctor291@gmail.com
            </a>
            .
          </p>
        </section>
      </div>
    </main>
  );
}
