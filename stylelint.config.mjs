/** @type {import("stylelint").Config} */
export default {
  extends: ["stylelint-config-standard-scss"],
  rules: {
    "declaration-block-no-redundant-longhand-properties": null, // It's so much easier to read margin when it has 4 values rather than trying to remember what having 3 means
    "shorthand-property-no-redundant-values": null, // As above
    "selector-class-pattern": null, // I've got a system okay!
    "selector-type-no-unknown": null, // We use some custom elements
  }
}
