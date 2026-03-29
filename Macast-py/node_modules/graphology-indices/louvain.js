/**
 * Graphology Louvain Indices
 * ===========================
 *
 * Undirected & Directed Louvain Index structures used to compute the famous
 * Louvain community detection algorithm.
 *
 * Most of the rationale is explained in `graphology-metrics`.
 *
 * Note that this index shares a lot with the classic Union-Find data
 * structure. It also relies on a unused id stack to make sure we can
 * increase again the number of communites when isolating nodes.
 *
 * [Articles]
 * M. E. J. Newman, « Modularity and community structure in networks »,
 * Proc. Natl. Acad. Sci. USA, vol. 103, no 23, 2006, p. 8577–8582
 * https://dx.doi.org/10.1073%2Fpnas.0601602103
 *
 * Newman, M. E. J. « Community detection in networks: Modularity optimization
 * and maximum likelihood are equivalent ». Physical Review E, vol. 94, no 5,
 * novembre 2016, p. 052315. arXiv.org, doi:10.1103/PhysRevE.94.052315.
 * https://arxiv.org/pdf/1606.02319.pdf
 *
 * Blondel, Vincent D., et al. « Fast unfolding of communities in large
 * networks ». Journal of Statistical Mechanics: Theory and Experiment,
 * vol. 2008, no 10, octobre 2008, p. P10008. DOI.org (Crossref),
 * doi:10.1088/1742-5468/2008/10/P10008.
 * https://arxiv.org/pdf/0803.0476.pdf
 *
 * Nicolas Dugué, Anthony Perez. Directed Louvain: maximizing modularity in
 * directed networks. [Research Report] Université d’Orléans. 2015. hal-01231784
 * https://hal.archives-ouvertes.fr/hal-01231784
 *
 * R. Lambiotte, J.-C. Delvenne and M. Barahona. Laplacian Dynamics and
 * Multiscale Modular Structure in Networks,
 * doi:10.1109/TNSE.2015.2391998.
 * https://arxiv.org/abs/0812.1770
 *
 * [Latex]:
 *
 * Undirected Case:
 * ----------------
 *
 * \Delta Q=\bigg{[}\frac{\sum^{c}_{in}-(2d_{c}+l)}{2m}-\bigg{(}\frac{\sum^{c}_{tot}-(d+l)}{2m}\bigg{)}^{2}+\frac{\sum^{t}_{in}+(2d_{t}+l)}{2m}-\bigg{(}\frac{\sum^{t}_{tot}+(d+l)}{2m}\bigg{)}^{2}\bigg{]}-\bigg{[}\frac{\sum^{c}_{in}}{2m}-\bigg{(}\frac{\sum^{c}_{tot}}{2m}\bigg{)}^{2}+\frac{\sum^{t}_{in}}{2m}-\bigg{(}\frac{\sum^{t}_{tot}}{2m}\bigg{)}^{2}\bigg{]}
 * \Delta Q=\frac{d_{t}-d_{c}}{m}+\frac{l\sum^{c}_{tot}+d\sum^{c}_{tot}-d^{2}-l^{2}-2dl-l\sum^{t}_{tot}-d\sum^{t}_{tot}}{2m^{2}}
 * \Delta Q=\frac{d_{t}-d_{c}}{m}+\frac{(l+d)\sum^{c}_{tot}-d^{2}-l^{2}-2dl-(l+d)\sum^{t}_{tot}}{2m^{2}}
 *
 * Directed Case:
 * --------------
 * \Delta Q_d=\bigg{[}\frac{\sum^{c}_{in}-(d_{c.in}+d_{c.out}+l)}{m}-\frac{(\sum^{c}_{tot.in}-(d_{in}+l))(\sum^{c}_{tot.out}-(d_{out}+l))}{m^{2}}+\frac{\sum^{t}_{in}+(d_{t.in}+d_{t.out}+l)}{m}-\frac{(\sum^{t}_{tot.in}+(d_{in}+l))(\sum^{t}_{tot.out}+(d_{out}+l))}{m^{2}}\bigg{]}-\bigg{[}\frac{\sum^{c}_{in}}{m}-\frac{\sum^{c}_{tot.in}\sum^{c}_{tot.out}}{m^{2}}+\frac{\sum^{t}_{in}}{m}-\frac{\sum^{t}_{tot.in}\sum^{t}_{tot.out}}{m^{2}}\bigg{]}
 *
 * [Notes]:
 * Louvain is a bit unclear on this but delta computation are not derived from
 * Q1 - Q2 but rather between Q when considered node is isolated in its own
 * community versus Q with this node in target community. This is in fact
 * an optimization because the subtract part is constant in the formulae and
 * does not affect delta comparisons.
 */
