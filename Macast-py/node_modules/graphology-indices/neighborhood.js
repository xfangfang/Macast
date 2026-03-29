/**
 * Graphology Neighborhood Indices
 * ================================
 */
var typed = require('mnemonist/utils/typed-arrays');
var createEdgeWeightGetter =
  require('graphology-utils/getters').createEdgeWeightGetter;

function upperBoundPerMethod(method, graph) {
  if (method === 'outbound' || method === 'inbound')
    return graph.directedSize + graph.undirectedSize * 2;

  if (method === 'in' || method === 'out' || method === 'directed')
    return graph.directedSize;

  return graph.undirectedSize * 2;
}

function NeighborhoodIndex(graph, method) {
  method = method || 'outbound';
  var getNeighbors = graph[method + 'Neighbors'].bind(graph);

  var upperBound = upperBoundPerMethod(method, graph);

  var NeighborhoodPointerArray = typed.getPointerArray(upperBound);
  var NodesPointerArray = typed.getPointerArray(graph.order);

  // NOTE: directedSize + undirectedSize * 2 is an upper bound for
  // neighborhood size
  this.graph = graph;
  this.neighborhood = new NodesPointerArray(upperBound);

  this.starts = new NeighborhoodPointerArray(graph.order + 1);

  this.nodes = graph.nodes();

  var ids = {};

  var i, l, j, m, node, neighbors;

  var n = 0;

  for (i = 0, l = graph.order; i < l; i++) ids[this.nodes[i]] = i;

  for (i = 0, l = graph.order; i < l; i++) {
    node = this.nodes[i];
    neighbors = getNeighbors(node);

    this.starts[i] = n;

    for (j = 0, m = neighbors.length; j < m; j++)
      this.neighborhood[n++] = ids[neighbors[j]];
  }

  // NOTE: we keep one more index as upper bound to simplify iteration
  this.starts[i] = upperBound;
}

NeighborhoodIndex.prototype.bounds = function (i) {
  return [this.starts[i], this.starts[i + 1]];
};

NeighborhoodIndex.prototype.project = function () {
  var self = this;

  var projection = {};

  self.nodes.forEach(function (node, i) {
    projection[node] = Array.from(
      self.neighborhood.slice(self.starts[i], self.starts[i + 1])
    ).map(function (j) {
      return self.nodes[j];
    });
  });

  return projection;
};

NeighborhoodIndex.prototype.collect = function (results) {
  var i, l;

  var o = {};

  for (i = 0, l = results.length; i < l; i++) o[this.nodes[i]] = results[i];

  return o;
};

NeighborhoodIndex.prototype.assign = function (prop, results) {
  var i = 0;

  this.graph.updateEachNodeAttributes(
    function (_, attr) {
      attr[prop] = results[i++];

      return attr;
    },
    {attributes: [prop]}
  );
};

exports.NeighborhoodIndex = NeighborhoodIndex;

function WeightedNeighborhoodIndex(graph, getEdgeWeight, method) {
  method = method || 'outbound';
  var getEdges = graph[method + 'Edges'].bind(graph);

  var upperBound = upperBoundPerMethod(method, graph);

  var NeighborhoodPointerArray = typed.getPointerArray(upperBound);
  var NodesPointerArray = typed.getPointerArray(graph.order);

  var weightGetter = createEdgeWeightGetter(getEdgeWeight).fromMinimalEntry;

  // NOTE: directedSize + undirectedSize * 2 is an upper bound for
  // neighborhood size
  this.graph = graph;
  this.neighborhood = new NodesPointerArray(upperBound);
  this.weights = new Float64Array(upperBound);
  this.outDegrees = new Float64Array(graph.order);

  this.starts = new NeighborhoodPointerArray(graph.order + 1);

  this.nodes = graph.nodes();

  var ids = {};

  var i, l, j, m, node, neighbor, edges, edge, weight;

  var n = 0;

  for (i = 0, l = graph.order; i < l; i++) ids[this.nodes[i]] = i;

  for (i = 0, l = graph.order; i < l; i++) {
    node = this.nodes[i];
    edges = getEdges(node);

    this.starts[i] = n;

    for (j = 0, m = edges.length; j < m; j++) {
      edge = edges[j];
      neighbor = graph.opposite(node, edge);
      weight = weightGetter(edge, graph.getEdgeAttributes(edge));

      // NOTE: for weighted mixed beware of merging weights if twice the same neighbor
      this.neighborhood[n] = ids[neighbor];
      this.weights[n++] = weight;
      this.outDegrees[i] += weight;
    }
  }

  // NOTE: we keep one more index as upper bound to simplify iteration
  this.starts[i] = upperBound;
}

WeightedNeighborhoodIndex.prototype.bounds = NeighborhoodIndex.prototype.bounds;
WeightedNeighborhoodIndex.prototype.project =
  NeighborhoodIndex.prototype.project;
WeightedNeighborhoodIndex.prototype.collect =
  NeighborhoodIndex.prototype.collect;
WeightedNeighborhoodIndex.prototype.assign = NeighborhoodIndex.prototype.assign;

exports.WeightedNeighborhoodIndex = WeightedNeighborhoodIndex;
