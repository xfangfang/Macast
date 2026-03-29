import Graph, {Attributes} from 'graphology-types';
import {MinimalEdgeMapper} from 'graphology-utils/getters';

type PointerArray = Uint8Array | Uint16Array | Uint32Array | Float64Array;

type NeighborhoodMethod =
  | 'in'
  | 'out'
  | 'directed'
  | 'undirected'
  | 'inbound'
  | 'outbound';

export class NeighborhoodIndex {
  constructor(graph: Graph, method?: NeighborhoodMethod);

  graph: Graph;
  neighborhood: PointerArray;
  starts: PointerArray;
  nodes: Array<string>;

  bounds(index: number): [number, number];
  project(): {[key: string]: Array<string>};
  collect<T>(results: Array<T>): {[key: string]: T};
  assign<T>(name: string, results: Array<T>): void;
}

export class WeightedNeighborhoodIndex<
  NodeAttributes extends Attributes = Attributes,
  EdgeAttributes extends Attributes = Attributes
> extends NeighborhoodIndex {
  constructor(
    graph: Graph<NodeAttributes, EdgeAttributes>,
    weightAttribute?:
      | keyof EdgeAttributes
      | MinimalEdgeMapper<number, EdgeAttributes>,
    method?: NeighborhoodMethod
  );

  weights: Float64Array;
  outDegrees: Float64Array;
}
