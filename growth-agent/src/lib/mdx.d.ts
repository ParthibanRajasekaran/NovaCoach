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
export declare function toSlug(query: string, locale: string): string;
export declare function buildFrontMatter({ title, metaDesc, canonical, locale, slug, links, ...rest }: FrontMatterInput): string;
export declare function renderMdx({ frontMatter, h1, outline, howToSteps, faqs, jsonLd, intro, }: RenderMdxOptions): string;
//# sourceMappingURL=mdx.d.ts.map