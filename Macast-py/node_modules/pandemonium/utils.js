/**
 * Pandemonium Utils
 * ==================
 *
 * Miscellaneous helper functions.
 */

/**
 * Function returning an array of indices.
 *
 * @param  {number} n - Length of the array to create.
 * @return {Array}    - The created array.
 */
exports.indices = function (n) {
  var a = new Array(n);
  var i;

  for (i = 0; i < n; i++) {
    a[i] = i;
  }

  return a;
};

/**
 * Function related to conversion between coordinates in an upper triangular
 * square matrices and the equivalent linear indices (we don't consider the diagonal).
 *
 * [References]:
 * https://stackoverflow.com/questions/27086195/linear-index-upper-triangular-matrix
 * https://gist.github.com/PhDP/2358809
 */
exports.triuLinearLength = function (n) {
  return (n * (n - 1)) / 2;
};
exports.linearIndexToTriuCoords = function (n, k) {
  var i = n - 2 - Math.floor(Math.sqrt(-8 * k + 4 * n * (n - 1) - 7) / 2 - 0.5);
  var j = k + i + 1 - (n * (n - 1)) / 2 + ((n - i) * (n - i - 1)) / 2;

  return [i, j];
};
exports.triuCoordsToLinearIndex = function (n, i, j) {
  return (n * (n - 1)) / 2 - ((n - i) * (n - i - 1)) / 2 + j - i - 1;
};
exports.linearIndexToTriuCoordsFast = function (k) {
  var i = Math.floor(-0.5 + 0.5 * Math.sqrt(1 + 8 * k)) + 2;
  var j = (i * (3 - i)) / 2 + k;

  return [i - 1, j - 1];
};

/**
 * Function returning a unique key for a pair of numbers.
 */
var MAX_SAFE_ROOT = Math.floor(Math.sqrt(Number.MAX_SAFE_INTEGER));

exports.createPairKeyFunction = function (n) {
  if (n <= MAX_SAFE_ROOT)
    return function (i, j) {
      return j * n + i;
    };

  return function (i, j) {
    return i + ',' + j;
  };
};
