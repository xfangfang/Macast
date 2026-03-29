/**
 * Pandemonium Shuffle In Place
 * =============================
 *
 * Shuffle function applying the Fisher-Yates algorithm to the provided array.
 */
var createRandom = require('./random.js').createRandom;

/**
 * Creating a function returning the given array shuffled.
 *
 * @param  {function} rng - The RNG to use.
 * @return {function}     - The created function.
 */
function createShuffleInPlace(rng) {
  var customRandom = createRandom(rng);

  /**
   * Function returning the shuffled array.
   *
   * @param  {array}  sequence - Target sequence.
   * @return {array}           - The shuffled sequence.
   */
  return function (sequence) {
    var length = sequence.length,
      lastIndex = length - 1;

    var index = -1;

    while (++index < length) {
      var r = customRandom(index, lastIndex),
        value = sequence[r];

      sequence[r] = sequence[index];
      sequence[index] = value;
    }
  };
}

/**
 * Default shuffle in place using `Math.random`.
 */
var shuffleInPlace = createShuffleInPlace(Math.random);

/**
 * Exporting.
 */
shuffleInPlace.createShuffleInPlace = createShuffleInPlace;
module.exports = shuffleInPlace;