var typed = require('mnemonist/utils/typed-arrays');
var resolveDefaults = require('graphology-utils/defaults');
var createEdgeWeightGetter =
  require('graphology-utils/getters').createEdgeWeightGetter;

var INSPECT = Symbol.for('nodejs.util.inspect.custom');

var DEFAULTS = {
  getEdgeWeight: 'weight',
  keepDendrogram: false,
  resolution: 1
};

function UndirectedLouvainIndex(graph, options) {
  // Solving options
  options = resolveDefaults(options, DEFAULTS);

  var resolution = options.resolution;

  // Weight getters
  var getEdgeWeight = createEdgeWeightGetter(options.getEdgeWeight).fromEntry;

  // Building the index
  var size = (graph.size - graph.selfLoopCount) * 2;

  var NeighborhoodPointerArray = typed.getPointerArray(size);
  var NodesPointerArray = typed.getPointerArray(graph.order + 1);

  // NOTE: this memory optimization can yield overflow deopt when computing deltas
  var WeightsArray = options.getEdgeWeight
    ? Float64Array
    : typed.getPointerArray(graph.size * 2);

  // Properties
  this.C = graph.order;
  this.M = 0;
  this.E = size;
  this.U = 0;
  this.resolution = resolution;
  this.level = 0;
  this.graph = graph;
  this.nodes = new Array(graph.order);
  this.keepDendrogram = options.keepDendrogram;

  // Edge-level
  this.neighborhood = new NodesPointerArray(size);
  this.weights = new WeightsArray(size);

  // Node-level
  this.loops = new WeightsArray(graph.order);
  this.starts = new NeighborhoodPointerArray(graph.order + 1);
  this.belongings = new NodesPointerArray(graph.order);
  this.dendrogram = [];
  this.mapping = null;

  // Community-level
  this.counts = new NodesPointerArray(graph.order);
  this.unused = new NodesPointerArray(graph.order);
  this.totalWeights = new WeightsArray(graph.order);

  var ids = {};

  var weight;

  var i = 0,
    n = 0;

  var self = this;

  graph.forEachNode(function (node) {
    self.nodes[i] = node;

    // Node map to index
    ids[node] = i;

    // Initializing starts
    n += graph.undirectedDegreeWithoutSelfLoops(node);
    self.starts[i] = n;

    // Belongings
    self.belongings[i] = i;
    self.counts[i] = 1;
    i++;
  });

  // Single sweep over the edges
  graph.forEachEdge(function (edge, attr, source, target, sa, ta, u) {
    weight = getEdgeWeight(edge, attr, source, target, sa, ta, u);

    source = ids[source];
    target = ids[target];

    self.M += weight;

    // Self loop?
    if (source === target) {
      self.totalWeights[source] += weight * 2;
      self.loops[source] = weight * 2;
    } else {
      self.totalWeights[source] += weight;
      self.totalWeights[target] += weight;

      var startSource = --self.starts[source],
        startTarget = --self.starts[target];

      self.neighborhood[startSource] = target;
      self.neighborhood[startTarget] = source;

      self.weights[startSource] = weight;
      self.weights[startTarget] = weight;
    }
  });

  this.starts[i] = this.E;

  if (this.keepDendrogram) this.dendrogram.push(this.belongings.slice());
  else this.mapping = this.belongings.slice();
}

UndirectedLouvainIndex.prototype.isolate = function (i, degree) {
  var currentCommunity = this.belongings[i];

  // The node is already isolated
  if (this.counts[currentCommunity] === 1) return currentCommunity;

  var newCommunity = this.unused[--this.U];

  var loops = this.loops[i];

  this.totalWeights[currentCommunity] -= degree + loops;
  this.totalWeights[newCommunity] += degree + loops;

  this.belongings[i] = newCommunity;

  this.counts[currentCommunity]--;
  this.counts[newCommunity]++;

  return newCommunity;
};

