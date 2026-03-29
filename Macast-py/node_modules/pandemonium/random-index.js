/**
 * Pandemonium Random Index
 * =========================
 *
 * Random index function.
 */

/**
 * Creating a function returning a random index from the given array.
 *
 * @param  {function} rng - RNG function returning uniform random.
 * @return {function}     - The created function.
 */
function createRandomIndex(rng) {
  /**
   * Random function.
   *
   * @param  {array|number}  array - Target array or length of the array.
   * @return {number}
   */
  return function (length) {
    if (typeof length !== 'number') length = length.length;

    return Math.floor(rng() * length);
  };
}

/**
 * Default random index using `Math.random`.
 */
var randomIndex = createRandomIndex(Math.random);

/**
 * Exporting.
 */
randomIndex.createRandomIndex = createRandomIndex;
module.exports = randomIndex;
