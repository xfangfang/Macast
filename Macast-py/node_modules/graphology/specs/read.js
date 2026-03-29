"use strict";

Object.defineProperty(exports, "__esModule", {
  value: true
});
exports["default"] = read;
var _assert = _interopRequireDefault(require("assert"));
var _helpers = require("./helpers");
function _interopRequireDefault(obj) { return obj && obj.__esModule ? obj : { "default": obj }; }
/**
 * Graphology Read Specs
 * ======================
 *
 * Testing the read methods of the graph.
 */

function read(Graph, checkers) {
  var invalid = checkers.invalid,
    notFound = checkers.notFound,
    usage = checkers.usage;
  return {
    '#.hasNode': {
      'it should correctly return whether the given node is found in the graph.': function itShouldCorrectlyReturnWhetherTheGivenNodeIsFoundInTheGraph() {
        var graph = new Graph();
        _assert["default"].strictEqual(graph.hasNode('John'), false);
        graph.addNode('John');
        _assert["default"].strictEqual(graph.hasNode('John'), true);
      }
    },
    '#.hasDirectedEdge': {
      'it should throw if invalid arguments are provided.': function itShouldThrowIfInvalidArgumentsAreProvided() {
        var graph = new Graph();
        _assert["default"]["throws"](function () {
          graph.hasDirectedEdge(1, 2, 3);
        }, invalid());
      },
      'it should correctly return whether a matching edge exists in the graph.': function itShouldCorrectlyReturnWhetherAMatchingEdgeExistsInTheGraph() {
        var graph = new Graph();
        graph.addNode('Martha');
        graph.addNode('Catherine');
        graph.addNode('John');
        graph.addDirectedEdgeWithKey('M->C', 'Martha', 'Catherine');
        graph.addUndirectedEdgeWithKey('C<->J', 'Catherine', 'John');
        _assert["default"].strictEqual(graph.hasDirectedEdge('M->C'), true);
        _assert["default"].strictEqual(graph.hasDirectedEdge('C<->J'), false);
        _assert["default"].strictEqual(graph.hasDirectedEdge('test'), false);
        _assert["default"].strictEqual(graph.hasDirectedEdge('Martha', 'Catherine'), true);
        _assert["default"].strictEqual(graph.hasDirectedEdge('Martha', 'Thomas'), false);
        _assert["default"].strictEqual(graph.hasDirectedEdge('Catherine', 'John'), false);
        _assert["default"].strictEqual(graph.hasDirectedEdge('John', 'Catherine'), false);
      },
      'it should work with self loops.': function itShouldWorkWithSelfLoops() {
        var graph = new Graph();
        graph.mergeDirectedEdge('Lucy', 'Lucy');
        _assert["default"].strictEqual(graph.hasDirectedEdge('Lucy', 'Lucy'), true);
        _assert["default"].strictEqual(graph.hasUndirectedEdge('Lucy', 'Lucy'), false);
      }
    },
    '#.hasUndirectedEdge': {
      'it should throw if invalid arguments are provided.': function itShouldThrowIfInvalidArgumentsAreProvided() {
        var graph = new Graph();
        _assert["default"]["throws"](function () {
          graph.hasUndirectedEdge(1, 2, 3);
        }, invalid());
      },
      'it should correctly return whether a matching edge exists in the graph.': function itShouldCorrectlyReturnWhetherAMatchingEdgeExistsInTheGraph() {
        var graph = new Graph();
        graph.addNode('Martha');
        graph.addNode('Catherine');
        graph.addNode('John');
        graph.addDirectedEdgeWithKey('M->C', 'Martha', 'Catherine');
        graph.addUndirectedEdgeWithKey('C<->J', 'Catherine', 'John');
        _assert["default"].strictEqual(graph.hasUndirectedEdge('M->C'), false);
        _assert["default"].strictEqual(graph.hasUndirectedEdge('C<->J'), true);
        _assert["default"].strictEqual(graph.hasUndirectedEdge('test'), false);
        _assert["default"].strictEqual(graph.hasUndirectedEdge('Martha', 'Catherine'), false);
        _assert["default"].strictEqual(graph.hasUndirectedEdge('Martha', 'Thomas'), false);
        _assert["default"].strictEqual(graph.hasUndirectedEdge('Catherine', 'John'), true);
        _assert["default"].strictEqual(graph.hasUndirectedEdge('John', 'Catherine'), true);
      },
      'it should work with self loops.': function itShouldWorkWithSelfLoops() {
        var graph = new Graph();
        graph.mergeUndirectedEdge('Lucy', 'Lucy');
        _assert["default"].strictEqual(graph.hasDirectedEdge('Lucy', 'Lucy'), false);
        _assert["default"].strictEqual(graph.hasUndirectedEdge('Lucy', 'Lucy'), true);
      }
    },
    '#.hasEdge': {
      'it should throw if invalid arguments are provided.': function itShouldThrowIfInvalidArgumentsAreProvided() {
        var graph = new Graph();
        _assert["default"]["throws"](function () {
          graph.hasEdge(1, 2, 3);
        }, invalid());
      },
      'it should correctly return whether a matching edge exists in the graph.': function itShouldCorrectlyReturnWhetherAMatchingEdgeExistsInTheGraph() {
        var graph = new Graph();
        graph.addNode('Martha');
        graph.addNode('Catherine');
        graph.addNode('John');
        graph.addDirectedEdgeWithKey('M->C', 'Martha', 'Catherine');
        graph.addUndirectedEdgeWithKey('C<->J', 'Catherine', 'John');
        _assert["default"].strictEqual(graph.hasEdge('M->C'), true);
        _assert["default"].strictEqual(graph.hasEdge('C<->J'), true);
        _assert["default"].strictEqual(graph.hasEdge('test'), false);
        _assert["default"].strictEqual(graph.hasEdge('Martha', 'Catherine'), true);
        _assert["default"].strictEqual(graph.hasEdge('Martha', 'Thomas'), false);
        _assert["default"].strictEqual(graph.hasEdge('Catherine', 'John'), true);
        _assert["default"].strictEqual(graph.hasEdge('John', 'Catherine'), true);
      },
      'it should work properly with typed graphs.': function itShouldWorkProperlyWithTypedGraphs() {
        var directedGraph = new Graph({
            type: 'directed'
          }),
          undirectedGraph = new Graph({
            type: 'undirected'
          });
        (0, _helpers.addNodesFrom)(directedGraph, [1, 2]);
        (0, _helpers.addNodesFrom)(undirectedGraph, [1, 2]);
        _assert["default"].strictEqual(directedGraph.hasEdge(1, 2), false);
        _assert["default"].strictEqual(undirectedGraph.hasEdge(1, 2), false);
      },
      'it should work with self loops.': function itShouldWorkWithSelfLoops() {
        var graph = new Graph();
        graph.mergeUndirectedEdge('Lucy', 'Lucy');
        _assert["default"].strictEqual(graph.hasDirectedEdge('Lucy', 'Lucy'), false);
        _assert["default"].strictEqual(graph.hasUndirectedEdge('Lucy', 'Lucy'), true);
        _assert["default"].strictEqual(graph.hasEdge('Lucy', 'Lucy'), true);
      },
      'it should work with multi graphs (issue #431).': function itShouldWorkWithMultiGraphsIssue431() {
        var graph = new Graph({
          multi: true,
          type: 'directed'
        });
        var na = graph.addNode('A');
        var nb = graph.addNode('B');
        var eid = graph.addEdge('A', 'B');
        _assert["default"].strictEqual(graph.hasEdge('A', 'B'), true);
        _assert["default"].strictEqual(graph.hasEdge(na, nb), true);
        _assert["default"].strictEqual(graph.hasEdge(eid), true);
      }
    },
    '#.directedEdge': {
      'it should throw if invalid arguments are provided.': function itShouldThrowIfInvalidArgumentsAreProvided() {
        var graph = new Graph(),
          multiGraph = new Graph({
            multi: true
          });
        graph.addNode('John');
        _assert["default"]["throws"](function () {
          multiGraph.directedEdge(1, 2);
        }, usage());
        _assert["default"]["throws"](function () {
          graph.directedEdge('Jack', 'John');
        }, notFound());
        _assert["default"]["throws"](function () {
          graph.directedEdge('John', 'Jack');
        }, notFound());
      },
      'it should return the correct edge.': function itShouldReturnTheCorrectEdge() {
        var graph = new Graph();
        (0, _helpers.addNodesFrom)(graph, ['Jack', 'Lucy']);
        graph.addDirectedEdgeWithKey('J->L', 'Jack', 'Lucy');
        graph.addUndirectedEdgeWithKey('J<->L', 'Jack', 'Lucy');
        _assert["default"].strictEqual(graph.directedEdge('Lucy', 'Jack'), undefined);
        _assert["default"].strictEqual(graph.directedEdge('Jack', 'Lucy'), 'J->L');
        var undirectedGraph = new Graph({
          type: 'undirected'
        });
        undirectedGraph.mergeEdge('Jack', 'Lucy');
        _assert["default"].strictEqual(undirectedGraph.directedEdge('Jack', 'Lucy'), undefined);
      },
      'it should return the correct self loop.': function itShouldReturnTheCorrectSelfLoop() {
        var graph = new Graph();
        graph.addNode('John');
        graph.addEdgeWithKey('d', 'John', 'John');
        graph.addUndirectedEdgeWithKey('u', 'John', 'John');
        _assert["default"].strictEqual(graph.directedEdge('John', 'John'), 'd');
      }
    },
    '#.undirectedEdge': {
      'it should throw if invalid arguments are provided.': function itShouldThrowIfInvalidArgumentsAreProvided() {
        var graph = new Graph(),
          multiGraph = new Graph({
            multi: true
          });
        graph.addNode('John');
        _assert["default"]["throws"](function () {
          multiGraph.undirectedEdge(1, 2);
        }, usage());
        _assert["default"]["throws"](function () {
          graph.undirectedEdge('Jack', 'John');
        }, notFound());
        _assert["default"]["throws"](function () {
          graph.undirectedEdge('John', 'Jack');
        }, notFound());
      },
      'it should return the correct edge.': function itShouldReturnTheCorrectEdge() {
        var graph = new Graph();
        (0, _helpers.addNodesFrom)(graph, ['Jack', 'Lucy']);
        graph.addDirectedEdgeWithKey('J->L', 'Jack', 'Lucy');
        graph.addUndirectedEdgeWithKey('J<->L', 'Jack', 'Lucy');
        _assert["default"].strictEqual(graph.undirectedEdge('Lucy', 'Jack'), 'J<->L');
        _assert["default"].strictEqual(graph.undirectedEdge('Jack', 'Lucy'), 'J<->L');
        var directedGraph = new Graph({
          type: 'directed'
        });
        directedGraph.mergeEdge('Jack', 'Lucy');
        _assert["default"].strictEqual(directedGraph.undirectedEdge('Jack', 'Lucy'), undefined);
      },
      'it should return the correct self loop.': function itShouldReturnTheCorrectSelfLoop() {
        var graph = new Graph();
        graph.addNode('John');
        graph.addEdgeWithKey('d', 'John', 'John');
        graph.addUndirectedEdgeWithKey('u', 'John', 'John');
        _assert["default"].strictEqual(graph.undirectedEdge('John', 'John'), 'u');
      }
    },
    '#.edge': {
      'it should throw if invalid arguments are provided.': function itShouldThrowIfInvalidArgumentsAreProvided() {
        var graph = new Graph(),
          multiGraph = new Graph({
            multi: true
          });
        graph.addNode('John');
        _assert["default"]["throws"](function () {
          multiGraph.edge(1, 2);
        }, usage());
        _assert["default"]["throws"](function () {
          graph.edge('Jack', 'John');
        }, notFound());
        _assert["default"]["throws"](function () {
          graph.edge('John', 'Jack');
        }, notFound());
      },
      'it should return the correct edge.': function itShouldReturnTheCorrectEdge() {
        var graph = new Graph();
        (0, _helpers.addNodesFrom)(graph, ['Jack', 'Lucy']);
        graph.addDirectedEdgeWithKey('J->L', 'Jack', 'Lucy');
        graph.addUndirectedEdgeWithKey('J<->L', 'Jack', 'Lucy');
        _assert["default"].strictEqual(graph.edge('Lucy', 'Jack'), 'J<->L');
        _assert["default"].strictEqual(graph.edge('Jack', 'Lucy'), 'J->L');
      },
      'it should return the correct self loop.': function itShouldReturnTheCorrectSelfLoop() {
        var graph = new Graph();
        graph.addNode('John');
        graph.addEdgeWithKey('d', 'John', 'John');
        graph.addUndirectedEdgeWithKey('u', 'John', 'John');
        _assert["default"].strictEqual(graph.edge('John', 'John'), 'd');
      }
    },
    '#.areDirectedNeighbors': {
      'it should throw if node is not in the graph.': function itShouldThrowIfNodeIsNotInTheGraph() {
        var graph = new Graph();
        _assert["default"]["throws"](function () {
          graph.areDirectedNeighbors('source', 'target');
        }, notFound());
      },
      'it should correctly return whether two nodes are neighbors.': function itShouldCorrectlyReturnWhetherTwoNodesAreNeighbors() {
        var graph = new Graph();
        graph.mergeDirectedEdge('Mary', 'Joseph');
        graph.mergeUndirectedEdge('Martha', 'Mary');
        _assert["default"].strictEqual(graph.areDirectedNeighbors('Mary', 'Joseph'), true);
        _assert["default"].strictEqual(graph.areDirectedNeighbors('Joseph', 'Mary'), true);
        _assert["default"].strictEqual(graph.areDirectedNeighbors('Martha', 'Mary'), false);
        var undirectedGraph = new Graph({
          type: 'undirected'
        });
        undirectedGraph.mergeEdge('Mary', 'Martha');
        _assert["default"].strictEqual(undirectedGraph.areDirectedNeighbors('Mary', 'Martha'), false);
      }
    },
    '#.areInNeighbors': {
      'it should throw if node is not in the graph.': function itShouldThrowIfNodeIsNotInTheGraph() {
        var graph = new Graph();
        _assert["default"]["throws"](function () {
          graph.areInNeighbors('source', 'target');
        }, notFound());
      },
      'it should correctly return whether two nodes are neighbors.': function itShouldCorrectlyReturnWhetherTwoNodesAreNeighbors() {
        var graph = new Graph();
        graph.mergeDirectedEdge('Mary', 'Joseph');
        graph.mergeUndirectedEdge('Martha', 'Mary');
        _assert["default"].strictEqual(graph.areInNeighbors('Mary', 'Joseph'), false);
        _assert["default"].strictEqual(graph.areInNeighbors('Joseph', 'Mary'), true);
        _assert["default"].strictEqual(graph.areInNeighbors('Martha', 'Mary'), false);
        var undirectedGraph = new Graph({
          type: 'undirected'
        });
        undirectedGraph.mergeEdge('Mary', 'Martha');
        _assert["default"].strictEqual(undirectedGraph.areInNeighbors('Mary', 'Martha'), false);
      }
    },
    '#.areOutNeighbors': {
      'it should throw if node is not in the graph.': function itShouldThrowIfNodeIsNotInTheGraph() {
        var graph = new Graph();
        _assert["default"]["throws"](function () {
          graph.areOutNeighbors('source', 'target');
        }, notFound());
      },
      'it should correctly return whether two nodes are neighbors.': function itShouldCorrectlyReturnWhetherTwoNodesAreNeighbors() {
        var graph = new Graph();
        graph.mergeDirectedEdge('Mary', 'Joseph');
        graph.mergeUndirectedEdge('Martha', 'Mary');
        _assert["default"].strictEqual(graph.areOutNeighbors('Mary', 'Joseph'), true);
        _assert["default"].strictEqual(graph.areOutNeighbors('Joseph', 'Mary'), false);
        _assert["default"].strictEqual(graph.areOutNeighbors('Martha', 'Mary'), false);
        var undirectedGraph = new Graph({
          type: 'undirected'
        });
        undirectedGraph.mergeEdge('Mary', 'Martha');
        _assert["default"].strictEqual(undirectedGraph.areOutNeighbors('Mary', 'Martha'), false);
      }
    },
    '#.areOutboundNeighbors': {
      'it should throw if node is not in the graph.': function itShouldThrowIfNodeIsNotInTheGraph() {
        var graph = new Graph();
        _assert["default"]["throws"](function () {
          graph.areOutboundNeighbors('source', 'target');
        }, notFound());
      },
      'it should correctly return whether two nodes are neighbors.': function itShouldCorrectlyReturnWhetherTwoNodesAreNeighbors() {
        var graph = new Graph();
        graph.mergeDirectedEdge('Mary', 'Joseph');
        graph.mergeUndirectedEdge('Martha', 'Mary');
        _assert["default"].strictEqual(graph.areOutboundNeighbors('Mary', 'Joseph'), true);
        _assert["default"].strictEqual(graph.areOutboundNeighbors('Joseph', 'Mary'), false);
        _assert["default"].strictEqual(graph.areOutboundNeighbors('Martha', 'Mary'), true);
        var undirectedGraph = new Graph({
          type: 'undirected'
        });
        undirectedGraph.mergeEdge('Mary', 'Martha');
        _assert["default"].strictEqual(undirectedGraph.areOutboundNeighbors('Mary', 'Martha'), true);
      }
    },
    '#.areInboundNeighbors': {
      'it should throw if node is not in the graph.': function itShouldThrowIfNodeIsNotInTheGraph() {
        var graph = new Graph();
        _assert["default"]["throws"](function () {
          graph.areInboundNeighbors('source', 'target');
        }, notFound());
      },
      'it should correctly return whether two nodes are neighbors.': function itShouldCorrectlyReturnWhetherTwoNodesAreNeighbors() {
        var graph = new Graph();
        graph.mergeDirectedEdge('Mary', 'Joseph');
        graph.mergeUndirectedEdge('Martha', 'Mary');
        _assert["default"].strictEqual(graph.areInboundNeighbors('Mary', 'Joseph'), false);
        _assert["default"].strictEqual(graph.areInboundNeighbors('Joseph', 'Mary'), true);
        _assert["default"].strictEqual(graph.areInboundNeighbors('Martha', 'Mary'), true);
        var undirectedGraph = new Graph({
          type: 'undirected'
        });
        undirectedGraph.mergeEdge('Mary', 'Martha');
        _assert["default"].strictEqual(undirectedGraph.areInboundNeighbors('Mary', 'Martha'), true);
      }
    },
    '#.areUndirectedNeighbors': {
      'it should throw if node is not in the graph.': function itShouldThrowIfNodeIsNotInTheGraph() {
        var graph = new Graph();
        _assert["default"]["throws"](function () {
          graph.areUndirectedNeighbors('source', 'target');
        }, notFound());
      },
      'it should correctly return whether two nodes are neighbors.': function itShouldCorrectlyReturnWhetherTwoNodesAreNeighbors() {
        var graph = new Graph();
        graph.mergeDirectedEdge('Mary', 'Joseph');
        graph.mergeUndirectedEdge('Martha', 'Mary');
        _assert["default"].strictEqual(graph.areUndirectedNeighbors('Mary', 'Joseph'), false);
        _assert["default"].strictEqual(graph.areUndirectedNeighbors('Joseph', 'Mary'), false);
        _assert["default"].strictEqual(graph.areUndirectedNeighbors('Martha', 'Mary'), true);
        var directedGraph = new Graph({
          type: 'directed'
        });
        directedGraph.mergeEdge('Mary', 'Martha');
        _assert["default"].strictEqual(directedGraph.areUndirectedNeighbors('Mary', 'Martha'), false);
      }
    },
    '#.areNeighbors': {
      'it should throw if node is not in the graph.': function itShouldThrowIfNodeIsNotInTheGraph() {
        var graph = new Graph();
        _assert["default"]["throws"](function () {
          graph.areNeighbors('source', 'target');
        }, notFound());
      },
      'it should correctly return whether two nodes are neighbors.': function itShouldCorrectlyReturnWhetherTwoNodesAreNeighbors() {
        var graph = new Graph();
        graph.mergeDirectedEdge('Mary', 'Joseph');
        graph.mergeUndirectedEdge('Martha', 'Mary');
        _assert["default"].strictEqual(graph.areNeighbors('Mary', 'Joseph'), true);
        _assert["default"].strictEqual(graph.areNeighbors('Joseph', 'Mary'), true);
        _assert["default"].strictEqual(graph.areNeighbors('Martha', 'Mary'), true);
        _assert["default"].strictEqual(graph.areNeighbors('Joseph', 'Martha'), false);
        var undirectedGraph = new Graph({
          type: 'undirected'
        });
        undirectedGraph.mergeEdge('Mary', 'Martha');
        _assert["default"].strictEqual(undirectedGraph.areNeighbors('Mary', 'Martha'), true);
      }
    },
    '#.source': {
      'it should throw if the edge is not in the graph.': function itShouldThrowIfTheEdgeIsNotInTheGraph() {
        var graph = new Graph();
        _assert["default"]["throws"](function () {
          graph.source('test');
        }, notFound());
      },
      'it should return the correct source.': function itShouldReturnTheCorrectSource() {
        var graph = new Graph();
        graph.addNode('John');
        graph.addNode('Martha');
        var edge = graph.addDirectedEdge('John', 'Martha');
        _assert["default"].strictEqual(graph.source(edge), 'John');
      }
    },
    '#.target': {
      'it should throw if the edge is not in the graph.': function itShouldThrowIfTheEdgeIsNotInTheGraph() {
        var graph = new Graph();
        _assert["default"]["throws"](function () {
          graph.target('test');
        }, notFound());
      },
      'it should return the correct target.': function itShouldReturnTheCorrectTarget() {
        var graph = new Graph();
        graph.addNode('John');
        graph.addNode('Martha');
        var edge = graph.addDirectedEdge('John', 'Martha');
        _assert["default"].strictEqual(graph.target(edge), 'Martha');
      }
    },
    '#.extremities': {
      'it should throw if the edge is not in the graph.': function itShouldThrowIfTheEdgeIsNotInTheGraph() {
        var graph = new Graph();
        _assert["default"]["throws"](function () {
          graph.extremities('test');
        }, notFound());
      },
      'it should return the correct extremities.': function itShouldReturnTheCorrectExtremities() {
        var graph = new Graph();
        graph.addNode('John');
        graph.addNode('Martha');
        var edge = graph.addDirectedEdge('John', 'Martha');
        _assert["default"].deepStrictEqual(graph.extremities(edge), ['John', 'Martha']);
      }
    },
    '#.opposite': {
      'it should throw if either the node or the edge is not found in the graph.': function itShouldThrowIfEitherTheNodeOrTheEdgeIsNotFoundInTheGraph() {
        var graph = new Graph();
        graph.addNode('Thomas');
        _assert["default"]["throws"](function () {
          graph.opposite('Jeremy', 'T->J');
        }, notFound());
        _assert["default"]["throws"](function () {
          graph.opposite('Thomas', 'T->J');
        }, notFound());
      },
      'it should throw if the node & the edge are not related.': function itShouldThrowIfTheNodeTheEdgeAreNotRelated() {
        var graph = new Graph();
        (0, _helpers.addNodesFrom)(graph, ['Thomas', 'Isabella', 'Estelle']);
        graph.addEdgeWithKey('I->E', 'Isabella', 'Estelle');
        _assert["default"]["throws"](function () {
          graph.opposite('Thomas', 'I->E');
        }, notFound());
      },
      'it should return the correct node.': function itShouldReturnTheCorrectNode() {
        var graph = new Graph();
        (0, _helpers.addNodesFrom)(graph, ['Thomas', 'Estelle']);
        var edge = graph.addEdge('Thomas', 'Estelle');
        _assert["default"].strictEqual(graph.opposite('Thomas', edge), 'Estelle');
      }
    },
    '#.hasExtremity': {
      'it should throw if either the edge is not found in the graph.': function itShouldThrowIfEitherTheEdgeIsNotFoundInTheGraph() {
        var graph = new Graph();
        graph.mergeEdge('Thomas', 'Laura');
        _assert["default"]["throws"](function () {
          graph.hasExtremity('inexisting-edge', 'Thomas');
        }, notFound());
      },
      'it should return the correct answer.': function itShouldReturnTheCorrectAnswer() {
        var graph = new Graph();
        graph.addNode('Jack');
        var _graph$mergeEdge = graph.mergeEdge('Thomas', 'Estelle'),
          edge = _graph$mergeEdge[0];
        _assert["default"].strictEqual(graph.hasExtremity(edge, 'Thomas'), true);
        _assert["default"].strictEqual(graph.hasExtremity(edge, 'Estelle'), true);
        _assert["default"].strictEqual(graph.hasExtremity(edge, 'Jack'), false);
        _assert["default"].strictEqual(graph.hasExtremity(edge, 'Who?'), false);
      }
    },
    '#.isDirected': {
      'it should throw if the edge is not in the graph.': function itShouldThrowIfTheEdgeIsNotInTheGraph() {
        var graph = new Graph();
        _assert["default"]["throws"](function () {
          graph.isDirected('test');
        }, notFound());
      },
      'it should correctly return whether the edge is directed or not.': function itShouldCorrectlyReturnWhetherTheEdgeIsDirectedOrNot() {
        var graph = new Graph();
        graph.addNode('John');
        graph.addNode('Rachel');
        graph.addNode('Suzan');
        var directedEdge = graph.addDirectedEdge('John', 'Rachel'),
          undirectedEdge = graph.addUndirectedEdge('Rachel', 'Suzan');
        _assert["default"].strictEqual(graph.isDirected(directedEdge), true);
        _assert["default"].strictEqual(graph.isDirected(undirectedEdge), false);
      }
    },
    '#.isUndirected': {
      'it should throw if the edge is not in the graph.': function itShouldThrowIfTheEdgeIsNotInTheGraph() {
        var graph = new Graph();
        _assert["default"]["throws"](function () {
          graph.isUndirected('test');
        }, notFound());
      },
      'it should correctly return whether the edge is undirected or not.': function itShouldCorrectlyReturnWhetherTheEdgeIsUndirectedOrNot() {
        var graph = new Graph();
        graph.addNode('John');
        graph.addNode('Rachel');
        graph.addNode('Suzan');
        var directedEdge = graph.addDirectedEdge('John', 'Rachel'),
          undirectedEdge = graph.addUndirectedEdge('Rachel', 'Suzan');
        _assert["default"].strictEqual(graph.isUndirected(directedEdge), false);
        _assert["default"].strictEqual(graph.isUndirected(undirectedEdge), true);
      }
    },
    '#.isSelfLoop': {
      'it should throw if the edge is not in the graph.': function itShouldThrowIfTheEdgeIsNotInTheGraph() {
        var graph = new Graph();
        _assert["default"]["throws"](function () {
          graph.isSelfLoop('test');
        }, notFound());
      },
      'it should correctly return whether the edge is a self-loop or not.': function itShouldCorrectlyReturnWhetherTheEdgeIsASelfLoopOrNot() {
        var graph = new Graph();
        graph.addNode('John');
        graph.addNode('Rachel');
        var selfLoop = graph.addDirectedEdge('John', 'John'),
          edge = graph.addUndirectedEdge('John', 'Rachel');
        _assert["default"].strictEqual(graph.isSelfLoop(selfLoop), true);
        _assert["default"].strictEqual(graph.isSelfLoop(edge), false);
      }
    },
    Degree: {
      '#.inDegree': {
        'it should throw if the node is not found in the graph.': function itShouldThrowIfTheNodeIsNotFoundInTheGraph() {
          var graph = new Graph();
          _assert["default"]["throws"](function () {
            graph.inDegree('Test');
          }, notFound());
        },
        'it should return the correct in degree.': function itShouldReturnTheCorrectInDegree() {
          var graph = new Graph();
          (0, _helpers.addNodesFrom)(graph, ['Helen', 'Sue', 'William', 'John']);
          graph.addDirectedEdge('Helen', 'Sue');
          graph.addDirectedEdge('William', 'Sue');
          _assert["default"].strictEqual(graph.inDegree('Sue'), 2);
          graph.addDirectedEdge('Sue', 'Sue');
          _assert["default"].strictEqual(graph.inDegree('Sue'), 3);
          _assert["default"].strictEqual(graph.inDegreeWithoutSelfLoops('Sue'), 2);
        },
        'it should always return 0 in an undirected graph.': function itShouldAlwaysReturn0InAnUndirectedGraph() {
          var graph = new Graph({
            type: 'undirected'
          });
          (0, _helpers.addNodesFrom)(graph, ['Helen', 'Sue']);
          graph.addEdge('Helen', 'Sue');
          _assert["default"].strictEqual(graph.inDegree('Helen'), 0);
        }
      },
      '#.inboundDegree': {
        'it should throw if the node is not found in the graph.': function itShouldThrowIfTheNodeIsNotFoundInTheGraph() {
          var graph = new Graph();
          _assert["default"]["throws"](function () {
            graph.inboundDegree('Test');
          }, notFound());
        },
        'it should return the correct in degree.': function itShouldReturnTheCorrectInDegree() {
          var graph = new Graph();
          (0, _helpers.addNodesFrom)(graph, ['Helen', 'Sue', 'William', 'John']);
          graph.addDirectedEdge('Helen', 'Sue');
          graph.addDirectedEdge('William', 'Sue');
          graph.addUndirectedEdge('Helen', 'Sue');
          _assert["default"].strictEqual(graph.inboundDegree('Sue'), 3);
          graph.addDirectedEdge('Sue', 'Sue');
          _assert["default"].strictEqual(graph.inboundDegree('Sue'), 4);
          _assert["default"].strictEqual(graph.inboundDegreeWithoutSelfLoops('Sue'), 3);
        },
        'it should always the undirected degree in an undirected graph.': function itShouldAlwaysTheUndirectedDegreeInAnUndirectedGraph() {
          var graph = new Graph({
            type: 'undirected'
          });
          (0, _helpers.addNodesFrom)(graph, ['Helen', 'Sue']);
          graph.addEdge('Helen', 'Sue');
          _assert["default"].strictEqual(graph.inboundDegree('Helen'), 1);
        }
      },
      '#.outDegree': {
        'it should throw if the node is not found in the graph.': function itShouldThrowIfTheNodeIsNotFoundInTheGraph() {
          var graph = new Graph();
          _assert["default"]["throws"](function () {
            graph.outDegree('Test');
          }, notFound());
        },
        'it should return the correct out degree.': function itShouldReturnTheCorrectOutDegree() {
          var graph = new Graph();
          (0, _helpers.addNodesFrom)(graph, ['Helen', 'Sue', 'William', 'John']);
          graph.addDirectedEdge('Helen', 'Sue');
          graph.addDirectedEdge('Helen', 'William');
          _assert["default"].strictEqual(graph.outDegree('Helen'), 2);
          graph.addDirectedEdge('Helen', 'Helen');
          _assert["default"].strictEqual(graph.outDegree('Helen'), 3);
          _assert["default"].strictEqual(graph.outDegreeWithoutSelfLoops('Helen'), 2);
        },
        'it should always return 0 in an undirected graph.': function itShouldAlwaysReturn0InAnUndirectedGraph() {
          var graph = new Graph({
            type: 'undirected'
          });
          (0, _helpers.addNodesFrom)(graph, ['Helen', 'Sue']);
          graph.addEdge('Helen', 'Sue');
          _assert["default"].strictEqual(graph.outDegree('Sue'), 0);
        }
      },
      '#.outboundDegree': {
        'it should throw if the node is not found in the graph.': function itShouldThrowIfTheNodeIsNotFoundInTheGraph() {
          var graph = new Graph();
          _assert["default"]["throws"](function () {
            graph.outboundDegree('Test');
          }, notFound());
        },
        'it should return the correct out degree.': function itShouldReturnTheCorrectOutDegree() {
          var graph = new Graph();
          (0, _helpers.addNodesFrom)(graph, ['Helen', 'Sue', 'William', 'John']);
          graph.addDirectedEdge('Helen', 'Sue');
          graph.addDirectedEdge('Helen', 'William');
          graph.addUndirectedEdge('Helen', 'Sue');
          _assert["default"].strictEqual(graph.outboundDegree('Helen'), 3);
          graph.addDirectedEdge('Helen', 'Helen');
          _assert["default"].strictEqual(graph.outboundDegree('Helen'), 4);
          _assert["default"].strictEqual(graph.outboundDegreeWithoutSelfLoops('Helen'), 3);
        },
        'it should always the undirected degree in an undirected graph.': function itShouldAlwaysTheUndirectedDegreeInAnUndirectedGraph() {
          var graph = new Graph({
            type: 'undirected'
          });
          (0, _helpers.addNodesFrom)(graph, ['Helen', 'Sue']);
          graph.addEdge('Helen', 'Sue');
          _assert["default"].strictEqual(graph.outboundDegree('Sue'), 1);
        }
      },
      '#.directedDegree': {
        'it should throw if the node is not found in the graph.': function itShouldThrowIfTheNodeIsNotFoundInTheGraph() {
          var graph = new Graph();
          _assert["default"]["throws"](function () {
            graph.directedDegree('Test');
          }, notFound());
        },
        'it should return the correct directed degree.': function itShouldReturnTheCorrectDirectedDegree() {
          var graph = new Graph();
          (0, _helpers.addNodesFrom)(graph, ['Helen', 'Sue', 'William', 'John', 'Martha']);
          graph.addDirectedEdge('Helen', 'Sue');
          graph.addDirectedEdge('Helen', 'William');
          graph.addDirectedEdge('Martha', 'Helen');
          graph.addUndirectedEdge('Helen', 'John');
          _assert["default"].strictEqual(graph.directedDegree('Helen'), 3);
          _assert["default"].strictEqual(graph.directedDegree('Helen'), graph.inDegree('Helen') + graph.outDegree('Helen'));
          graph.addDirectedEdge('Helen', 'Helen');
          _assert["default"].strictEqual(graph.directedDegree('Helen'), 5);
          _assert["default"].strictEqual(graph.directedDegreeWithoutSelfLoops('Helen'), 3);
        },
        'it should always return 0 in an undirected graph.': function itShouldAlwaysReturn0InAnUndirectedGraph() {
          var graph = new Graph({
            type: 'undirected'
          });
          (0, _helpers.addNodesFrom)(graph, ['Helen', 'Sue']);
          graph.addEdge('Helen', 'Sue');
          _assert["default"].strictEqual(graph.inDegree('Helen'), 0);
        }
      },
      '#.undirectedDegree': {
        'it should throw if the node is not found in the graph.': function itShouldThrowIfTheNodeIsNotFoundInTheGraph() {
          var graph = new Graph();
          _assert["default"]["throws"](function () {
            graph.undirectedDegree('Test');
          }, notFound());
        },
        'it should return the correct undirected degree.': function itShouldReturnTheCorrectUndirectedDegree() {
          var graph = new Graph();
          (0, _helpers.addNodesFrom)(graph, ['Helen', 'Sue', 'William', 'John']);
          graph.addDirectedEdge('Helen', 'Sue');
          graph.addDirectedEdge('Helen', 'William');
          graph.addUndirectedEdge('Helen', 'John');
          _assert["default"].strictEqual(graph.undirectedDegree('Helen'), 1);
          graph.addUndirectedEdge('Helen', 'Helen');
          _assert["default"].strictEqual(graph.undirectedDegree('Helen'), 3);
          _assert["default"].strictEqual(graph.undirectedDegreeWithoutSelfLoops('Helen'), 1);
        },
        'it should always return 0 in a directed graph.': function itShouldAlwaysReturn0InADirectedGraph() {
          var graph = new Graph({
            type: 'directed'
          });
          (0, _helpers.addNodesFrom)(graph, ['Helen', 'Sue']);
          graph.addEdge('Helen', 'Sue');
          _assert["default"].strictEqual(graph.undirectedDegree('Helen'), 0);
        }
      },
      '#.degree': {
        'it should throw if the node is not found in the graph.': function itShouldThrowIfTheNodeIsNotFoundInTheGraph() {
          var graph = new Graph();
          _assert["default"]["throws"](function () {
            graph.degree('Test');
          }, notFound());
        },
        'it should return the correct degree.': function itShouldReturnTheCorrectDegree() {
          var graph = new Graph();
          (0, _helpers.addNodesFrom)(graph, ['Helen', 'Sue', 'William', 'John', 'Martha']);
          graph.addDirectedEdge('Helen', 'Sue');
          graph.addDirectedEdge('Helen', 'William');
          graph.addDirectedEdge('Martha', 'Helen');
          graph.addUndirectedEdge('Helen', 'John');
          _assert["default"].strictEqual(graph.degree('Helen'), 4);
          _assert["default"].strictEqual(graph.degree('Helen'), graph.directedDegree('Helen') + graph.undirectedDegree('Helen'));
          graph.addUndirectedEdge('Helen', 'Helen');
          _assert["default"].strictEqual(graph.degree('Helen'), 6);
          _assert["default"].strictEqual(graph.degreeWithoutSelfLoops('Helen'), 4);
        }
      },
      'it should also work with typed graphs.': function itShouldAlsoWorkWithTypedGraphs() {
        var directedGraph = new Graph({
            type: 'directed'
          }),
          undirectedGraph = new Graph({
            type: 'undirected'
          });
        (0, _helpers.addNodesFrom)(directedGraph, [1, 2]);
        (0, _helpers.addNodesFrom)(undirectedGraph, [1, 2]);
        _assert["default"].strictEqual(directedGraph.degree(1), 0);
        _assert["default"].strictEqual(undirectedGraph.degree(1), 0);
        directedGraph.addDirectedEdge(1, 2);
        undirectedGraph.addUndirectedEdge(1, 2);
        _assert["default"].strictEqual(directedGraph.degree(1), 1);
        _assert["default"].strictEqual(undirectedGraph.degree(1), 1);
      },
      'it should correctly consider self loops in the multi case (issue #431).': function itShouldCorrectlyConsiderSelfLoopsInTheMultiCaseIssue431() {
        var multiGraph = new Graph({
          multi: true
        });
        multiGraph.mergeDirectedEdge(0, 1);
        multiGraph.mergeDirectedEdge(0, 1);
        multiGraph.mergeDirectedEdge(1, 0);
        multiGraph.mergeUndirectedEdge(0, 1);
        multiGraph.mergeUndirectedEdge(0, 1);
        multiGraph.mergeDirectedEdge(2, 0);
        multiGraph.mergeDirectedEdge(0, 3);
        multiGraph.mergeUndirectedEdge(0, 3);
        multiGraph.mergeDirectedEdge(0, 0);
        multiGraph.mergeDirectedEdge(0, 0);
        multiGraph.mergeDirectedEdge(0, 0);
        multiGraph.mergeUndirectedEdge(0, 0);
        multiGraph.mergeUndirectedEdge(0, 0);
        _assert["default"].strictEqual(multiGraph.degree(0), 18);
        _assert["default"].strictEqual(multiGraph.directedDegree(0), 11);
        _assert["default"].strictEqual(multiGraph.undirectedDegree(0), 7);
        _assert["default"].strictEqual(multiGraph.outDegree(0), 6);
        _assert["default"].strictEqual(multiGraph.inDegree(0), 5);
        _assert["default"].strictEqual(multiGraph.degreeWithoutSelfLoops(0), 8);
        _assert["default"].strictEqual(multiGraph.directedDegreeWithoutSelfLoops(0), 5);
        _assert["default"].strictEqual(multiGraph.undirectedDegreeWithoutSelfLoops(0), 3);
        _assert["default"].strictEqual(multiGraph.outDegreeWithoutSelfLoops(0), 3);
        _assert["default"].strictEqual(multiGraph.inDegreeWithoutSelfLoops(0), 2);
      }
    }
  };
}