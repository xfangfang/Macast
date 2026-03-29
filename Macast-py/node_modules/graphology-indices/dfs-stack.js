/**
 * Graphology DFS Stack
 * =====================
 *
 * An experiment to speed up DFS in graphs and connected component detection.
 *
 * It should mostly save memory and not improve theoretical runtime.
 */
function DFSStack(graph) {
  this.graph = graph;
  this.stack = new Array(graph.order);
  this.seen = new Set();
  this.size = 0;
}

DFSStack.prototype.hasAlreadySeenEverything = function () {
  return this.seen.size === this.graph.order;
};

DFSStack.prototype.countUnseenNodes = function () {
  return this.graph.order - this.seen.size;
};

DFSStack.prototype.forEachNodeYetUnseen = function (callback) {
  var seen = this.seen;
  var graph = this.graph;

  graph.someNode(function (node, attr) {
    // Useful early exit for connected graphs
    if (seen.size === graph.order) return true; // break

    // Node already seen?
    if (seen.has(node)) return false; // continue

    var shouldBreak = callback(node, attr);

    if (shouldBreak) return true;

    return false;
  });
};

DFSStack.prototype.has = function (node) {
  return this.seen.has(node);
};

DFSStack.prototype.push = function (node) {
  var seenSizeBefore = this.seen.size;

  this.seen.add(node);

  // If node was already seen
  if (seenSizeBefore === this.seen.size) return false;

  this.stack[this.size++] = node;

  return true;
};

DFSStack.prototype.pushWith = function (node, item) {
  var seenSizeBefore = this.seen.size;

  this.seen.add(node);

  // If node was already seen
  if (seenSizeBefore === this.seen.size) return false;

  this.stack[this.size++] = item;

  return true;
};

DFSStack.prototype.pop = function () {
  if (this.size === 0) return;

  return this.stack[--this.size];
};

module.exports = DFSStack;
