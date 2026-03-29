/**
 * Pandemonium Random Float
 * =========================
 *
 * Random float function.
 */

/**
 * Creating a function returning a random float such as a <= N <= b.
 *
 * @param  {function} rng - RNG function returning uniform random.
 * @return {function}     - The created function.
 */
function createRandomFloat(rng) {
  /**
   * Random float function.
   *
   * @param  {number} a - From.
   * @param  {number} b - To.
   * @return {number}
   */
  return function (a, b) {
    return a + rng() * (b - a);
  };
}

/**
 * Default random using `Math.random`.
 */
var randomFloat = createRandomFloat(Math.random);

/**
 * Exporting.
 */
randomFloat.createRandomFloat = createRandomFloat;
module.exports = randomFloat;
