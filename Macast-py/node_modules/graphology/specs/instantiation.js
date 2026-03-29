"use strict";

Object.defineProperty(exports, "__esModule", {
  value: true
});
exports["default"] = instantiation;
var _assert = _interopRequireDefault(require("assert"));
var _helpers = require("./helpers");
function _interopRequireDefault(obj) { return obj && obj.__esModule ? obj : { "default": obj }; }
/* eslint no-unused-vars: 0 */
/**
 * Graphology Instantiation Specs
 * ===============================
 *
 * Testing the instantiation of the graph.
 */

var CONSTRUCTORS = ['DirectedGraph', 'UndirectedGraph', 'MultiGraph', 'MultiDirectedGraph', 'MultiUndirectedGraph'];
var OPTIONS = [{
  multi: false,
  type: 'directed'
}, {
  multi: false,
  type: 'undirected'
}, {
  multi: true,
  type: 'mixed'
}, {
  multi: true,
  type: 'directed'
}, {
  multi: true,
  type: 'undirected'
}];
function instantiation(Graph, implementation, checkers) {
  var invalid = checkers.invalid;
  return {
    'Static #.from method': {
      'it should be possible to create a Graph from a Graph instance.': function itShouldBePossibleToCreateAGraphFromAGraphInstance() {
        var graph = new Graph();
        (0, _helpers.addNodesFrom)(graph, ['John', 'Thomas']);
        graph.addEdge('John', 'Thomas');
        var other = Graph.from(graph);
        _assert["default"].deepStrictEqual(graph.nodes(), other.nodes());
        _assert["default"].deepStrictEqual(graph.edges(), other.edges());
      },
      'it should be possible to create a Graph from a serialized graph': function itShouldBePossibleToCreateAGraphFromASerializedGraph() {
        var graph = Graph.from({
          nodes: [{
            key: 'John'
          }, {
            key: 'Thomas'
          }],
          edges: [{
            source: 'John',
            target: 'Thomas'
          }]
        });
        _assert["default"].deepStrictEqual(graph.nodes(), ['John', 'Thomas']);
        _assert["default"].strictEqual(graph.hasEdge('John', 'Thomas'), true);
      },
      'it should be possible to provide options.': function itShouldBePossibleToProvideOptions() {
        var graph = Graph.from({
          node: [{
            key: 'John'
          }],
          attributes: {
            name: 'Awesome graph'
          }
        }, {
          type: 'directed'
        });
        _assert["default"].strictEqual(graph.type, 'directed');
        _assert["default"].strictEqual(graph.getAttribute('name'), 'Awesome graph');
      },
      'it should be possible to take options from the serialized format.': function itShouldBePossibleToTakeOptionsFromTheSerializedFormat() {
        var graph = Graph.from({
          node: [{
            key: 'John'
          }],
          attributes: {
            name: 'Awesome graph'
          },
          options: {
            type: 'directed',
            multi: true
          }
        });
        _assert["default"].strictEqual(graph.type, 'directed');
        _assert["default"].strictEqual(graph.multi, true);
        _assert["default"].strictEqual(graph.getAttribute('name'), 'Awesome graph');
      },
      'given options should take precedence over the serialization ones.': function givenOptionsShouldTakePrecedenceOverTheSerializationOnes() {
        var graph = Graph.from({
          node: [{
            key: 'John'
          }],
          attributes: {
            name: 'Awesome graph'
          },
          options: {
            type: 'directed',
            multi: true
          }
        }, {
          type: 'undirected'
        });
        _assert["default"].strictEqual(graph.type, 'undirected');
        _assert["default"].strictEqual(graph.multi, true);
        _assert["default"].strictEqual(graph.getAttribute('name'), 'Awesome graph');
      }
    },
    Options: {
      /**
       * allowSelfLoops
       */
      allowSelfLoops: {
        'providing a non-boolean value should throw.': function providingANonBooleanValueShouldThrow() {
          _assert["default"]["throws"](function () {
            var graph = new Graph({
              allowSelfLoops: 'test'
            });
          }, invalid());
        }
      },
      /**
       * multi
       */
      multi: {
        'providing a non-boolean value should throw.': function providingANonBooleanValueShouldThrow() {
          _assert["default"]["throws"](function () {
            var graph = new Graph({
              multi: 'test'
            });
          }, invalid());
        }
      },
      /**
       * type
       */
      type: {
        'providing an invalid type should throw.': function providingAnInvalidTypeShouldThrow() {
          _assert["default"]["throws"](function () {
            var graph = new Graph({
              type: 'test'
            });
          }, invalid());
        }
      }
    },
    Constructors: {
      'all alternative constructors should be available.': function allAlternativeConstructorsShouldBeAvailable() {
        CONSTRUCTORS.forEach(function (name) {
          return (0, _assert["default"])(name in implementation);
        });
      },
      'alternative constructors should have the correct options.': function alternativeConstructorsShouldHaveTheCorrectOptions() {
        CONSTRUCTORS.forEach(function (name, index) {
          var graph = new implementation[name]();
          var _OPTIONS$index = OPTIONS[index],
            multi = _OPTIONS$index.multi,
            type = _OPTIONS$index.type;
          _assert["default"].strictEqual(graph.multi, multi);
          _assert["default"].strictEqual(graph.type, type);
        });
      },
      'alternative constructors should throw if given inconsistent options.': function alternativeConstructorsShouldThrowIfGivenInconsistentOptions() {
        CONSTRUCTORS.forEach(function (name, index) {
          var _OPTIONS$index2 = OPTIONS[index],
            multi = _OPTIONS$index2.multi,
            type = _OPTIONS$index2.type;
          _assert["default"]["throws"](function () {
            var graph = new implementation[name]({
              multi: !multi
            });
          }, invalid());
          if (type === 'mixed') return;
          _assert["default"]["throws"](function () {
            var graph = new implementation[name]({
              type: type === 'directed' ? 'undirected' : 'directed'
            });
          }, invalid());
        });
      }
    }
  };
}