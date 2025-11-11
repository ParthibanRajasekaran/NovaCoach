import type { BaseCommandOptions } from './types.js';
export interface DiffOptions extends BaseCommandOptions {
    existing: string;
    desired: string;
    format: 'patch' | 'table';
}
export declare function runDiff(options: DiffOptions): Promise<void>;
//# sourceMappingURL=diff.d.ts.map