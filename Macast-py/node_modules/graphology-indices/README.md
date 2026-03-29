# Graphology Indices

Miscellaneous indices to be used with [`graphology`](https://graphology.github.io).

## Installation

```
npm install graphology-indices
```

## Contents

This library contains multiple low-level indexation structures used to optimize graph computations in other `graphology` libraries. This library is not meant to be used as such and this is why it is not thoroughly documented.

For now, here are the exposed indices:

- An unweighted and weighted neighborhood index used to speed up computations requiring many successive BSTs in a graph.
- A directed and undirected index used to track an evolving community structure when running the Louvain community detection algorithm.
- An indexed view of a graph's connected components sorted by order.
- A specialized stack/set that can be used to perform memory-efficient DFS traversals.
- A specialized queue/set that can be used to perform memory-efficient BFS traversals.
