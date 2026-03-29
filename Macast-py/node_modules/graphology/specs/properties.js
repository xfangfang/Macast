"use strict";

Object.defineProperty(exports, "__esModule", {
  value: true
});
exports["default"] = properties;
var _assert = _interopRequireDefault(require("assert"));
function _interopRequireDefault(obj) { return obj && obj.__esModule ? obj : { "default": obj }; }
function _typeof(obj) { "@babel/helpers - typeof"; return _typeof = "function" == typeof Symbol && "symbol" == typeof Symbol.iterator ? function (obj) { return typeof obj; } : function (obj) { return obj && "function" == typeof Symbol && obj.constructor === Symbol && obj !== Symbol.prototype ? "symbol" : typeof obj; }, _typeof(obj); }
var PROPERTIES = ['order', 'size', 'directedSize', 'undirectedSize', 'type', 'multi', 'allowSelfLoops', 'implementation', 'selfLoopCount', 'directedSelfLoopCount', 'undirectedSelfLoopCount'];
function properties(Graph) {
  return {
    /**
     * Regarding all properties.
     */
    misc: {
      'all expected properties should be set.': function allExpectedPropertiesShouldBeSet() {
        var graph = new Graph();
        PROPERTIES.forEach(function (property) {
          (0, _assert["default"])(property in graph, property);
        });
      },
      'properties should be read-only.': function propertiesShouldBeReadOnly() {
        var graph = new Graph();

        // Attempting to mutate the properties
        PROPERTIES.forEach(function (property) {
          _assert["default"]["throws"](function () {
            graph[property] = 'test';
          }, TypeError);
        });
      }
    },
    /**
     * Order.
     */
    '#.order': {
      'it should be 0 if the graph is empty.': function itShouldBe0IfTheGraphIsEmpty() {
        var graph = new Graph();
        _assert["default"].strictEqual(graph.order, 0);
      },
      'adding nodes should increase order.': function addingNodesShouldIncreaseOrder() {
        var graph = new Graph();
        graph.addNode('John');
        graph.addNode('Jack');
        _assert["default"].strictEqual(graph.order, 2);
      }
    },
    /**
     * Size.
     */
    '#.size': {
      'it should be 0 if the graph is empty.': function itShouldBe0IfTheGraphIsEmpty() {
        var graph = new Graph();
        _assert["default"].strictEqual(graph.size, 0);
      },
      'adding & dropping edges should affect size.': function addingDroppingEdgesShouldAffectSize() {
        var graph = new Graph();
        graph.addNode('John');
        graph.addNode('Jack');
        graph.addDirectedEdge('John', 'Jack');
        _assert["default"].strictEqual(graph.size, 1);
        graph.dropEdge('John', 'Jack');
        _assert["default"].strictEqual(graph.size, 0);
      }
    },
    /**
     * Directed Size.
     */
    '#.directedSize': {
      'it should be 0 if the graph is empty.': function itShouldBe0IfTheGraphIsEmpty() {
        var graph = new Graph();
        _assert["default"].strictEqual(graph.directedSize, 0);
      },
      'adding & dropping edges should affect directed size.': function addingDroppingEdgesShouldAffectDirectedSize() {
        var graph = new Graph();
        graph.addNode('John');
        graph.addNode('Jack');
        var directedEdge = graph.addDirectedEdge('John', 'Jack');
        _assert["default"].strictEqual(graph.directedSize, 1);
        var undirectedEdge = graph.addUndirectedEdge('John', 'Jack');
        _assert["default"].strictEqual(graph.directedSize, 1);
        graph.dropEdge(directedEdge);
        _assert["default"].strictEqual(graph.directedSize, 0);
        graph.dropEdge(undirectedEdge);
        _assert["default"].strictEqual(graph.directedSize, 0);
      }
    },
    /**
     * Undirected Size.
     */
    '#.undirectedSize': {
      'it should be 0 if the graph is empty.': function itShouldBe0IfTheGraphIsEmpty() {
        var graph = new Graph();
        _assert["default"].strictEqual(graph.undirectedSize, 0);
      },
      'adding & dropping edges should affect undirected size.': function addingDroppingEdgesShouldAffectUndirectedSize() {
        var graph = new Graph();
        graph.addNode('John');
        graph.addNode('Jack');
        var directedEdge = graph.addDirectedEdge('John', 'Jack');
        _assert["default"].strictEqual(graph.undirectedSize, 0);
        var undirectedEdge = graph.addUndirectedEdge('John', 'Jack');
        _assert["default"].strictEqual(graph.undirectedSize, 1);
        graph.dropEdge(directedEdge);
        _assert["default"].strictEqual(graph.undirectedSize, 1);
        graph.dropEdge(undirectedEdge);
        _assert["default"].strictEqual(graph.undirectedSize, 0);
      }
    },
    /**
     * Multi.
     */
    '#.multi': {
      'it should be false by default.': function itShouldBeFalseByDefault() {
        var graph = new Graph();
        _assert["default"].strictEqual(graph.multi, false);
      }
    },
    /**
     * Type.
     */
    '#.type': {
      'it should be "mixed" by default.': function itShouldBeMixedByDefault() {
        var graph = new Graph();
        _assert["default"].strictEqual(graph.type, 'mixed');
      }
    },
    /**
     * Self loops.
     */
    '#.allowSelfLoops': {
      'it should be true by default.': function itShouldBeTrueByDefault() {
        var graph = new Graph();
        _assert["default"].strictEqual(graph.allowSelfLoops, true);
      }
    },
    /**
     * Implementation.
     */
    '#.implementation': {
      'it should exist and be a string.': function itShouldExistAndBeAString() {
        var graph = new Graph();
        _assert["default"].strictEqual(_typeof(graph.implementation), 'string');
      }
    },
    /**
     * Self Loop Count.
     */
    '#.selfLoopCount': {
      'it should exist and be correct.': function itShouldExistAndBeCorrect() {
        var graph = new Graph();
        graph.mergeDirectedEdge('John', 'John');
        graph.mergeDirectedEdge('Lucy', 'Lucy');
        graph.mergeUndirectedEdge('Joana', 'Joana');
        _assert["default"].strictEqual(graph.selfLoopCount, 3);
        _assert["default"].strictEqual(graph.directedSelfLoopCount, 2);
        _assert["default"].strictEqual(graph.undirectedSelfLoopCount, 1);
        graph.forEachEdge(function (edge) {
          return graph.dropEdge(edge);
        });
        _assert["default"].strictEqual(graph.selfLoopCount, 0);
        _assert["default"].strictEqual(graph.directedSelfLoopCount, 0);
        _assert["default"].strictEqual(graph.undirectedSelfLoopCount, 0);
      }
    }
  };
}