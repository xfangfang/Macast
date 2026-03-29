/**
 * Pandemonium Dangerously Mutating Sample
 * ========================================
 *
 * Performant sampling function running in O(k) memory & time but mutating the
 * given array before reversing the mutations at the end of the process.
 */
var createRandom = require('./random.js').createRandom;

/**
 * Creating a function returning a sample of size k using the provided RNG.
 *
 * @param  {function} rng - The RNG to use.
 * @return {function}     - The created function.
 */
function createDangerouslyMutatingSample(rng) {
  var customRandom = createRandom(rng);

  /**
   * Function returning sample of size k from array.
   *
   * @param  {number} k        - Size of the sample.
   * @param  {array}  sequence - Target sequence.
   * @return {array}           - The random sample.
   */
  return function (k, sequence) {
    if (k >= sequence.length) return sequence.slice();

    var result = new Array(k),
      swaps = new Array(k),
      lastIndex = sequence.length - 1;

    var index = -1,
      value,
      swap,
      r;

    while (++index < k) {
      r = customRandom(index, lastIndex);
      value = sequence[r];

      sequence[r] = sequence[index];
      sequence[index] = value;
      result[index] = value;

      // Storing the swap so we can reverse it
      swaps[index] = r;
    }

    // Reversing the mutations
    while (--index >= 0) {
      swap = swaps[index];
      value = sequence[index];

      sequence[index] = sequence[swap];
      sequence[swap] = value;
    }

    return result;
  };
}

/**
 * Default dangerous sample using `Math.random`.
 */
var dangerouslyMutatingSample = createDangerouslyMutatingSample(Math.random);

/**
 * Exporting.
 */
dangerouslyMutatingSample.createDangerouslyMutatingSample =
  createDangerouslyMutatingSample;
module.exports = dangerouslyMutatingSample;
