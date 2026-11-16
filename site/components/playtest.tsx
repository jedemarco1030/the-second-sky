import { siteConfig } from "@/site.config";
import { SectionHeading } from "@/components/section-heading";

const linkClass =
  "font-semibold text-accent underline underline-offset-4 hover:no-underline";

export function Playtest() {
  const { desktopDownloads, browserDemoUrl } = siteConfig;

  return (
    <section id="playtest" aria-labelledby="playtest-title" className="scroll-mt-4 border-t border-border">
      <div className="mx-auto flex max-w-6xl flex-col gap-12 px-5 py-16 md:py-24">
        <SectionHeading id="playtest-title" eyebrow="Playtest" title="Try the prototype">
          The prototype runs from source in the Godot editor. It takes a few
          minutes to set up.
        </SectionHeading>

        <div className="grid gap-10 lg:grid-cols-5">
          <div className="flex flex-col gap-8 lg:col-span-3">
            <div className="flex flex-col gap-2">
              <a
                href={siteConfig.sourceZipUrl}
                className="inline-flex items-center justify-center self-start rounded-lg bg-accent px-6 py-3 text-base font-semibold text-accent-foreground transition-opacity hover:opacity-90"
              >
                Download Godot project
              </a>
              <p className="text-sm text-muted-foreground">
                Source ZIP · Godot editor required
              </p>
            </div>

            <ol className="flex flex-col gap-4">
              {[
                <>
                  Install{" "}
                  <a href={siteConfig.godotDownloadUrl} className={linkClass}>
                    Godot {siteConfig.godotVersion} stable
                  </a>{" "}
                  (the standard build, not .NET).
                </>,
                <>Unzip the project. The folder is named the-second-sky-main.</>,
                <>
                  Open Godot, choose Import, and select the{" "}
                  <code className="rounded bg-surface px-1.5 py-0.5 font-mono text-sm">
                    project.godot
                  </code>{" "}
                  file at the root of that folder.
                </>,
                <>Press F5 to run the game.</>,
              ].map((step, index) => (
                <li key={index} className="flex gap-4">
                  <span
                    aria-hidden="true"
                    className="flex size-8 shrink-0 items-center justify-center rounded-full border border-accent/60 font-semibold text-accent"
                  >
                    {index + 1}
                  </span>
                  <span className="pt-1 leading-relaxed">{step}</span>
                </li>
              ))}
            </ol>

            <p className="leading-relaxed text-muted-foreground">
              Stuck? The{" "}
              <a href={siteConfig.readmeUrl} className={linkClass}>
                repository README
              </a>{" "}
              covers setup, controls, and the full playtest checklist.
            </p>
          </div>

          <div className="flex flex-col gap-6 lg:col-span-2">
            <div className="flex flex-col gap-4 rounded-lg border border-border bg-surface p-6">
              <h3 className="font-serif text-xl font-semibold">Controls</h3>
              <dl className="grid grid-cols-[auto_1fr] gap-x-4 gap-y-2">
                <dt className="font-semibold">Move</dt>
                <dd className="text-muted-foreground">Arrow keys or WASD</dd>
                <dt className="font-semibold">Interact</dt>
                <dd className="text-muted-foreground">E or Enter</dd>
              </dl>
              <p className="leading-relaxed">
                Speak to Nell first, then find Tovan at the west seawall.
              </p>
            </div>

            <div className="flex flex-col gap-3 rounded-lg border border-border p-6">
              <h3 className="font-serif text-xl font-semibold">Other ways to play</h3>
              <ul className="flex flex-col gap-2">
                {desktopDownloads.length > 0 ? (
                  desktopDownloads.map((download) => (
                    <li key={download.platform}>
                      <a href={download.url} className={linkClass}>
                        {download.label}
                      </a>
                    </li>
                  ))
                ) : (
                  <li className="text-muted-foreground">Desktop build — planned</li>
                )}
                {browserDemoUrl ? (
                  <li>
                    <a href={browserDemoUrl} className={linkClass}>
                      Play the browser demo
                    </a>
                  </li>
                ) : (
                  <li className="text-muted-foreground">Browser demo — planned</li>
                )}
              </ul>
            </div>
          </div>
        </div>
      </div>
    </section>
  );
}
