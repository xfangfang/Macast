"use strict";

Object.defineProperty(exports, "__esModule", {
  value: true
});
exports["default"] = events;
var _assert = _interopRequireDefault(require("assert"));
var _helpers = require("./helpers");
function _interopRequireDefault(obj) { return obj && obj.__esModule ? obj : { "default": obj }; }
function ownKeys(object, enumerableOnly) { var keys = Object.keys(object); if (Object.getOwnPropertySymbols) { var symbols = Object.getOwnPropertySymbols(object); enumerableOnly && (symbols = symbols.filter(function (sym) { return Object.getOwnPropertyDescriptor(object, sym).enumerable; })), keys.push.apply(keys, symbols); } return keys; }
function _objectSpread(target) { for (var i = 1; i < arguments.length; i++) { var source = null != arguments[i] ? arguments[i] : {}; i % 2 ? ownKeys(Object(source), !0).forEach(function (key) { _defineProperty(target, key, source[key]); }) : Object.getOwnPropertyDescriptors ? Object.defineProperties(target, Object.getOwnPropertyDescriptors(source)) : ownKeys(Object(source)).forEach(function (key) { Object.defineProperty(target, key, Object.getOwnPropertyDescriptor(source, key)); }); } return target; }
function _defineProperty(obj, key, value) { if (key in obj) { Object.defineProperty(obj, key, { value: value, enumerable: true, configurable: true, writable: true }); } else { obj[key] = value; } return obj; }
var VALID_TYPES = new Set(['set', 'merge', 'replace', 'remove']);
function events(Graph) {
  return {
    nodeAdded: {
      'it should fire when a node is added.': function itShouldFireWhenANodeIsAdded() {
        var graph = new Graph();
        var handler = (0, _helpers.spy)(function (data) {
          _assert["default"].strictEqual(data.key, 'John');
          _assert["default"].deepStrictEqual(data.attributes, {
            age: 34
          });
        });
        graph.on('nodeAdded', handler);
        graph.addNode('John', {
          age: 34
        });
        (0, _assert["default"])(handler.called);
      }
    },
    edgeAdded: {
      'it should fire when an edge is added.': function itShouldFireWhenAnEdgeIsAdded() {
        var graph = new Graph();
        var handler = (0, _helpers.spy)(function (data) {
          _assert["default"].strictEqual(data.key, 'J->T');
          _assert["default"].deepStrictEqual(data.attributes, {
            weight: 1
          });
          _assert["default"].strictEqual(data.source, 'John');
          _assert["default"].strictEqual(data.target, 'Thomas');
          _assert["default"].strictEqual(data.undirected, false);
        });
        graph.on('edgeAdded', handler);
        (0, _helpers.addNodesFrom)(graph, ['John', 'Thomas']);
        graph.addEdgeWithKey('J->T', 'John', 'Thomas', {
          weight: 1
        });
        (0, _assert["default"])(handler.called);
      }
    },
    nodeDropped: {
      'it should fire when a node is dropped.': function itShouldFireWhenANodeIsDropped() {
        var graph = new Graph();
        var handler = (0, _helpers.spy)(function (data) {
          _assert["default"].strictEqual(data.key, 'John');
          _assert["default"].deepStrictEqual(data.attributes, {
            age: 34
          });
        });
        graph.on('nodeDropped', handler);
        graph.addNode('John', {
          age: 34
        });
        graph.dropNode('John');
        (0, _assert["default"])(handler.called);
      }
    },
    edgeDropped: {
      'it should fire when an edge is added.': function itShouldFireWhenAnEdgeIsAdded() {
        var graph = new Graph();
        var handler = (0, _helpers.spy)(function (data) {
          _assert["default"].strictEqual(data.key, 'J->T');
          _assert["default"].deepStrictEqual(data.attributes, {
            weight: 1
          });
          _assert["default"].strictEqual(data.source, 'John');
          _assert["default"].strictEqual(data.target, 'Thomas');
          _assert["default"].strictEqual(data.undirected, false);
        });
        graph.on('edgeDropped', handler);
        (0, _helpers.addNodesFrom)(graph, ['John', 'Thomas']);
        graph.addEdgeWithKey('J->T', 'John', 'Thomas', {
          weight: 1
        });
        graph.dropEdge('J->T');
        (0, _assert["default"])(handler.called);
      }
    },
    cleared: {
      'it should fire when the graph is cleared.': function itShouldFireWhenTheGraphIsCleared() {
        var graph = new Graph();
        var handler = (0, _helpers.spy)();
        graph.on('cleared', handler);
        graph.clear();
        (0, _assert["default"])(handler.called);
      }
    },
    attributesUpdated: {
      'it should fire when a graph attribute is updated.': function itShouldFireWhenAGraphAttributeIsUpdated() {
        var graph = new Graph();
        var handler = (0, _helpers.spy)(function (payload) {
          (0, _assert["default"])(VALID_TYPES.has(payload.type));
          if (payload.type === 'set') {
            _assert["default"].strictEqual(payload.name, 'name');
          } else if (payload.type === 'remove') {
            _assert["default"].strictEqual(payload.name, 'name');
          } else if (payload.type === 'merge') {
            _assert["default"].deepStrictEqual(payload.data, {
              author: 'John'
            });
          }
          _assert["default"].deepStrictEqual(payload.attributes, graph.getAttributes());
        });
        graph.on('attributesUpdated', handler);
        graph.setAttribute('name', 'Awesome graph');
        graph.replaceAttributes({
          name: 'Shitty graph'
        });
        graph.mergeAttributes({
          author: 'John'
        });
        graph.removeAttribute('name');
        _assert["default"].strictEqual(handler.times, 4);
      }
    },
    nodeAttributesUpdated: {
      "it should fire when a node's attributes are updated.": function itShouldFireWhenANodeSAttributesAreUpdated() {
        var graph = new Graph();
        var handler = (0, _helpers.spy)(function (payload) {
          _assert["default"].strictEqual(payload.key, 'John');
          (0, _assert["default"])(VALID_TYPES.has(payload.type));
          if (payload.type === 'set') {
            _assert["default"].strictEqual(payload.name, 'age');
          } else if (payload.type === 'remove') {
            _assert["default"].strictEqual(payload.name, 'eyes');
          } else if (payload.type === 'merge') {
            _assert["default"].deepStrictEqual(payload.data, {
              eyes: 'blue'
            });
          }
          _assert["default"].strictEqual(payload.attributes, graph.getNodeAttributes(payload.key));
        });
        graph.on('nodeAttributesUpdated', handler);
        graph.addNode('John');
        graph.setNodeAttribute('John', 'age', 34);
        graph.replaceNodeAttributes('John', {
          age: 56
        });
        graph.mergeNodeAttributes('John', {
          eyes: 'blue'
        });
        graph.removeNodeAttribute('John', 'eyes');
        _assert["default"].strictEqual(handler.times, 4);
      },
      'it should fire when a node is merged.': function itShouldFireWhenANodeIsMerged() {
        var graph = new Graph();
        var handler = (0, _helpers.spy)(function (payload) {
          _assert["default"].deepStrictEqual(payload, {
            type: 'merge',
            key: 'John',
            attributes: {
              count: 2
            },
            data: {
              count: 2
            }
          });
          _assert["default"].deepStrictEqual(graph.getNodeAttributes(payload.key), {
            count: 2
          });
        });
        graph.on('nodeAttributesUpdated', handler);
        graph.mergeNode('John', {
          count: 1
        });
        graph.mergeNode('John', {
          count: 2
        });
        _assert["default"].strictEqual(handler.times, 1);
      },
      'it should fire when a node is updated.': function itShouldFireWhenANodeIsUpdated() {
        var graph = new Graph();
        var handler = (0, _helpers.spy)(function (payload) {
          _assert["default"].deepStrictEqual(payload, {
            type: 'replace',
            key: 'John',
            attributes: {
              count: 2
            }
          });
          _assert["default"].deepStrictEqual(graph.getNodeAttributes(payload.key), {
            count: 2
          });
        });
        graph.on('nodeAttributesUpdated', handler);
        graph.mergeNode('John', {
          count: 1
        });
        graph.updateNode('John', function (attr) {
          return _objectSpread(_objectSpread({}, attr), {}, {
            count: attr.count + 1
          });
        });
        _assert["default"].strictEqual(handler.times, 1);
      }
    },
    edgeAttributesUpdated: {
      "it should fire when an edge's attributes are updated.": function itShouldFireWhenAnEdgeSAttributesAreUpdated() {
        var graph = new Graph();
        var handler = (0, _helpers.spy)(function (payload) {
          _assert["default"].strictEqual(payload.key, 'J->T');
          (0, _assert["default"])(VALID_TYPES.has(payload.type));
          if (payload.type === 'set') {
            _assert["default"].strictEqual(payload.name, 'weight');
          } else if (payload.type === 'remove') {
            _assert["default"].strictEqual(payload.name, 'type');
          } else if (payload.type === 'merge') {
            _assert["default"].deepStrictEqual(payload.data, {
              type: 'KNOWS'
            });
          }
          _assert["default"].strictEqual(payload.attributes, graph.getEdgeAttributes(payload.key));
        });
        graph.on('edgeAttributesUpdated', handler);
        (0, _helpers.addNodesFrom)(graph, ['John', 'Thomas']);
        graph.addEdgeWithKey('J->T', 'John', 'Thomas');
        graph.setEdgeAttribute('J->T', 'weight', 34);
        graph.replaceEdgeAttributes('J->T', {
          weight: 56
        });
        graph.mergeEdgeAttributes('J->T', {
          type: 'KNOWS'
        });
        graph.removeEdgeAttribute('J->T', 'type');
        _assert["default"].strictEqual(handler.times, 4);
      },
      'it should fire when an edge is merged.': function itShouldFireWhenAnEdgeIsMerged() {
        var graph = new Graph();
        var handler = (0, _helpers.spy)(function (payload) {
          _assert["default"].deepStrictEqual(payload, {
            type: 'merge',
            key: graph.edge('John', 'Mary'),
            attributes: {
              weight: 2
            },
            data: {
              weight: 2
            }
          });
          _assert["default"].deepStrictEqual(graph.getEdgeAttributes(payload.key), {
            weight: 2
          });
        });
        graph.on('edgeAttributesUpdated', handler);
        graph.mergeEdge('John', 'Mary', {
          weight: 1
        });
        graph.mergeEdge('John', 'Mary', {
          weight: 2
        });
        _assert["default"].strictEqual(handler.times, 1);
      },
      'it should fire when an edge is updated.': function itShouldFireWhenAnEdgeIsUpdated() {
        var graph = new Graph();
        var handler = (0, _helpers.spy)(function (payload) {
          _assert["default"].deepStrictEqual(payload, {
            type: 'replace',
            key: 'j->m',
            attributes: {
              weight: 2
            }
          });
          _assert["default"].deepStrictEqual(graph.getEdgeAttributes(payload.key), {
            weight: 2
          });
        });
        graph.on('edgeAttributesUpdated', handler);
        graph.mergeEdgeWithKey('j->m', 'John', 'Mary', {
          weight: 1
        });
        graph.updateEdgeWithKey('j->m', 'John', 'Mary', function (attr) {
          return _objectSpread(_objectSpread({}, attr), {}, {
            weight: attr.weight + 1
          });
        });
        _assert["default"].strictEqual(handler.times, 1);
      }
    },
    eachNodeAttributesUpdated: {
      'it should fire when using #.updateEachNodeAttributes.': function itShouldFireWhenUsingUpdateEachNodeAttributes() {
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
        var handler = (0, _helpers.spy)(function (payload) {
          _assert["default"].strictEqual(payload.hints, null);
        });
        graph.on('eachNodeAttributesUpdated', handler);
        graph.updateEachNodeAttributes(function (node, attr) {
          return _objectSpread(_objectSpread({}, attr), {}, {
            age: attr.age + 1
          });
        });
        _assert["default"].strictEqual(handler.times, 1);
      },
      'it should provide hints when user gave them.': function itShouldProvideHintsWhenUserGaveThem() {
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
        var handler = (0, _helpers.spy)(function (payload) {
          _assert["default"].deepStrictEqual(payload.hints, {
            attributes: ['age']
          });
        });
        graph.on('eachNodeAttributesUpdated', handler);
        graph.updateEachNodeAttributes(function (node, attr) {
          return _objectSpread(_objectSpread({}, attr), {}, {
            age: attr.age + 1
          });
        }, {
          attributes: ['age']
        });
        _assert["default"].strictEqual(handler.times, 1);
      }
    },
    eachEdgeAttributesUpdated: {
      'it should fire when using #.updateEachEdgeAttributes.': function itShouldFireWhenUsingUpdateEachEdgeAttributes() {
        var graph = new Graph();
        graph.mergeEdgeWithKey(0, 'John', 'Lucy', {
          weight: 1
        });
        graph.mergeEdgeWithKey(1, 'John', 'Mary', {
          weight: 10
        });
        var handler = (0, _helpers.spy)(function (payload) {
          _assert["default"].strictEqual(payload.hints, null);
        });
        graph.on('eachEdgeAttributesUpdated', handler);
        graph.updateEachEdgeAttributes(function (node, attr) {
          return _objectSpread(_objectSpread({}, attr), {}, {
            age: attr.weight + 1
          });
        });
        _assert["default"].strictEqual(handler.times, 1);
      },
      'it should provide hints when user gave them.': function itShouldProvideHintsWhenUserGaveThem() {
        var graph = new Graph();
        graph.mergeEdgeWithKey(0, 'John', 'Lucy', {
          weight: 1
        });
        graph.mergeEdgeWithKey(1, 'John', 'Mary', {
          weight: 10
        });
        var handler = (0, _helpers.spy)(function (payload) {
          _assert["default"].deepStrictEqual(payload.hints, {
            attributes: ['weight']
          });
        });
        graph.on('eachEdgeAttributesUpdated', handler);
        graph.updateEachEdgeAttributes(function (node, attr) {
          return _objectSpread(_objectSpread({}, attr), {}, {
            weight: attr.weight + 1
          });
        }, {
          attributes: ['weight']
        });
        _assert["default"].strictEqual(handler.times, 1);
      }
    }
  };
}