/**
 * Pandemonium Weighted Index
 * ===========================
 *
 * Function returning a random index from a weighted list of items.
 *
 * [Reference]:
 * http://eli.thegreenplace.net/2010/01/22/weighted-random-generation-in-python
 */

/**
 * Defaults.
 */
var DEFAULTS = {
  rng: Math.random,
  getWeight: null
};

/**
 * Function returning upper bound of value in the given sorted array. This
 * is the equivalent of python's `bisect_right`.
 *
 * @param  {array}  array - Target array.
 * @param  {number} value - Number to position.
 * @return {number}
 */
function upperBound(array, value) {
  var l = array.length,
    d,
    c,
    i = 0;

  while (l) {
    d = l >>> 1;
    c = i + d;

    if (value < array[c]) {
      l = d;
    } else {
      i = c + 1;
      l -= d + 1;
    }
  }

  return i;
}

/**
 * Creating a function returning a weighted random index from a cached
 * cumulative density function.
 *
 * This algorithm is more costly in space because it needs to store O(n)
 * items to cache the CDF but is way faster if one is going to need a random
 * weighted index several times from the same sequence.
 *
 * @param  {object|function} rngOrOptions - Either RNG function or options:
 * @param  {function}          rng        - Custom RNG.
 * @param  {function}          getWeight  - Weight getter.
 * @return {function}
 */
function createCachedWeightedRandomIndex(rngOrOptions, sequence) {
  var rng, options;

  if (typeof rngOrOptions === 'function') {
    rng = rngOrOptions;
    options = {};
  } else {
    rng = rngOrOptions.rng || DEFAULTS.rng;
    options = rngOrOptions;
  }

  var getWeight =
    typeof options.getWeight === 'function' ? options.getWeight : null;

  // Computing the cumulative density function of the sequence (CDF)
  var l = sequence.length;

  var CDF = new Float64Array(l);
  var total = 0;
  var weight;

  for (var i = 0; i < l; i++) {
    weight = getWeight ? getWeight(sequence[i], i) : sequence[i];
    total += weight;
    CDF[i] = total;
  }

  /**
   * Weighted random index from the given sequence.
   *
   * @return {number}
   */
  return function () {
    var random = rng() * total;

    return upperBound(CDF, random);
  };
}

/**
 * Creating a function returning a weighted random index.
 *
 * Note that this function uses the "King of the hill" algorithm which runs in
 * linear time O(n) and has some advantages, one being that one does not need
 * to know the weight's sum in advance. However, it may be slower that some
 * other methods because we have to run the RNG function n times.
 *
 * @param  {object|function} rngOrOptions - Either RNG function or options:
 * @param  {function}          rng        - Custom RNG.
 * @param  {function}          getWeight  - Weight getter.
 * @return {function}
 */
function createWeightedRandomIndex(rngOrOptions) {
  var rng, options;

  if (typeof rngOrOptions === 'function') {
    rng = rngOrOptions;
    options = {};
  } else {
    rng = rngOrOptions.rng || DEFAULTS.rng;
    options = rngOrOptions;
  }

  var getWeight =
    typeof options.getWeight === 'function' ? options.getWeight : null;

  /**
   * Weighted random index from the given sequence.
   *
   * @param  {array} sequence - Target sequence.
   * @return {number}
   */
  return function (sequence) {
    var total = 0;
    var winner = 0;
    var weight;

    for (var i = 0, l = sequence.length; i < l; i++) {
      weight = getWeight ? getWeight(sequence[i], i) : sequence[i];

      total += weight;

      if (rng() * total < weight) winner = i;
    }

    return winner;
  };
}

/**
 * Default weighted index using `Math.random`.
 */
var weightedRandomIndex = createWeightedRandomIndex(Math.random);

/**
 * Exporting.
 */
weightedRandomIndex.createCachedWeightedRandomIndex =
  createCachedWeightedRandomIndex;
weightedRandomIndex.createWeightedRandomIndex = createWeightedRandomIndex;
module.exports = weightedRandomIndex;
