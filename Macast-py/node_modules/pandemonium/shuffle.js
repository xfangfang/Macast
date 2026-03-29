/**
 * Pandemonium Shuffle
 * ====================
 *
 * Shuffle function which is basically just applying the Fisher-Yates sampling
 * function over the whole array.
 */
var createShuffleInPlace =
  require('./shuffle-in-place.js').createShuffleInPlace;

/**
 * Creating a function returning the given array shuffled.
 *
 * @param  {function} rng - The RNG to use.
 * @return {function}     - The created function.
 */
function createShuffle(rng) {
  var customShuffleInPlace = createShuffleInPlace(rng);

  /**
   * Function returning the shuffled array.
   *
   * @param  {array}  sequence - Target sequence.
   * @return {array}           - The shuffled sequence.
   */
  return function (sequence) {
    var copy = sequence.slice();
    customShuffleInPlace(copy);

    return copy;
  };
}

/**
 * Default shuffle using `Math.random`.
 */
var shuffle = createShuffle(Math.random);

/**
 * Exporting.
 */
shuffle.createShuffle = createShuffle;
module.exports = shuffle;
