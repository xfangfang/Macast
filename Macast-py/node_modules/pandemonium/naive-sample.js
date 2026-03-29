/**
 * Pandemonium Naive Sample
 * =========================
 *
 * Naive sampling function storing the already picked values in a Set.
 * Performance of this function will decrease dramatically when `k` is a
 * high proportion of `n`.
 */
var createRandomIndex = require('./random-index.js').createRandomIndex;
var utils = require('./utils.js');

/**
 * Creating a function returning a sample of size k using the provided RNG.
 *
 * @param  {function} rng - The RNG to use.
 * @return {function}     - The created function.
 */
function createNaiveSample(rng) {
  var customRandomIndex = createRandomIndex(rng);

  /**
   * Function returning sample of size k from array.
   *
   * @param  {number} k              - Size of the sample.
   * @param  {array|number} sequence - Target sequence or its length.
   * @return {array}                 - The random sample.
   */
  return function (k, sequence) {
    var needItems = typeof sequence !== 'number';

    if (needItems) {
      if (k >= sequence.length) return sequence.slice();
    } else if (k >= sequence) {
      return utils.indices(sequence);
    }

    var items = new Set();
    var result = new Array(k);
    var size = 0;
    var index;

    while (items.size < k) {
      index = customRandomIndex(sequence);

      items.add(index);

      if (items.size > size) {
        result[size++] = needItems ? sequence[index] : index;
      }
    }

    return result;
  };
}

/**
 * Default naive sample using `Math.random`.
 */
var naiveSample = createNaiveSample(Math.random);

/**
 * Exporting.
 */
naiveSample.createNaiveSample = createNaiveSample;
module.exports = naiveSample;
