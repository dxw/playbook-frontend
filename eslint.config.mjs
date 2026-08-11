import js from "@eslint/js"
import { defineConfig } from "eslint/config"

export default defineConfig([
  {
    ignores: ["app/assets/builds/**", "coverage/**", "node_modules/**", "vendor/**"],
  },
  { 
    files: ["**/*.{js,mjs,cjs}"], 
    plugins: { js }, 
    extends: ["js/recommended"], 
    rules: {
      "comma-dangle": ["error", { arrays: "always-multiline", objects: "only-multiline" }], // Consistent with Ruby style, and helps with cleaner diffs
      "semi": ["error", "never"], // Why add semicolons when they are not needed?
      "quotes": ["error", "double"], // Consistent with Ruby style
      "quote-props": ["error", "consistent-as-needed"], // Consistent with JSON style
      "no-new": "off", // Sometimes you just need to instantiate an object without assigning it
      "no-unused-vars": ["error", { argsIgnorePattern: "^_" }], // Sometimes it's clearer to include all parameters even if some aren't used
      "no-undef": "off", // This throws false positives with window/global variables
    }
  },
])