UndirectedLouvainIndex.prototype.move = function (i, degree, targetCommunity) {
  var currentCommunity = this.belongings[i],
    loops = this.loops[i];

  this.totalWeights[currentCommunity] -= degree + loops;
  this.totalWeights[targetCommunity] += degree + loops;

  this.belongings[i] = targetCommunity;

  var nowEmpty = this.counts[currentCommunity]-- === 1;
  this.counts[targetCommunity]++;

  if (nowEmpty) this.unused[this.U++] = currentCommunity;
};

UndirectedLouvainIndex.prototype.computeNodeDegree = function (i) {
  var o, l, weight;

  var degree = 0;

  for (o = this.starts[i], l = this.starts[i + 1]; o < l; o++) {
    weight = this.weights[o];

    degree += weight;
  }

  return degree;
};

UndirectedLouvainIndex.prototype.expensiveIsolate = function (i) {
  var degree = this.computeNodeDegree(i);
  return this.isolate(i, degree);
};

UndirectedLouvainIndex.prototype.expensiveMove = function (i, ci) {
  var degree = this.computeNodeDegree(i);
  this.move(i, degree, ci);
};

UndirectedLouvainIndex.prototype.zoomOut = function () {
  var inducedGraph = new Array(this.C - this.U),
    newLabels = {};

  var N = this.nodes.length;

  var C = 0,
    E = 0;

  var i, j, l, m, n, ci, cj, data, adj;

  // Renumbering communities
  for (i = 0, l = this.C; i < l; i++) {
    ci = this.belongings[i];

    if (!(ci in newLabels)) {
      newLabels[ci] = C;
      inducedGraph[C] = {
        adj: {},
        totalWeights: this.totalWeights[ci],
        internalWeights: 0
      };
      C++;
    }

    // We do this to otpimize the number of lookups in next loop
    this.belongings[i] = newLabels[ci];
  }

  // Actualizing dendrogram
  var currentLevel, nextLevel;

  if (this.keepDendrogram) {
    currentLevel = this.dendrogram[this.level];
    nextLevel = new (typed.getPointerArray(C))(N);

    for (i = 0; i < N; i++) nextLevel[i] = this.belongings[currentLevel[i]];

    this.dendrogram.push(nextLevel);
  } else {
    for (i = 0; i < N; i++) this.mapping[i] = this.belongings[this.mapping[i]];
  }

  // Building induced graph matrix
  for (i = 0, l = this.C; i < l; i++) {
    ci = this.belongings[i];

    data = inducedGraph[ci];
    adj = data.adj;
    data.internalWeights += this.loops[i];

    for (j = this.starts[i], m = this.starts[i + 1]; j < m; j++) {
      n = this.neighborhood[j];
      cj = this.belongings[n];

      if (ci === cj) {
        data.internalWeights += this.weights[j];
        continue;
      }

      if (!(cj in adj)) adj[cj] = 0;

      adj[cj] += this.weights[j];
    }
  }

  // Rewriting neighborhood
  this.C = C;

  n = 0;

  for (ci = 0; ci < C; ci++) {
    data = inducedGraph[ci];
    adj = data.adj;

    ci = +ci;

    this.totalWeights[ci] = data.totalWeights;
    this.loops[ci] = data.internalWeights;
    this.counts[ci] = 1;

    this.starts[ci] = n;
    this.belongings[ci] = ci;

    for (cj in adj) {
      this.neighborhood[n] = +cj;
      this.weights[n] = adj[cj];

      E++;
      n++;
    }
  }

  this.starts[C] = E;

  this.E = E;
  this.U = 0;
  this.level++;

  return newLabels;
};

UndirectedLouvainIndex.prototype.modularity = function () {
  var ci, cj, i, j, m;

  var Q = 0;
  var M2 = this.M * 2;
  var internalWeights = new Float64Array(this.C);

  for (i = 0; i < this.C; i++) {
    ci = this.belongings[i];
    internalWeights[ci] += this.loops[i];

    for (j = this.starts[i], m = this.starts[i + 1]; j < m; j++) {
      cj = this.belongings[this.neighborhood[j]];

      if (ci !== cj) continue;

      internalWeights[ci] += this.weights[j];
    }
  }

  for (i = 0; i < this.C; i++) {
    Q +=
      internalWeights[i] / M2 -
      Math.pow(this.totalWeights[i] / M2, 2) * this.resolution;
  }

  return Q;
};

