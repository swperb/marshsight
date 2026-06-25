"use client";

import { useState } from "react";

const API_URL =
  process.env.NEXT_PUBLIC_API_URL || "http://localhost:8088";

const EMAIL_RE = /^[^\s@]+@[^\s@]+\.[^\s@]+$/;

type Status = "idle" | "submitting" | "success" | "error";

export default function WaitlistForm() {
  const [email, setEmail] = useState("");
  const [status, setStatus] = useState<Status>("idle");
  const [message, setMessage] = useState("");

  async function handleSubmit(e: React.FormEvent) {
    e.preventDefault();

    const value = email.trim();
    if (!EMAIL_RE.test(value)) {
      setStatus("error");
      setMessage("Please enter a valid email address.");
      return;
    }

    setStatus("submitting");
    setMessage("");

    try {
      const res = await fetch(`${API_URL}/v1/waitlist`, {
        method: "POST",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify({ email: value }),
      });

      if (res.ok) {
        setStatus("success");
        setMessage("");
        setEmail("");
      } else {
        setStatus("error");
        setMessage(
          "Something went wrong on our end. Please try again in a moment."
        );
      }
    } catch {
      setStatus("error");
      setMessage(
        "We could not reach the server. Check your connection and try again."
      );
    }
  }

  if (status === "success") {
    return (
      <div className="rounded-2xl border border-moss-500/40 bg-marsh-800/60 p-6 text-center">
        <p className="text-lg font-semibold text-moss-400">
          You are on the list.
        </p>
        <p className="mt-2 text-sm text-foreground/70">
          Thanks for signing up. We will email you when the beta opens. No spam,
          ever.
        </p>
      </div>
    );
  }

  return (
    <form
      onSubmit={handleSubmit}
      noValidate
      className="flex flex-col gap-3 sm:flex-row"
    >
      <label htmlFor="waitlist-email" className="sr-only">
        Email address
      </label>
      <input
        id="waitlist-email"
        type="email"
        inputMode="email"
        autoComplete="email"
        placeholder="you@example.com"
        value={email}
        onChange={(e) => {
          setEmail(e.target.value);
          if (status === "error") setStatus("idle");
        }}
        disabled={status === "submitting"}
        aria-invalid={status === "error"}
        className="w-full flex-1 rounded-xl border border-marsh-700 bg-marsh-950/60 px-4 py-3 text-base text-foreground placeholder:text-foreground/40 outline-none transition focus:border-moss-500 focus:ring-2 focus:ring-moss-500/30 disabled:opacity-60"
      />
      <button
        type="submit"
        disabled={status === "submitting"}
        className="rounded-xl bg-moss-500 px-6 py-3 text-base font-semibold text-marsh-950 transition hover:bg-moss-400 disabled:cursor-not-allowed disabled:opacity-60"
      >
        {status === "submitting" ? "Joining..." : "Join the waitlist"}
      </button>
      {status === "error" && (
        <p
          role="alert"
          className="order-last w-full text-sm text-red-400 sm:order-none sm:basis-full"
        >
          {message}
        </p>
      )}
    </form>
  );
}
