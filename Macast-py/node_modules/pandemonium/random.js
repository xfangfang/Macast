/**
 * Pandemonium Random
 * ===================
 *
 * Random function.
 */

/**
 * Creating a function returning a random integer such as a <= N <= b.
 *
 * @param  {function} rng - RNG function returning uniform random.
 * @return {function}     - The created function.
 */
function createRandom(rng) {
  /**
   * Random function.
   *
   * @param  {number} a - From.
   * @param  {number} b - To.
   * @return {number}
   */
  return function (a, b) {
    return a + Math.floor(rng() * (b - a + 1));
  };
}

/**
 * Default random using `Math.random`.
 */
var random = createRandom(Math.random);

/**
 * Exporting.
 */
random.createRandom = createRandom;
module.exports = random;
