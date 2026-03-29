/**
 * Pandemonium Library Endpoint
 * =============================
 *
 * Exporting the library's functions.
 */
var choice = require('./choice.js');
var dangerouslyMutatingSample = require('./dangerously-mutating-sample.js');
var FisherYatesPermutation = require('./fisher-yates-permutation.js');
var fisherYatesSample = require('./fisher-yates-sample.js');
var geometricReservoirSample = require('./geometric-reservoir-sample.js');
var naiveSample = require('./naive-sample.js');
var random = require('./random.js');
var randomBoolean = require('./random-boolean.js');
var randomFloat = require('./random-float.js');
var randomIndex = require('./random-index.js');
var randomPair = require('./random-pair.js');
var randomOrderedPair = require('./random-ordered-pair.js');
var randomString = require('./random-string.js');
var randomTypedInt = require('./random-typed-int.js');
var reservoirSample = require('./reservoir-sample.js');
var weightedReservoirSample = require('./weighted-reservoir-sample.js');
var samplePairs = require('./sample-pairs.js');
var sampleOrderedPairs = require('./sample-ordered-pairs.js');
var sampleWithReplacements = require('./sample-with-replacements.js');
var shuffle = require('./shuffle.js');
var shuffleInPlace = require('./shuffle-in-place.js');
var weightedChoice = require('./weighted-choice.js');
var weightedRandomIndex = require('./weighted-random-index.js');

exports.choice = choice;
exports.createChoice = choice.createChoice;

exports.dangerouslyMutatingSample = dangerouslyMutatingSample;
exports.createDangerouslyMutatingSample =
  dangerouslyMutatingSample.createDangerouslyMutatingSample;

exports.FisherYatesPermutation = FisherYatesPermutation.FisherYatesPermutation;

exports.fisherYatesSample = fisherYatesSample;
exports.createFisherYatesSample = fisherYatesSample.createFisherYatesSample;

exports.geometricReservoirSample = geometricReservoirSample;
exports.createGeometricReservoirSample =
  geometricReservoirSample.createGeometricReservoirSample;

exports.naiveSample = naiveSample;
exports.createNaiveSample = naiveSample.createNaiveSample;

exports.random = random;
exports.createRandom = random.createRandom;

exports.randomBoolean = randomBoolean;
exports.createRandomBoolean = randomBoolean.createRandomBoolean;

exports.randomFloat = randomFloat;
exports.createRandomFloat = randomFloat.createRandomFloat;

exports.randomIndex = randomIndex;
exports.createRandomIndex = randomIndex.createRandomIndex;

exports.randomPair = randomPair;
exports.createRandomPair = randomPair.createRandomPair;

exports.randomOrderedPair = randomOrderedPair;
exports.createRandomOrderedPair = randomOrderedPair.createRandomOrderedPair;

exports.randomString = randomString;
exports.createRandomString = randomString.createRandomString;

exports.randomUint32 = randomTypedInt.randomUint32;
exports.createRandomUint32 = randomTypedInt.createRandomUint32;

exports.reservoirSample = reservoirSample;
exports.createReservoirSample = reservoirSample.createReservoirSample;
exports.ReservoirSampler = reservoirSample.ReservoirSampler;

exports.weightedReservoirSample = weightedReservoirSample;
exports.createWeightedReservoirSample =
  weightedReservoirSample.createWeightedReservoirSample;
exports.WeightedReservoirSampler =
  weightedReservoirSample.WeightedReservoirSampler;

exports.samplePairs = samplePairs;
exports.createSamplePairs = samplePairs.createSamplePairs;

exports.sampleOrderedPairs = sampleOrderedPairs;
exports.createSampleOrderedPairs = sampleOrderedPairs.createSampleOrderedPairs;

exports.sampleWithReplacements = sampleWithReplacements;
exports.createSampleWithReplacements =
  sampleWithReplacements.createSampleWithReplacements;

exports.shuffle = shuffle;
exports.createShuffle = shuffle.createShuffle;

exports.shuffleInPlace = shuffleInPlace;
exports.createShuffleInPlace = shuffleInPlace.createShuffleInPlace;

exports.weightedChoice = weightedChoice;
exports.createWeightedChoice = weightedChoice.createWeightedChoice;
exports.createCachedWeightedChoice = weightedChoice.createCachedWeightedChoice;

exports.weightedRandomIndex = weightedRandomIndex;
exports.createWeightedRandomIndex =
  weightedRandomIndex.createWeightedRandomIndex;
exports.createCachedWeightedRandomIndex =
  weightedRandomIndex.createCachedWeightedRandomIndex;
