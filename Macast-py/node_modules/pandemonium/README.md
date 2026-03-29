[![Build Status](https://github.com/Yomguithereal/pandemonium/workflows/Tests/badge.svg)](https://github.com/Yomguithereal/pandemonium/actions)

# Pandemonium

Pandemonium is a dead simple JavaScript/TypeScript library providing typical random-related functions such as `choice`, `sample` etc.

The library also provides a way to create any of the available functions using a custom random source ([seedrandom](https://www.npmjs.com/package/seedrandom), for instance).

# Installation

```
npm install --save pandemonium
```

# Usage

## Summary

_Typical helpers_

- [choice](#choice)
- [random](#random)
- [randomBoolean](#randomboolean)
- [randomFloat](#randomfloat)
- [randomIndex](#randomindex)
- [randomString](#randomstring)
- [randomUint32](#randomuint32)
- [randomPair](#randompair)
- [randomOrderedPair](#randomorderedpair)
- [shuffle](#shuffle)
- [shuffleInPlace](#shuffleinplace)
- [weightedChoice](#weightedchoice)
- [weightedRandomIndex](#weightedrandomindex)

_Sampling_

`n` being the number of items in the sampled sequence and `k` being the number of items to be sampled.

| Method                                                  | Time            | Memory | Note                                                                        |
| ------------------------------------------------------- | --------------- | ------ | --------------------------------------------------------------------------- |
| [dangerouslyMutatingSample](#dangerouslymutatingsample) | `O(k)`          | `O(k)` | Must be able to mutate given array to work.                                 |
| [fisherYatesSample](#fisheryatessample)                 | `O(n)`          | `O(n)` | Probably not a good idea.                                                   |
| [geometricReservoirSample](#geometricreservoirsample)   | `O(k*log(n/k))` | `O(k)` | Probably the best way of sampling from a random access data structure.      |
| [naiveSample](#naivesample)                             | `Ω(k)`, `O(∞)`  | `O(k)` | Only useful if `k << n`.                                                    |
| [reservoirSample](#reservoirsample)                     | `O(n)`          | `O(k)` | Useful if pulling a sample from a stream.                                   |
| [sampleWithReplacements](#samplewithreplacements)       | `O(k)`          | `O(k)` | Performant but allows replacements.                                         |
| [samplePairs](#samplepairs)                             | `Ω(k)`, `O(∞)`  | `O(k)` | Variant of [naiveSample](#naivesample) for unordered pairs.                 |
| [sampleOrderedPairs](#sampleorderedpairs)               | `Ω(k)`, `O(∞)`  | `O(k)` | Variant of [naiveSample](#naivesample) for ordered pairs.                   |
| [weightedReservoirSample](#weightedreservoirsample)     | `O(n)`          | `O(k)` | Variant of [reservoirSample](#reservoirsample) working with weighted items. |

## choice

Function returning a random item from the given array.

```js
import choice from 'pandemonium/choice';
// Or
import {choice} from 'pandemonium';

choice(['apple', 'orange', 'pear']);
>>> 'orange'

// To create your own function using custom RNG
import {createChoice} from 'pandemonium/choice';

const customChoice = createChoice(rng);
```

## random

Function returning a random integer between given `a` & `b`.

```js
import random from 'pandemonium/random';
// Or
import {random} from 'pandemonium';

random(3, 7);
>>> 4

// To create your own function using custom RNG
import {createRandom} from 'pandemonium/random';

const customRandom = createRandom(rng);
```

## randomBoolean

Function returning a random boolean.

```js
import randomBoolean from 'pandemonium/random-boolean';
// Or
import {randomBoolean} from 'pandemonium';

randomBoolean();
>>> true

// To create your own function using custom RNG
import {createrandomBoolean} from 'pandemonium/random-boolean';

const customRandomBoolean = createRandomBoolean(rng);
```

## randomFloat

Function returning a random float between given `a` & `b`.

```js
import randomFloat from 'pandemonium/random-float';
// Or
import {randomFloat} from 'pandemonium';

randomFloat(-5, 55);
>>> 6.756482

// To create your own function using custom RNG
import {createRandomFloat} from 'pandemonium/random-float';

const customRandomFloat = createRandomFloat(rng);
```

## randomIndex

Function returning a random index of the given array.

```js
import randomIndex from 'pandemonium/random-index';
// Or
import {randomIndex} from 'pandemonium';

randomIndex(['apple', 'orange', 'pear']);
>>> 1

// Alternatively, you can give the array's length instead
randomIndex(3);
>>> 2

// To create your own function using custom RNG
import {createRandomIndex} from 'pandemonium/random-index';

const customRandomIndex = createRandomIndex(rng);
```

## randomString

Function returning a random string.

```js
import randomString from 'pandemonium/random-string';
// Or
import {randomString} from 'pandemonium';

// To generate a string of fixed length
randomString(5);
>>> 'gHepM'

// To generate a string of variable length
randomString(3, 7);
>>> 'hySf3'

// To create your own function using custom RNG
import {createRandomString} from 'pandemonium/random-string';

const customRandomString = createRandomString(rng);

// If you need a custom alphabet
const customRandomString = createRandomString(rng, 'ATGC');
```

## randomUint32

Function returning a random unsigned 32bits number.

```js
import {randomUint32} from 'pandemonium/random-typed-int';
// Or
import {randomUint32} from 'pandemonium';

randomUint32();
>>> 397536

// To create your own function using custom RNG
import {createRandomUint32} from 'pandemonium/random-typed-int';

const customRandomUint32 = createRandomUint32(rng);
```

## randomPair

Function returning a random pair from the given array.

Note that this function will return unordered pairs (i.e. `[0, 1]` and `[1, 0]` are to be considered the same) and will not return pairs containing twice the same item (i.e. `[0, 0]`).

```js
import randomPair from 'pandemonium/random-pair';
// Or
import {randomPair} from 'pandemonium';

randomPair(['apple', 'orange', 'pear', 'cherry']);
>>> ['orange', 'cherry']

// Alternatively, you can give the array's length instead and get a pair of indices
randomPair(4);
>>> [1, 3]

// To create your own function using custom RNG
import {createRandomPair} from 'pandemonium/random-pair';

const customRandomPair = createRandomPair(rng);
```

## randomOrderedPair

Function returning a random ordered pair (i.e. `[0, 1]` won't be considered to be the same as `[1, 0]`) from the given array.

```js
import randomOrderedPair from 'pandemonium/random-ordered-pair';
// Or
import {randomOrderedPair} from 'pandemonium';

randomOrderedPair(['apple', 'orange', 'pear', 'cherry']);
>>> ['cherry', 'apple']

// Alternatively, you can give the array's length instead and get a pair of indices
randomOrderedPair(4);
>>> [3, 0]

// To create your own function using custom RNG
import {createRandomOrderedPair} from 'pandemonium/random-ordered-pair';

const customRandomPair = createRandomOrderedPair(rng);
```

## shuffle

Function returning a shuffled version of the given array using the Fisher-Yates algorithm.

If what you need is to shuffle the original array in place, check out [`shuffleInPlace`](#shuffleinplace).

```js
import shuffle from 'pandemonium/shuffle';
// Or
import {shuffle} from 'pandemonium';

shuffle(['apple', 'orange', 'pear', 'pineapple']);
>>> ['pear', 'orange', 'apple', 'pineapple']

// To create your own function using custom RNG
import {createShuffle} from 'pandemonium/shuffle';

const customShuffle = createShuffle(rng);
```

## shuffleInPlace

Function shuffling the given array in place using the Fisher-Yates algorithm.

```js
import shuffleInPlace from 'pandemonium/shuffle-in-place';
// Or
import {shuffleInPlace} from 'pandemonium';

const array = ['apple', 'orange', 'pear', 'pineapple'];
shuffleInPlace(array);

// Array was mutated:
array >>> ['pear', 'orange', 'apple', 'pineapple'];

// To create your own function using custom RNG
import {createShuffleInPlace} from 'pandemonium/shuffle-in-place';

const customShuffleInPlace = createShuffleInPlace(rng);
```

## weightedChoice

Function returning a random item from the given array of weights.

Note that weights don't need to be relative.

```js
import weightedChoice from 'pandemonium/weighted-choice';
// Or
import {weightedChoice} from 'pandemonium';

const array = [.1, .1, .4, .3, .1];
weightedChoice(array);
>>> .4

// To create your own function using custom RNG
import {createWeightedChoice} from 'pandemonium/weighted-choice';

const customWeightedChoice = createWeightedChoice(rng);

// If you have an array of objects
const customWeightedChoice = createWeightedChoice({
  rng: rng,
  getWeight: (item, index) => {
    return item.weight;
  }
});

const array = [{fruit: 'pear', weight: 4}, {fruit: 'apple', weight: 30}];
customWeightedChoice(array);
>>> 'apple'


// If you intent to call the function multiple times on the same array,
// you should use the cached version instead:
import {createCachedWeightedChoice} from 'pandemonium/weighted-choice';

const array = [.1, .1, .4, .3, .1];
const customWeightedChoice = createCachedWeightedChoice(rng, array);

customWeightedChoice();
>>> .3
```

## weightedRandomIndex

Function returning a random index from the given array of weights.

Note that weights don't need to be relative.

```js
import weightedRandomIndex from 'pandemonium/weighted-random-index';
// Or
import {weightedRandomIndex} from 'pandemonium';

const array = [.1, .1, .4, .3, .1];
weightedRandomIndex(array);
>>> 2

// To create your own function using custom RNG
import {createWeightedRandomIndex} from 'pandemonium/weighted-random-index';

const customWeightedRandomIndex = createWeightedRandomIndex(rng);

// If you have an array of objects
const customWeightedRandomIndex = createWeightedRandomIndex({
  rng: rng,
  getWeight: (item, index) => {
    return item.weight;
  }
});

const array = [{fruit: 'pear', weight: 4}, {fruit: 'apple', weight: 30}];
customWeightedRandomIndex(array);
>>> 1


// If you intent to call the function multiple times on the same array,
// you should use the cached version instead:
import {createCachedWeightedRandomIndex} from 'pandemonium/weighted-random-index';

const array = [.1, .1, .4, .3, .1];
const customWeightedRandomIndex = createCachedWeightedRandomIndex(rng, array);

customWeightedRandomIndex();
>>> 3
```

## dangerouslyMutatingSample

Function returning a random sample of size `k` from the given array.

This function runs in `O(k)` time & memory but is somewhat dangerous because it will mutate the given array while performing its Fisher-Yates shuffle before reverting the mutations at the end.

```js
import dangerouslyMutatingSample from 'pandemonium/dangerously-mutating-sample';
// Or
import {dangerouslyMutatingSample} from 'pandemonium';

dangerouslyMutatingSample(2, ['apple', 'orange', 'pear', 'pineapple']);
>>> ['apple', 'pear']

// To create your own function using custom RNG
import {createDangerouslyMutatingSample} from 'pandemonium/dangerously-mutating-sample';

const customSample = createDangerouslyMutatingSample(rng);
```

## fisherYatesSample

Function returning a random sample of size `k` from the given array.

This function uses a partial Fisher-Yates shuffle and therefore runs in `O(k)` time but must clone the given array to work, which adds `O(n)` time & memory.

```js
import fisherYatesSample from 'pandemonium/fisher-yates-sample';
// Or
import {fisherYatesSample} from 'pandemonium';

fisherYatesSample(2, ['apple', 'orange', 'pear', 'pineapple']);
>>> ['apple', 'pear']

// To create your own function using custom RNG
import {createFisherYatesSample} from 'pandemonium/fisherYatesSample';

const customFisherYatesSample = createFisherYatesSample(rng);
```

## geometricReservoirSample

Function returning a random sample of size `k` from the given array.

This function runs in `O(k * (1 + log(n / k)))` time & `O(k)` memory using "Algorithm L" taken from the following paper:

> Li, Kim-Hung. "Reservoir-sampling algorithms of time complexity O(n (1+ log (N/n)))." ACM Transactions on Mathematical Software (TOMS) 20.4 (1994): 481-493.

Note that this function is able to sample indices without requiring you to represent the range of indices in memory.

```js
import geometricReservoirSample from 'pandemonium/geometric-reservoir-sample';
// Or
import {geometricReservoirSample} from 'pandemonium';

geometricReservoirSample(2, ['apple', 'orange', 'pear', 'pineapple']);
>>> ['apple', 'pear']

// Alternatively, you can pass a length and get a sample of indices back
geometricReservoirSample(2, 4);
>>> [0, 2]

// To create your own function using custom RNG
import {createGeometricReservoirSample} from 'pandemonium/geometric-reservoir-sample';

const customSample = createGeometricReservoirSample(rng);
```

## naiveSample

Function returning a random sample of size `k` from the given array.

This function works by keeping a `Set` of the already picked items and choosing a random item in the array until we have the desired `k` items.

While it is a good pick for cases when `k` is little compared to the size of your array, this function will see its performance drop really fast when `k` becomes proportionally bigger.

Note that this function is able to sample indices without requiring you to represent the range of indices in memory.

```js
import naiveSample from 'pandemonium/naive-sample';
// Or
import {naiveSample} from 'pandemonium';

naiveSample(2, ['apple', 'orange', 'pear', 'pineapple']);
>>> ['apple', 'pear']

// Alternatively, you can pass a length and get a sample of indices back
naiveSample(2, 4);
>>> [0, 2]

// To create your own function using custom RNG
import {createNaiveSample} from 'pandemonium/naive-sample';

const customSample = createNaiveSample(rng);
```

## reservoirSample

Function returning a random sample of size `k` from the given array.

This function runs in `O(n)` time and `O(k)` memory.

A helper class able to work on an arbitrary stream of data that does not need to fit into memory is also available if you need it.

```js
import reservoirSample from 'pandemonium/reservoir-sample';
// Or
import {reservoirSample} from 'pandemonium';

reservoirSample(2, ['apple', 'orange', 'pear', 'pineapple']);
>>> ['apple', 'pear']

// To create your own function using custom RNG
import {createReservoirSample} from 'pandemonium/reservoir-sample';

const customReservoirSample = createReservoirSample(rng);

// To use the helper class
import {ReservoirSampler} from 'pandemonium/reservoir-sample';

// If RNG is not provided, will default to Math.random
const sampler = new ReservoirSampler(10, rng);

for (const value of lazyIterable) {
  sampler.process(value);
}

// To retrieve the sample once every value has been consumed
const sample = sampler.end();
```

## sampleWithReplacements

Function returning a random sample of size `k` with replacements from the given array. This prosaically means that an items from the array might occur several times in the resulting sample.

The function runs in both `O(k)` time & space complexity.

```js
import sampleWithReplacements from 'pandemonium/sample-with-replacements';
// Or
import {sampleWithReplacements} from 'pandemonium';

sampleWithReplacements(3, ['apple', 'orange', 'pear', 'pineapple']);
>>> ['apple', 'pear', 'apple']

// To create your own function using custom RNG
import {createSampleWithReplacements} from 'pandemonium/sample-with-replacements';

const customSample = createSampleWithReplacements(rng);
```

## samplePairs

Function returning a random sample of `k` unique unordered pairs from the given array.

It works by storing a unique key created from the picked pairs, making it a specialized variant of [naiveSample](#naivesample).

It is usually quite efficient because when sampling pairs, the total size of the population, being combinatorial, is often magnitudes larger than the size of the sample we need to retrieve.

Note finally that this function is able to sample pairs of indices without requiring you to represent the range of indices in memory.

```js
import samplePairs from 'pandemonium/sample-pairs';
// Or
import {samplePairs} from 'pandemonium';

samplePairs(2, ['apple', 'orange', 'pear', 'pineapple']);
>>>  [['apple', 'pear'], ['orange', 'pear']]

// Alternatively, you can pass a length and get a sample of pairs of indices
samplePairs(2, 4);
>>> [[0, 2], [1, 2]]

// To create your own function using custom RNG
import {createSamplePairs} from 'pandemonium/sample-pairs';

const customSamplePairs = createSamplePairs(rng);
```

## sampleOrderedPairs

Function returning a random sample of `k` unique ordered pairs from the given array.

It works by storing a unique key created from the picked pairs, making it a specialized variant of [naiveSample](#naivesample).

It is usually quite efficient because when sampling pairs, the total size of the population, being combinatorial, is often magnitudes larger than the size of the sample we need to retrieve.

Note finally that this function is able to sample pairs of indices without requiring you to represent the range of indices in memory.

```js
import sampleOrderedPairs from 'pandemonium/sample-pairs';
// Or
import {sampleOrderedPairs} from 'pandemonium';

sampleOrderedPairs(2, ['apple', 'orange', 'pear', 'pineapple']);
>>>  [['apple', 'pear'], ['pear', 'orange']]

// Alternatively, you can pass a length and get a sample of pairs of indices
sampleOrderedPairs(2, 4);
>>> [[0, 2], [2, 1]]

// To create your own function using custom RNG
import {createSampleOrderedPairs} from 'pandemonium/sample-ordered-pairs';

const customSampleOrderedPairs = createSampleOrderedPairs(rng);
```

## weightedReservoirSample

Function returning a random sample of size `k` from a given array of weighted items.

The result is a sample without replacement, which, in the case of weighted items, has been chosen to mean that subsequent items are picked based on the proportional total weight of the remaining items.

We use algorithm "A-ES" from the following papers:

> Pavlos S. Efraimidis, Paul G. Spirakis. "Weighted random sampling with a reservoir." https://arxiv.org/pdf/1012.0256.pdf

> Pavlos S. Efraimidis. "Weighted Random Sampling over Data Streams."

This function runs in `O(n)` time and `O(k)` memory.

A helper class working able to work on an arbitrary stream of data that does not need to fit into memory is also available if you need it.

```js
import weightedReservoirSample from 'pandemonium/weighted-reservoir-sample';
// Or
import {weightedReservoirSample} from 'pandemonium';

weightedReservoirSample(2, [.1, .1, .4, .3, .05]);
>>> [.3, .4]

// To create your own function using custom RNG
import {createWeightedReservoirSample} from 'pandemonium/weighted-reservoir-sample';

const customWeightedReservoirSample = createWeightedReservoirSample(rng);

// To sample arbitrary items
const data = [{label: 'orange', importance: 34}, ...];

const customWeightedReservoirSample = createWeightedReservoirSample({
  getWeight: item => item.importance
});

// To use the helper class
import {WeightedReservoirSampler} from 'pandemonium/weighted-reservoir-sample';

// If RNG is not provided, will default to Math.random
const sampler = new WeightedReservoirSampler(10, {rng, getWeight});

for (const value of lazyIterable) {
  sampler.process(value);
}

// To retrieve the sample once every value has been consumed
const sample = sampler.end();
```

# Contribution

Contributions are obviously welcome. Please be sure to lint the code & add the relevant unit tests before submitting any PR.

```
git clone git@github.com:Yomguithereal/pandemonium.git
cd pandemonium
npm install

# To lint the code
npm run lint

# To run the unit tests
npm test
```

# License

[MIT](LICENSE.txt)
