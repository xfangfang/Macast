/**
 * Pandemonium Fisher-Yates Permutation
 * =====================================
 *
 * Helper class that can be used to cycle through Fisher-Yates permutations
 * using a convenient interface.
 */
var typed = require('mnemonist/utils/typed-arrays');

function FisherYatesPermutation(length, rng) {
  if (!rng) rng = Math.random;

  var PointerArray = typed.getPointerArray(length);
  this.PointerArray = PointerArray;

  this.length = length;
  this.indices = new PointerArray(length);
  this.rng = rng;

  this.reset();
  this.reorder();
}

FisherYatesPermutation.prototype.reorder = function () {
  for (var i = 0; i < this.length; i++) {
    this.indices[i] = i;
  }
};

FisherYatesPermutation.prototype.reset = function () {
  this.state = this.length;
};

FisherYatesPermutation.prototype.shrink = function (newLength) {
  if (newLength >= this.length)
    throw new Error(
      'pandemonium/fisher-yates-permutation: new length should be less than current length.'
    );

  this.length = newLength;
  this.reset();
  this.reorder();
};

FisherYatesPermutation.prototype.permute = function () {
  if (this.state === 0) {
    throw new Error(
      'pandemonium/fisher-yates-permutation: permutation is exhausted.'
    );
  } else if (this.state === 1) {
    this.state--;
    return this.indices[0];
  }

  var r = Math.floor(this.rng() * this.state);

  this.state--;

  var v = this.indices[r];
  this.indices[r] = this.indices[this.state];
  this.indices[this.state] = v;

  return v;
};

exports.FisherYatesPermutation = FisherYatesPermutation;
