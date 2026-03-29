"use strict";

Object.defineProperty(exports, "__esModule", {
  value: true
});
exports["default"] = specs;
var _instantiation = _interopRequireDefault(require("./instantiation"));
var _properties = _interopRequireDefault(require("./properties"));
var _read = _interopRequireDefault(require("./read"));
var _mutation = _interopRequireDefault(require("./mutation"));
var _attributes = _interopRequireDefault(require("./attributes"));
var _iteration = _interopRequireDefault(require("./iteration"));
var _serialization = _interopRequireDefault(require("./serialization"));
var _events = _interopRequireDefault(require("./events"));
var _utils = _interopRequireDefault(require("./utils"));
var _known = _interopRequireDefault(require("./known"));
var _misc = _interopRequireDefault(require("./misc"));
function _interopRequireDefault(obj) { return obj && obj.__esModule ? obj : { "default": obj }; }
/**
 * Graphology Specs
 * =================
 *
 * Unit tests factory taking the Graph object implementation.
 */

var createErrorChecker = function createErrorChecker(name) {
  return function () {
    return function (error) {
      return error && error.name === name;
    };
  };
};

/**
 * Returning the unit tests to run.
 *
 * @param  {string} path - Path to the implementation (should be absolute).
 * @return {object}      - The tests to run with Mocha.
 */
function specs(Graph, implementation) {
  var errors = [['invalid', 'InvalidArgumentsGraphError'], ['notFound', 'NotFoundGraphError'], ['usage', 'UsageGraphError']];

  // Building error checkers
  var errorCheckers = {};
  errors.forEach(function (_ref) {
    var fn = _ref[0],
      name = _ref[1];
    return errorCheckers[fn] = createErrorChecker(name);
  });
  var tests = {
    Basic: {
      Instantiation: (0, _instantiation["default"])(Graph, implementation, errorCheckers),
      Properties: (0, _properties["default"])(Graph, errorCheckers),
      Mutation: (0, _mutation["default"])(Graph, errorCheckers),
      Read: (0, _read["default"])(Graph, errorCheckers),
      Attributes: (0, _attributes["default"])(Graph, errorCheckers),
      Iteration: (0, _iteration["default"])(Graph, errorCheckers),
      Serialization: (0, _serialization["default"])(Graph, errorCheckers),
      Events: (0, _events["default"])(Graph),
      Utils: (0, _utils["default"])(Graph, errorCheckers),
      'Known Methods': (0, _known["default"])(Graph, errorCheckers),
      Miscellaneous: (0, _misc["default"])(Graph)
    }
  };
  return tests;
}