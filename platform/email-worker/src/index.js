import PostalMime from "postal-mime";

// Cloudflare Email Worker for the MarshSight trail-camera inbox.
// Mail to cam-<code>@marshsight.com → grab the photo → upload to the Supabase
// Storage bucket → ping the API so it lands on the user's map. Any other address
// is forwarded to FORWARD_TO so your normal @marshsight.com mail still works.
export default {
  async email(message, env, ctx) {
    const to = (message.to || "").toLowerCase();
    const m = to.match(/cam-([a-z0-9]+)@/);

    // Not a camera address: forward to your real inbox (if configured).
    if (!m) {
      if (env.FORWARD_TO) { try { await message.forward(env.FORWARD_TO); } catch {} }
      return;
    }
    const camCode = m[1];

    const email = await new PostalMime().parse(message.raw);
    const photo = (email.attachments || []).find(
      (a) => (a.mimeType || "").startsWith("image/")
    );
    if (!photo) return; // nothing to ingest

    const ext = (photo.mimeType.split("/")[1] || "jpg").replace("jpeg", "jpg");
    const path = `cameras/${camCode}-${Date.now()}.${ext}`;

    // Upload to the public Supabase Storage bucket.
    const up = await fetch(`${env.SUPABASE_URL}/storage/v1/object/${env.BUCKET}/${path}`, {
      method: "POST",
      headers: {
        Authorization: `Bearer ${env.SUPABASE_SERVICE_KEY}`,
        apikey: env.SUPABASE_SERVICE_KEY,
        "Content-Type": photo.mimeType,
        "x-upsert": "true",
      },
      body: photo.content, // ArrayBuffer
    });
    if (!up.ok) { console.log("storage upload failed", up.status, await up.text()); return; }

    const photoUrl = `${env.SUPABASE_URL}/storage/v1/object/public/${env.BUCKET}/${path}`;

    // Tell the API to record the photo for this camera.
    await fetch(`${env.API_BASE}/v1/inbound/camera`, {
      method: "POST",
      headers: { "Content-Type": "application/json" },
      body: JSON.stringify({
        to,
        photoUrl,
        cameraName: email.subject || undefined,
        takenAt: email.date || undefined,
      }),
    });
  },
};
