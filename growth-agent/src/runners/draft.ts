import { constants as fsConstants } from 'node:fs';
import { access, mkdir, readFile, writeFile } from 'node:fs/promises';
import path from 'node:path';
import { buildFrontMatter, renderMdx, toSlug, type RenderFaq } from '../lib/mdx.js';

export type DraftOptions = {
  locale: string;
  query: string;
  brief?: string | undefined;
  outDir?: string | undefined;
};

type BriefInsights = {
  summary: string;
  links: string[];
};

const DEFAULT_OUT_DIR = path.resolve('out', 'content');

export async function run({ locale, query, brief, outDir = DEFAULT_OUT_DIR }: DraftOptions): Promise<string> {
  if (!locale) {
    throw new Error('Locale is required.');
  }
  if (!query) {
    throw new Error('Query is required.');
  }

  const slug = toSlug(query, locale);
  const outputDir = path.join(outDir, locale.toLowerCase());
  const destination = path.join(outputDir, `${slug}.mdx`);

  await mkdir(outputDir, { recursive: true });

  const insights = await loadBriefInsights(brief);
  const title = buildTitle(query);
  const metaDesc = `Practical walkthrough for ${query} tailored to ${locale}.`;
  const canonicalBase = ensureTrailingSlash(process.env.CANONICAL_BASE_URL ?? 'https://example.com/');
  const canonical = new URL(`${locale.toLowerCase()}/${slug}`, canonicalBase).toString();

  const frontMatter = buildFrontMatter({
    title,
    metaDesc,
    canonical,
    locale,
    slug,
    links: insights.links,
  });

  const outline = buildOutline(query, insights.summary);
  const howToSteps = buildHowTo(query);
  const faqs = buildFaqs(query);
  const jsonLd = buildJsonLd({ title, locale, canonical, metaDesc });
  const intro = buildIntro(query, locale, insights.summary);

  const mdx = renderMdx({
    frontMatter,
    h1: title,
    outline,
    howToSteps,
    faqs,
    jsonLd,
    intro,
  });

  const existing = await readExisting(destination);
  if (existing === mdx) {
    console.log(`No changes detected for ${destination}`);
    return destination;
  }

  await writeFile(destination, mdx, 'utf8');
  console.log(`Draft saved to ${destination}`);
  return destination;
}

async function loadBriefInsights(briefPath?: string): Promise<BriefInsights> {
  if (!briefPath) {
    return { summary: 'Focus on user intent, measurement, and credible proof.', links: [] };
  }

  try {
    const contents = await readFile(briefPath, 'utf8');
    const summary = contents.split(/\n+/)[0]?.slice(0, 200).trim();
    const links = Array.from(contents.matchAll(/https?:\/\/\S+/g)).map((match) => match[0]);
    return {
      summary: summary || 'Focus on user intent, measurement, and credible proof.',
      links,
    };
  } catch (error) {
    console.warn(`Unable to read brief at ${briefPath}:`, error);
    return { summary: 'Focus on user intent, measurement, and credible proof.', links: [] };
  }
}

function buildTitle(query: string): string {
  return query.replace(/\.$/, '').trim();
}

function buildOutline(query: string, summary: string): string[] {
  return [
    `Clarify what “${query}” means for the reader and how success is measured.`,
    `Share a lightweight framework to apply immediately. ${summary}`,
    'Highlight proof points, tooling tips, and next experiments.',
  ];
}

function buildHowTo(query: string): string[] {
  return [
    `Assess the current journey for “${query}” and collect baseline metrics.`,
    'Operationalize a repeatable playbook with owners, timelines, and guardrails.',
    'Measure lift, document learnings, and feed them back into the roadmap.',
  ];
}

function buildFaqs(query: string): RenderFaq[] {
  return [
    {
      question: `What is the fastest way to pilot ${query}?`,
      answer: 'Start with a narrow persona and a single success metric to keep scope tight.',
    },
    {
      question: `How do we get stakeholder buy-in for ${query}?`,
      answer: 'Lead with the business impact, share a mock, and secure a single sponsor.',
    },
    {
      question: `Which KPIs prove that ${query} is working?`,
      answer: 'Blend a north-star KPI with one leading metric so you can steer mid-flight.',
    },
    {
      question: `What tools support ${query}?`,
      answer: 'Lean on the existing analytics stack first, then layer new tools if gaps remain.',
    },
    {
      question: `How often should we revisit the ${query} playbook?`,
      answer: 'Plan a quarterly retro to refresh assumptions and double down on what worked.',
    },
  ];
}

function buildJsonLd({
  title,
  locale,
  canonical,
  metaDesc,
}: {
  title: string;
  locale: string;
  canonical: string;
  metaDesc: string;
}) {
  return {
    '@context': 'https://schema.org',
    '@type': 'WebApplication',
    name: title,
    inLanguage: locale,
    applicationCategory: 'MarketingApplication',
    description: metaDesc,
    url: canonical,
  };
}

function buildIntro(query: string, locale: string, summary: string): string {
  return `This ${locale} playbook translates “${query}” into a concrete roadmap so teams can move from ideas to shipped impact.` +
    (summary ? ` ${summary}` : '');
}

async function readExisting(file: string): Promise<string | null> {
  try {
    await access(file, fsConstants.F_OK);
    return await readFile(file, 'utf8');
  } catch {
    return null;
  }
}

function ensureTrailingSlash(value: string): string {
  return value.endsWith('/') ? value : `${value}/`;
}
