/**
 * Pandemonium Random Ordered Pair
 * ================================
 *
 * Random ordered pair function.
 */

/**
 * Creating a function returning a random ordered pair of the given array.
 *
 * @param  {function} rng - RNG function returning uniform random.
 * @return {function}     - The created function.
 */
function createRandomOrderedPair(rng) {
  /**
   * Random ordered pair function.
   *
   * @param  {array|number}  array - Target array or length of the array.
   * @return {number}
   */
  return function (array) {
    var needItems = typeof array !== 'number';

    var n = needItems ? array.length : array;

    if (n < 2)
      throw new Error(
        'pandemonium/random-ordered-pair: cannot draw a random ordered pair for length < 2.'
      );

    var i = Math.floor(rng() * n);
    var o = 1 + Math.floor(rng() * (n - 1));
    var j = (i + o) % n;

    if (needItems) return [array[i], array[j]];

    return [i, j];
  };
}

/**
 * Default random ordered pair using `Math.random`.
 */
var randomOrderedPair = createRandomOrderedPair(Math.random);

/**
 * Exporting.
 */
randomOrderedPair.createRandomOrderedPair = createRandomOrderedPair;
module.exports = randomOrderedPair;
