import { google } from 'googleapis';
export async function getCountryQueryStats({ startDaysAgo, endDaysAgo, siteUrl, }) {
    const propertyUri = siteUrl ?? process.env.GSC_PROPERTY_URI ?? process.env.GSC_SITE_URL;
    if (!propertyUri) {
        throw new Error('Missing Search Console property URI. Provide siteUrl or set GSC_PROPERTY_URI.');
    }
    const auth = await google.auth.getClient({
        scopes: ['https://www.googleapis.com/auth/webmasters.readonly'],
    });
    const searchConsole = google.searchconsole({ version: 'v1', auth });
    let startDate = offsetToDate(startDaysAgo);
    let endDate = offsetToDate(endDaysAgo);
    if (startDate > endDate) {
        [startDate, endDate] = [endDate, startDate];
    }
    const { data } = await searchConsole.searchanalytics.query({
        siteUrl: propertyUri,
        requestBody: {
            startDate: formatDate(startDate),
            endDate: formatDate(endDate),
            type: 'web',
            rowLimit: 1000,
            dataState: 'final',
            dimensions: ['page', 'country', 'query'],
            aggregationType: 'auto',
        },
    });
    const rows = data.rows ?? [];
    return rows
        .map((row) => ({
        page: row.keys?.[0] ?? 'unknown',
        country: row.keys?.[1] ?? 'unknown',
        query: row.keys?.[2] ?? 'unknown',
        clicks: row.clicks ?? 0,
        impressions: row.impressions ?? 0,
        ctr: row.ctr ?? 0,
        position: row.position ?? 0,
    }))
        .sort((a, b) => {
        if (b.clicks !== a.clicks) {
            return b.clicks - a.clicks;
        }
        return b.impressions - a.impressions;
    });
}
function offsetToDate(daysAgo) {
    const date = new Date();
    date.setUTCHours(0, 0, 0, 0);
    date.setUTCDate(date.getUTCDate() - Math.max(0, Math.floor(daysAgo)));
    return date;
}
function formatDate(date) {
    return date.toISOString().slice(0, 10);
}
//# sourceMappingURL=gsc.js.map