UndirectedLouvainIndex.prototype.delta = function (
  i,
  degree,
  targetCommunityDegree,
  targetCommunity
) {
  var M = this.M;

  var targetCommunityTotalWeight = this.totalWeights[targetCommunity];

  degree += this.loops[i];

  return (
    targetCommunityDegree / M - // NOTE: formula is a bit different here because targetCommunityDegree is passed without * 2
    (targetCommunityTotalWeight * degree * this.resolution) / (2 * M * M)
  );
};

UndirectedLouvainIndex.prototype.deltaWithOwnCommunity = function (
  i,
  degree,
  targetCommunityDegree,
  targetCommunity
) {
  var M = this.M;

  var targetCommunityTotalWeight = this.totalWeights[targetCommunity];

  degree += this.loops[i];

  return (
    targetCommunityDegree / M - // NOTE: formula is a bit different here because targetCommunityDegree is passed without * 2
    ((targetCommunityTotalWeight - degree) * degree * this.resolution) /
      (2 * M * M)
  );
};

// NOTE: this is just a faster but equivalent version of #.delta
// It is just off by a constant factor and is just faster to compute
UndirectedLouvainIndex.prototype.fastDelta = function (
  i,
  degree,
  targetCommunityDegree,
  targetCommunity
) {
  var M = this.M;

  var targetCommunityTotalWeight = this.totalWeights[targetCommunity];

  degree += this.loops[i];

  return (
    targetCommunityDegree -
    (degree * targetCommunityTotalWeight * this.resolution) / (2 * M)
  );
};

UndirectedLouvainIndex.prototype.fastDeltaWithOwnCommunity = function (
  i,
  degree,
  targetCommunityDegree,
  targetCommunity
) {
  var M = this.M;

  var targetCommunityTotalWeight = this.totalWeights[targetCommunity];

  degree += this.loops[i];

  return (
    targetCommunityDegree -
    (degree * (targetCommunityTotalWeight - degree) * this.resolution) / (2 * M)
  );
};

UndirectedLouvainIndex.prototype.bounds = function (i) {
  return [this.starts[i], this.starts[i + 1]];
};

UndirectedLouvainIndex.prototype.project = function () {
  var self = this;

  var projection = {};

  self.nodes.slice(0, this.C).forEach(function (node, i) {
    projection[node] = Array.from(
      self.neighborhood.slice(self.starts[i], self.starts[i + 1])
    ).map(function (j) {
      return self.nodes[j];
    });
  });

  return projection;
};

UndirectedLouvainIndex.prototype.collect = function (level) {
  if (arguments.length < 1) level = this.level;

  var o = {};

  var mapping = this.keepDendrogram ? this.dendrogram[level] : this.mapping;

  var i, l;

  for (i = 0, l = mapping.length; i < l; i++) o[this.nodes[i]] = mapping[i];

  return o;
};

UndirectedLouvainIndex.prototype.assign = function (prop, level) {
  if (arguments.length < 2) level = this.level;

  var mapping = this.keepDendrogram ? this.dendrogram[level] : this.mapping;

  var i, l;

  for (i = 0, l = mapping.length; i < l; i++)
    this.graph.setNodeAttribute(this.nodes[i], prop, mapping[i]);
};

UndirectedLouvainIndex.prototype[INSPECT] = function () {
  var proxy = {};

  // Trick so that node displays the name of the constructor
  Object.defineProperty(proxy, 'constructor', {
    value: UndirectedLouvainIndex,
    enumerable: false
  });

  proxy.C = this.C;
  proxy.M = this.M;
  proxy.E = this.E;
  proxy.U = this.U;
  proxy.resolution = this.resolution;
  proxy.level = this.level;
  proxy.nodes = this.nodes;
  proxy.starts = this.starts.slice(0, proxy.C + 1);

  var eTruncated = ['neighborhood', 'weights'];
  var cTruncated = ['counts', 'loops', 'belongings', 'totalWeights'];

  var self = this;

  eTruncated.forEach(function (key) {
    proxy[key] = self[key].slice(0, proxy.E);
  });

  cTruncated.forEach(function (key) {
    proxy[key] = self[key].slice(0, proxy.C);
  });

  proxy.unused = this.unused.slice(0, this.U);

  if (this.keepDendrogram) proxy.dendrogram = this.dendrogram;
  else proxy.mapping = this.mapping;

  return proxy;
};

