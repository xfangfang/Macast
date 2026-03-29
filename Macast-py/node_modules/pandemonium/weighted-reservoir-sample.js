/**
 * Pandemonium Weighted Reservoir Sample
 * ======================================
 *
 * Weighted variant of reservoir sampling, using algorithm "A-ES" from the
 * following papers:
 *
 * 1. Pavlos S. Efraimidis, Paul G. Spirakis. "Weighted random sampling with a reservoir."
 * 2. Pavlos S. Efraimidis. "Weighted Random Sampling over Data Streams."
 *
 * Note that this algorithm picks a sample of weighted items without replacement,
 * i.e. we subtract to the total sum of weights the weight of already selected
 * items for subsequent picks.
 *
 * [Reference]:
 * https://doi.org/10.1016/j.ipl.2005.11.003
 * https://arxiv.org/pdf/1012.0256.pdf
 */
var FixedReverseHeap = require('mnemonist/fixed-reverse-heap');

/**
 * Helpers.
 */

function comparator(a, b) {
  a = a[0];
  b = b[0];

  if (a > b) return -1;
  if (a < b) return 1;

  return 0;
}

/**
 * Helper class.
 */
function WeightedReservoirSampler(k, rngOrOptions) {
  var rng, options;

  if (typeof rngOrOptions === 'function') {
    rng = rngOrOptions;
    options = {};
  } else {
    rng = rngOrOptions.rng || Math.random;
    options = rngOrOptions;
  }

  var getWeight =
    typeof options.getWeight === 'function' ? options.getWeight : null;

  this.size = 0;
  this.rng = rng;
  this.getWeight = getWeight;
  this.heap = new FixedReverseHeap(Array, comparator, k);
  this.done = false;
}

WeightedReservoirSampler.prototype.process = function (item) {
  if (this.done) {
    throw new Error(
      'pandemonium/WeightedReservoirSampler: this sampler has returned its result and cannot be used anymore.'
    );
  }

  var u = this.rng();
  var w = item;

  if (this.getWeight) w = this.getWeight(item, this.size);

  var ki = Math.pow(u, 1 / w);

  this.heap.push([ki, item]);

  this.size++;
};

WeightedReservoirSampler.prototype.end = function () {
  this.done = true;

  var consumed = this.heap.consume();
  var l = consumed.length;

  var result = new Array(l);

  for (var i = 0; i < l; i++) result[i] = consumed[i][1];

  return result;
};

/**
 * Creating a function returning a weighted sample of size n using the provided RNG.
 *
 * @param  {function} rng - The RNG to use.
 * @return {function}     - The created function.
 */
function createWeightedReservoirSample(rngOrOptions) {
  var rng, options;

  if (typeof rngOrOptions === 'function') {
    rng = rngOrOptions;
    options = {};
  } else {
    rng = rngOrOptions.rng || Math.random;
    options = rngOrOptions;
  }

  var getWeight =
    typeof options.getWeight === 'function' ? options.getWeight : null;

  /**
   * Function returning weighted sample of size n from array.
   *
   * @param  {number} k              - Size of the sample.
   * @param  {array|number} sequence - Target sequence or its length.
   * @return {array}                 - The random sample.
   */
  return function (k, sequence) {
    var heap = new FixedReverseHeap(Array, comparator, k);

    var l = sequence.length;
    var item, i, u, w, ki;

    for (i = 0; i < l; i++) {
      u = rng();
      item = sequence[i];
      w = item;

      if (getWeight) w = getWeight(w, i);

      ki = Math.pow(u, 1 / w);

      heap.push([ki, item]);
    }

    var consumed = heap.consume();
    l = consumed.length;

    var result = new Array(l);

    for (i = 0; i < l; i++) result[i] = consumed[i][1];

    return result;
  };
}

/**
 * Default reservoir sample using `Math.random`.
 */
var weightedReservoirSample = createWeightedReservoirSample(Math.random);

/**
 * Exporting.
 */
weightedReservoirSample.createWeightedReservoirSample =
  createWeightedReservoirSample;
weightedReservoirSample.WeightedReservoirSampler = WeightedReservoirSampler;
module.exports = weightedReservoirSample;
