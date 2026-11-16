import { siteConfig } from "@/site.config";

export function SiteFooter() {
  return (
    <footer className="border-t border-border bg-surface">
      <div className="mx-auto flex max-w-6xl flex-col gap-3 px-5 py-10 text-sm text-muted-foreground md:flex-row md:items-center md:justify-between">
        <p>
          <span className="font-serif font-semibold text-foreground">The Second Sky</span>{" "}
          is an early prototype. Concept art is not final.
        </p>
        <a
          href={siteConfig.repoUrl}
          className="font-semibold text-foreground underline underline-offset-4 hover:no-underline"
        >
          Source on GitHub
        </a>
      </div>
    </footer>
  );
}
