/**
 * Every outbound link the site renders lives here.
 *
 * Optional entries stay empty until a real destination exists. The page shows
 * plain "planned" status text in their place, so nothing links to a dead URL.
 * Desktop downloads must point at verified GitHub Release assets, e.g.
 * https://github.com/jedemarco1030/the-second-sky/releases/download/v0.1.0/the-second-sky-windows.zip
 */

export type DesktopPlatform = "windows" | "macos" | "linux";

export interface DesktopDownload {
  platform: DesktopPlatform;
  label: string;
  url: string;
}

export interface GameplayScreenshot {
  src: string;
  width: number;
  height: number;
  alt: string;
  caption: string;
}

export interface SiteConfig {
  siteUrl: string;
  repoUrl: string;
  readmeUrl: string;
  sourceZipUrl: string;
  godotDownloadUrl: string;
  godotVersion: string;
  desktopDownloads: DesktopDownload[];
  browserDemoUrl?: string;
  gameplayScreenshots: GameplayScreenshot[];
}

const repoUrl = "https://github.com/jedemarco1030/the-second-sky";

export const siteConfig: SiteConfig = {
  siteUrl: "https://the-second-sky.vercel.app",
  repoUrl,
  readmeUrl: `${repoUrl}#readme`,
  sourceZipUrl: `${repoUrl}/archive/refs/heads/main.zip`,
  godotDownloadUrl: "https://godotengine.org/download/archive/4.7.2-stable/",
  godotVersion: "4.7.2",
  desktopDownloads: [],
  browserDemoUrl: undefined,
  gameplayScreenshots: [],
};
