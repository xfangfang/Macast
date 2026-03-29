"use strict";

Object.defineProperty(exports, "__esModule", {
  value: true
});
exports["default"] = iteration;
var _assert = _interopRequireDefault(require("assert"));
var _nodes = _interopRequireDefault(require("./nodes"));
var _edges = _interopRequireDefault(require("./edges"));
var _neighbors = _interopRequireDefault(require("./neighbors"));
function _interopRequireDefault(obj) { return obj && obj.__esModule ? obj : { "default": obj }; }
/**
 * Graphology Iteration Specs
 * ===========================
 *
 * Testing the iteration-related methods of the graph.
 */

function iteration(Graph, checkers) {
  return {
    Adjacency: {
      '#.forEachAdjacencyEntry': {
        'it should iterate over the relevant elements.': function itShouldIterateOverTheRelevantElements() {
          function test(multi) {
            var graph = new Graph({
              multi: multi
            });
            graph.addNode('John', {
              hello: 'world'
            });
            var _graph$mergeUndirecte = graph.mergeUndirectedEdge('John', 'Mary', {
                weight: 3
              }),
              e1 = _graph$mergeUndirecte[0];
            graph.mergeUndirectedEdge('Thomas', 'John');
            graph.mergeDirectedEdge('John', 'Thomas');
            var count = 0;
            graph.forEachAdjacencyEntry(function (node, neighbor, attr, neighborAttr, edge, edgeAttr, undirected) {
              count++;
              if (node === 'John') {
                _assert["default"].deepStrictEqual(attr, {
                  hello: 'world'
                });
              } else {
                _assert["default"].deepStrictEqual(attr, {});
              }
              if (neighbor === 'John') {
                _assert["default"].deepStrictEqual(neighborAttr, {
                  hello: 'world'
                });
              } else {
                _assert["default"].deepStrictEqual(neighborAttr, {});
              }
              if (edge === e1) {
                _assert["default"].deepStrictEqual(edgeAttr, {
                  weight: 3
                });
              } else {
                _assert["default"].deepStrictEqual(edgeAttr, {});
              }
              _assert["default"].strictEqual(graph.isUndirected(edge), undirected);
            });
            _assert["default"].strictEqual(count, graph.directedSize + graph.undirectedSize * 2);
            graph.addNode('Disconnected');
            count = 0;
            graph.forEachAdjacencyEntryWithOrphans(function (node, neighbor, attr, neighborAttr, edge, edgeAttr, undirected) {
              count++;
              if (node !== 'Disconnected') return;
              _assert["default"].strictEqual(neighbor, null);
              _assert["default"].strictEqual(neighborAttr, null);
              _assert["default"].strictEqual(edge, null);
              _assert["default"].strictEqual(edgeAttr, null);
              _assert["default"].strictEqual(undirected, null);
            }, true);
            _assert["default"].strictEqual(count, graph.directedSize + graph.undirectedSize * 2 + 1);
          }
          test(false);
          test(true);
        }
      },
      '#.forEachAssymetricAdjacencyEntry': {
        'it should iterate over the relevant elements.': function itShouldIterateOverTheRelevantElements() {
          function test(multi) {
            var graph = new Graph({
              multi: multi
            });
            graph.addNode('John', {
              hello: 'world'
            });
            graph.mergeUndirectedEdge('John', 'Mary', {
              weight: 3
            });
            graph.mergeUndirectedEdge('Thomas', 'John');
            graph.mergeDirectedEdge('John', 'Thomas');
            var edges = [];
            graph.forEachAssymetricAdjacencyEntry(function (node, neighbor, attr, neighborAttr, edge, edgeAttr, undirected) {
              if (undirected) {
                _assert["default"].strictEqual(node < neighbor, true);
              }
              edges.push(edge);
            });
            _assert["default"].strictEqual(edges.length, graph.directedSize + graph.undirectedSize);
            _assert["default"].deepStrictEqual(new Set(edges).size, edges.length);
            graph.addNode('Disconnected');
            var count = 0;
            var nulls = 0;
            graph.forEachAssymetricAdjacencyEntryWithOrphans(function (node, neighbor, attr, neighborAttr, edge, edgeAttr, undirected) {
              count++;
              if (neighbor) return;
              nulls++;
              _assert["default"].strictEqual(neighbor, null);
              _assert["default"].strictEqual(neighborAttr, null);
              _assert["default"].strictEqual(edge, null);
              _assert["default"].strictEqual(edgeAttr, null);
              _assert["default"].strictEqual(undirected, null);
            }, true);
            _assert["default"].strictEqual(count, graph.directedSize + graph.undirectedSize + 3);
            _assert["default"].strictEqual(nulls, 3);
          }
          test(false);
          test(true);
        }
      }
    },
    Nodes: (0, _nodes["default"])(Graph, checkers),
    Edges: (0, _edges["default"])(Graph, checkers),
    Neighbors: (0, _neighbors["default"])(Graph, checkers)
  };
}