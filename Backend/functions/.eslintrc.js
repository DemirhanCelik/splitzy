module.exports = {
  env: {
    es6: true,
    node: true,
  },
  parserOptions: {
    "ecmaVersion": 2018,
  },
  extends: [
    "eslint:recommended",
    "google",
  ],
  rules: {
    "no-restricted-globals": ["error", "name", "length"],
    "prefer-arrow-callback": "error",
    "quotes": ["off"],
    "max-len": ["off"],
    "require-jsdoc": ["off"],
    "indent": ["off"],
    "object-curly-spacing": ["off"],
    "no-trailing-spaces": ["off"],
    "padded-blocks": ["off"],
    "arrow-parens": ["off"],
  },
  overrides: [
    {
      files: ["**/*.spec.*"],
      env: {
        mocha: true,
      },
      rules: {},
    },
  ],
  globals: {},
};
