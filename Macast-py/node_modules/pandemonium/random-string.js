/**
 * Pandemonium Random String
 * ==========================
 *
 * Function generating random strings.
 */
var createRandom = require('./random.js').createRandom;

/**
 * Constants.
 */
var DEFAULT_ALPHABET =
  'abcdefghijklmnopqrstuvwxyz' + 'ABCDEFGHIJKLMNOPQRSTUVWXYZ' + '0123456789';

/**
 * Creating a function returning a random string composed from characters of
 * the given alphabet.
 *
 * @param  {function}     rng      - RNG function returning uniform random.
 * @param  {string|array} alphabet - Target alphabet.
 * @return {function}              - The created function.
 */
function createRandomString(rng, alphabet) {
  if (!alphabet) alphabet = DEFAULT_ALPHABET;

  var customRandom = createRandom(rng),
    randomCharacterIndex = customRandom.bind(null, 0, alphabet.length - 1);

  /**
   * Random string function.
   *
   * @param  {number} length - Desired string length.
   * @return {number}
   */
  return function (length) {
    if (arguments.length > 1) {
      // We want to generate a string of variable length
      length = customRandom(arguments[0], arguments[1]);
    }

    var characters = new Array(length);

    for (var i = 0; i < length; i++)
      characters[i] = alphabet[randomCharacterIndex()];

    return characters.join('');
  };
}

/**
 * Default random string using `Math.random`.
 */
var randomString = createRandomString(Math.random);

/**
 * Exporting.
 */
randomString.createRandomString = createRandomString;
module.exports = randomString;
