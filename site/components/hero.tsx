import Image from "next/image";
import harborReveal from "@/public/images/harbor-reveal.png";
import { siteConfig } from "@/site.config";
import { ArtLabel } from "@/components/art-label";

export function Hero() {
  return (
    <section aria-labelledby="hero-title" className="relative">
      <div className="relative h-[62vh] min-h-80 max-h-[760px] w-full overflow-hidden md:h-[78vh]">
        <Image
          src={harborReveal}
          alt="Concept art: Mira, a young courier in a red cape, stands on a lantern-lit boardwalk with Pip the glowing moth, looking out over sunken stone ruins risen from the tide toward a lighthouse beneath a cracked moon."
          fill
          priority
          placeholder="blur"
          sizes="100vw"
          className="object-cover object-[30%_center] md:object-center"
        />
        <div
          aria-hidden="true"
          className="absolute inset-x-0 bottom-0 h-1/3 bg-gradient-to-t from-background to-transparent"
        />
        <ArtLabel className="absolute bottom-4 right-4">Concept art</ArtLabel>
      </div>

      <div className="mx-auto flex max-w-6xl flex-col gap-6 px-5 pb-16 pt-8 md:pb-24">
        <p className="rise-in font-semibold uppercase tracking-[0.2em] text-accent text-sm">
          A JRPG prototype in Godot
        </p>
        <h1
          id="hero-title"
          className="rise-in font-serif text-5xl font-bold leading-tight text-balance md:text-7xl"
          style={{ animationDelay: "80ms" }}
        >
          The Second Sky
        </h1>
        <p
          className="rise-in max-w-2xl text-lg leading-relaxed text-pretty text-muted-foreground md:text-xl"
          style={{ animationDelay: "160ms" }}
        >
          When an artificial moon cracks, a lost waterfront rises from beneath
          the tide. Follow Mira, a harbor courier, as a distress call draws her
          party to a lighthouse that has been dark for decades.
        </p>
        <div
          className="rise-in flex flex-col gap-3 sm:flex-row"
          style={{ animationDelay: "240ms" }}
        >
          <a
            href="#playtest"
            className="inline-flex items-center justify-center rounded-lg bg-accent px-6 py-3 text-base font-semibold text-accent-foreground transition-opacity hover:opacity-90"
          >
            Try the prototype
          </a>
          <a
            href={siteConfig.repoUrl}
            className="inline-flex items-center justify-center rounded-lg border border-border px-6 py-3 text-base font-semibold transition-colors hover:bg-surface"
          >
            View on GitHub
          </a>
        </div>
      </div>
    </section>
  );
}
