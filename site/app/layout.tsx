import type { Metadata, Viewport } from "next";
import { Cinzel, Source_Sans_3 } from "next/font/google";
import { siteConfig } from "@/site.config";
import "./globals.css";

const display = Cinzel({
  variable: "--font-display",
  subsets: ["latin"],
  weight: ["600", "700"],
});

const body = Source_Sans_3({
  variable: "--font-body",
  subsets: ["latin"],
});

const description =
  "When an artificial moon cracks, a lost waterfront rises from beneath the tide. A JRPG prototype built in Godot. Download the source and playtest the harbor slice.";

export const metadata: Metadata = {
  metadataBase: new URL(siteConfig.siteUrl),
  title: "The Second Sky — A JRPG prototype",
  description,
  openGraph: {
    title: "The Second Sky",
    description,
    url: "/",
    siteName: "The Second Sky",
    type: "website",
    images: [
      {
        url: "/images/harbor-reveal.png",
        width: 1672,
        height: 941,
        alt: "Concept art: Mira looks out from a lantern-lit boardwalk over sunken ruins risen from the tide, toward a lighthouse.",
      },
    ],
  },
  twitter: {
    card: "summary_large_image",
    title: "The Second Sky",
    description,
    images: ["/images/harbor-reveal.png"],
  },
};

export const viewport: Viewport = {
  themeColor: "#0a2228",
  colorScheme: "dark",
};

export default function RootLayout({ children }: LayoutProps<"/">) {
  return (
    <html
      lang="en"
      className={`${display.variable} ${body.variable} bg-background antialiased`}
    >
      <body className="min-h-dvh bg-background font-sans text-foreground">
        {children}
      </body>
    </html>
  );
}
