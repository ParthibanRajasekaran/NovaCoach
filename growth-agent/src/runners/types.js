export function createLogger(verbose) {
    return {
        info: console.log.bind(console),
        warn: console.warn.bind(console),
        error: console.error.bind(console),
        debug: verbose ? console.debug.bind(console) : () => { },
    };
}
//# sourceMappingURL=types.js.map