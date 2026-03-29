"use strict";

Object.defineProperty(exports, "__esModule", {
  value: true
});
exports["default"] = attributes;
var _assert = _interopRequireDefault(require("assert"));
var _helpers = require("./helpers");
function _interopRequireDefault(obj) { return obj && obj.__esModule ? obj : { "default": obj }; }
function ownKeys(object, enumerableOnly) { var keys = Object.keys(object); if (Object.getOwnPropertySymbols) { var symbols = Object.getOwnPropertySymbols(object); enumerableOnly && (symbols = symbols.filter(function (sym) { return Object.getOwnPropertyDescriptor(object, sym).enumerable; })), keys.push.apply(keys, symbols); } return keys; }
function _objectSpread(target) { for (var i = 1; i < arguments.length; i++) { var source = null != arguments[i] ? arguments[i] : {}; i % 2 ? ownKeys(Object(source), !0).forEach(function (key) { _defineProperty(target, key, source[key]); }) : Object.getOwnPropertyDescriptors ? Object.defineProperties(target, Object.getOwnPropertyDescriptors(source)) : ownKeys(Object(source)).forEach(function (key) { Object.defineProperty(target, key, Object.getOwnPropertyDescriptor(source, key)); }); } return target; }
function _defineProperty(obj, key, value) { if (key in obj) { Object.defineProperty(obj, key, { value: value, enumerable: true, configurable: true, writable: true }); } else { obj[key] = value; } return obj; }
function attributes(Graph, checkers) {
  var invalid = checkers.invalid,
    notFound = checkers.notFound,
    usage = checkers.usage;
  function commonTests(method) {
    return _defineProperty({}, '#.' + method, {
      'it should throw if the given path is not found.': function itShouldThrowIfTheGivenPathIsNotFound() {
        if (!method.includes('Edge')) return;
        var graph = new Graph();
        _assert["default"]["throws"](function () {
          graph[method]('source', 'target', 'name', 'value');
        }, notFound());
      },
      'it should throw when using a path on a multi graph.': function itShouldThrowWhenUsingAPathOnAMultiGraph() {
        if (!method.includes('Edge')) return;
        var graph = new Graph({
          multi: true
        });
        _assert["default"]["throws"](function () {
          graph[method]('source', 'target', 'name', 'value');
        }, usage());
      },
      'it should throw if the element is not found in the graph.': function itShouldThrowIfTheElementIsNotFoundInTheGraph() {
        var graph = new Graph();
        if (method.includes('Edge') && method.includes('Directed') || method.includes('Undirected')) {
          _assert["default"]["throws"](function () {
            graph[method]('Test');
          }, usage());
        } else {
          _assert["default"]["throws"](function () {
            graph[method]('Test');
          }, notFound());
        }
      }
    });
  }
  var tests = {};
  var relevantMethods = Object.keys(Graph.prototype).filter(function (name) {
    return (name.includes('NodeAttribute') || name.includes('EdgeAttribute') || name.includes('SourceAttribute') || name.includes('TargetAttribute') || name.includes('OppositeAttribute')) && !name.includes('Each');
  });
  relevantMethods.forEach(function (method) {
    return (0, _helpers.deepMerge)(tests, commonTests(method));
  });
  return (0, _helpers.deepMerge)(tests, {
    '#.getAttribute': {
      'it should return the correct value.': function itShouldReturnTheCorrectValue() {
        var graph = new Graph();
        graph.setAttribute('name', 'graph');
        _assert["default"].strictEqual(graph.getAttribute('name'), 'graph');
      },
      'it should return undefined if the attribute does not exist.': function itShouldReturnUndefinedIfTheAttributeDoesNotExist() {
        var graph = new Graph();
        _assert["default"].strictEqual(graph.getAttribute('name'), undefined);
      }
    },
    '#.getNodeAttribute': {
      'it should return the correct value.': function itShouldReturnTheCorrectValue() {
        var graph = new Graph();
        graph.addNode('Martha', {
          age: 34
        });
        _assert["default"].strictEqual(graph.getNodeAttribute('Martha', 'age'), 34);
      },
      'it should return undefined if the attribute does not exist.': function itShouldReturnUndefinedIfTheAttributeDoesNotExist() {
        var graph = new Graph();
        graph.addNode('Martha');
        _assert["default"].strictEqual(graph.getNodeAttribute('Martha', 'age'), undefined);
      }
    },
    '#.getSourceAttribute': {
      'it should return the correct value.': function itShouldReturnTheCorrectValue() {
        var graph = new Graph();
        graph.addNode('Martha', {
          age: 34
        });
        var _graph$mergeEdge = graph.mergeEdge('Martha', 'Riwan'),
          edge = _graph$mergeEdge[0];
        _assert["default"].strictEqual(graph.getSourceAttribute(edge, 'age'), 34);
      },
      'it should return undefined if the attribute does not exist.': function itShouldReturnUndefinedIfTheAttributeDoesNotExist() {
        var graph = new Graph();
        graph.addNode('Martha');
        var _graph$mergeEdge2 = graph.mergeEdge('Martha', 'Riwan'),
          edge = _graph$mergeEdge2[0];
        _assert["default"].strictEqual(graph.getSourceAttribute(edge, 'age'), undefined);
      }
    },
    '#.getTargetAttribute': {
      'it should return the correct value.': function itShouldReturnTheCorrectValue() {
        var graph = new Graph();
        graph.addNode('Martha', {
          age: 34
        });
        var _graph$mergeEdge3 = graph.mergeEdge('Riwan', 'Martha'),
          edge = _graph$mergeEdge3[0];
        _assert["default"].strictEqual(graph.getTargetAttribute(edge, 'age'), 34);
      },
      'it should return undefined if the attribute does not exist.': function itShouldReturnUndefinedIfTheAttributeDoesNotExist() {
        var graph = new Graph();
        graph.addNode('Martha');
        var _graph$mergeEdge4 = graph.mergeEdge('Riwan', 'Martha'),
          edge = _graph$mergeEdge4[0];
        _assert["default"].strictEqual(graph.getTargetAttribute(edge, 'age'), undefined);
      }
    },
    '#.getOppositeAttribute': {
      'it should return the correct value.': function itShouldReturnTheCorrectValue() {
        var graph = new Graph();
        graph.addNode('Martha', {
          age: 34
        });
        graph.addNode('Riwan', {
          age: 25
        });
        var _graph$mergeEdge5 = graph.mergeEdge('Riwan', 'Martha'),
          edge = _graph$mergeEdge5[0];
        _assert["default"].strictEqual(graph.getOppositeAttribute('Riwan', edge, 'age'), 34);
        _assert["default"].strictEqual(graph.getOppositeAttribute('Martha', edge, 'age'), 25);
      }
    },
    '#.getEdgeAttribute': {
      'it should return the correct value.': function itShouldReturnTheCorrectValue() {
        var graph = new Graph();
        (0, _helpers.addNodesFrom)(graph, ['John', 'Thomas']);
        var edge = graph.addEdge('John', 'Thomas', {
          weight: 2
        });
        _assert["default"].strictEqual(graph.getEdgeAttribute(edge, 'weight'), 2);
        _assert["default"].strictEqual(graph.getEdgeAttribute('John', 'Thomas', 'weight'), 2);
      },
      'it should also work with typed edges.': function itShouldAlsoWorkWithTypedEdges() {
        var graph = new Graph();
        (0, _helpers.addNodesFrom)(graph, ['John', 'Thomas']);
        graph.addDirectedEdge('John', 'Thomas', {
          weight: 2
        });
        graph.addUndirectedEdge('John', 'Thomas', {
          weight: 3
        });
        _assert["default"].strictEqual(graph.getDirectedEdgeAttribute('John', 'Thomas', 'weight'), 2);
        _assert["default"].strictEqual(graph.getUndirectedEdgeAttribute('John', 'Thomas', 'weight'), 3);
      },
      'it should return undefined if the attribute does not exist.': function itShouldReturnUndefinedIfTheAttributeDoesNotExist() {
        var graph = new Graph();
        (0, _helpers.addNodesFrom)(graph, ['John', 'Thomas']);
        var edge = graph.addEdge('John', 'Thomas');
        _assert["default"].strictEqual(graph.getEdgeAttribute(edge, 'weight'), undefined);
      }
    },
    '#.getAttributes': {
      'it should return the correct value.': function itShouldReturnTheCorrectValue() {
        var graph = new Graph();
        graph.setAttribute('name', 'graph');
        _assert["default"].deepStrictEqual(graph.getAttributes(), {
          name: 'graph'
        });
      },
      'it should return an empty object if the node does not have attributes.': function itShouldReturnAnEmptyObjectIfTheNodeDoesNotHaveAttributes() {
        var graph = new Graph();
        _assert["default"].deepStrictEqual(graph.getAttributes(), {});
      }
    },
    '#.getNodeAttributes': {
      'it should return the correct value.': function itShouldReturnTheCorrectValue() {
        var graph = new Graph();
        graph.addNode('Martha', {
          age: 34
        });
        _assert["default"].deepStrictEqual(graph.getNodeAttributes('Martha'), {
          age: 34
        });
      },
      'it should return an empty object if the node does not have attributes.': function itShouldReturnAnEmptyObjectIfTheNodeDoesNotHaveAttributes() {
        var graph = new Graph();
        graph.addNode('Martha');
        _assert["default"].deepStrictEqual(graph.getNodeAttributes('Martha'), {});
      }
    },
    '#.getEdgeAttributes': {
      'it should return the correct value.': function itShouldReturnTheCorrectValue() {
        var graph = new Graph();
        (0, _helpers.addNodesFrom)(graph, ['John', 'Thomas']);
        var edge = graph.addEdge('John', 'Thomas', {
          weight: 2
        });
        _assert["default"].deepStrictEqual(graph.getEdgeAttributes(edge), {
          weight: 2
        });
        _assert["default"].deepStrictEqual(graph.getEdgeAttributes('John', 'Thomas'), {
          weight: 2
        });
      },
      'it should also work with typed edges.': function itShouldAlsoWorkWithTypedEdges() {
        var graph = new Graph();
        (0, _helpers.addNodesFrom)(graph, ['John', 'Thomas']);
        graph.addDirectedEdge('John', 'Thomas', {
          weight: 2
        });
        graph.addUndirectedEdge('John', 'Thomas', {
          weight: 3
        });
        _assert["default"].deepStrictEqual(graph.getDirectedEdgeAttributes('John', 'Thomas', 'weight'), {
          weight: 2
        });
        _assert["default"].deepStrictEqual(graph.getUndirectedEdgeAttributes('John', 'Thomas', 'weight'), {
          weight: 3
        });
      },
      'it should return an empty object if the edge does not have attributes.': function itShouldReturnAnEmptyObjectIfTheEdgeDoesNotHaveAttributes() {
        var graph = new Graph();
        (0, _helpers.addNodesFrom)(graph, ['John', 'Thomas']);
        var edge = graph.addEdge('John', 'Thomas');
        _assert["default"].deepStrictEqual(graph.getEdgeAttributes(edge), {});
      }
    },
    '#.hasAttribute': {
      'it should correctly return whether the attribute is set.': function itShouldCorrectlyReturnWhetherTheAttributeIsSet() {
        var graph = new Graph();
        graph.setAttribute('name', 'graph');
        _assert["default"].strictEqual(graph.hasAttribute('name'), true);
        _assert["default"].strictEqual(graph.hasAttribute('info'), false);
      },
      'it does not fail with typical prototypal properties.': function itDoesNotFailWithTypicalPrototypalProperties() {
        var graph = new Graph();
        _assert["default"].strictEqual(graph.hasAttribute('toString'), false);
      }
    },
    '#.hasNodeAttribute': {
      'it should correctly return whether the attribute is set.': function itShouldCorrectlyReturnWhetherTheAttributeIsSet() {
        var graph = new Graph();
        graph.addNode('John', {
          age: 20
        });
        _assert["default"].strictEqual(graph.hasNodeAttribute('John', 'age'), true);
        _assert["default"].strictEqual(graph.hasNodeAttribute('John', 'eyes'), false);
      },
      'it does not fail with typical prototypal properties.': function itDoesNotFailWithTypicalPrototypalProperties() {
        var graph = new Graph();
        graph.addNode('John', {
          age: 20
        });
        _assert["default"].strictEqual(graph.hasNodeAttribute('John', 'toString'), false);
      }
    },
    '#.hasEdgeAttribute': {
      'it should correctly return whether the attribute is set.': function itShouldCorrectlyReturnWhetherTheAttributeIsSet() {
        var graph = new Graph();
        (0, _helpers.addNodesFrom)(graph, ['John', 'Martha']);
        graph.addEdgeWithKey('J->M', 'John', 'Martha', {
          weight: 10
        });
        _assert["default"].strictEqual(graph.hasEdgeAttribute('J->M', 'weight'), true);
        _assert["default"].strictEqual(graph.hasEdgeAttribute('J->M', 'type'), false);
      },
      'it should also work with typed edges.': function itShouldAlsoWorkWithTypedEdges() {
        var graph = new Graph();
        (0, _helpers.addNodesFrom)(graph, ['John', 'Thomas']);
        graph.addDirectedEdge('John', 'Thomas', {
          weight: 2
        });
        graph.addUndirectedEdge('John', 'Thomas');
        _assert["default"].strictEqual(graph.hasDirectedEdgeAttribute('John', 'Thomas', 'weight'), true);
        _assert["default"].strictEqual(graph.hasUndirectedEdgeAttribute('John', 'Thomas', 'weight'), false);
      },
      'it does not fail with typical prototypal properties.': function itDoesNotFailWithTypicalPrototypalProperties() {
        var graph = new Graph();
        (0, _helpers.addNodesFrom)(graph, ['John', 'Martha']);
        graph.addEdgeWithKey('J->M', 'John', 'Martha', {
          weight: 10
        });
        _assert["default"].strictEqual(graph.hasEdgeAttribute('J->M', 'toString'), false);
      }
    },
    '#.setAttribute': {
      "it should correctly set the graph's attribute.": function itShouldCorrectlySetTheGraphSAttribute() {
        var graph = new Graph();
        graph.setAttribute('name', 'graph');
        _assert["default"].strictEqual(graph.getAttribute('name'), 'graph');
      }
    },
    '#.setNodeAttribute': {
      "it should correctly set the node's attribute.": function itShouldCorrectlySetTheNodeSAttribute() {
        var graph = new Graph();
        graph.addNode('John', {
          age: 20
        });
        graph.setNodeAttribute('John', 'age', 45);
        _assert["default"].strictEqual(graph.getNodeAttribute('John', 'age'), 45);
      }
    },
    '#.setEdgeAttribute': {
      "it should correctly set the edge's attribute.": function itShouldCorrectlySetTheEdgeSAttribute() {
        var graph = new Graph();
        (0, _helpers.addNodesFrom)(graph, ['John', 'Martha']);
        var edge = graph.addEdge('John', 'Martha', {
          weight: 3
        });
        graph.setEdgeAttribute(edge, 'weight', 40);
        _assert["default"].strictEqual(graph.getEdgeAttribute(edge, 'weight'), 40);
        graph.setEdgeAttribute('John', 'Martha', 'weight', 60);
        _assert["default"].strictEqual(graph.getEdgeAttribute(edge, 'weight'), 60);
      },
      'it should also work with typed edges.': function itShouldAlsoWorkWithTypedEdges() {
        var graph = new Graph();
        (0, _helpers.addNodesFrom)(graph, ['John', 'Thomas']);
        graph.addDirectedEdge('John', 'Thomas', {
          weight: 0
        });
        graph.addUndirectedEdge('John', 'Thomas', {
          weight: 0
        });
        graph.setDirectedEdgeAttribute('John', 'Thomas', 'weight', 2);
        graph.setUndirectedEdgeAttribute('John', 'Thomas', 'weight', 3);
        _assert["default"].strictEqual(graph.getDirectedEdgeAttribute('John', 'Thomas', 'weight'), 2);
        _assert["default"].strictEqual(graph.getUndirectedEdgeAttribute('John', 'Thomas', 'weight'), 3);
      }
    },
    '#.updateAttribute': {
      'it should throw if the updater is not a function.': function itShouldThrowIfTheUpdaterIsNotAFunction() {
        var graph = new Graph();
        graph.setAttribute('count', 0);
        _assert["default"]["throws"](function () {
          graph.updateAttribute('count', {
            hello: 'world'
          });
        }, invalid());
      },
      "it should correctly set the graph's attribute.": function itShouldCorrectlySetTheGraphSAttribute() {
        var graph = new Graph();
        graph.setAttribute('name', 'graph');
        graph.updateAttribute('name', function (name) {
          return name + '1';
        });
        _assert["default"].strictEqual(graph.getAttribute('name'), 'graph1');
      },
      'the given value should be undefined if not found.': function theGivenValueShouldBeUndefinedIfNotFound() {
        var graph = new Graph();
        var updater = function updater(x) {
          _assert["default"].strictEqual(x, undefined);
          return 'graph';
        };
        graph.updateAttribute('name', updater);
        _assert["default"].strictEqual(graph.getAttribute('name'), 'graph');
      }
    },
    '#.updateNodeAttribute': {
      'it should throw if given an invalid updater.': function itShouldThrowIfGivenAnInvalidUpdater() {
        var graph = new Graph();
        graph.addNode('John', {
          age: 20
        });
        _assert["default"]["throws"](function () {
          graph.updateNodeAttribute('John', 'age', {
            hello: 'world'
          });
        }, invalid());
      },
      'it should throw if not enough arguments are provided.': function itShouldThrowIfNotEnoughArgumentsAreProvided() {
        var graph = new Graph();
        graph.addNode('Lucy');
        _assert["default"]["throws"](function () {
          graph.updateNodeAttribute('Lucy', {
            hello: 'world'
          });
        }, invalid());
      },
      "it should correctly set the node's attribute.": function itShouldCorrectlySetTheNodeSAttribute() {
        var graph = new Graph();
        graph.addNode('John', {
          age: 20
        });
        graph.updateNodeAttribute('John', 'age', function (x) {
          return x + 1;
        });
        _assert["default"].strictEqual(graph.getNodeAttribute('John', 'age'), 21);
      },
      'the given value should be undefined if not found.': function theGivenValueShouldBeUndefinedIfNotFound() {
        var graph = new Graph();
        graph.addNode('John');
        var updater = function updater(x) {
          _assert["default"].strictEqual(x, undefined);
          return 10;
        };
        graph.updateNodeAttribute('John', 'age', updater);
        _assert["default"].strictEqual(graph.getNodeAttribute('John', 'age'), 10);
      }
    },
    '#.updateEdgeAttribute': {
      'it should throw if given an invalid updater.': function itShouldThrowIfGivenAnInvalidUpdater() {
        var graph = new Graph();
        (0, _helpers.addNodesFrom)(graph, ['John', 'Martha']);
        graph.addEdge('John', 'Martha', {
          weight: 3
        });
        _assert["default"]["throws"](function () {
          graph.updateEdgeAttribute('John', 'Martha', 'weight', {
            hello: 'world'
          });
        }, invalid());
      },
      "it should correctly set the edge's attribute.": function itShouldCorrectlySetTheEdgeSAttribute() {
        var graph = new Graph();
        (0, _helpers.addNodesFrom)(graph, ['John', 'Martha']);
        var edge = graph.addEdge('John', 'Martha', {
          weight: 3
        });
        graph.updateEdgeAttribute(edge, 'weight', function (x) {
          return x + 1;
        });
        _assert["default"].strictEqual(graph.getEdgeAttribute(edge, 'weight'), 4);
        graph.updateEdgeAttribute('John', 'Martha', 'weight', function (x) {
          return x + 2;
        });
        _assert["default"].strictEqual(graph.getEdgeAttribute(edge, 'weight'), 6);
      },
      'it should also work with typed edges.': function itShouldAlsoWorkWithTypedEdges() {
        var graph = new Graph();
        (0, _helpers.addNodesFrom)(graph, ['John', 'Thomas']);
        graph.addDirectedEdge('John', 'Thomas', {
          weight: 0
        });
        graph.addUndirectedEdge('John', 'Thomas', {
          weight: 0
        });
        graph.updateDirectedEdgeAttribute('John', 'Thomas', 'weight', function (x) {
          return x + 2;
        });
        graph.updateUndirectedEdgeAttribute('John', 'Thomas', 'weight', function (x) {
          return x + 3;
        });
        _assert["default"].strictEqual(graph.getDirectedEdgeAttribute('John', 'Thomas', 'weight'), 2);
        _assert["default"].strictEqual(graph.getUndirectedEdgeAttribute('John', 'Thomas', 'weight'), 3);
      },
      'the given value should be undefined if not found.': function theGivenValueShouldBeUndefinedIfNotFound() {
        var graph = new Graph();
        (0, _helpers.addNodesFrom)(graph, ['John', 'Martha']);
        var edge = graph.addEdge('John', 'Martha');
        var updater = function updater(x) {
          _assert["default"].strictEqual(x, undefined);
          return 10;
        };
        graph.updateEdgeAttribute(edge, 'weight', updater);
        _assert["default"].strictEqual(graph.getEdgeAttribute(edge, 'weight'), 10);
      }
    },
    '#.removeAttribute': {
      'it should correctly remove the attribute.': function itShouldCorrectlyRemoveTheAttribute() {
        var graph = new Graph();
        graph.setAttribute('name', 'graph');
        graph.removeAttribute('name');
        _assert["default"].strictEqual(graph.hasAttribute('name'), false);
        _assert["default"].deepStrictEqual(graph.getAttributes(), {});
      }
    },
    '#.removeNodeAttribute': {
      'it should correctly remove the attribute.': function itShouldCorrectlyRemoveTheAttribute() {
        var graph = new Graph();
        graph.addNode('Martha', {
          age: 34
        });
        graph.removeNodeAttribute('Martha', 'age');
        _assert["default"].strictEqual(graph.hasNodeAttribute('Martha', 'age'), false);
        _assert["default"].deepStrictEqual(graph.getNodeAttributes('Martha'), {});
      }
    },
    '#.removeEdgeAttribute': {
      'it should correclty remove the attribute.': function itShouldCorrecltyRemoveTheAttribute() {
        var graph = new Graph();
        var _graph$mergeEdge6 = graph.mergeEdge('John', 'Martha', {
            weight: 1,
            size: 3
          }),
          edge = _graph$mergeEdge6[0];
        graph.removeEdgeAttribute('John', 'Martha', 'weight');
        graph.removeEdgeAttribute(edge, 'size');
        _assert["default"].strictEqual(graph.hasEdgeAttribute(edge, 'weight'), false);
        _assert["default"].strictEqual(graph.hasEdgeAttribute(edge, 'size'), false);
        _assert["default"].deepStrictEqual(graph.getEdgeAttributes(edge), {});
      },
      'it should also work with typed edges.': function itShouldAlsoWorkWithTypedEdges() {
        var graph = new Graph();
        (0, _helpers.addNodesFrom)(graph, ['John', 'Thomas']);
        graph.addDirectedEdge('John', 'Thomas', {
          weight: 2
        });
        graph.addUndirectedEdge('John', 'Thomas', {
          weight: 3
        });
        graph.removeDirectedEdgeAttribute('John', 'Thomas', 'weight');
        graph.removeUndirectedEdgeAttribute('John', 'Thomas', 'weight');
        _assert["default"].strictEqual(graph.hasDirectedEdgeAttribute('John', 'Thomas', 'weight'), false);
        _assert["default"].strictEqual(graph.hasUndirectedEdgeAttribute('John', 'Thomas', 'weight'), false);
      }
    },
    '#.replaceAttribute': {
      'it should throw if given attributes are not a plain object.': function itShouldThrowIfGivenAttributesAreNotAPlainObject() {
        var graph = new Graph();
        _assert["default"]["throws"](function () {
          graph.replaceAttributes(true);
        }, invalid());
      },
      'it should correctly replace attributes.': function itShouldCorrectlyReplaceAttributes() {
        var graph = new Graph();
        graph.setAttribute('name', 'graph');
        graph.replaceAttributes({
          name: 'other graph'
        });
        _assert["default"].deepStrictEqual(graph.getAttributes(), {
          name: 'other graph'
        });
      }
    },
    '#.replaceNodeAttributes': {
      'it should throw if given attributes are not a plain object.': function itShouldThrowIfGivenAttributesAreNotAPlainObject() {
        var graph = new Graph();
        graph.addNode('John');
        _assert["default"]["throws"](function () {
          graph.replaceNodeAttributes('John', true);
        }, invalid());
      },
      'it should correctly replace attributes.': function itShouldCorrectlyReplaceAttributes() {
        var graph = new Graph();
        graph.addNode('John', {
          age: 45
        });
        graph.replaceNodeAttributes('John', {
          age: 23,
          eyes: 'blue'
        });
        _assert["default"].deepStrictEqual(graph.getNodeAttributes('John'), {
          age: 23,
          eyes: 'blue'
        });
      }
    },
    '#.replaceEdgeAttributes': {
      'it should throw if given attributes are not a plain object.': function itShouldThrowIfGivenAttributesAreNotAPlainObject() {
        var graph = new Graph();
        (0, _helpers.addNodesFrom)(graph, ['John', 'Martha']);
        var edge = graph.addEdge('John', 'Martha');
        _assert["default"]["throws"](function () {
          graph.replaceEdgeAttributes(edge, true);
        }, invalid());
      },
      'it should also work with typed edges.': function itShouldAlsoWorkWithTypedEdges() {
        var graph = new Graph();
        (0, _helpers.addNodesFrom)(graph, ['John', 'Thomas']);
        graph.addDirectedEdge('John', 'Thomas', {
          test: 0
        });
        graph.addUndirectedEdge('John', 'Thomas', {
          test: 0
        });
        graph.replaceDirectedEdgeAttributes('John', 'Thomas', {
          weight: 2
        });
        graph.replaceUndirectedEdgeAttributes('John', 'Thomas', {
          weight: 3
        });
        _assert["default"].deepStrictEqual(graph.getDirectedEdgeAttributes('John', 'Thomas'), {
          weight: 2
        });
        _assert["default"].deepStrictEqual(graph.getUndirectedEdgeAttributes('John', 'Thomas'), {
          weight: 3
        });
      },
      'it should correctly replace attributes.': function itShouldCorrectlyReplaceAttributes() {
        var graph = new Graph();
        (0, _helpers.addNodesFrom)(graph, ['John', 'Martha']);
        var edge = graph.addEdge('John', 'Martha', {
          weight: 1
        });
        graph.replaceEdgeAttributes(edge, {
          weight: 4,
          type: 'KNOWS'
        });
        _assert["default"].deepStrictEqual(graph.getEdgeAttributes(edge), {
          weight: 4,
          type: 'KNOWS'
        });
      }
    },
    '#.mergeAttributes': {
      'it should throw if given attributes are not a plain object.': function itShouldThrowIfGivenAttributesAreNotAPlainObject() {
        var graph = new Graph();
        _assert["default"]["throws"](function () {
          graph.mergeAttributes(true);
        }, invalid());
      },
      'it should correctly merge attributes.': function itShouldCorrectlyMergeAttributes() {
        var graph = new Graph();
        graph.setAttribute('name', 'graph');
        graph.mergeAttributes({
          color: 'blue'
        });
        _assert["default"].deepStrictEqual(graph.getAttributes(), {
          name: 'graph',
          color: 'blue'
        });
      }
    },
    '#.mergeNodeAttributes': {
      'it should throw if given attributes are not a plain object.': function itShouldThrowIfGivenAttributesAreNotAPlainObject() {
        var graph = new Graph();
        graph.addNode('John');
        _assert["default"]["throws"](function () {
          graph.mergeNodeAttributes('John', true);
        }, invalid());
      },
      'it should correctly merge attributes.': function itShouldCorrectlyMergeAttributes() {
        var graph = new Graph();
        graph.addNode('John', {
          age: 45
        });
        graph.mergeNodeAttributes('John', {
          eyes: 'blue'
        });
        _assert["default"].deepStrictEqual(graph.getNodeAttributes('John'), {
          age: 45,
          eyes: 'blue'
        });
      }
    },
    '#.mergeEdgeAttributes': {
      'it should throw if given attributes are not a plain object.': function itShouldThrowIfGivenAttributesAreNotAPlainObject() {
        var graph = new Graph();
        (0, _helpers.addNodesFrom)(graph, ['John', 'Martha']);
        var edge = graph.addEdge('John', 'Martha');
        _assert["default"]["throws"](function () {
          graph.mergeEdgeAttributes(edge, true);
        }, invalid());
      },
      'it should also work with typed edges.': function itShouldAlsoWorkWithTypedEdges() {
        var graph = new Graph();
        (0, _helpers.addNodesFrom)(graph, ['John', 'Thomas']);
        graph.addDirectedEdge('John', 'Thomas', {
          test: 0
        });
        graph.addUndirectedEdge('John', 'Thomas', {
          test: 0
        });
        graph.mergeDirectedEdgeAttributes('John', 'Thomas', {
          weight: 2
        });
        graph.mergeUndirectedEdgeAttributes('John', 'Thomas', {
          weight: 3
        });
        _assert["default"].deepStrictEqual(graph.getDirectedEdgeAttributes('John', 'Thomas'), {
          weight: 2,
          test: 0
        });
        _assert["default"].deepStrictEqual(graph.getUndirectedEdgeAttributes('John', 'Thomas'), {
          weight: 3,
          test: 0
        });
      },
      'it should correctly merge attributes.': function itShouldCorrectlyMergeAttributes() {
        var graph = new Graph();
        (0, _helpers.addNodesFrom)(graph, ['John', 'Martha']);
        var edge = graph.addEdge('John', 'Martha', {
          weight: 1
        });
        graph.mergeEdgeAttributes(edge, {
          type: 'KNOWS'
        });
        _assert["default"].deepStrictEqual(graph.getEdgeAttributes(edge), {
          weight: 1,
          type: 'KNOWS'
        });
      }
    },
    '#.updateAttributes': {
      'it should throw if given updater is not a function.': function itShouldThrowIfGivenUpdaterIsNotAFunction() {
        var graph = new Graph();
        _assert["default"]["throws"](function () {
          graph.updateAttribute(true);
        }, invalid());
      },
      'it should correctly update attributes.': function itShouldCorrectlyUpdateAttributes() {
        var graph = new Graph();
        graph.setAttribute('name', 'graph');
        graph.updateAttributes(function (attr) {
          return _objectSpread(_objectSpread({}, attr), {}, {
            color: 'blue'
          });
        });
        _assert["default"].deepStrictEqual(graph.getAttributes(), {
          name: 'graph',
          color: 'blue'
        });
      }
    },
    '#.updateNodeAttributes': {
      'it should throw if given updater is not a function': function itShouldThrowIfGivenUpdaterIsNotAFunction() {
        var graph = new Graph();
        graph.addNode('John');
        _assert["default"]["throws"](function () {
          graph.updateNodeAttributes('John', true);
        }, invalid());
      },
      'it should correctly update attributes.': function itShouldCorrectlyUpdateAttributes() {
        var graph = new Graph();
        graph.addNode('John', {
          age: 45
        });
        graph.updateNodeAttributes('John', function (attr) {
          return _objectSpread(_objectSpread({}, attr), {}, {
            eyes: 'blue'
          });
        });
        _assert["default"].deepStrictEqual(graph.getNodeAttributes('John'), {
          age: 45,
          eyes: 'blue'
        });
      }
    },
    '#.updateEdgeAttributes': {
      'it should throw if given updater is not a function.': function itShouldThrowIfGivenUpdaterIsNotAFunction() {
        var graph = new Graph();
        (0, _helpers.addNodesFrom)(graph, ['John', 'Martha']);
        var edge = graph.addEdge('John', 'Martha');
        _assert["default"]["throws"](function () {
          graph.updateEdgeAttributes(edge, true);
        }, invalid());
      },
      'it should also work with typed edges.': function itShouldAlsoWorkWithTypedEdges() {
        var graph = new Graph();
        (0, _helpers.addNodesFrom)(graph, ['John', 'Thomas']);
        graph.addDirectedEdge('John', 'Thomas', {
          test: 0
        });
        graph.addUndirectedEdge('John', 'Thomas', {
          test: 0
        });
        graph.updateDirectedEdgeAttributes('John', 'Thomas', function (attr) {
          return _objectSpread(_objectSpread({}, attr), {}, {
            weight: 2
          });
        });
        graph.updateUndirectedEdgeAttributes('John', 'Thomas', function (attr) {
          return _objectSpread(_objectSpread({}, attr), {}, {
            weight: 3
          });
        });
        _assert["default"].deepStrictEqual(graph.getDirectedEdgeAttributes('John', 'Thomas'), {
          weight: 2,
          test: 0
        });
        _assert["default"].deepStrictEqual(graph.getUndirectedEdgeAttributes('John', 'Thomas'), {
          weight: 3,
          test: 0
        });
      },
      'it should correctly update attributes.': function itShouldCorrectlyUpdateAttributes() {
        var graph = new Graph();
        (0, _helpers.addNodesFrom)(graph, ['John', 'Martha']);
        var edge = graph.addEdge('John', 'Martha', {
          weight: 1
        });
        graph.updateEdgeAttributes(edge, function (attr) {
          return _objectSpread(_objectSpread({}, attr), {}, {
            type: 'KNOWS'
          });
        });
        _assert["default"].deepStrictEqual(graph.getEdgeAttributes(edge), {
          weight: 1,
          type: 'KNOWS'
        });
      }
    },
    '#.updateEachNodeAttributes': {
      'it should throw when given invalid arguments.': function itShouldThrowWhenGivenInvalidArguments() {
        var graph = new Graph();
        _assert["default"]["throws"](function () {
          graph.updateEachNodeAttributes(null);
        }, invalid());
        _assert["default"]["throws"](function () {
          graph.updateEachNodeAttributes(Function.prototype, 'test');
        }, invalid());
        _assert["default"]["throws"](function () {
          graph.updateEachNodeAttributes(Function.prototype, {
            attributes: 'yes'
          });
        }, invalid());
      },
      "it should update each node's attributes.": function itShouldUpdateEachNodeSAttributes() {
        var graph = new Graph();
        graph.addNode('John', {
          age: 34
        });
        graph.addNode('Mary', {
          age: 56
        });
        graph.addNode('Suz', {
          age: 13
        });
        graph.updateEachNodeAttributes(function (node, attr) {
          return _objectSpread(_objectSpread({}, attr), {}, {
            age: attr.age + 1
          });
        });
        _assert["default"].deepStrictEqual(graph.nodes().map(function (n) {
          return graph.getNodeAttributes(n);
        }), [{
          age: 35
        }, {
          age: 57
        }, {
          age: 14
        }]);
      }
    },
    '#.updateEachEdgeAttributes': {
      'it should throw when given invalid arguments.': function itShouldThrowWhenGivenInvalidArguments() {
        var graph = new Graph();
        _assert["default"]["throws"](function () {
          graph.updateEachEdgeAttributes(null);
        }, invalid());
        _assert["default"]["throws"](function () {
          graph.updateEachEdgeAttributes(Function.prototype, 'test');
        }, invalid());
        _assert["default"]["throws"](function () {
          graph.updateEachEdgeAttributes(Function.prototype, {
            attributes: 'yes'
          });
        }, invalid());
      },
      "it should update each node's attributes.": function itShouldUpdateEachNodeSAttributes() {
        var graph = new Graph();
        graph.mergeEdgeWithKey(0, 'John', 'Lucy', {
          weight: 1
        });
        graph.mergeEdgeWithKey(1, 'John', 'Mary', {
          weight: 10
        });
        graph.updateEachEdgeAttributes(function (edge, attr, source, _t, _sa, _ta, undirected) {
          _assert["default"].strictEqual(source, 'John');
          _assert["default"].strictEqual(undirected, false);
          return _objectSpread(_objectSpread({}, attr), {}, {
            weight: attr.weight + 1
          });
        });
        _assert["default"].deepStrictEqual(graph.mapEdges(function (_, attr) {
          return attr;
        }), [{
          weight: 2
        }, {
          weight: 11
        }]);
      }
    }
  });
}