/**
 * Graphology Sorted Component Index
 * ==================================
 *
 * An index storing the connected components of given graph sorted by order.
 */
var DFSStack = require('./dfs-stack.js');

function SortedComponentsIndex(graph) {
  var orders = [];
  var offsets = [];
  var nodes = new Array(graph.order);
  var count = 0;
  var n = 0;

  if (!graph.order) return;

  var stack = new DFSStack(graph.order);
  var push = stack.push.bind(stack);

  var componentOrder;

  // Performing DFS
  graph.forEachNode(function (node) {
    if (stack.has(node)) return;

    componentOrder = 0;
    offsets.push(n);
    stack.push(node);

    var source;

    while (stack.size !== 0) {
      source = stack.pop();

      componentOrder += 1;
      nodes[n++] = source;

      graph.forEachNeighbor(source, push);
    }

    orders.push(componentOrder);
    count++;
  });

  // Sorting by decreasing component order
  var argsort = new Array(orders.length);
  var i;

  for (i = 0; i < orders.length; i++) argsort[i] = i;

  function comparator(a, b) {
    a = orders[a];
    b = orders[b];

    if (a < b) return 1;

    if (a > b) return -1;

    return 0;
  }

  argsort.sort(comparator);

  var sortedOrders = new Uint32Array(orders.length);
  var sortedOffsets = new Uint32Array(orders.length);

  var j;

  for (i = 0; i < argsort.length; i++) {
    j = argsort[i];
    sortedOrders[i] = orders[j];
    sortedOffsets[i] = offsets[j];
  }

  // Exposed properties
  this.nodes = nodes;
  this.orders = sortedOrders;
  this.offsets = sortedOffsets;
  this.count = count;
}

module.exports = SortedComponentsIndex;
