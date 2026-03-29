"use strict";

Object.defineProperty(exports, "__esModule", {
  value: true
});
exports["default"] = neighborsIteration;
var _assert = _interopRequireDefault(require("assert"));
var _take = _interopRequireDefault(require("obliterator/take"));
var _helpers = require("../helpers");
function _interopRequireDefault(obj) { return obj && obj.__esModule ? obj : { "default": obj }; }
function _defineProperty(obj, key, value) { if (key in obj) { Object.defineProperty(obj, key, { value: value, enumerable: true, configurable: true, writable: true }); } else { obj[key] = value; } return obj; }
var METHODS = ['neighbors', 'inNeighbors', 'outNeighbors', 'inboundNeighbors', 'outboundNeighbors', 'directedNeighbors', 'undirectedNeighbors'];
function neighborsIteration(Graph, checkers) {
  var notFound = checkers.notFound,
    invalid = checkers.invalid;
  var graph = new Graph({
    multi: true
  });
  (0, _helpers.addNodesFrom)(graph, ['John', 'Thomas', 'Martha', 'Roger', 'Catherine', 'Alone', 'Forever']);
  graph.replaceNodeAttributes('John', {
    age: 34
  });
  graph.replaceNodeAttributes('Martha', {
    age: 35
  });
  graph.addDirectedEdgeWithKey('J->T', 'John', 'Thomas');
  graph.addDirectedEdgeWithKey('J->M', 'John', 'Martha');
  graph.addDirectedEdgeWithKey('C->J', 'Catherine', 'John');
  graph.addUndirectedEdgeWithKey('M<->R', 'Martha', 'Roger');
  graph.addUndirectedEdgeWithKey('M<->J', 'Martha', 'John');
  graph.addUndirectedEdgeWithKey('J<->R', 'John', 'Roger');
  graph.addUndirectedEdgeWithKey('T<->M', 'Thomas', 'Martha');
  var TEST_DATA = {
    neighbors: {
      node: {
        key: 'John',
        neighbors: ['Catherine', 'Thomas', 'Martha', 'Roger']
      }
    },
    inNeighbors: {
      node: {
        key: 'John',
        neighbors: ['Catherine']
      }
    },
    outNeighbors: {
      node: {
        key: 'John',
        neighbors: ['Thomas', 'Martha']
      }
    },
    inboundNeighbors: {
      node: {
        key: 'John',
        neighbors: ['Catherine', 'Martha', 'Roger']
      }
    },
    outboundNeighbors: {
      node: {
        key: 'John',
        neighbors: ['Thomas', 'Martha', 'Roger']
      }
    },
    directedNeighbors: {
      node: {
        key: 'John',
        neighbors: ['Catherine', 'Thomas', 'Martha']
      }
    },
    undirectedNeighbors: {
      node: {
        key: 'John',
        neighbors: ['Martha', 'Roger']
      }
    }
  };
  function commonTests(name) {
    return _defineProperty({}, '#.' + name, {
      'it should throw when the node is not found.': function itShouldThrowWhenTheNodeIsNotFound() {
        _assert["default"]["throws"](function () {
          graph[name]('Test');
        }, notFound());
        if (~name.indexOf('count')) return;
        _assert["default"]["throws"](function () {
          graph[name]('Test', 'SecondTest');
        }, notFound());
      }
    });
  }
  function specificTests(name, data) {
    var _ref2;
    var capitalized = name[0].toUpperCase() + name.slice(1, -1);
    var forEachName = 'forEach' + capitalized;
    var findName = 'find' + capitalized;
    var iteratorName = name.slice(0, -1) + 'Entries';
    var areName = 'are' + capitalized + 's';
    var mapName = 'map' + capitalized + 's';
    var filterName = 'filter' + capitalized + 's';
    var reduceName = 'reduce' + capitalized + 's';
    var someName = 'some' + capitalized;
    var everyName = 'every' + capitalized;
    return _ref2 = {}, _defineProperty(_ref2, '#.' + name, {
      'it should return the correct neighbors array.': function itShouldReturnTheCorrectNeighborsArray() {
        var neighbors = graph[name](data.node.key);
        _assert["default"].deepStrictEqual(neighbors, data.node.neighbors);
        _assert["default"].deepStrictEqual(graph[name]('Alone'), []);
      }
    }), _defineProperty(_ref2, '#.' + forEachName, {
      'it should be possible to iterate over neighbors using a callback.': function itShouldBePossibleToIterateOverNeighborsUsingACallback() {
        var neighbors = [];
        graph[forEachName](data.node.key, function (target, attrs) {
          neighbors.push(target);
          _assert["default"].deepStrictEqual(graph.getNodeAttributes(target), attrs);
          _assert["default"].strictEqual(graph[areName](data.node.key, target), true);
        });
        _assert["default"].deepStrictEqual(neighbors, data.node.neighbors);
      }
    }), _defineProperty(_ref2, '#.' + mapName, {
      'it should be possible to map neighbors using a callback.': function itShouldBePossibleToMapNeighborsUsingACallback() {
        var result = graph[mapName](data.node.key, function (target) {
          return target;
        });
        _assert["default"].deepStrictEqual(result, data.node.neighbors);
      }
    }), _defineProperty(_ref2, '#.' + filterName, {
      'it should be possible to filter neighbors using a callback.': function itShouldBePossibleToFilterNeighborsUsingACallback() {
        var result = graph[filterName](data.node.key, function () {
          return true;
        });
        _assert["default"].deepStrictEqual(result, data.node.neighbors);
        result = graph[filterName](data.node.key, function () {
          return false;
        });
        _assert["default"].deepStrictEqual(result, []);
      }
    }), _defineProperty(_ref2, '#.' + reduceName, {
      'it sould throw if not given an initial value.': function itSouldThrowIfNotGivenAnInitialValue() {
        _assert["default"]["throws"](function () {
          graph[reduceName]('node', function () {
            return true;
          });
        }, invalid());
      },
      'it should be possible to reduce neighbors using a callback.': function itShouldBePossibleToReduceNeighborsUsingACallback() {
        var result = graph[reduceName](data.node.key, function (acc, key) {
          return acc.concat(key);
        }, []);
        _assert["default"].deepStrictEqual(result, data.node.neighbors);
      }
    }), _defineProperty(_ref2, '#.' + findName, {
      'it should be possible to find neighbors.': function itShouldBePossibleToFindNeighbors() {
        var neighbors = [];
        var found = graph[findName](data.node.key, function (target, attrs) {
          neighbors.push(target);
          _assert["default"].deepStrictEqual(graph.getNodeAttributes(target), attrs);
          _assert["default"].strictEqual(graph[areName](data.node.key, target), true);
          return true;
        });
        _assert["default"].strictEqual(found, neighbors[0]);
        _assert["default"].deepStrictEqual(neighbors, data.node.neighbors.slice(0, 1));
        found = graph[findName](data.node.key, function () {
          return false;
        });
        _assert["default"].strictEqual(found, undefined);
      }
    }), _defineProperty(_ref2, '#.' + someName, {
      'it should always return false on empty set.': function itShouldAlwaysReturnFalseOnEmptySet() {
        var loneGraph = new Graph();
        loneGraph.addNode('alone');
        _assert["default"].strictEqual(loneGraph[someName]('alone', function () {
          return true;
        }), false);
      },
      'it should be possible to assert whether any neighbor matches a predicate.': function itShouldBePossibleToAssertWhetherAnyNeighborMatchesAPredicate() {
        _assert["default"].strictEqual(graph[someName](data.node.key, function () {
          return true;
        }), data.node.neighbors.length > 0);
      }
    }), _defineProperty(_ref2, '#.' + everyName, {
      'it should always return true on empty set.': function itShouldAlwaysReturnTrueOnEmptySet() {
        var loneGraph = new Graph();
        loneGraph.addNode('alone');
        _assert["default"].strictEqual(loneGraph[everyName]('alone', function () {
          return true;
        }), true);
      },
      'it should be possible to assert whether any neighbor matches a predicate.': function itShouldBePossibleToAssertWhetherAnyNeighborMatchesAPredicate() {
        _assert["default"].strictEqual(graph[everyName](data.node.key, function () {
          return true;
        }), data.node.neighbors.length > 0);
      }
    }), _defineProperty(_ref2, '#.' + iteratorName, {
      'it should be possible to create an iterator over neighbors.': function itShouldBePossibleToCreateAnIteratorOverNeighbors() {
        var iterator = graph[iteratorName](data.node.key);
        _assert["default"].deepStrictEqual((0, _take["default"])(iterator), data.node.neighbors.map(function (neighbor) {
          return {
            neighbor: neighbor,
            attributes: graph.getNodeAttributes(neighbor)
          };
        }));
      }
    }), _ref2;
  }
  var tests = {
    Miscellaneous: {
      'self loops should appear when using #.inNeighbors and should appear only once with #.neighbors.': function selfLoopsShouldAppearWhenUsingInNeighborsAndShouldAppearOnlyOnceWithNeighbors() {
        var directed = new Graph({
          type: 'directed'
        });
        directed.addNode('Lucy');
        directed.addEdgeWithKey('test', 'Lucy', 'Lucy');
        _assert["default"].deepStrictEqual(directed.inNeighbors('Lucy'), ['Lucy']);
        _assert["default"].deepStrictEqual(Array.from(directed.inNeighborEntries('Lucy')).map(function (x) {
          return x.neighbor;
        }), ['Lucy']);
        var neighbors = [];
        directed.forEachInNeighbor('Lucy', function (neighbor) {
          neighbors.push(neighbor);
        });
        _assert["default"].deepStrictEqual(neighbors, ['Lucy']);
        _assert["default"].deepStrictEqual(directed.neighbors('Lucy'), ['Lucy']);
        neighbors = [];
        directed.forEachNeighbor('Lucy', function (neighbor) {
          neighbors.push(neighbor);
        });
        _assert["default"].deepStrictEqual(neighbors, ['Lucy']);
        _assert["default"].deepStrictEqual(Array.from(directed.neighborEntries('Lucy')).map(function (x) {
          return x.neighbor;
        }), ['Lucy']);
      }
    }
  };

  // Common tests
  METHODS.forEach(function (name) {
    return (0, _helpers.deepMerge)(tests, commonTests(name));
  });

  // Specific tests
  for (var name in TEST_DATA) {
    (0, _helpers.deepMerge)(tests, specificTests(name, TEST_DATA[name]));
  }
  return tests;
}