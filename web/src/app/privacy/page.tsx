import type { Metadata } from "next";

export const metadata: Metadata = {
  title: "Privacy Policy - MarshSight",
  description: "How MarshSight handles your location, camera, photos, and contributions.",
};

export default function Privacy() {
  return (
    <main className="mx-auto max-w-3xl px-5 py-16 text-ink-800">
      <a
        href="/"
        className="text-sm font-medium text-pine-700 transition hover:text-pine-800"
      >
        ← Back to MarshSight
      </a>
      <h1 className="mt-6 font-serif text-4xl font-bold tracking-tight">
        Privacy Policy
      </h1>
      <p className="mt-2 text-sm text-ink-500">Last updated: June 2026</p>

      <div className="mt-8 space-y-8 leading-relaxed text-ink-600">
        <p>
          MarshSight is built to respect your privacy and your spots. Most of
          what the app does happens entirely on your device. This policy
          explains what stays local, what you can choose to share, and what we
          store when you do.
        </p>

        <section>
          <h2 className="font-serif text-xl font-semibold">What stays on your device</h2>
          <ul className="mt-3 list-disc space-y-2 pl-5">
            <li>
              <strong>Location (GPS and compass).</strong> Used to show your
              position, place navigation markers and boundaries, and drive the
              augmented-reality view. Your location is processed on your device
              and is not sent to us unless you choose to attach it to something
              you share (see below). There is no background location tracking.
            </li>
            <li>
              <strong>Live camera (AR).</strong> The augmented-reality view uses
              the camera only to draw an overlay on the live image. Those frames
              are never recorded, saved, or transmitted.
            </li>
            <li>
              <strong>Motion sensors.</strong> Used on device to stabilize the AR
              overlay.
            </li>
            <li>
              <strong>Private spots and your logbook.</strong> Waypoints, blinds,
              cameras, harvest and catch entries you keep private stay on your
              device and are not uploaded.
            </li>
          </ul>
        </section>

        <section>
          <h2 className="font-serif text-xl font-semibold">What you choose to share</h2>
          <p className="mt-3">
            Some features upload data to our servers, and only when you take an
            explicit action:
          </p>
          <ul className="mt-3 list-disc space-y-2 pl-5">
            <li>
              <strong>Public or group spots.</strong> When you set a spot to
              public or group, its location, name, and any note you write are
              uploaded so others can see and verify it. Location sharing is off
              by default. Do not share locations you want to keep secret.
            </li>
            <li>
              <strong>Community feed posts.</strong> When you share a harvest or
              catch to the feed, the photo and details you include are uploaded.
              Location is opt-in and off by default for feed posts.
            </li>
            <li>
              <strong>Trail-camera photos.</strong> If you use the trail-camera
              feature, photos you email to your private camera inbox address are
              received, stored, and shown back to you (and anyone you share your
              code with).
            </li>
            <li>
              <strong>Display name (optional).</strong> You may set a name to show
              on your posts. You are not required to provide a name, email, or
              account to use the app.
            </li>
            <li>
              <strong>Waitlist email.</strong> If you join the waitlist on this
              website, we store your email only to tell you about the beta.
            </li>
          </ul>
        </section>

        <section>
          <h2 className="font-serif text-xl font-semibold">Identity</h2>
          <p className="mt-3">
            MarshSight does not require an account. Shared content is tied to an
            anonymous identifier generated on your device, used to show you your
            own private spots across sessions and to let you remove your own
            content. It is not linked to your name or contact details unless you
            choose to add a display name.
          </p>
        </section>

        <section>
          <h2 className="font-serif text-xl font-semibold">Community content and moderation</h2>
          <p className="mt-3">
            The feed and public spots are user-generated. We have zero tolerance
            for objectionable content and abusive behavior. You can report any
            post or spot and block users from within the app. Reported content is
            reviewed and removed within 24 hours if it violates our guidelines,
            and repeat offenders are banned. A basic filter also blocks obvious
            objectionable language before it is posted.
          </p>
        </section>

        <section>
          <h2 className="font-serif text-xl font-semibold">Who processes this data</h2>
          <p className="mt-3">
            When you share, your data is stored and served using a small set of
            providers acting on our behalf: Supabase (database and photo
            storage), Vercel (hosting), and Cloudflare (routing trail-camera
            email). Purchases of MarshSight+ are handled by Apple; we never
            receive your payment details. Map imagery and layers come from
            public-domain government sources (USGS, NOAA, PAD-US, USFS) and
            Esri. The app uses no onX data.
          </p>
        </section>

        <section>
          <h2 className="font-serif text-xl font-semibold">What we never do</h2>
          <ul className="mt-3 list-disc space-y-2 pl-5">
            <li>No advertising or third-party ad tracking.</li>
            <li>No selling of personal data.</li>
            <li>No background location tracking.</li>
          </ul>
        </section>

        <section>
          <h2 className="font-serif text-xl font-semibold">Your control and data deletion</h2>
          <p className="mt-3">
            Deleting the app removes all local data, including your private spots
            and logbook. To delete content you have shared (public spots, feed
            posts, trail-camera photos) or your waitlist email, email{" "}
            <a className="text-pine-700 underline" href="mailto:stephenproctor291@gmail.com">
              stephenproctor291@gmail.com
            </a>{" "}
            from the address you used, or with your in-app display name, and we
            will remove it. We honor deletion requests within 30 days.
          </p>
        </section>

        <section>
          <h2 className="font-serif text-xl font-semibold">Children</h2>
          <p className="mt-3">
            MarshSight is intended for adult hunters and anglers and is not
            directed to children.
          </p>
        </section>

        <section>
          <h2 className="font-serif text-xl font-semibold">Contact</h2>
          <p className="mt-3">
            Questions about this policy? Email{" "}
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
