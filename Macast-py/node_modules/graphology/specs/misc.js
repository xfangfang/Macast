"use strict";

Object.defineProperty(exports, "__esModule", {
  value: true
});
exports["default"] = misc;
var _assert = _interopRequireDefault(require("assert"));
var _helpers = require("./helpers");
function _interopRequireDefault(obj) { return obj && obj.__esModule ? obj : { "default": obj }; }
/**
 * Graphology Misc Specs
 * ======================
 *
 * Testing the miscellaneous things about the graph.
 */

function misc(Graph) {
  return {
    Structure: {
      'a simple mixed graph can have A->B, B->A & A<->B': function aSimpleMixedGraphCanHaveABBAAB() {
        var graph = new Graph();
        (0, _helpers.addNodesFrom)(graph, ['Audrey', 'Benjamin']);
        _assert["default"].doesNotThrow(function () {
          graph.addEdge('Audrey', 'Benjamin');
          graph.addEdge('Benjamin', 'Audrey');
          graph.addUndirectedEdge('Benjamin', 'Audrey');
        });
      },
      'deleting the last edge between A & B should correctly clear neighbor index.': function deletingTheLastEdgeBetweenABShouldCorrectlyClearNeighborIndex() {
        var graph = new Graph({
          multi: true
        });
        graph.addNode('A');
        graph.addNode('B');
        graph.addEdge('A', 'B');
        graph.addEdge('A', 'B');
        graph.forEachEdge('A', function (edge) {
          return graph.dropEdge(edge);
        });
        _assert["default"].deepStrictEqual(graph.neighbors('A'), []);
        _assert["default"].deepStrictEqual(graph.neighbors('B'), []);
      },
      'exhaustive deletion use-cases should not break doubly-linked lists implementation of multigraph edge storage.': function exhaustiveDeletionUseCasesShouldNotBreakDoublyLinkedListsImplementationOfMultigraphEdgeStorage() {
        var graph = new Graph({
          multi: true
        });
        graph.mergeEdgeWithKey('1', 'A', 'B');
        graph.mergeEdgeWithKey('2', 'A', 'B');
        graph.mergeEdgeWithKey('3', 'A', 'B');
        graph.mergeEdgeWithKey('4', 'A', 'B');
        graph.dropEdge('1');
        graph.dropEdge('2');
        graph.dropEdge('3');
        graph.dropEdge('4');
        _assert["default"].strictEqual(graph.size, 0);
        _assert["default"].strictEqual(graph.areNeighbors('A', 'B'), false);
        graph.mergeEdgeWithKey('1', 'A', 'B');
        graph.mergeEdgeWithKey('2', 'A', 'B');
        graph.mergeEdgeWithKey('3', 'A', 'B');
        graph.mergeEdgeWithKey('4', 'A', 'B');
        _assert["default"].strictEqual(graph.size, 4);
        _assert["default"].strictEqual(graph.areNeighbors('A', 'B'), true);
        graph.dropEdge('2');
        graph.dropEdge('3');
        _assert["default"].strictEqual(graph.size, 2);
        _assert["default"].strictEqual(graph.areNeighbors('A', 'B'), true);
        graph.dropEdge('4');
        graph.dropEdge('1');
        _assert["default"].strictEqual(graph.size, 0);
        _assert["default"].strictEqual(graph.areNeighbors('A', 'B'), false);
      }
    },
    'Key coercion': {
      'keys should be correctly coerced to strings.': function keysShouldBeCorrectlyCoercedToStrings() {
        var graph = new Graph();
        graph.addNode(1);
        graph.addNode('2');
        _assert["default"].strictEqual(graph.hasNode(1), true);
        _assert["default"].strictEqual(graph.hasNode('1'), true);
        _assert["default"].strictEqual(graph.hasNode(2), true);
        _assert["default"].strictEqual(graph.hasNode('2'), true);
        graph.addEdgeWithKey(3, 1, 2);
        _assert["default"].strictEqual(graph.hasEdge(3), true);
        _assert["default"].strictEqual(graph.hasEdge('3'), true);
      }
    }
  };
}