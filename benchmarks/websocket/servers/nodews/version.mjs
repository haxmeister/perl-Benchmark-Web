import pkg from 'ws/package.json' with { type: 'json' };
console.log(`${process.version}, ws ${pkg.version}`);
