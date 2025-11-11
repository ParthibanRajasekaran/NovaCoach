export type QueryStatRow = {
    page: string;
    country: string;
    query: string;
    clicks: number;
    impressions: number;
    ctr: number;
    position: number;
};
export type CountryQueryStatsOptions = {
    startDaysAgo: number;
    endDaysAgo: number;
    siteUrl?: string | undefined;
};
export declare function getCountryQueryStats({ startDaysAgo, endDaysAgo, siteUrl, }: CountryQueryStatsOptions): Promise<QueryStatRow[]>;
//# sourceMappingURL=gsc.d.ts.map