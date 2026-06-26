import type { Metadata } from "next";
import { Inter, Fraunces } from "next/font/google";
import "./globals.css";

const inter = Inter({
  variable: "--font-inter",
  subsets: ["latin"],
  weight: ["400", "500", "600"],
});

const fraunces = Fraunces({
  variable: "--font-fraunces",
  subsets: ["latin"],
  weight: ["400", "500", "600"],
  style: ["normal", "italic"],
});

const SITE_TITLE =
  "MarshSight: Free, open-source AR navigation for hunters and anglers";
const SITE_DESCRIPTION =
  "MarshSight overlays public-land boundaries, river channels, live water levels, and hazards onto your live camera view. Free and open source, built on public government data.";

export const metadata: Metadata = {
  metadataBase: new URL("https://marshsight.com"),
  title: SITE_TITLE,
  description: SITE_DESCRIPTION,
  applicationName: "MarshSight",
  openGraph: {
    type: "website",
    url: "https://marshsight.com",
    siteName: "MarshSight",
    title: SITE_TITLE,
    description: SITE_DESCRIPTION,
  },
  twitter: {
    card: "summary_large_image",
    title: SITE_TITLE,
    description: SITE_DESCRIPTION,
  },
};

export default function RootLayout({
  children,
}: Readonly<{
  children: React.ReactNode;
}>) {
  return (
    <html
      lang="en"
      className={`${inter.variable} ${fraunces.variable} h-full antialiased`}
    >
      <body className="min-h-full flex flex-col">{children}</body>
    </html>
  );
}
