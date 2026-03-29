/**
 * This file is a customized loader for the lbugjs.node native module.
 * It is used to load the native module with the correct flags on Linux so that
 * extension loading works correctly.
 * @module lbug_native
 * @private
 */

const process = require("process");
const constants = require("constants");
const join = require("path").join;

const lbugNativeModule = { exports: {} };
const modulePath = join(__dirname, "lbugjs.node");
if (process.platform === "linux") {
  process.dlopen(
    lbugNativeModule,
    modulePath,
    constants.RTLD_LAZY | constants.RTLD_GLOBAL
  );
} else {
  process.dlopen(lbugNativeModule, modulePath);
}

module.exports = lbugNativeModule.exports;
