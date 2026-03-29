"use strict";

Object.defineProperty(exports, "__esModule", {
  value: true
});
exports["default"] = nodesIteration;
var _assert = _interopRequireDefault(require("assert"));
var _helpers = require("../helpers");
function _interopRequireDefault(obj) { return obj && obj.__esModule ? obj : { "default": obj }; }
/**
 * Graphology Nodes Iteration Specs
 * =================================
 *
 * Testing the nodes iteration-related methods of the graph.
 */

function nodesIteration(Graph, checkers) {
  var invalid = checkers.invalid;
  return {
    '#.nodes': {
      'it should return the list of nodes of the graph.': function itShouldReturnTheListOfNodesOfTheGraph() {
        var graph = new Graph();
        (0, _helpers.addNodesFrom)(graph, ['one', 'two', 'three']);
        _assert["default"].deepStrictEqual(graph.nodes(), ['one', 'two', 'three']);
      }
    },
    '#.forEachNode': {
      'it should throw if given callback is not a function.': function itShouldThrowIfGivenCallbackIsNotAFunction() {
        var graph = new Graph();
        _assert["default"]["throws"](function () {
          graph.forEachNode(null);
        }, invalid());
      },
      'it should be possible to iterate over nodes and their attributes.': function itShouldBePossibleToIterateOverNodesAndTheirAttributes() {
        var graph = new Graph();
        graph.addNode('John', {
          age: 34
        });
        graph.addNode('Martha', {
          age: 33
        });
        var count = 0;
        graph.forEachNode(function (key, attributes) {
          _assert["default"].strictEqual(key, count ? 'Martha' : 'John');
          _assert["default"].deepStrictEqual(attributes, count ? {
            age: 33
          } : {
            age: 34
          });
          count++;
        });
        _assert["default"].strictEqual(count, 2);
      }
    },
    '#.findNode': {
      'it should throw if given callback is not a function.': function itShouldThrowIfGivenCallbackIsNotAFunction() {
        var graph = new Graph();
        _assert["default"]["throws"](function () {
          graph.findNode(null);
        }, invalid());
      },
      'it should be possible to find a node in the graph.': function itShouldBePossibleToFindANodeInTheGraph() {
        var graph = new Graph();
        graph.addNode('John', {
          age: 34
        });
        graph.addNode('Martha', {
          age: 33
        });
        var count = 0;
        var found = graph.findNode(function (key, attributes) {
          _assert["default"].strictEqual(key, 'John');
          _assert["default"].deepStrictEqual(attributes, {
            age: 34
          });
          count++;
          if (key === 'John') return true;
        });
        _assert["default"].strictEqual(found, 'John');
        _assert["default"].strictEqual(count, 1);
        found = graph.findNode(function () {
          return false;
        });
        _assert["default"].strictEqual(found, undefined);
      }
    },
    '#.mapNodes': {
      'it should be possible to map nodes.': function itShouldBePossibleToMapNodes() {
        var graph = new Graph();
        graph.addNode('one', {
          weight: 2
        });
        graph.addNode('two', {
          weight: 3
        });
        var result = graph.mapNodes(function (node, attr) {
          return attr.weight * 2;
        });
        _assert["default"].deepStrictEqual(result, [4, 6]);
      }
    },
    '#.someNode': {
      'it should always return false on empty sets.': function itShouldAlwaysReturnFalseOnEmptySets() {
        var graph = new Graph();
        _assert["default"].strictEqual(graph.someNode(function () {
          return true;
        }), false);
      },
      'it should be possible to find if some node matches a predicate.': function itShouldBePossibleToFindIfSomeNodeMatchesAPredicate() {
        var graph = new Graph();
        graph.addNode('one', {
          weight: 2
        });
        graph.addNode('two', {
          weight: 3
        });
        _assert["default"].strictEqual(graph.someNode(function (node, attr) {
          return attr.weight > 6;
        }), false);
        _assert["default"].strictEqual(graph.someNode(function (node, attr) {
          return attr.weight > 2;
        }), true);
      }
    },
    '#.everyNode': {
      'it should always return true on empty sets.': function itShouldAlwaysReturnTrueOnEmptySets() {
        var graph = new Graph();
        _assert["default"].strictEqual(graph.everyNode(function () {
          return true;
        }), true);
      },
      'it should be possible to find if all node matches a predicate.': function itShouldBePossibleToFindIfAllNodeMatchesAPredicate() {
        var graph = new Graph();
        graph.addNode('one', {
          weight: 2
        });
        graph.addNode('two', {
          weight: 3
        });
        _assert["default"].strictEqual(graph.everyNode(function (node, attr) {
          return attr.weight > 2;
        }), false);
        _assert["default"].strictEqual(graph.everyNode(function (node, attr) {
          return attr.weight > 1;
        }), true);
      }
    },
    '#.filterNodes': {
      'it should be possible to filter nodes.': function itShouldBePossibleToFilterNodes() {
        var graph = new Graph();
        graph.addNode('one', {
          weight: 2
        });
        graph.addNode('two', {
          weight: 3
        });
        graph.addNode('three', {
          weight: 4
        });
        var result = graph.filterNodes(function (node, _ref) {
          var weight = _ref.weight;
          return weight >= 3;
        });
        _assert["default"].deepStrictEqual(result, ['two', 'three']);
      }
    },
    '#.reduceNodes': {
      'it should throw if initial value is not given.': function itShouldThrowIfInitialValueIsNotGiven() {
        var graph = new Graph();
        _assert["default"]["throws"](function () {
          graph.reduceNodes(function (x, _, attr) {
            return x + attr.weight;
          });
        }, invalid());
      },
      'it should be possible to reduce nodes.': function itShouldBePossibleToReduceNodes() {
        var graph = new Graph();
        graph.addNode('one', {
          weight: 2
        });
        graph.addNode('two', {
          weight: 3
        });
        graph.addNode('three', {
          weight: 4
        });
        var result = graph.reduceNodes(function (x, _, attr) {
          return x + attr.weight;
        }, 0);
        _assert["default"].strictEqual(result, 9);
      }
    },
    '#.nodeEntries': {
      'it should be possible to create a nodes iterator.': function itShouldBePossibleToCreateANodesIterator() {
        var graph = new Graph();
        (0, _helpers.addNodesFrom)(graph, ['one', 'two', 'three']);
        graph.replaceNodeAttributes('two', {
          hello: 'world'
        });
        var iterator = graph.nodeEntries();
        _assert["default"].deepStrictEqual(iterator.next().value, {
          node: 'one',
          attributes: {}
        });
        _assert["default"].deepStrictEqual(iterator.next().value, {
          node: 'two',
          attributes: {
            hello: 'world'
          }
        });
        _assert["default"].deepStrictEqual(iterator.next().value, {
          node: 'three',
          attributes: {}
        });
        _assert["default"].strictEqual(iterator.next().done, true);
      }
    }
  };
}