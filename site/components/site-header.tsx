import { siteConfig } from "@/site.config";

const navItems = [
  { href: "#characters", label: "Characters" },
  { href: "#features", label: "Gameplay" },
  { href: "#gallery", label: "Gallery" },
];

export function SiteHeader() {
  return (
    <header className="absolute inset-x-0 top-0 z-20">
      <nav
        aria-label="Primary"
        className="mx-auto flex max-w-6xl items-center justify-between gap-4 px-5 py-4"
      >
        <a
          href="#main"
          className="rounded-lg bg-background/70 px-3 py-1.5 font-serif text-sm font-semibold tracking-wide backdrop-blur"
        >
          The Second Sky
        </a>
        <ul className="flex items-center gap-1 rounded-lg bg-background/70 px-2 py-1 text-sm backdrop-blur">
          {navItems.map((item) => (
            <li key={item.href} className="hidden md:block">
              <a
                href={item.href}
                className="block rounded-md px-3 py-1.5 text-muted-foreground transition-colors hover:text-foreground"
              >
                {item.label}
              </a>
            </li>
          ))}
          <li>
            <a
              href="#playtest"
              className="block rounded-md px-3 py-1.5 text-muted-foreground transition-colors hover:text-foreground"
            >
              Playtest
            </a>
          </li>
          <li>
            <a
              href={siteConfig.repoUrl}
              className="block rounded-md px-3 py-1.5 text-muted-foreground transition-colors hover:text-foreground"
            >
              GitHub
            </a>
          </li>
        </ul>
      </nav>
    </header>
  );
}
