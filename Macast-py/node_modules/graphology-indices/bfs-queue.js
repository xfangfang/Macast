/**
 * Graphology BFS Queue
 * =====================
 *
 * An experiment to speed up BFS in graphs and connected component detection.
 *
 * It should mostly save memory and not improve theoretical runtime.
 */
var FixedDeque = require('mnemonist/fixed-deque');

function BFSQueue(graph) {
  this.graph = graph;
  this.queue = new FixedDeque(Array, graph.order);
  this.seen = new Set();
  this.size = 0;
}

BFSQueue.prototype.hasAlreadySeenEverything = function () {
  return this.seen.size === this.graph.order;
};

BFSQueue.prototype.countUnseenNodes = function () {
  return this.graph.order - this.seen.size;
};

BFSQueue.prototype.forEachNodeYetUnseen = function (callback) {
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

BFSQueue.prototype.has = function (node) {
  return this.seen.has(node);
};

BFSQueue.prototype.push = function (node) {
  var seenSizeBefore = this.seen.size;

  this.seen.add(node);

  // If node was already seen
  if (seenSizeBefore === this.seen.size) return false;

  this.queue.push(node);
  this.size++;

  return true;
};

BFSQueue.prototype.pushWith = function (node, item) {
  var seenSizeBefore = this.seen.size;

  this.seen.add(node);

  // If node was already seen
  if (seenSizeBefore === this.seen.size) return false;

  this.queue.push(item);
  this.size++;

  return true;
};

BFSQueue.prototype.shift = function () {
  var item = this.queue.shift();
  this.size = this.queue.size;

  return item;
};

module.exports = BFSQueue;
