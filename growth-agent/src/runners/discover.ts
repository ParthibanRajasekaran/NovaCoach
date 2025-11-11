import { getCountryQueryStats, type QueryStatRow } from '../integrations/gsc.js';

export type DiscoverOptions = {
  startDaysAgo?: number;
  endDaysAgo?: number;
  limit?: number;
  siteUrl?: string | undefined;
};

export async function run({
  startDaysAgo = 28,
  endDaysAgo = 0,
  limit = 10,
  siteUrl,
}: DiscoverOptions = {}): Promise<QueryStatRow[]> {
  const rows = await getCountryQueryStats({ startDaysAgo, endDaysAgo, siteUrl });
  const slice = rows.slice(0, limit);
  if (slice.length === 0) {
    console.log('No Search Console rows returned.');
    return [];
  }

  console.table(
    slice.map((row) => ({
      Page: row.page,
      Country: row.country,
      Query: row.query,
      Clicks: row.clicks,
      Impressions: row.impressions,
      CTR: `${(row.ctr * 100).toFixed(2)}%`,
      Position: row.position.toFixed(1),
    })),
  );
  return slice;
}
