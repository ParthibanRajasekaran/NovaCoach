import matter from 'gray-matter';

export type FrontMatterInput = {
  title: string;
  metaDesc: string;
  canonical: string;
  locale: string;
  slug: string;
  links?: string[];
  [key: string]: unknown;
};

export type RenderFaq = {
  question: string;
  answer: string;
};

export type RenderMdxOptions = {
  frontMatter: Record<string, unknown> | string;
  h1: string;
  outline: string[];
  howToSteps: string[];
  faqs: RenderFaq[];
  jsonLd: Record<string, unknown>;
  intro?: string;
};

export function toSlug(query: string, locale: string): string {
  const normalizedQuery = query
    .normalize('NFD')
    .replace(/\p{Diacritic}/gu, '')
    .toLowerCase()
    .replace(/[^a-z0-9]+/g, '-')
    .replace(/^-+|-+$/g, '')
    .replace(/-{2,}/g, '-');
  const localePart = locale.toLowerCase().replace(/[^a-z0-9-]/g, '').replace(/^-+|-+$/g, '');
  if (!normalizedQuery) {
    return localePart || 'content';
  }
  return localePart ? `${localePart}-${normalizedQuery}` : normalizedQuery;
}

export function buildFrontMatter({
  title,
  metaDesc,
  canonical,
  locale,
  slug,
  links = [],
  ...rest
}: FrontMatterInput): string {
  const data = {
    title,
    description: metaDesc,
    canonical,
    locale,
    slug,
    links,
    ...rest,
  };
  return matter.stringify('', data).trim();
}

export function renderMdx({
  frontMatter,
  h1,
  outline,
  howToSteps,
  faqs,
  jsonLd,
  intro,
}: RenderMdxOptions): string {
  const fmBlock =
    typeof frontMatter === 'string' ? frontMatter.trim() : matter.stringify('', frontMatter).trim();
  const sections: string[] = [fmBlock, '', `# ${h1}`];
  if (intro) {
    sections.push('', intro);
  }
  if (outline.length) {
    sections.push('', '## TL;DR Outline');
    outline.forEach((item) => sections.push(`- ${item}`));
  }
  if (howToSteps.length) {
    sections.push('', '## How to get it done');
    howToSteps.forEach((step, index) => sections.push(`${index + 1}. ${step}`));
  }
  if (faqs.length) {
    sections.push('', '## FAQs');
    faqs.forEach(({ question, answer }) => {
      sections.push(`### ${question}`, answer, '');
    });
  }
  sections.push(
    '',
    '<script type="application/ld+json">',
    JSON.stringify(jsonLd, null, 2),
    '</script>',
    '',
  );
  return sections.join('\n').replace(/\n{3,}/g, '\n\n');
}
