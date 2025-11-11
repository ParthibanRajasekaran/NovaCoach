import { App } from '@octokit/app';
import { Octokit } from '@octokit/rest';

let cachedClient: Octokit | undefined;
let cachedToken: string | undefined;

export async function getOctokit(): Promise<Octokit> {
  if (cachedClient) {
    return cachedClient;
  }
  const authToken = await resolveAuthToken();
  cachedClient = new Octokit({ auth: authToken });
  return cachedClient;
}

export async function getGitAuthToken(): Promise<string> {
  return resolveAuthToken();
}

async function resolveAuthToken(): Promise<string> {
  if (cachedToken) {
    return cachedToken;
  }

  const token = process.env.GITHUB_TOKEN;
  if (token) {
    cachedToken = token;
    return cachedToken;
  }

  const appId = process.env.GITHUB_APP_ID;
  const installationId = process.env.GITHUB_INSTALLATION_ID;
  const privateKey = process.env.GITHUB_PRIVATE_KEY;

  if (appId && installationId && privateKey) {
    const app = new App({
      appId: Number(appId),
      privateKey,
    });

    const installationOctokit = await app.getInstallationOctokit(Number(installationId));
    const authentication = await installationOctokit.auth({ type: 'installation' });
    if (!isInstallationAuth(authentication)) {
      throw new Error('GitHub App authentication did not return an installation token.');
    }
    cachedToken = authentication.token;
    return cachedToken;
  }

  throw new Error(
    'Missing GitHub credentials. Set GITHUB_TOKEN or the GitHub App trio (GITHUB_APP_ID, GITHUB_INSTALLATION_ID, GITHUB_PRIVATE_KEY).',
  );
}

function isInstallationAuth(value: unknown): value is { token: string } {
  return Boolean(value && typeof value === 'object' && 'token' in value);
}
