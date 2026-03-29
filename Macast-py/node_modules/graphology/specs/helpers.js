"use strict";

Object.defineProperty(exports, "__esModule", {
  value: true
});
exports.addNodesFrom = addNodesFrom;
exports.capitalize = capitalize;
exports.deepMerge = deepMerge;
exports.sameMembers = sameMembers;
exports.spy = spy;
function _typeof(obj) { "@babel/helpers - typeof"; return _typeof = "function" == typeof Symbol && "symbol" == typeof Symbol.iterator ? function (obj) { return typeof obj; } : function (obj) { return obj && "function" == typeof Symbol && obj.constructor === Symbol && obj !== Symbol.prototype ? "symbol" : typeof obj; }, _typeof(obj); }
/**
 * Graphology Specs Helpers
 * =========================
 *
 * Miscellaneous helpers to test more easily.
 */

/**
 * Capitalize function.
 */
function capitalize(string) {
  return string[0].toUpperCase() + string.slice(1);
}

/**
 * Simplistic deep merger function.
 */
function deepMerge() {
  for (var _len = arguments.length, objects = new Array(_len), _key = 0; _key < _len; _key++) {
    objects[_key] = arguments[_key];
  }
  var o = objects[0];
  var t, i, l, k;
  for (i = 1, l = objects.length; i < l; i++) {
    t = objects[i];
    for (k in t) {
      if (_typeof(t[k]) === 'object') {
        o[k] = deepMerge(o[k] || {}, t[k]);
      } else {
        o[k] = t[k];
      }
    }
  }
  return o;
}

/**
 * Checking that two arrays have the same members.
 */
function sameMembers(a1, a2) {
  if (a1.length !== a2.length) return false;
  var set = new Set(a1);
  for (var i = 0, l = a2.length; i < l; i++) {
    if (!set.has(a2[i])) return false;
  }
  return true;
}

/**
 * Function spying on the execution of the provided function to ease some
 * tests, notably related to event handling.
 *
 * @param {function} target - Target function.
 * @param {function}        - The spy.
 */
function spy(target) {
  var fn = function fn() {
    fn.called = true;
    fn.times++;
    if (typeof target === 'function') return target.apply(null, arguments);
  };
  fn.called = false;
  fn.times = 0;
  return fn;
}

/**
 * Function adding multiple nodes from an array to the given graph.
 *
 * @param {Graph} graph - Target graph.
 * @param {array} nodes - Node array.
 */
function addNodesFrom(graph, nodes) {
  nodes.forEach(function (node) {
    graph.addNode(node);
  });
}