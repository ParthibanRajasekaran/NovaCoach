#!/usr/bin/env node
import yargs, {} from 'yargs';
import { hideBin } from 'yargs/helpers';
import { run as runDiscover } from '../runners/discover.js';
import { run as runDraft } from '../runners/draft.js';
import { run as runPr } from '../runners/pr.js';
import { run as runReport } from '../runners/report.js';
export async function runCLI(argv = hideBin(process.argv)) {
    try {
        await buildParser(argv).parseAsync();
    }
    catch (error) {
        console.error('growth-agent failed:', error);
        process.exitCode = 1;
    }
}
function buildParser(argv) {
    return yargs(argv)
        .scriptName('growth-agent')
        .strict()
        .demandCommand(1, 'Select a subcommand.')
        .command(discoverCommand)
        .command(draftCommand)
        .command(prCommand)
        .command(reportCommand)
        .alias('h', 'help')
        .alias('v', 'version')
        .wrap(Math.min(100, process.stdout.columns ?? 80));
}
void runCLI();
const discoverCommand = {
    command: 'discover',
    describe: 'Summarize promising GSC queries grouped by country.',
    builder: (command) => command
        .option('startDaysAgo', {
        alias: 'start-days-ago',
        type: 'number',
        default: 28,
        describe: 'Relative start date (inclusive).',
    })
        .option('endDaysAgo', {
        alias: 'end-days-ago',
        type: 'number',
        default: 0,
        describe: 'Relative end date (inclusive).',
    })
        .option('limit', {
        type: 'number',
        default: 10,
        describe: 'Maximum number of rows to print.',
    })
        .option('siteUrl', {
        alias: 'site-url',
        type: 'string',
        describe: 'Override the Search Console property URI.',
    }),
    handler: async (rawArgs) => {
        const args = rawArgs;
        await runDiscover({
            startDaysAgo: args.startDaysAgo,
            endDaysAgo: args.endDaysAgo,
            limit: args.limit,
            siteUrl: args.siteUrl ?? undefined,
        });
    },
};
const draftCommand = {
    command: 'draft',
    describe: 'Generate an MDX draft under out/content/{locale}.',
    builder: (command) => command
        .option('locale', {
        type: 'string',
        demandOption: true,
        describe: 'Locale folder such as en-us.',
    })
        .option('query', {
        type: 'string',
        demandOption: true,
        describe: 'Human-friendly query/topic for the content.',
    })
        .option('brief', {
        type: 'string',
        describe: 'Optional supporting brief to shape the outline.',
    }),
    handler: async (rawArgs) => {
        const args = rawArgs;
        await runDraft({
            locale: args.locale,
            query: args.query,
            brief: args.brief ?? undefined,
        });
    },
};
const prCommand = {
    command: 'pr',
    describe: 'Clone the TARGET_REPO, commit out/content, and raise a pull request.',
    builder: (command) => command
        .option('locale', {
        type: 'string',
        demandOption: true,
        describe: 'Locale used to scope the branch name and labels.',
    })
        .option('repo', {
        type: 'string',
        describe: 'Override TARGET_REPO.',
    })
        .option('base', {
        type: 'string',
        describe: 'Override TARGET_DEFAULT_BRANCH.',
    })
        .option('contentDir', {
        alias: 'content-dir',
        type: 'string',
        describe: 'Override the default out/content directory.',
    }),
    handler: async (rawArgs) => {
        const args = rawArgs;
        await runPr({
            locale: args.locale,
            repo: args.repo ?? undefined,
            base: args.base ?? undefined,
            contentDir: args.contentDir ?? undefined,
        });
    },
};
const reportCommand = {
    command: 'report',
    describe: 'Emit a markdown stub for the current week.',
    builder: (command) => command
        .option('weekOf', {
        alias: 'week-of',
        type: 'string',
        describe: 'Any ISO date inside the target week (UTC).',
    })
        .option('outputDir', {
        alias: 'output-dir',
        type: 'string',
        describe: 'Optional override for out/reports.',
    }),
    handler: async (rawArgs) => {
        const args = rawArgs;
        await runReport({
            weekOf: args.weekOf ?? undefined,
            outputDir: args.outputDir ?? undefined,
        });
    },
};
//# sourceMappingURL=index.js.map