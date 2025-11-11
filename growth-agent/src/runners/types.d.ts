export interface BaseCommandOptions {
    /**
     * Optional path to a JSON/YAML config that individual commands can consume.
     */
    config?: string;
    /**
     * Emits additional diagnostic output when true.
     */
    verbose: boolean;
    /**
     * Prevents runners from making remote or irreversible changes.
     */
    dryRun: boolean;
}
export interface Logger {
    info(message: string): void;
    warn(message: string): void;
    error(message: string, error?: unknown): void;
    debug(message: string): void;
}
export declare function createLogger(verbose: boolean): Logger;
//# sourceMappingURL=types.d.ts.map