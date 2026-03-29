/**
 * Pandemonium Random Pair
 * ========================
 *
 * Random pair function.
 */

/**
 * Creating a function returning a random pair of the given array.
 *
 * @param  {function} rng - RNG function returning uniform random.
 * @return {function}     - The created function.
 */
function createRandomPair(rng) {
  /**
   * Random pair function.
   *
   * @param  {array|number}  array - Target array or length of the array.
   * @return {number}
   */
  return function (array) {
    var needItems = typeof array !== 'number';

    var n = needItems ? array.length : array;

    if (n < 2)
      throw new Error(
        'pandemonium/random-pair: cannot draw a random pair for length < 2.'
      );

    var i = Math.floor(rng() * n);
    var o = 1 + Math.floor(rng() * (n - 1));
    var j = (i + o) % n;

    var tmp;

    // Swapping coordinates to produce an unordered pair
    if (i > j) {
      tmp = i;
      i = j;
      j = tmp;
    }

    if (needItems) return [array[i], array[j]];

    return [i, j];
  };
}

/**
 * Default random pair using `Math.random`.
 */
var randomPair = createRandomPair(Math.random);

/**
 * Exporting.
 */
randomPair.createRandomPair = createRandomPair;
module.exports = randomPair;
