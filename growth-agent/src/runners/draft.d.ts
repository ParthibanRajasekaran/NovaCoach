export type DraftOptions = {
    locale: string;
    query: string;
    brief?: string | undefined;
    outDir?: string | undefined;
};
export declare function run({ locale, query, brief, outDir }: DraftOptions): Promise<string>;
//# sourceMappingURL=draft.d.ts.map