function DirectedLouvainIndex(graph, options) {
  // Solving options
  options = resolveDefaults(options, DEFAULTS);

  var resolution = options.resolution;

  // Weight getters
  var getEdgeWeight = createEdgeWeightGetter(options.getEdgeWeight).fromEntry;

  // Building the index
  var size = (graph.size - graph.selfLoopCount) * 2;

  var NeighborhoodPointerArray = typed.getPointerArray(size);
  var NodesPointerArray = typed.getPointerArray(graph.order + 1);

  // NOTE: this memory optimization can yield overflow deopt when computing deltas
  var WeightsArray = options.getEdgeWeight
    ? Float64Array
    : typed.getPointerArray(graph.size * 2);

  // Properties
  this.C = graph.order;
  this.M = 0;
  this.E = size;
  this.U = 0;
  this.resolution = resolution;
  this.level = 0;
  this.graph = graph;
  this.nodes = new Array(graph.order);
  this.keepDendrogram = options.keepDendrogram;

  // Edge-level
  // NOTE: edges are stored out then in, in this order
  this.neighborhood = new NodesPointerArray(size);
  this.weights = new WeightsArray(size);

  // Node-level
  this.loops = new WeightsArray(graph.order);
  this.starts = new NeighborhoodPointerArray(graph.order + 1);
  this.offsets = new NeighborhoodPointerArray(graph.order);
  this.belongings = new NodesPointerArray(graph.order);
  this.dendrogram = [];

  // Community-level
  this.counts = new NodesPointerArray(graph.order);
  this.unused = new NodesPointerArray(graph.order);
  this.totalInWeights = new WeightsArray(graph.order);
  this.totalOutWeights = new WeightsArray(graph.order);

  var ids = {};

  var weight;

  var i = 0,
    n = 0;

  var self = this;

  graph.forEachNode(function (node) {
    self.nodes[i] = node;

    // Node map to index
    ids[node] = i;

    // Initializing starts & offsets
    n += graph.outDegreeWithoutSelfLoops(node);
    self.starts[i] = n;

    n += graph.inDegreeWithoutSelfLoops(node);
    self.offsets[i] = n;

    // Belongings
    self.belongings[i] = i;
    self.counts[i] = 1;
    i++;
  });

  // Single sweep over the edges
  graph.forEachEdge(function (edge, attr, source, target, sa, ta, u) {
    weight = getEdgeWeight(edge, attr, source, target, sa, ta, u);

    source = ids[source];
    target = ids[target];

    self.M += weight;

    // Self loop?
    if (source === target) {
      self.loops[source] += weight;
      self.totalInWeights[source] += weight;
      self.totalOutWeights[source] += weight;
    } else {
      self.totalOutWeights[source] += weight;
      self.totalInWeights[target] += weight;

      var startSource = --self.starts[source],
        startTarget = --self.offsets[target];

      self.neighborhood[startSource] = target;
      self.neighborhood[startTarget] = source;

      self.weights[startSource] = weight;
      self.weights[startTarget] = weight;
    }
  });

  this.starts[i] = this.E;

  if (this.keepDendrogram) this.dendrogram.push(this.belongings.slice());
  else this.mapping = this.belongings.slice();
}

DirectedLouvainIndex.prototype.bounds = UndirectedLouvainIndex.prototype.bounds;

DirectedLouvainIndex.prototype.inBounds = function (i) {
  return [this.offsets[i], this.starts[i + 1]];
};

DirectedLouvainIndex.prototype.outBounds = function (i) {
  return [this.starts[i], this.offsets[i]];
};

DirectedLouvainIndex.prototype.project =
  UndirectedLouvainIndex.prototype.project;

DirectedLouvainIndex.prototype.projectIn = function () {
  var self = this;

  var projection = {};

  self.nodes.slice(0, this.C).forEach(function (node, i) {
    projection[node] = Array.from(
      self.neighborhood.slice(self.offsets[i], self.starts[i + 1])
    ).map(function (j) {
      return self.nodes[j];
    });
  });

  return projection;
};

DirectedLouvainIndex.prototype.projectOut = function () {
  var self = this;

  var projection = {};

  self.nodes.slice(0, this.C).forEach(function (node, i) {
    projection[node] = Array.from(
      self.neighborhood.slice(self.starts[i], self.offsets[i])
    ).map(function (j) {
      return self.nodes[j];
    });
  });

  return projection;
};

