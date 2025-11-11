import { promises as fs } from 'node:fs';
import path from 'node:path';
import matter from 'gray-matter';
import yaml from 'js-yaml';
import { createLogger } from './types.js';
export async function runDiff(options) {
    const logger = createLogger(options.verbose);
    const existingPath = path.resolve(options.existing);
    const desiredPath = path.resolve(options.desired);
    const [existingContents, desiredContents] = await Promise.all([
        fs.readFile(existingPath, 'utf8'),
        fs.readFile(desiredPath, 'utf8'),
    ]);
    const existingMatter = matter(existingContents);
    const desiredMatter = matter(desiredContents);
    const diffEntries = computeDiffEntries(existingMatter.data, desiredMatter.data);
    if (diffEntries.length === 0) {
        logger.info('Front-matter already matches the desired state.');
        return;
    }
    if (options.format === 'table') {
        console.table(diffEntries.map((entry) => ({
            Field: entry.key,
            Current: formatValue(entry.before),
            Desired: formatValue(entry.after),
        })));
        return;
    }
    const patch = createFrontMatterPatch(existingPath, desiredPath, existingMatter.data, desiredMatter.data);
    logger.info('Front-matter patch:');
    console.log(patch);
}
function computeDiffEntries(current, next) {
    const keys = new Set([...Object.keys(current ?? {}), ...Object.keys(next ?? {})]);
    const entries = [];
    for (const key of keys) {
        const before = current?.[key];
        const after = next?.[key];
        if (!isEqual(before, after)) {
            entries.push({ key, before, after });
        }
    }
    return entries;
}
function isEqual(left, right) {
    return serialise(left) === serialise(right);
}
function serialise(value) {
    if (value === null || value === undefined) {
        return 'null';
    }
    if (typeof value !== 'object') {
        return JSON.stringify(value);
    }
    if (Array.isArray(value)) {
        return `[${value.map(serialise).join(',')}]`;
    }
    const entries = Object.entries(value).sort(([a], [b]) => a.localeCompare(b));
    return `{${entries.map(([key, val]) => `${JSON.stringify(key)}:${serialise(val)}`).join(',')}}`;
}
function createFrontMatterPatch(existingPath, desiredPath, existingFrontMatter, desiredFrontMatter) {
    const prevYaml = yaml.dump(existingFrontMatter ?? {}, { lineWidth: 0 }).trimEnd();
    const nextYaml = yaml.dump(desiredFrontMatter ?? {}, { lineWidth: 0 }).trimEnd();
    const prevLines = prevYaml.length > 0 ? prevYaml.split('\n') : [];
    const nextLines = nextYaml.length > 0 ? nextYaml.split('\n') : [];
    const header = [`--- ${existingPath}`, `+++ ${desiredPath}`, '@@ front-matter @@'];
    const removals = prevLines.map((line) => `-${line}`);
    const additions = nextLines.map((line) => `+${line}`);
    return [...header, ...removals, ...additions].join('\n');
}
function formatValue(value) {
    if (value === null || value === undefined) {
        return '—';
    }
    if (typeof value === 'string') {
        return value;
    }
    return yaml.dump(value, { lineWidth: 0 }).trim();
}
//# sourceMappingURL=diff.js.map