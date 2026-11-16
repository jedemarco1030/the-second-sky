export function SectionHeading({
  id,
  eyebrow,
  title,
  children,
}: {
  id: string;
  eyebrow: string;
  title: string;
  children?: React.ReactNode;
}) {
  return (
    <div className="flex max-w-2xl flex-col gap-3">
      <p className="text-sm font-semibold uppercase tracking-[0.2em] text-accent">
        {eyebrow}
      </p>
      <h2
        id={id}
        className="font-serif text-3xl font-bold leading-tight text-balance md:text-4xl"
      >
        {title}
      </h2>
      {children ? (
        <p className="text-lg leading-relaxed text-pretty text-muted-foreground">
          {children}
        </p>
      ) : null}
    </div>
  );
}