DirectedLouvainIndex.prototype.isolate = function (i, inDegree, outDegree) {
  var currentCommunity = this.belongings[i];

  // The node is already isolated
  if (this.counts[currentCommunity] === 1) return currentCommunity;

  var newCommunity = this.unused[--this.U];

  var loops = this.loops[i];

  this.totalInWeights[currentCommunity] -= inDegree + loops;
  this.totalInWeights[newCommunity] += inDegree + loops;

  this.totalOutWeights[currentCommunity] -= outDegree + loops;
  this.totalOutWeights[newCommunity] += outDegree + loops;

  this.belongings[i] = newCommunity;

  this.counts[currentCommunity]--;
  this.counts[newCommunity]++;

  return newCommunity;
};

DirectedLouvainIndex.prototype.move = function (
  i,
  inDegree,
  outDegree,
  targetCommunity
) {
  var currentCommunity = this.belongings[i],
    loops = this.loops[i];

  this.totalInWeights[currentCommunity] -= inDegree + loops;
  this.totalInWeights[targetCommunity] += inDegree + loops;

  this.totalOutWeights[currentCommunity] -= outDegree + loops;
  this.totalOutWeights[targetCommunity] += outDegree + loops;

  this.belongings[i] = targetCommunity;

  var nowEmpty = this.counts[currentCommunity]-- === 1;
  this.counts[targetCommunity]++;

  if (nowEmpty) this.unused[this.U++] = currentCommunity;
};

DirectedLouvainIndex.prototype.computeNodeInDegree = function (i) {
  var o, l, weight;

  var inDegree = 0;

  for (o = this.offsets[i], l = this.starts[i + 1]; o < l; o++) {
    weight = this.weights[o];

    inDegree += weight;
  }

  return inDegree;
};

DirectedLouvainIndex.prototype.computeNodeOutDegree = function (i) {
  var o, l, weight;

  var outDegree = 0;

  for (o = this.starts[i], l = this.offsets[i]; o < l; o++) {
    weight = this.weights[o];

    outDegree += weight;
  }

  return outDegree;
};

DirectedLouvainIndex.prototype.expensiveMove = function (i, ci) {
  var inDegree = this.computeNodeInDegree(i),
    outDegree = this.computeNodeOutDegree(i);

  this.move(i, inDegree, outDegree, ci);
};

DirectedLouvainIndex.prototype.zoomOut = function () {
  var inducedGraph = new Array(this.C - this.U),
    newLabels = {};

  var N = this.nodes.length;

  var C = 0,
    E = 0;

  var i, j, l, m, n, ci, cj, data, offset, out, adj, inAdj, outAdj;

  // Renumbering communities
  for (i = 0, l = this.C; i < l; i++) {
    ci = this.belongings[i];

    if (!(ci in newLabels)) {
      newLabels[ci] = C;
      inducedGraph[C] = {
        inAdj: {},
        outAdj: {},
        totalInWeights: this.totalInWeights[ci],
        totalOutWeights: this.totalOutWeights[ci],
        internalWeights: 0
      };
      C++;
    }

    // We do this to otpimize the number of lookups in next loop
    this.belongings[i] = newLabels[ci];
  }

  // Actualizing dendrogram
  var currentLevel, nextLevel;

  if (this.keepDendrogram) {
    currentLevel = this.dendrogram[this.level];
    nextLevel = new (typed.getPointerArray(C))(N);

    for (i = 0; i < N; i++) nextLevel[i] = this.belongings[currentLevel[i]];

    this.dendrogram.push(nextLevel);
  } else {
    for (i = 0; i < N; i++) this.mapping[i] = this.belongings[this.mapping[i]];
  }

  // Building induced graph matrix
  for (i = 0, l = this.C; i < l; i++) {
    ci = this.belongings[i];
    offset = this.offsets[i];

    data = inducedGraph[ci];
    inAdj = data.inAdj;
    outAdj = data.outAdj;
    data.internalWeights += this.loops[i];

    for (j = this.starts[i], m = this.starts[i + 1]; j < m; j++) {
      n = this.neighborhood[j];
      cj = this.belongings[n];
      out = j < offset;

      adj = out ? outAdj : inAdj;

      if (ci === cj) {
        if (out) data.internalWeights += this.weights[j];

        continue;
      }

      if (!(cj in adj)) adj[cj] = 0;

      adj[cj] += this.weights[j];
    }
  }

  // Rewriting neighborhood
  this.C = C;

  n = 0;

  for (ci = 0; ci < C; ci++) {
    data = inducedGraph[ci];
    inAdj = data.inAdj;
    outAdj = data.outAdj;

    ci = +ci;

    this.totalInWeights[ci] = data.totalInWeights;
    this.totalOutWeights[ci] = data.totalOutWeights;
    this.loops[ci] = data.internalWeights;
    this.counts[ci] = 1;

    this.starts[ci] = n;
    this.belongings[ci] = ci;

    for (cj in outAdj) {
      this.neighborhood[n] = +cj;
      this.weights[n] = outAdj[cj];

      E++;
      n++;
    }

    this.offsets[ci] = n;

    for (cj in inAdj) {
      this.neighborhood[n] = +cj;
      this.weights[n] = inAdj[cj];

      E++;
      n++;
    }
  }

  this.starts[C] = E;

  this.E = E;
  this.U = 0;
  this.level++;

  return newLabels;
};

