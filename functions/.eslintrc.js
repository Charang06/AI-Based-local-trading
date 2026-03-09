module.exports = {
  root: true,
  env: {
    node: true,
    es2021: true,
  },
  parser: "@typescript-eslint/parser",
  parserOptions: {
    project: ["tsconfig.json"],
    tsconfigRootDir: __dirname,
    sourceType: "module",
  },
  plugins: ["@typescript-eslint", "import"],
  extends: [
    "eslint:recommended",
    "plugin:@typescript-eslint/recommended",
    "google",
  ],
  rules: {
    "require-jsdoc": "off",        // ✅ important
    "valid-jsdoc": "off",          // ✅ important
    "max-len": ["error", { "code": 120 }], // relax line length
  },
  ignorePatterns: [
    "lib/**",
    ".eslintrc.js",                // ✅ ignore itself
  ],
};
