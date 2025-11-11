import { execFile } from 'node:child_process';
import { promisify } from 'node:util';
import { mkdir, mkdtemp, readFile, rm, writeFile, access } from 'node:fs/promises';
import { constants as fsConstants } from 'node:fs';
import path from 'node:path';
import { tmpdir } from 'node:os';
import fg from 'fast-glob';
import { getGitAuthToken, getOctokit } from '../integrations/github.js';
const runGit = promisify(execFile);
const DEFAULT_REPO = process.env.TARGET_REPO ?? 'ParthibanRajasekaran/text-from-image';
const DEFAULT_BASE = process.env.TARGET_DEFAULT_BRANCH ?? 'main';
const DEFAULT_CONTENT_DIR = path.resolve('out', 'content');
export async function run({ locale, repo = DEFAULT_REPO, base = DEFAULT_BASE, contentDir = DEFAULT_CONTENT_DIR, }) {
    if (!locale) {
        throw new Error('Locale is required to build the PR branch.');
    }
    const normalizedLocale = locale.toLowerCase();
    const contentRoot = path.resolve(contentDir);
    await ensureDirectory(contentRoot);
    const contentFiles = await fg('**/*', { cwd: contentRoot, onlyFiles: true });
    if (!contentFiles.length) {
        throw new Error(`No content files found under ${contentRoot}`);
    }
    const gitToken = await getGitAuthToken();
    const remoteUrl = buildRemoteUrl(repo, gitToken);
    const workspace = await mkdtemp(path.join(tmpdir(), 'growth-agent-pr-'));
    const repoDir = path.join(workspace, 'repo');
    try {
        await runGitCommand(['clone', remoteUrl, repoDir], workspace);
        await runGitCommand(['checkout', base], repoDir);
        await runGitCommand(['pull', '--ff-only', 'origin', base], repoDir);
        const branchName = buildBranchName(normalizedLocale);
        await runGitCommand(['checkout', '-b', branchName], repoDir);
        await syncContent(contentRoot, path.join(repoDir, 'out', 'content'), contentFiles);
        await configureGitIdentity(repoDir);
        await runGitCommand(['add', 'out/content'], repoDir);
        const status = await gitStatus(repoDir);
        if (!status.trim()) {
            throw new Error('No git changes detected after syncing out/content.');
        }
        const commitMessage = `growth: ${normalizedLocale} content ${timestamp()}`;
        await runGitCommand(['commit', '-m', commitMessage], repoDir);
        await runGitCommand(['push', '-u', 'origin', branchName], repoDir);
        const octokit = await getOctokit();
        const { owner, repo: repoName } = parseRepo(repo);
        const title = `Growth content for ${normalizedLocale} (${timestamp()})`;
        const body = buildPrBody(normalizedLocale);
        const pr = await octokit.pulls.create({
            owner,
            repo: repoName,
            title,
            head: branchName,
            base,
            body,
        });
        await addLabels(octokit, {
            owner,
            repo: repoName,
            issueNumber: pr.data.number,
            locale: normalizedLocale,
            status,
        });
        console.log(`Opened PR #${pr.data.number}: ${pr.data.html_url}`);
    }
    finally {
        await rm(workspace, { recursive: true, force: true });
    }
}
async function ensureDirectory(dir) {
    try {
        await access(dir, fsConstants.R_OK);
    }
    catch (error) {
        if (error.code === 'ENOENT') {
            throw new Error(`Directory not found: ${dir}`);
        }
        throw error;
    }
}
function buildRemoteUrl(repo, token) {
    return `https://x-access-token:${token}@github.com/${repo}.git`;
}
function buildBranchName(locale) {
    return `growth/${locale}-${new Date().toISOString().slice(0, 10).replaceAll('-', '')}`;
}
async function syncContent(srcRoot, destRoot, files) {
    await rm(destRoot, { recursive: true, force: true });
    for (const relative of files) {
        const src = path.join(srcRoot, relative);
        const dest = path.join(destRoot, relative);
        await mkdir(path.dirname(dest), { recursive: true });
        const buffer = await readFile(src);
        await writeFile(dest, buffer);
    }
}
async function configureGitIdentity(cwd) {
    const name = process.env.GIT_AUTHOR_NAME ?? 'growth-agent';
    const email = process.env.GIT_AUTHOR_EMAIL ?? 'growth-agent@example.com';
    await runGitCommand(['config', 'user.name', name], cwd);
    await runGitCommand(['config', 'user.email', email], cwd);
}
async function gitStatus(cwd) {
    const { stdout } = await runGit('git', ['status', '--short'], { cwd, encoding: 'utf8' });
    return stdout;
}
async function runGitCommand(args, cwd) {
    await runGit('git', args, { cwd, encoding: 'utf8' });
}
function timestamp() {
    return new Date().toISOString().slice(0, 10);
}
function buildPrBody(locale) {
    return `## Summary\n- Fresh content for ${locale}\n\n## Checklist\n- [ ] hreflang entries confirmed\n- [ ] Internal links reviewed\n- [ ] Lighthouse sanity check completed\n`;
}
async function addLabels(octokit, { owner, repo, issueNumber, locale, status, }) {
    const hasUpdates = status.split('\n').some((line) => line.trim().startsWith('M'));
    const labels = ['from:agent', `locale:${locale}`, hasUpdates ? 'type:update' : 'type:new'];
    try {
        await octokit.issues.addLabels({ owner, repo, issue_number: issueNumber, labels });
    }
    catch (error) {
        console.warn('Unable to add labels:', error);
    }
}
function parseRepo(repo) {
    const [owner, name] = repo.split('/');
    if (!owner || !name) {
        throw new Error(`Invalid TARGET_REPO value: ${repo}`);
    }
    return { owner, repo: name };
}
//# sourceMappingURL=pr.js.map