DirectedLouvainIndex.prototype.modularity = function () {
  var ci, cj, i, j, m;

  var Q = 0;
  var M = this.M;
  var internalWeights = new Float64Array(this.C);

  for (i = 0; i < this.C; i++) {
    ci = this.belongings[i];
    internalWeights[ci] += this.loops[i];

    for (j = this.starts[i], m = this.offsets[i]; j < m; j++) {
      cj = this.belongings[this.neighborhood[j]];

      if (ci !== cj) continue;

      internalWeights[ci] += this.weights[j];
    }
  }

  for (i = 0; i < this.C; i++)
    Q +=
      internalWeights[i] / M -
      ((this.totalInWeights[i] * this.totalOutWeights[i]) / Math.pow(M, 2)) *
        this.resolution;

  return Q;
};

DirectedLouvainIndex.prototype.delta = function (
  i,
  inDegree,
  outDegree,
  targetCommunityDegree,
  targetCommunity
) {
  var M = this.M;

  var targetCommunityTotalInWeight = this.totalInWeights[targetCommunity],
    targetCommunityTotalOutWeight = this.totalOutWeights[targetCommunity];

  var loops = this.loops[i];

  inDegree += loops;
  outDegree += loops;

  return (
    targetCommunityDegree / M -
    ((outDegree * targetCommunityTotalInWeight +
      inDegree * targetCommunityTotalOutWeight) *
      this.resolution) /
      (M * M)
  );
};

DirectedLouvainIndex.prototype.deltaWithOwnCommunity = function (
  i,
  inDegree,
  outDegree,
  targetCommunityDegree,
  targetCommunity
) {
  var M = this.M;

  var targetCommunityTotalInWeight = this.totalInWeights[targetCommunity],
    targetCommunityTotalOutWeight = this.totalOutWeights[targetCommunity];

  var loops = this.loops[i];

  inDegree += loops;
  outDegree += loops;

  return (
    targetCommunityDegree / M -
    ((outDegree * (targetCommunityTotalInWeight - inDegree) +
      inDegree * (targetCommunityTotalOutWeight - outDegree)) *
      this.resolution) /
      (M * M)
  );
};

DirectedLouvainIndex.prototype.collect =
  UndirectedLouvainIndex.prototype.collect;
DirectedLouvainIndex.prototype.assign = UndirectedLouvainIndex.prototype.assign;

DirectedLouvainIndex.prototype[INSPECT] = function () {
  var proxy = {};

  // Trick so that node displays the name of the constructor
  Object.defineProperty(proxy, 'constructor', {
    value: DirectedLouvainIndex,
    enumerable: false
  });

  proxy.C = this.C;
  proxy.M = this.M;
  proxy.E = this.E;
  proxy.U = this.U;
  proxy.resolution = this.resolution;
  proxy.level = this.level;
  proxy.nodes = this.nodes;
  proxy.starts = this.starts.slice(0, proxy.C + 1);

  var eTruncated = ['neighborhood', 'weights'];
  var cTruncated = [
    'counts',
    'offsets',
    'loops',
    'belongings',
    'totalInWeights',
    'totalOutWeights'
  ];

  var self = this;

  eTruncated.forEach(function (key) {
    proxy[key] = self[key].slice(0, proxy.E);
  });

  cTruncated.forEach(function (key) {
    proxy[key] = self[key].slice(0, proxy.C);
  });

  proxy.unused = this.unused.slice(0, this.U);

  if (this.keepDendrogram) proxy.dendrogram = this.dendrogram;
  else proxy.mapping = this.mapping;

  return proxy;
};

exports.UndirectedLouvainIndex = UndirectedLouvainIndex;
exports.DirectedLouvainIndex = DirectedLouvainIndex;
