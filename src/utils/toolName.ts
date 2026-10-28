// Localised display name for a scanned tool.
// Extracted from the (now removed) myProjects store so the Mother Agent
// quick-command chips keep working in the lite build.
import type { LocalTool } from '../api/types';

export const pickToolName = (tool: LocalTool, locale: string): string => {
  if (locale === 'en' || !tool.names) return tool.name;
  const direct = tool.names[locale];
  if (direct) return direct;
  const base = locale.split('-')[0];
  if (tool.names[base]) return tool.names[base];
  const fuzzy = Object.entries(tool.names).find(([k]) => k.startsWith(base));
  return fuzzy?.[1] || tool.name;
};
