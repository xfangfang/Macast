import Graph from 'graphology-types';

export default class SortedComponentsIndex {
  orders: Uint32Array;
  offsets: Uint32Array;
  nodes: Array<string>;
  count: number;

  constructor(graph: Graph);
}
