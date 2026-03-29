/**
 * Pandemonium Choice
 * ===================
 *
 * Choice function.
 */
var createRandomIndex = require('./random-index.js').createRandomIndex;

/**
 * Creating a function returning a random item from the given array.
 *
 * @param  {function} rng - RNG function returning uniform random.
 * @return {function}     - The created function.
 */
function createChoice(rng) {
  var customRandomIndex = createRandomIndex(rng);

  /**
   * Random function.
   *
   * @param  {array}  array - Target array.
   * @return {any}
   */
  return function (array) {
    return array[customRandomIndex(array)];
  };
}

/**
 * Default choice using `Math.random`.
 */
var choice = createChoice(Math.random);

/**
 * Exporting.
 */
choice.createChoice = createChoice;
module.exports = choice;
