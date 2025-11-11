import { mkdir, writeFile } from 'node:fs/promises';
import path from 'node:path';
const DEFAULT_OUTPUT_DIR = path.resolve('out', 'reports');
export async function run({ weekOf, outputDir = DEFAULT_OUTPUT_DIR } = {}) {
    const { start, end } = resolveWeek(weekOf);
    const stub = buildStub(start, end);
    await mkdir(outputDir, { recursive: true });
    const destination = path.join(outputDir, `${start}.md`);
    await writeFile(destination, stub, 'utf8');
    console.log(`Weekly summary stub saved to ${destination}`);
    console.log(stub);
    return destination;
}
function resolveWeek(reference) {
    const baseDate = reference ? new Date(reference) : new Date();
    if (Number.isNaN(baseDate.valueOf())) {
        throw new Error(`Invalid week reference: ${reference}`);
    }
    const day = baseDate.getUTCDay() || 7;
    const start = new Date(Date.UTC(baseDate.getUTCFullYear(), baseDate.getUTCMonth(), baseDate.getUTCDate()));
    start.setUTCDate(start.getUTCDate() - (day - 1));
    const end = new Date(start);
    end.setUTCDate(start.getUTCDate() + 6);
    return { start: toISO(start), end: toISO(end) };
}
function buildStub(weekStart, weekEnd) {
    return `# Weekly Growth Report\n\n**Week:** ${weekStart} → ${weekEnd}\n\n## Highlights\n- TODO: celebrate impact\n\n## Blockers\n- TODO: list risks\n\n## In Flight\n- TODO: capture live work\n\n## Next Steps\n- TODO: name the upcoming commitments\n`;
}
function toISO(date) {
    return date.toISOString().slice(0, 10);
}
//# sourceMappingURL=report.js.map