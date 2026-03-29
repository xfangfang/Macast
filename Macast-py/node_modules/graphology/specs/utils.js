"use strict";

Object.defineProperty(exports, "__esModule", {
  value: true
});
exports["default"] = utils;
var _assert = _interopRequireDefault(require("assert"));
var _helpers = require("./helpers");
function _interopRequireDefault(obj) { return obj && obj.__esModule ? obj : { "default": obj }; }
/**
 * Graphology Utils Specs
 * =======================
 *
 * Testing the utils methods.
 */

var PROPERTIES = ['type', 'multi', 'map', 'selfLoops'];
function utils(Graph, checkers) {
  var usage = checkers.usage;
  return {
    '#.nullCopy': {
      'it should create an null copy of the graph.': function itShouldCreateAnNullCopyOfTheGraph() {
        var graph = new Graph();
        (0, _helpers.addNodesFrom)(graph, ['John', 'Thomas']);
        graph.addEdge('John', 'Thomas');
        var copy = graph.nullCopy();
        _assert["default"].deepStrictEqual(copy.nodes(), []);
        _assert["default"].strictEqual(copy.order, 0);
        _assert["default"].strictEqual(copy.size, 0);
        PROPERTIES.forEach(function (property) {
          _assert["default"].strictEqual(graph[property], copy[property]);
        });
      },
      'it should be possible to pass options to merge.': function itShouldBePossibleToPassOptionsToMerge() {
        var graph = new Graph({
          type: 'directed'
        });
        var copy = graph.nullCopy({
          type: 'undirected'
        });
        _assert["default"].strictEqual(copy.type, 'undirected');
        _assert["default"]["throws"](function () {
          copy.addDirectedEdge('one', 'two');
        }, /addDirectedEdge/);
      },
      'copying the graph should conserve its attributes.': function copyingTheGraphShouldConserveItsAttributes() {
        var graph = new Graph();
        graph.setAttribute('title', 'The Graph');
        var copy = graph.nullCopy();
        _assert["default"].deepStrictEqual(graph.getAttributes(), copy.getAttributes());
      }
    },
    '#.emptyCopy': {
      'it should create an empty copy of the graph.': function itShouldCreateAnEmptyCopyOfTheGraph() {
        var graph = new Graph();
        (0, _helpers.addNodesFrom)(graph, ['John', 'Thomas']);
        graph.addEdge('John', 'Thomas');
        var copy = graph.emptyCopy();
        _assert["default"].deepStrictEqual(copy.nodes(), ['John', 'Thomas']);
        _assert["default"].strictEqual(copy.order, 2);
        _assert["default"].strictEqual(copy.size, 0);
        PROPERTIES.forEach(function (property) {
          _assert["default"].strictEqual(graph[property], copy[property]);
        });
        copy.mergeEdge('Mary', 'Thomas');
        copy.setNodeAttribute('John', 'age', 32);
        _assert["default"].strictEqual(copy.order, 3);
        _assert["default"].strictEqual(copy.size, 1);
        _assert["default"].deepStrictEqual(copy.getNodeAttributes('John'), {
          age: 32
        });
        _assert["default"].deepStrictEqual(graph.getNodeAttributes('John'), {});
      },
      'it should be possible to pass options to merge.': function itShouldBePossibleToPassOptionsToMerge() {
        var graph = new Graph({
          type: 'directed'
        });
        var copy = graph.emptyCopy({
          type: 'undirected'
        });
        _assert["default"].strictEqual(copy.type, 'undirected');
        _assert["default"]["throws"](function () {
          copy.addDirectedEdge('one', 'two');
        }, /addDirectedEdge/);
      },
      'copying the graph should conserve its attributes.': function copyingTheGraphShouldConserveItsAttributes() {
        var graph = new Graph();
        graph.setAttribute('title', 'The Graph');
        var copy = graph.emptyCopy();
        _assert["default"].deepStrictEqual(graph.getAttributes(), copy.getAttributes());
      }
    },
    '#.copy': {
      'it should create a full copy of the graph.': function itShouldCreateAFullCopyOfTheGraph() {
        var graph = new Graph();
        (0, _helpers.addNodesFrom)(graph, ['John', 'Thomas']);
        graph.addEdge('John', 'Thomas');
        var copy = graph.copy();
        _assert["default"].deepStrictEqual(copy.nodes(), graph.nodes());
        _assert["default"].deepStrictEqual(copy.edges(), graph.edges());
        _assert["default"].strictEqual(copy.order, 2);
        _assert["default"].strictEqual(copy.size, 1);
        PROPERTIES.forEach(function (property) {
          _assert["default"].strictEqual(graph[property], graph[property]);
        });
      },
      'it should not break when copying a graph with wrangled edge ids (issue #213).': function itShouldNotBreakWhenCopyingAGraphWithWrangledEdgeIdsIssue213() {
        var graph = new Graph();
        graph.addNode('n0');
        graph.addNode('n1');
        graph.addNode('n2');
        graph.addNode('n3');
        graph.addEdge('n0', 'n1');
        graph.addEdge('n1', 'n2');
        graph.addEdge('n2', 'n3');
        graph.addEdge('n3', 'n0');
        _assert["default"].doesNotThrow(function () {
          graph.copy();
        });

        // Do surgery on second edge
        var edgeToSplit = graph.edge('n1', 'n2');
        var newNode = 'n12';
        graph.addNode(newNode);
        graph.dropEdge('n1', 'n2');
        graph.addEdge('n1', newNode);
        graph.addEdgeWithKey(edgeToSplit, newNode, 'n2');
        var copy = graph.copy();
        _assert["default"].deepStrictEqual(new Set(graph.nodes()), new Set(copy.nodes()));
        _assert["default"].deepStrictEqual(new Set(graph.edges()), new Set(copy.edges()));
        _assert["default"].notStrictEqual(graph.getNodeAttributes('n1'), copy.getNodeAttributes('n1'));
        _assert["default"].doesNotThrow(function () {
          copy.addEdge('n0', 'n12');
        });
      },
      'it should not break on adversarial inputs.': function itShouldNotBreakOnAdversarialInputs() {
        var graph = new Graph();
        graph.mergeEdge(0, 1);
        graph.mergeEdge(1, 2);
        graph.mergeEdge(2, 0);
        var copy = graph.copy();
        copy.mergeEdge(3, 4);
        var serializedCopy = Graph.from(graph["export"]());
        _assert["default"].doesNotThrow(function () {
          serializedCopy.mergeEdge(3, 4);
        });
        _assert["default"].strictEqual(serializedCopy.size, 4);
      },
      'copying the graph should conserve its attributes.': function copyingTheGraphShouldConserveItsAttributes() {
        var graph = new Graph();
        graph.setAttribute('title', 'The Graph');
        var copy = graph.copy();
        _assert["default"].deepStrictEqual(graph.getAttributes(), copy.getAttributes());
      },
      'it should be possible to upgrade a graph.': function itShouldBePossibleToUpgradeAGraph() {
        var strict = new Graph({
          type: 'directed',
          allowSelfLoops: false
        });
        var loose = new Graph({
          multi: true
        });
        _assert["default"].strictEqual(strict.copy({
          type: 'directed'
        }).type, 'directed');
        _assert["default"].strictEqual(strict.copy({
          multi: false
        }).multi, false);
        _assert["default"].strictEqual(strict.copy({
          allowSelfLoops: false
        }).allowSelfLoops, false);
        _assert["default"].strictEqual(strict.copy({
          type: 'mixed'
        }).type, 'mixed');
        _assert["default"].strictEqual(strict.copy({
          multi: true
        }).multi, true);
        _assert["default"].strictEqual(strict.copy({
          allowSelfLoops: true
        }).allowSelfLoops, true);
        _assert["default"]["throws"](function () {
          strict.copy({
            type: 'undirected'
          });
        }, usage());
        _assert["default"]["throws"](function () {
          loose.copy({
            type: 'undirected'
          });
        }, usage());
        _assert["default"]["throws"](function () {
          loose.copy({
            multi: false
          });
        }, usage());
        _assert["default"]["throws"](function () {
          loose.copy({
            allowSelfLoops: false
          });
        }, usage());
      }
    }
  };
}