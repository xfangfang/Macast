/**
 * Pandemonium Random Boolean
 * ===========================
 *
 * Function used to return a random boolean.
 */

/**
 * Creating a function returning a random boolean.
 *
 * @param  {function} rng - RNG function returning uniform random.
 * @return {function}     - The created function.
 */
function createRandomBoolean(rng) {
  /**
   * Random boolean function.
   *
   * @return {boolean}
   */
  return function () {
    return rng() < 0.5;
  };
}

/**
 * Default random boolean using `Math.random`.
 */
var randomBoolean = createRandomBoolean(Math.random);

/**
 * Exporting.
 */
randomBoolean.createRandomBoolean = createRandomBoolean;
module.exports = randomBoolean;
