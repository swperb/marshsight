import type { Metadata } from "next";
import { Geist, Geist_Mono } from "next/font/google";
import "./globals.css";

const geistSans = Geist({
  variable: "--font-geist-sans",
  subsets: ["latin"],
});

const geistMono = Geist_Mono({
  variable: "--font-geist-mono",
  subsets: ["latin"],
});

const SITE_TITLE =
  "MarshSight: Free, open-source AR navigation for hunters and anglers";
const SITE_DESCRIPTION =
  "MarshSight overlays public-land boundaries, river channels, live water levels, and hazards onto your live camera view. Free and open source.";

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
      className={`${geistSans.variable} ${geistMono.variable} h-full antialiased`}
    >
      <body className="min-h-full flex flex-col">{children}</body>
    </html>
  );
}
