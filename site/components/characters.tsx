import { SectionHeading } from "@/components/section-heading";

const party = [
  {
    name: "Mira",
    role: "Harbor courier",
    description:
      "Knows every alley, stair, and pier by heart. When a distress call crackles out of a lighthouse no one has lit in decades, she is the one who goes.",
  },
  {
    name: "Nell",
    role: "Radio mechanic",
    description:
      "Keeps the harbor's old sets alive with solder and stubbornness. She caught the signal first, and she wants to know who is sending it.",
  },
  {
    name: "Tovan",
    role: "Retired knight",
    description:
      "Still walks the west seawall out of habit. His shield has outlasted his order, and he is not ready to hang it up.",
  },
  {
    name: "Pip",
    role: "Lantern moth",
    description:
      "A small glowing companion who lights the way, and who seems to understand far more about the rising tide than a moth should.",
  },
];

export function Characters() {
  return (
    <section
      id="characters"
      aria-labelledby="characters-title"
      className="border-t border-border bg-surface"
    >
      <div className="mx-auto flex max-w-6xl flex-col gap-10 px-5 py-16 md:py-24">
        <SectionHeading id="characters-title" eyebrow="The party" title="Four lanterns against the tide" />
        <ul className="grid gap-4 sm:grid-cols-2">
          {party.map((member) => (
            <li
              key={member.name}
              className="flex flex-col gap-2 rounded-lg border border-border bg-background p-6"
            >
              <h3 className="font-serif text-2xl font-semibold">{member.name}</h3>
              <p className="text-sm font-semibold uppercase tracking-wider text-accent">
                {member.role}
              </p>
              <p className="leading-relaxed text-muted-foreground">
                {member.description}
              </p>
            </li>
          ))}
        </ul>
      </div>
    </section>
  );
}
