import Image, { type StaticImageData } from "next/image";
import harborReveal from "@/public/images/harbor-reveal.png";
import seawallFight from "@/public/images/seawall-fight.png";
import harborFutures from "@/public/images/harbor-futures.webp";
import { siteConfig } from "@/site.config";
import { ArtLabel } from "@/components/art-label";
import { SectionHeading } from "@/components/section-heading";

interface ConceptPiece {
  title: string;
  label: "Concept art" | "Concept mockup";
  image?: StaticImageData;
  alt: string;
  caption: string;
}

const conceptPieces: ConceptPiece[] = [
  {
    title: "The harbor reveal",
    label: "Concept art",
    image: harborReveal,
    alt: "Concept art: at night, Mira and Pip watch from a lantern-strung boardwalk as stone arches and flooded streets rise out of glowing teal water, with a lighthouse beam crossing the sky.",
    caption: "The tide pulls back and a second shore appears.",
  },
  {
    title: "The seawall fight",
    label: "Concept mockup",
    image: seawallFight,
    alt: "Concept mockup of the battle screen: Mira, Tovan, Nell, and Pip face a crab-legged steam pump on the seawall. A turn-order bar runs along the top, a callout warns Surge in 2 turns, and a command menu lists Attack, Skill, Pair, and Guard beside party HP.",
    caption: "Turn order across the top, with Surge called out before it lands.",
  },
  {
    title: "Two futures for the harbor",
    label: "Concept art",
    image: harborFutures,
    alt: "Concept art comparing two daytime views of the same cliffside village: on the left the lighthouse is lit and a steamboat is docked; on the right the lighthouse is under scaffolding and market stalls fill the pier.",
    caption: "One possible harbor, restored or rebuilding.",
  },
];

export function Gallery() {
  const screenshots = siteConfig.gameplayScreenshots;

  return (
    <section
      id="gallery"
      aria-labelledby="gallery-title"
      className="border-t border-border bg-surface"
    >
      <div className="mx-auto flex max-w-6xl flex-col gap-10 px-5 py-16 md:py-24">
        <SectionHeading id="gallery-title" eyebrow="Gallery" title="Concept art">
          Mockups that guide the look of the game. They are targets, not
          in-game captures.
        </SectionHeading>

        <ul className="grid gap-8 md:grid-cols-2">
          {conceptPieces.map((piece, index) => (
            <li
              key={piece.title}
              className={index === 0 ? "md:col-span-2" : undefined}
            >
              <figure className="flex flex-col gap-3">
                <div className="relative aspect-video overflow-hidden rounded-lg border border-border bg-background">
                  {piece.image ? (
                    <Image
                      src={piece.image}
                      alt={piece.alt}
                      fill
                      placeholder="blur"
                      sizes={index === 0 ? "(min-width: 1152px) 1112px, 100vw" : "(min-width: 768px) 50vw, 100vw"}
                      className="object-cover"
                    />
                  ) : (
                    <div
                      role="img"
                      aria-label={`${piece.title}: image not yet available`}
                      className="flex h-full items-center justify-center text-muted-foreground"
                    >
                      Image coming soon
                    </div>
                  )}
                  <ArtLabel className="absolute left-3 top-3">{piece.label}</ArtLabel>
                </div>
                <figcaption className="flex flex-col gap-1">
                  <span className="font-serif text-lg font-semibold">{piece.title}</span>
                  <span className="text-muted-foreground leading-relaxed">{piece.caption}</span>
                </figcaption>
              </figure>
            </li>
          ))}
        </ul>

        {screenshots.length > 0 ? (
          <div className="flex flex-col gap-6">
            <h3 className="font-serif text-2xl font-semibold">Gameplay screenshots</h3>
            <ul className="grid gap-6 md:grid-cols-2">
              {screenshots.map((shot) => (
                <li key={shot.src}>
                  <figure className="flex flex-col gap-2">
                    <Image
                      src={shot.src}
                      alt={shot.alt}
                      width={shot.width}
                      height={shot.height}
                      sizes="(min-width: 768px) 50vw, 100vw"
                      className="h-auto w-full rounded-lg border border-border"
                    />
                    <figcaption className="text-muted-foreground">{shot.caption}</figcaption>
                  </figure>
                </li>
              ))}
            </ul>
          </div>
        ) : null}
      </div>
    </section>
  );
}
