import type { Metadata } from "next";

export const metadata: Metadata = {
  title: "Privacy Policy - MarshSight",
  description: "How MarshSight handles your location, camera, and contributions.",
};

export default function Privacy() {
  return (
    <main className="mx-auto max-w-3xl px-5 py-16 text-foreground">
      <h1 className="text-3xl font-bold tracking-tight">Privacy Policy</h1>
      <p className="mt-2 text-sm text-foreground/55">Last updated: June 2026</p>

      <div className="mt-8 space-y-8 leading-relaxed text-foreground/85">
        <p>
          MarshSight is built to respect your privacy and your spots. This policy
          explains what the app accesses and what, if anything, leaves your
          device.
        </p>

        <section>
          <h2 className="text-xl font-semibold">What the app uses</h2>
          <ul className="mt-3 list-disc space-y-2 pl-5">
            <li>
              <strong>Location (GPS and compass).</strong> Used on your device to
              place navigation markers, boundaries, and hazards in the
              augmented-reality view and to show your position on the map. Your
              location is not transmitted or stored on any server unless you
              choose to submit a contribution.
            </li>
            <li>
              <strong>Camera.</strong> Used only to display the live
              augmented-reality view. Camera frames are not recorded, saved, or
              transmitted.
            </li>
            <li>
              <strong>Motion sensors.</strong> Used on device to stabilize the AR
              overlay.
            </li>
          </ul>
        </section>

        <section>
          <h2 className="text-xl font-semibold">What you can choose to share</h2>
          <p className="mt-3">
            Contributions (waypoints, hazards, blinds, ramps, harvest and catch
            notes) are private by default and stay on your device. You can choose
            to share a spot with a group or publicly. Public and group
            contributions include the location and details you provide, so do not
            share locations you want to keep secret. If you join the waitlist on
            our website, we store your email only to notify you about the beta.
          </p>
        </section>

        <section>
          <h2 className="text-xl font-semibold">What we do not do</h2>
          <ul className="mt-3 list-disc space-y-2 pl-5">
            <li>No advertising or third-party ad tracking.</li>
            <li>No selling of personal data.</li>
            <li>
              No background location tracking. Location is used only while you are
              using the app for navigation.
            </li>
          </ul>
        </section>

        <section>
          <h2 className="text-xl font-semibold">Data sources</h2>
          <p className="mt-3">
            Map layers come from public-domain government sources (USGS, NOAA,
            PAD-US, USFS). The app uses no onX data.
          </p>
        </section>

        <section>
          <h2 className="text-xl font-semibold">Your control and contact</h2>
          <p className="mt-3">
            Delete the app to remove all local data, including private
            contributions stored on your device. To request deletion of public
            contributions or your waitlist email, contact{" "}
            <a className="text-moss-400 underline" href="mailto:stephenproctor291@gmail.com">
              stephenproctor291@gmail.com
            </a>
            .
          </p>
        </section>
      </div>
    </main>
  );
}
