/**
 * Pandemonium Random Typed Int
 * =============================
 *
 * Functions to generated random typed integers such as uint32.
 */

/**
 * Constants.
 */
var MAX_UINT32 = Math.pow(2, 32) - 1;

function createRandomUint32(rng) {
  return function () {
    return Math.floor(rng() * MAX_UINT32);
  };
}

/**
 * Default random using `Math.random`.
 */
var randomUint32 = createRandomUint32(Math.random);

/**
 * Exporting.
 */
exports.createRandomUint32 = createRandomUint32;
exports.randomUint32 = randomUint32;
