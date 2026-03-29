/**
 * Pandemonium Sample Pairs
 * =========================
 *
 * Algorithm to sample unordered pairs without replacement from the given
 * population.
 */
var utils = require('./utils.js');

/**
 * Creating a function returning a sample of k pairs using the provided RNG.
 *
 * @param  {function} rng - The RNG to use.
 * @return {function}     - The created function.
 */
function createSamplePairs(rng) {
  /**
   * Function returning sample of k pairs from given array or range.
   *
   * @param  {number} k              - Size of the sample.
   * @param  {array|number} sequence - Target sequence or its length.
   * @return {array}                 - The random sample.
   */
  return function (k, sequence) {
    var needItems = typeof sequence !== 'number';
    var n = needItems ? sequence.length : sequence;

    var key = utils.createPairKeyFunction(n);

    var items = new Set();
    var result = new Array(k);
    var size = 0;
    var i, j, o, tmp;

    while (items.size < k) {
      i = Math.floor(rng() * n);
      o = 1 + Math.floor(rng() * (n - 1));
      j = (i + o) % n;

      // Swapping coordinates to produce an unordered pair
      if (i > j) {
        tmp = i;
        i = j;
        j = tmp;
      }

      items.add(key(i, j));

      if (items.size > size) {
        result[size++] = needItems ? [sequence[i], sequence[j]] : [i, j];
      }
    }

    return result;
  };
}

/**
 * Default sample pairs using `Math.random`.
 */
var samplePairs = createSamplePairs(Math.random);

/**
 * Exporting.
 */
samplePairs.createSamplePairs = createSamplePairs;
module.exports = samplePairs;
