import { type QueryStatRow } from '../integrations/gsc.js';
export type DiscoverOptions = {
    startDaysAgo?: number;
    endDaysAgo?: number;
    limit?: number;
    siteUrl?: string | undefined;
};
export declare function run({ startDaysAgo, endDaysAgo, limit, siteUrl, }?: DiscoverOptions): Promise<QueryStatRow[]>;
//# sourceMappingURL=discover.d.ts.map