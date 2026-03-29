/**
 * Pandemonium Reservoir Sample
 * =============================
 *
 * Reservoir sampling function.
 *
 * [Reference]:
 * https://en.wikipedia.org/wiki/Reservoir_sampling#Simple_algorithm
 */
var createRandomIndex = require('./random-index.js').createRandomIndex;

/**
 * Helper class.
 */
function ReservoirSampler(k, rng) {
  if (!rng) rng = Math.random;

  this.randomIndex = createRandomIndex(rng);
  this.k = k;
  this.size = 0;
  this.sample = new Array(k);
  this.done = false;
}

ReservoirSampler.prototype.process = function (item) {
  if (this.done) {
    throw new Error(
      'pandemonium/ReservoirSampler: this sampler has returned its result and cannot be used anymore.'
    );
  }

  if (this.size < this.k) {
    this.sample[this.size++] = item;

    return;
  }

  var j = this.randomIndex(this.size);

  if (j < this.k) this.sample[j] = item;

  this.size++;
};

ReservoirSampler.prototype.end = function () {
  this.done = true;

  if (this.size < this.k) this.sample.length = this.size;

  return this.sample;
};

/**
 * Creating a function returning a sample of size n using the provided RNG.
 *
 * @param  {function} rng - The RNG to use.
 * @return {function}     - The created function.
 */
function createReservoirSample(rng) {
  var customRandomIndex = createRandomIndex(rng);

  /**
   * Function returning sample of size n from array.
   *
   * @param  {number} k              - Size of the sample.
   * @param  {array|number} sequence - Target sequence or its length.
   * @return {array}                 - The random sample.
   */
  return function (k, sequence) {
    var n = sequence.length;

    // Sample size gte sequence's length
    if (k >= n) return sequence.slice();

    var sample = new Array(k);
    var i, j;

    for (i = 0; i < k; i++) sample[i] = sequence[i];

    for (; i < n; i++) {
      j = customRandomIndex(i);

      if (j < k) sample[j] = sequence[i];
    }

    return sample;
  };
}

/**
 * Default reservoir sample using `Math.random`.
 */
var reservoirSample = createReservoirSample(Math.random);

/**
 * Exporting.
 */
reservoirSample.createReservoirSample = createReservoirSample;
reservoirSample.ReservoirSampler = ReservoirSampler;
module.exports = reservoirSample;
