import type { ReactNode } from "react";

export function ArtLabel({
  children,
  className = "",
}: {
  children: ReactNode;
  className?: string;
}) {
  return (
    <span
      className={`rounded-md bg-background/85 px-2.5 py-1 text-xs font-semibold uppercase tracking-wider text-foreground ${className}`}
    >
      {children}
    </span>
  );
}
