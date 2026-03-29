/**
 * Pandemonium Weighted Choice
 * ============================
 *
 * Function returning a random item from a weighted list.
 */
var lib = require('./weighted-random-index.js');

/**
 * Creating a function returning a weighted random item from a cached
 * cumulative density function.
 *
 * @param  {object|function} rngOrOptions - Either RNG function or options:
 * @param  {function}          rng        - Custom RNG.
 * @param  {function}          getWeight  - Weight getter.
 * @return {function}
 */
function createCachedWeightedChoice(rngOrOptions, sequence) {
  var randomIndex = lib.createCachedWeightedRandomIndex(rngOrOptions, sequence);

  /**
   * Weighted random item from the given sequence.
   *
   * @return {number}
   */
  return function () {
    var index = randomIndex();

    return sequence[index];
  };
}

/**
 * Creating a function returning a weighted random item.
 *
 * @param  {object|function} rngOrOptions - Either RNG function or options:
 * @param  {function}          rng        - Custom RNG.
 * @param  {function}          getWeight  - Weight getter.
 * @return {function}
 */
function createWeightedChoice(rngOrOptions) {
  var randomIndex = lib.createWeightedRandomIndex(rngOrOptions);

  /**
   * Weighted random item from the given sequence.
   *
   * @param  {array} sequence - Target sequence.
   * @return {number}
   */
  return function (sequence) {
    var index = randomIndex(sequence);

    return sequence[index];
  };
}

/**
 * Default weighted choice using `Math.random`.
 */
var weightedChoice = createWeightedChoice(Math.random);

/**
 * Exporting.
 */
weightedChoice.createCachedWeightedChoice = createCachedWeightedChoice;
weightedChoice.createWeightedChoice = createWeightedChoice;
module.exports = weightedChoice;
