import { SectionHeading } from "@/components/section-heading";

const playable = [
  {
    title: "Explore the harbor",
    body: "Walk the lantern-lit waterfront at your own pace, read the signs, and talk to the people who still live by the tide.",
  },
  {
    title: "Find Nell and Tovan",
    body: "Speak to Nell about the signal, then track down Tovan on the west seawall to gather the party.",
  },
  {
    title: "Fight the harbor pump",
    body: "A turn-based battle against a rusted machine. The turn-order timeline shows every upcoming action, including the pump's Surge.",
  },
];

const planned = [
  {
    title: "The harbor decision",
    body: "Choose what the waterfront becomes once the tide is settled.",
  },
  {
    title: "A playable return visit",
    body: "Walk back through the harbor and see what your choice changed.",
  },
  {
    title: "Endings",
    body: "Still being written. How the story closes is open for now.",
  },
];

export function Features() {
  return (
    <section
      id="features"
      aria-labelledby="features-title"
      className="border-t border-border"
    >
      <div className="mx-auto flex max-w-6xl flex-col gap-12 px-5 py-16 md:py-24">
        <SectionHeading id="features-title" eyebrow="Gameplay" title="What you can play today">
          The prototype is a short harbor slice: exploration, a gathering
          party, and one boss fight built around reading the turn order.
        </SectionHeading>

        <ul className="grid gap-4 md:grid-cols-3">
          {playable.map((item) => (
            <li key={item.title} className="flex flex-col gap-2 rounded-lg border border-border bg-surface p-6">
              <h3 className="font-serif text-xl font-semibold">{item.title}</h3>
              <p className="leading-relaxed text-muted-foreground">{item.body}</p>
            </li>
          ))}
        </ul>

        <div className="flex flex-col gap-6 rounded-lg border border-accent/40 bg-surface p-6 md:p-10">
          <h3 className="font-serif text-2xl font-semibold text-balance">
            Two ways through the Surge
          </h3>
          <div className="grid gap-8 md:grid-cols-2">
            <div className="flex flex-col gap-2">
              <p className="text-sm font-semibold uppercase tracking-wider text-accent">
                Hold the line
              </p>
              <p className="leading-relaxed">
                Watch the Surge approach on the timeline and have the party
                Guard before it lands. Slower, steadier, and forgiving.
              </p>
            </div>
            <div className="flex flex-col gap-2">
              <p className="text-sm font-semibold uppercase tracking-wider text-accent">
                Break the wave
              </p>
              <p className="leading-relaxed">
                Time Breakwater to interrupt it. Mira can move Nell up the turn
                order so she and Tovan set it up in time. Before you confirm,
                the timeline previews which two turns Breakwater spends and
                when it resolves.
              </p>
            </div>
          </div>
          <p className="text-muted-foreground leading-relaxed">
            No timed button presses. Every choice is made from a menu, with
            keyboard or gamepad, and a lost fight can be retried in one action.
          </p>
        </div>

        <div className="flex flex-col gap-6">
          <h3 className="font-serif text-2xl font-semibold">Planned</h3>
          <ul className="grid gap-4 md:grid-cols-3">
            {planned.map((item) => (
              <li key={item.title} className="flex flex-col gap-2 border-t border-border pt-4">
                <h4 className="font-semibold text-lg">{item.title}</h4>
                <p className="leading-relaxed text-muted-foreground">{item.body}</p>
              </li>
            ))}
          </ul>
        </div>
      </div>
    </section>
  );
}
