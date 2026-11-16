import { SiteHeader } from "@/components/site-header";
import { Hero } from "@/components/hero";
import { Characters } from "@/components/characters";
import { Features } from "@/components/features";
import { Gallery } from "@/components/gallery";
import { Playtest } from "@/components/playtest";
import { SiteFooter } from "@/components/site-footer";

export default function Home() {
  return (
    <>
      <a
        href="#main"
        className="sr-only focus:not-sr-only focus:fixed focus:left-4 focus:top-4 focus:z-50 focus:rounded-lg focus:bg-accent focus:px-4 focus:py-2 focus:font-semibold focus:text-accent-foreground"
      >
        Skip to content
      </a>
      <SiteHeader />
      <main id="main">
        <Hero />
        <Characters />
        <Features />
        <Gallery />
        <Playtest />
      </main>
      <SiteFooter />
    </>
  );
}
