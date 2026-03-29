/**
 * Graphology Typings
 * ===================
 *
 * Graphology TypeScript declaration.
 */

/**
 * Miscellaneous types.
 */
type Attributes = {[name: string]: any};

type GraphType = 'mixed' | 'directed' | 'undirected';

type UpdateHints<ItemAttributes extends Attributes = Attributes> = {
  attributes?: Array<keyof ItemAttributes>;
};

type GraphOptions = {
  allowSelfLoops?: boolean;
  multi?: boolean;
  type?: GraphType;
};

type AdjacencyEntry<
  NodeAttributes extends Attributes = Attributes,
  EdgeAttributes extends Attributes = Attributes
> = {
  source: string;
  target: string;
  sourceAttributes: NodeAttributes;
  targetAttributes: NodeAttributes;
  edge: string;
  edgeAttributes: EdgeAttributes;
  undirected: boolean;
};

type NodeEntry<NodeAttributes extends Attributes = Attributes> = {
  node: string;
  attributes: NodeAttributes;
};

type NodeMergeResult = [key: string, nodeWasAdded: boolean];

type NeighborEntry<NodeAttributes extends Attributes = Attributes> = {
  neighbor: string;
  attributes: NodeAttributes;
};

type EdgeEntry<
  NodeAttributes extends Attributes = Attributes,
  EdgeAttributes extends Attributes = Attributes
> = {
  edge: string;
  attributes: EdgeAttributes;
  source: string;
  target: string;
  sourceAttributes: NodeAttributes;
  targetAttributes: NodeAttributes;
  undirected: boolean;
};

type EdgeMergeResult = [
  key: string,
  edgeWasAdded: boolean,
  sourceWasAdded: boolean,
  targetWasAdded: boolean
];

type AdjacencyIterationCallback<
  NodeAttributes extends Attributes = Attributes,
  EdgeAttributes extends Attributes = Attributes
> = (
  node: string,
  neighbor: string,
  nodeAttributes: NodeAttributes,
  neighborAttributes: NodeAttributes,
  edge: string,
  edgeAttributes: EdgeAttributes,
  undirected: boolean
) => void;

type AdjacencyIterationCallbackWithOrphans<
  NodeAttributes extends Attributes = Attributes,
  EdgeAttributes extends Attributes = Attributes
> = (
  node: string,
  neighbor: string | null,
  nodeAttributes: NodeAttributes,
  neighborAttributes: NodeAttributes | null,
  edge: string | null,
  edgeAttributes: EdgeAttributes | null,
  undirected: boolean | null
) => void;

type NodeIterationCallback<NodeAttributes extends Attributes = Attributes> = (
  node: string,
  attributes: NodeAttributes
) => void;

type NodePredicate<NodeAttributes extends Attributes = Attributes> = (
  node: string,
  attributes: NodeAttributes
) => boolean | void;

type NodeMapper<T, NodeAttributes extends Attributes = Attributes> = (
  node: string,
  attributes: NodeAttributes
) => T;

type NodeReducer<T, NodeAttributes extends Attributes = Attributes> = (
  accumulator: T,
  node: string,
  attributes: NodeAttributes
) => T;

type NeighborIterationCallback<NodeAttributes extends Attributes = Attributes> =
  (neighbor: string, attributes: NodeAttributes) => void;

type NeighborPredicate<NodeAttributes extends Attributes = Attributes> = (
  neighbor: string,
  attributes: NodeAttributes
) => boolean | void;

type NeighborMapper<T, NodeAttributes extends Attributes = Attributes> = (
  neighbor: string,
  attributes: NodeAttributes
) => T;

type NeighborReducer<T, NodeAttributes extends Attributes = Attributes> = (
  accumulator: T,
  neighbor: string,
  attributes: NodeAttributes
) => T;

type EdgeIterationCallback<
  NodeAttributes extends Attributes = Attributes,
  EdgeAttributes extends Attributes = Attributes
> = (
  edge: string,
  attributes: EdgeAttributes,
  source: string,
  target: string,
  sourceAttributes: NodeAttributes,
  targetAttributes: NodeAttributes,
  undirected: boolean
) => void;

type EdgePredicate<
  NodeAttributes extends Attributes = Attributes,
  EdgeAttributes extends Attributes = Attributes
> = (
  edge: string,
  attributes: EdgeAttributes,
  source: string,
  target: string,
  sourceAttributes: NodeAttributes,
  targetAttributes: NodeAttributes,
  undirected: boolean
) => boolean | void;

type EdgeMapper<
  T,
  NodeAttributes extends Attributes = Attributes,
  EdgeAttributes extends Attributes = Attributes
> = (
  edge: string,
  attributes: EdgeAttributes,
  source: string,
  target: string,
  sourceAttributes: NodeAttributes,
  targetAttributes: NodeAttributes,
  undirected: boolean
) => T;

type EdgeReducer<
  T,
  NodeAttributes extends Attributes = Attributes,
  EdgeAttributes extends Attributes = Attributes
> = (
  accumulator: T,
  edge: string,
  attributes: EdgeAttributes,
  source: string,
  target: string,
  sourceAttributes: NodeAttributes,
  targetAttributes: NodeAttributes,
  undirected: boolean
) => T;

type SerializedNode<NodeAttributes extends Attributes = Attributes> = {
  key: string;
  attributes?: NodeAttributes;
};

type SerializedEdge<EdgeAttributes extends Attributes = Attributes> = {
  key?: string;
  source: string;
  target: string;
  attributes?: EdgeAttributes;
  undirected?: boolean;
};

type SerializedGraph<
  NodeAttributes extends Attributes = Attributes,
  EdgeAttributes extends Attributes = Attributes,
  GraphAttributes extends Attributes = Attributes
> = {
  attributes: GraphAttributes;
  options: GraphOptions;
  nodes: Array<SerializedNode<NodeAttributes>>;
  edges: Array<SerializedEdge<EdgeAttributes>>;
};

/**
 * Event Emitter typings for convience.
 * @note Taken from here: https://github.com/DefinitelyTyped/DefinitelyTyped/blob/master/types/events/index.d.ts
 */
type Listener = (...args: any[]) => void;
type EventsMapping = Record<string, Listener>;

type AttributeUpdateType = 'set' | 'remove' | 'replace' | 'merge' | 'update';

type AttributeUpdatePayload<ItemAttributes extends Attributes = Attributes> =
  | {
      type: 'set';
      key: string;
      attributes: ItemAttributes;
      name: keyof ItemAttributes;
    }
  | {
      type: 'remove';
      key: string;
      attributes: ItemAttributes;
      name: keyof ItemAttributes;
    }
  | {
      type: 'replace';
      key: string;
      attributes: ItemAttributes;
    }
  | {
      type: 'merge';
      key: string;
      attributes: ItemAttributes;
      data: ItemAttributes;
    }
  | {
      type: 'update';
      key: string;
      attributes: ItemAttributes;
    };

type GraphEvents<
  NodeAttributes extends Attributes = Attributes,
  EdgeAttributes extends Attributes = Attributes,
  GraphAttributes extends Attributes = Attributes
> = {
  nodeAdded(payload: {key: string; attributes: NodeAttributes}): void;
  edgeAdded(payload: {
    key: string;
    source: string;
    target: string;
    attributes: EdgeAttributes;
    undirected: boolean;
  }): void;
  nodeDropped(payload: {key: string; attributes: NodeAttributes}): void;
  edgeDropped(payload: {
    key: string;
    source: string;
    target: string;
    attributes: EdgeAttributes;
    undirected: boolean;
  }): void;
  cleared(): void;
  edgesCleared(): void;
  attributesUpdated(
    payload: Omit<AttributeUpdatePayload<GraphAttributes>, 'key'>
  ): void;
  nodeAttributesUpdated(payload: AttributeUpdatePayload<NodeAttributes>): void;
  edgeAttributesUpdated(payload: AttributeUpdatePayload<EdgeAttributes>): void;
  eachNodeAttributesUpdated(payload: {
    hints: UpdateHints<NodeAttributes>;
  }): void;
  eachEdgeAttributesUpdated(payload: {
    hints: UpdateHints<EdgeAttributes>;
  }): void;
};

declare class GraphEventEmitter<Events extends EventsMapping> {
  static listenerCount<Events extends EventsMapping>(
    emitter: GraphEventEmitter<Events>,
    type: string | number
  ): number;
  static defaultMaxListeners: number;

  eventNames<Event extends keyof Events>(): Array<Event>;
  setMaxListeners(n: number): this;
  getMaxListeners(): number;
  emit<Event extends keyof Events>(
    type: Event,
    ...args: Parameters<Events[Event]>
  ): boolean;
  addListener<Event extends keyof Events>(
    type: Event,
    listener: Events[Event]
  ): this;
  on<Event extends keyof Events>(type: Event, listener: Events[Event]): this;
  once<Event extends keyof Events>(type: Event, listener: Events[Event]): this;
  prependListener<Event extends keyof Events>(
    type: Event,
    listener: Events[Event]
  ): this;
  prependOnceListener<Event extends keyof Events>(
    type: Event,
    listener: Events[Event]
  ): this;
  removeListener<Event extends keyof Events>(
    type: Event,
    listener: Events[Event]
  ): this;
  off<Event extends keyof Events>(type: Event, listener: Events[Event]): this;
  removeAllListeners<Event extends keyof Events>(type?: Event): this;
  listeners<Event extends keyof Events>(type: Event): Events[Event][];
  listenerCount<Event extends keyof Events>(type: Event): number;
  rawListeners<Event extends keyof Events>(type: Event): Events[Event][];
}

/**
 * Main interface.
 */
declare abstract class AbstractGraph<
  NodeAttributes extends Attributes = Attributes,
  EdgeAttributes extends Attributes = Attributes,
  GraphAttributes extends Attributes = Attributes
> extends GraphEventEmitter<
  GraphEvents<NodeAttributes, EdgeAttributes, GraphAttributes>
> {
  // Constructor
  constructor(options?: GraphOptions);

  // Members
  order: number;
  size: number;
  directedSize: number;
  undirectedSize: number;
  type: GraphType;
  multi: boolean;
  allowSelfLoops: boolean;
  implementation: string;
  selfLoopCount: number;
  directedSelfLoopCount: number;
  undirectedSelfLoopCount: number;

  // Read methods
  hasNode(node: unknown): boolean;
  hasDirectedEdge(edge: unknown): boolean;
  hasDirectedEdge(source: unknown, target: unknown): boolean;
  hasUndirectedEdge(edge: unknown): boolean;
  hasUndirectedEdge(source: unknown, target: unknown): boolean;
  hasEdge(edge: unknown): boolean;
  hasEdge(source: unknown, target: unknown): boolean;
  directedEdge(source: unknown, target: unknown): string | undefined;
  undirectedEdge(source: unknown, target: unknown): string | undefined;
  edge(source: unknown, target: unknown): string | undefined;
  inDegree(node: unknown): number;
  outDegree(node: unknown): number;
  inboundDegree(node: unknown): number;
  outboundDegree(node: unknown): number;
  directedDegree(node: unknown): number;
  undirectedDegree(node: unknown): number;
  degree(node: unknown): number;
  inDegreeWithoutSelfLoops(node: unknown): number;
  outDegreeWithoutSelfLoops(node: unknown): number;
  inboundDegreeWithoutSelfLoops(node: unknown): number;
  outboundDegreeWithoutSelfLoops(node: unknown): number;
  directedDegreeWithoutSelfLoops(node: unknown): number;
  undirectedDegreeWithoutSelfLoops(node: unknown): number;
  degreeWithoutSelfLoops(node: unknown): number;
  source(edge: unknown): string;
  target(edge: unknown): string;
  extremities(edge: unknown): [string, string];
  opposite(node: unknown, edge: unknown): string;
  isUndirected(edge: unknown): boolean;
  isDirected(edge: unknown): boolean;
  isSelfLoop(edge: unknown): boolean;
  hasExtremity(edge: unknown, node: unknown): boolean;
  areNeighbors(source: unknown, target: unknown): boolean;
  areUndirectedNeighbors(source: unknown, target: unknown): boolean;
  areDirectedNeighbors(source: unknown, target: unknown): boolean;
  areInNeighbors(source: unknown, target: unknown): boolean;
  areOutNeighbors(source: unknown, target: unknown): boolean;
  areInboundNeighbors(source: unknown, target: unknown): boolean;
  areOutboundNeighbors(source: unknown, target: unknown): boolean;

  // Mutation methods
  addNode(node: unknown, attributes?: NodeAttributes): string;
  mergeNode(
    node: unknown,
    attributes?: Partial<NodeAttributes>
  ): NodeMergeResult;
  updateNode(
    node: unknown,
    updater?: (attributes: Partial<NodeAttributes>) => NodeAttributes
  ): NodeMergeResult;
  addEdge(
    source: unknown,
    target: unknown,
    attributes?: EdgeAttributes
  ): string;
  mergeEdge(
    source: unknown,
    target: unknown,
    attributes?: Partial<EdgeAttributes>
  ): EdgeMergeResult;
  updateEdge(
    source: unknown,
    target: unknown,
    updater?: (attributes: Partial<EdgeAttributes>) => EdgeAttributes
  ): EdgeMergeResult;
  addDirectedEdge(
    source: unknown,
    target: unknown,
    attributes?: EdgeAttributes
  ): string;
  mergeDirectedEdge(
    source: unknown,
    target: unknown,
    attributes?: Partial<EdgeAttributes>
  ): EdgeMergeResult;
  updateDirectedEdge(
    source: unknown,
    target: unknown,
    updater?: (attributes: Partial<EdgeAttributes>) => EdgeAttributes
  ): EdgeMergeResult;
  addUndirectedEdge(
    source: unknown,
    target: unknown,
    attributes?: EdgeAttributes
  ): string;
  mergeUndirectedEdge(
    source: unknown,
    target: unknown,
    attributes?: Partial<EdgeAttributes>
  ): EdgeMergeResult;
  updateUndirectedEdge(
    source: unknown,
    target: unknown,
    updater?: (attributes: Partial<EdgeAttributes>) => EdgeAttributes
  ): EdgeMergeResult;
  addEdgeWithKey(
    edge: unknown,
    source: unknown,
    target: unknown,
    attributes?: EdgeAttributes
  ): string;
  mergeEdgeWithKey(
    edge: unknown,
    source: unknown,
    target: unknown,
    attributes?: Partial<EdgeAttributes>
  ): EdgeMergeResult;
  updateEdgeWithKey(
    edge: unknown,
    source: unknown,
    target: unknown,
    updater?: (attributes: Partial<EdgeAttributes>) => EdgeAttributes
  ): EdgeMergeResult;
  addDirectedEdgeWithKey(
    edge: unknown,
    source: unknown,
    target: unknown,
    attributes?: EdgeAttributes
  ): string;
  mergeDirectedEdgeWithKey(
    edge: unknown,
    source: unknown,
    target: unknown,
    attributes?: Partial<EdgeAttributes>
  ): EdgeMergeResult;
  updateDirectedEdgeWithKey(
    edge: unknown,
    source: unknown,
    target: unknown,
    updater?: (attributes: Partial<EdgeAttributes>) => EdgeAttributes
  ): EdgeMergeResult;
  addUndirectedEdgeWithKey(
    edge: unknown,
    source: unknown,
    target: unknown,
    attributes?: EdgeAttributes
  ): string;
  mergeUndirectedEdgeWithKey(
    edge: unknown,
    source: unknown,
    target: unknown,
    attributes?: Partial<EdgeAttributes>
  ): EdgeMergeResult;
  updateUndirectedEdgeWithKey(
    edge: unknown,
    source: unknown,
    target: unknown,
    updater?: (attributes: Partial<EdgeAttributes>) => EdgeAttributes
  ): EdgeMergeResult;
  dropNode(node: unknown): void;
  dropEdge(edge: unknown): void;
  dropEdge(source: unknown, target: unknown): void;
  dropDirectedEdge(source: unknown, target: unknown): void;
  dropUndirectedEdge(source: unknown, target: unknown): void;
  clear(): void;
  clearEdges(): void;

  // Graph attribute methods
  getAttribute<AttributeName extends keyof GraphAttributes>(
    name: AttributeName
  ): GraphAttributes[AttributeName];
  getAttributes(): GraphAttributes;
  hasAttribute<AttributeName extends keyof GraphAttributes>(
    name: AttributeName
  ): boolean;
  setAttribute<AttributeName extends keyof GraphAttributes>(
    name: AttributeName,
    value: GraphAttributes[AttributeName]
  ): this;
  updateAttribute<AttributeName extends keyof GraphAttributes>(
    name: AttributeName,
    updater: (
      value: GraphAttributes[AttributeName] | undefined
    ) => GraphAttributes[AttributeName]
  ): this;
  removeAttribute<AttributeName extends keyof GraphAttributes>(
    name: AttributeName
  ): this;
  replaceAttributes(attributes: GraphAttributes): this;
  mergeAttributes(attributes: Partial<GraphAttributes>): this;
  updateAttributes(
    updater: (attributes: GraphAttributes) => GraphAttributes
  ): this;

  // Node attribute methods
  getNodeAttribute<AttributeName extends keyof NodeAttributes>(
    node: unknown,
    name: AttributeName
  ): NodeAttributes[AttributeName];
  getNodeAttributes(node: unknown): NodeAttributes;
  hasNodeAttribute<AttributeName extends keyof NodeAttributes>(
    node: unknown,
    name: AttributeName
  ): boolean;
  setNodeAttribute<AttributeName extends keyof NodeAttributes>(
    node: unknown,
    name: AttributeName,
    value: NodeAttributes[AttributeName]
  ): this;
  updateNodeAttribute<AttributeName extends keyof NodeAttributes>(
    node: unknown,
    name: AttributeName,
    updater: (
      value: NodeAttributes[AttributeName] | undefined
    ) => NodeAttributes[AttributeName]
  ): this;
  removeNodeAttribute<AttributeName extends keyof NodeAttributes>(
    node: unknown,
    name: AttributeName
  ): this;
  replaceNodeAttributes(node: unknown, attributes: NodeAttributes): this;
  mergeNodeAttributes(node: unknown, attributes: Partial<NodeAttributes>): this;
  updateNodeAttributes(
    node: unknown,
    updater: (attributes: NodeAttributes) => NodeAttributes
  ): this;

  getSourceAttribute<AttributeName extends keyof NodeAttributes>(
    edge: unknown,
    name: AttributeName
  ): NodeAttributes[AttributeName];
  getSourceAttributes(edge: unknown): NodeAttributes;
  hasSourceAttribute<AttributeName extends keyof NodeAttributes>(
    edge: unknown,
    name: AttributeName
  ): boolean;
  setSourceAttribute<AttributeName extends keyof NodeAttributes>(
    edge: unknown,
    name: AttributeName,
    value: NodeAttributes[AttributeName]
  ): this;
  updateSourceAttribute<AttributeName extends keyof NodeAttributes>(
    edge: unknown,
    name: AttributeName,
    updater: (
      value: NodeAttributes[AttributeName] | undefined
    ) => NodeAttributes[AttributeName]
  ): this;
  removeSourceAttribute<AttributeName extends keyof NodeAttributes>(
    edge: unknown,
    name: AttributeName
  ): this;
  replaceSourceAttributes(edge: unknown, attributes: NodeAttributes): this;
  mergeSourceAttributes(
    edge: unknown,
    attributes: Partial<NodeAttributes>
  ): this;
  updateSourceAttributes(
    edge: unknown,
    updater: (attributes: NodeAttributes) => NodeAttributes
  ): this;

  getTargetAttribute<AttributeName extends keyof NodeAttributes>(
    edge: unknown,
    name: AttributeName
  ): NodeAttributes[AttributeName];
  getTargetAttributes(edge: unknown): NodeAttributes;
  hasTargetAttribute<AttributeName extends keyof NodeAttributes>(
    edge: unknown,
    name: AttributeName
  ): boolean;
  setTargetAttribute<AttributeName extends keyof NodeAttributes>(
    edge: unknown,
    name: AttributeName,
    value: NodeAttributes[AttributeName]
  ): this;
  updateTargetAttribute<AttributeName extends keyof NodeAttributes>(
    edge: unknown,
    name: AttributeName,
    updater: (
      value: NodeAttributes[AttributeName] | undefined
    ) => NodeAttributes[AttributeName]
  ): this;
  removeTargetAttribute<AttributeName extends keyof NodeAttributes>(
    edge: unknown,
    name: AttributeName
  ): this;
  replaceTargetAttributes(edge: unknown, attributes: NodeAttributes): this;
  mergeTargetAttributes(
    edge: unknown,
    attributes: Partial<NodeAttributes>
  ): this;
  updateTargetAttributes(
    edge: unknown,
    updater: (attributes: NodeAttributes) => NodeAttributes
  ): this;

  getOppositeAttribute<AttributeName extends keyof NodeAttributes>(
    node: unknown,
    edge: unknown,
    name: AttributeName
  ): NodeAttributes[AttributeName];
  getOppositeAttributes(node: unknown): NodeAttributes;
  hasOppositeAttribute<AttributeName extends keyof NodeAttributes>(
    node: unknown,
    edge: unknown,
    name: AttributeName
  ): boolean;
  setOppositeAttribute<AttributeName extends keyof NodeAttributes>(
    node: unknown,
    edge: unknown,
    name: AttributeName,
    value: NodeAttributes[AttributeName]
  ): this;
  updateOppositeAttribute<AttributeName extends keyof NodeAttributes>(
    node: unknown,
    edge: unknown,
    name: AttributeName,
    updater: (
      value: NodeAttributes[AttributeName] | undefined
    ) => NodeAttributes[AttributeName]
  ): this;
  removeOppositeAttribute<AttributeName extends keyof NodeAttributes>(
    node: unknown,
    edge: unknown,
    name: AttributeName
  ): this;
  replaceOppositeAttributes(
    node: unknown,
    edge: unknown,
    attributes: NodeAttributes
  ): this;
  mergeOppositeAttributes(
    node: unknown,
    edge: unknown,
    attributes: Partial<NodeAttributes>
  ): this;
  updateOppositeAttributes(
    node: unknown,
    edge: unknown,
    updater: (attributes: NodeAttributes) => NodeAttributes
  ): this;

  updateEachNodeAttributes(
    updater: NodeMapper<NodeAttributes, NodeAttributes>,
    hints?: UpdateHints<NodeAttributes>
  ): void;

  // Edge attribute methods
  getEdgeAttribute<AttributeName extends keyof EdgeAttributes>(
    edge: unknown,
    name: AttributeName
  ): EdgeAttributes[AttributeName];
  getEdgeAttributes(edge: unknown): EdgeAttributes;
  hasEdgeAttribute<AttributeName extends keyof EdgeAttributes>(
    edge: unknown,
    name: AttributeName
  ): boolean;
  setEdgeAttribute<AttributeName extends keyof EdgeAttributes>(
    edge: unknown,
    name: AttributeName,
    value: EdgeAttributes[AttributeName]
  ): this;
  updateEdgeAttribute<AttributeName extends keyof EdgeAttributes>(
    edge: unknown,
    name: AttributeName,
    updater: (
      value: EdgeAttributes[AttributeName] | undefined
    ) => EdgeAttributes[AttributeName]
  ): this;
  removeEdgeAttribute<AttributeName extends keyof EdgeAttributes>(
    edge: unknown,
    name: AttributeName
  ): this;
  replaceEdgeAttributes(edge: unknown, attributes: EdgeAttributes): this;
  mergeEdgeAttributes(edge: unknown, attributes: Partial<EdgeAttributes>): this;
  updateEdgeAttributes(
    edge: unknown,
    updater: (attributes: EdgeAttributes) => EdgeAttributes
  ): this;

  updateEachEdgeAttributes(
    updater: EdgeMapper<EdgeAttributes, NodeAttributes, EdgeAttributes>,
    hints?: UpdateHints<EdgeAttributes>
  ): void;

  // Edge attribute methods (source, target)
  getEdgeAttribute<AttributeName extends keyof EdgeAttributes>(
    source: unknown,
    target: unknown,
    name: AttributeName
  ): EdgeAttributes[AttributeName];
  getEdgeAttributes(source: unknown, target: unknown): EdgeAttributes;
  hasEdgeAttribute<AttributeName extends keyof EdgeAttributes>(
    source: unknown,
    target: unknown,
    name: AttributeName
  ): boolean;
  setEdgeAttribute<AttributeName extends keyof EdgeAttributes>(
    source: unknown,
    target: unknown,
    name: AttributeName,
    value: EdgeAttributes[AttributeName]
  ): this;
  updateEdgeAttribute<AttributeName extends keyof EdgeAttributes>(
    source: unknown,
    target: unknown,
    name: AttributeName,
    updater: (
      value: EdgeAttributes[AttributeName] | undefined
    ) => EdgeAttributes[AttributeName]
  ): this;
  removeEdgeAttribute<AttributeName extends keyof EdgeAttributes>(
    source: unknown,
    target: unknown,
    name: AttributeName
  ): this;
  replaceEdgeAttributes(
    source: unknown,
    target: unknown,
    attributes: EdgeAttributes
  ): this;
  mergeEdgeAttributes(
    source: unknown,
    target: unknown,
    attributes: Partial<EdgeAttributes>
  ): this;
  updateEdgeAttributes(
    source: unknown,
    target: unknown,
    updater: (attributes: EdgeAttributes) => EdgeAttributes
  ): this;

  getDirectedEdgeAttribute<AttributeName extends keyof EdgeAttributes>(
    source: unknown,
    target: unknown,
    name: AttributeName
  ): EdgeAttributes[AttributeName];
  getDirectedEdgeAttributes(source: unknown, target: unknown): EdgeAttributes;
  hasDirectedEdgeAttribute<AttributeName extends keyof EdgeAttributes>(
    source: unknown,
    target: unknown,
    name: AttributeName
  ): boolean;
  setDirectedEdgeAttribute<AttributeName extends keyof EdgeAttributes>(
    source: unknown,
    target: unknown,
    name: AttributeName,
    value: EdgeAttributes[AttributeName]
  ): this;
  updateDirectedEdgeAttribute<AttributeName extends keyof EdgeAttributes>(
    source: unknown,
    target: unknown,
    name: AttributeName,
    updater: (
      value: EdgeAttributes[AttributeName] | undefined
    ) => EdgeAttributes[AttributeName]
  ): this;
  removeDirectedEdgeAttribute<AttributeName extends keyof EdgeAttributes>(
    source: unknown,
    target: unknown,
    name: AttributeName
  ): this;
  replaceDirectedEdgeAttributes(
    source: unknown,
    target: unknown,
    attributes: EdgeAttributes
  ): this;
  mergeDirectedEdgeAttributes(
    source: unknown,
    target: unknown,
    attributes: Partial<EdgeAttributes>
  ): this;
  updateDirectedEdgeAttributes(
    source: unknown,
    target: unknown,
    updater: (attributes: EdgeAttributes) => EdgeAttributes
  ): this;

  getUndirectedEdgeAttribute<AttributeName extends keyof EdgeAttributes>(
    source: unknown,
    target: unknown,
    name: AttributeName
  ): EdgeAttributes[AttributeName];
  getUndirectedEdgeAttributes(source: unknown, target: unknown): EdgeAttributes;
  hasUndirectedEdgeAttribute<AttributeName extends keyof EdgeAttributes>(
    source: unknown,
    target: unknown,
    name: AttributeName
  ): boolean;
  setUndirectedEdgeAttribute<AttributeName extends keyof EdgeAttributes>(
    source: unknown,
    target: unknown,
    name: AttributeName,
    value: EdgeAttributes[AttributeName]
  ): this;
  updateUndirectedEdgeAttribute<AttributeName extends keyof EdgeAttributes>(
    source: unknown,
    target: unknown,
    name: AttributeName,
    updater: (
      value: EdgeAttributes[AttributeName] | undefined
    ) => EdgeAttributes[AttributeName]
  ): this;
  removeUndirectedEdgeAttribute<AttributeName extends keyof EdgeAttributes>(
    source: unknown,
    target: unknown,
    name: AttributeName
  ): this;
  replaceUndirectedEdgeAttributes(
    source: unknown,
    target: unknown,
    attributes: EdgeAttributes
  ): this;
  mergeUndirectedEdgeAttributes(
    source: unknown,
    target: unknown,
    attributes: Partial<EdgeAttributes>
  ): this;
  updateUndirectedEdgeAttributes(
    source: unknown,
    target: unknown,
    updater: (attributes: EdgeAttributes) => EdgeAttributes
  ): this;

  // Iteration methods
  forEachAdjacencyEntry(
    callback: AdjacencyIterationCallback<NodeAttributes, EdgeAttributes>
  ): void;
  forEachAssymetricAdjacencyEntry(
    callback: AdjacencyIterationCallback<NodeAttributes, EdgeAttributes>
  ): void;
  forEachAdjacencyEntryWithOrphans(
    callback: AdjacencyIterationCallbackWithOrphans<
      NodeAttributes,
      EdgeAttributes
    >
  ): void;
  forEachAssymetricAdjacencyEntryWithOrphans(
    callback: AdjacencyIterationCallbackWithOrphans<
      NodeAttributes,
      EdgeAttributes
    >
  ): void;

  nodes(): Array<string>;
  forEachNode(callback: NodeIterationCallback<NodeAttributes>): void;
  mapNodes<T>(callback: NodeMapper<T, NodeAttributes>): Array<T>;
  filterNodes(callback: NodePredicate<NodeAttributes>): Array<string>;
  reduceNodes<T>(callback: NodeReducer<T, NodeAttributes>, initialValue: T): T;
  findNode(callback: NodePredicate<NodeAttributes>): string | undefined;
  someNode(callback: NodePredicate<NodeAttributes>): boolean;
  everyNode(callback: NodePredicate<NodeAttributes>): boolean;
  nodeEntries(): IterableIterator<NodeEntry<NodeAttributes>>;

  edges(): Array<string>;
  edges(node: unknown): Array<string>;
  edges(source: unknown, target: unknown): Array<string>;
  undirectedEdges(): Array<string>;
  undirectedEdges(node: unknown): Array<string>;
  undirectedEdges(source: unknown, target: unknown): Array<string>;
  directedEdges(): Array<string>;
  directedEdges(node: unknown): Array<string>;
  directedEdges(source: unknown, target: unknown): Array<string>;
  inEdges(): Array<string>;
  inEdges(node: unknown): Array<string>;
  inEdges(source: unknown, target: unknown): Array<string>;
  outEdges(): Array<string>;
  outEdges(node: unknown): Array<string>;
  outEdges(source: unknown, target: unknown): Array<string>;
  inboundEdges(): Array<string>;
  inboundEdges(node: unknown): Array<string>;
  inboundEdges(source: unknown, target: unknown): Array<string>;
  outboundEdges(): Array<string>;
  outboundEdges(node: unknown): Array<string>;
  outboundEdges(source: unknown, target: unknown): Array<string>;

  forEachEdge(
    callback: EdgeIterationCallback<NodeAttributes, EdgeAttributes>
  ): void;
  forEachEdge(
    node: unknown,
    callback: EdgeIterationCallback<NodeAttributes, EdgeAttributes>
  ): void;
  forEachEdge(
    source: unknown,
    target: unknown,
    callback: EdgeIterationCallback<NodeAttributes, EdgeAttributes>
  ): void;
  forEachUndirectedEdge(
    callback: EdgeIterationCallback<NodeAttributes, EdgeAttributes>
  ): void;
  forEachUndirectedEdge(
    node: unknown,
    callback: EdgeIterationCallback<NodeAttributes, EdgeAttributes>
  ): void;
  forEachUndirectedEdge(
    source: unknown,
    target: unknown,
    callback: EdgeIterationCallback<NodeAttributes, EdgeAttributes>
  ): void;
  forEachDirectedEdge(
    callback: EdgeIterationCallback<NodeAttributes, EdgeAttributes>
  ): void;
  forEachDirectedEdge(
    node: unknown,
    callback: EdgeIterationCallback<NodeAttributes, EdgeAttributes>
  ): void;
  forEachDirectedEdge(
    source: unknown,
    target: unknown,
    callback: EdgeIterationCallback<NodeAttributes, EdgeAttributes>
  ): void;
  forEachInEdge(
    callback: EdgeIterationCallback<NodeAttributes, EdgeAttributes>
  ): void;
  forEachInEdge(
    node: unknown,
    callback: EdgeIterationCallback<NodeAttributes, EdgeAttributes>
  ): void;
  forEachInEdge(
    source: unknown,
    target: unknown,
    callback: EdgeIterationCallback<NodeAttributes, EdgeAttributes>
  ): void;
  forEachOutEdge(
    callback: EdgeIterationCallback<NodeAttributes, EdgeAttributes>
  ): void;
  forEachOutEdge(
    node: unknown,
    callback: EdgeIterationCallback<NodeAttributes, EdgeAttributes>
  ): void;
  forEachOutEdge(
    source: unknown,
    target: unknown,
    callback: EdgeIterationCallback<NodeAttributes, EdgeAttributes>
  ): void;
  forEachInboundEdge(
    callback: EdgeIterationCallback<NodeAttributes, EdgeAttributes>
  ): void;
  forEachInboundEdge(
    node: unknown,
    callback: EdgeIterationCallback<NodeAttributes, EdgeAttributes>
  ): void;
  forEachInboundEdge(
    source: unknown,
    target: unknown,
    callback: EdgeIterationCallback<NodeAttributes, EdgeAttributes>
  ): void;
  forEachOutboundEdge(
    callback: EdgeIterationCallback<NodeAttributes, EdgeAttributes>
  ): void;
  forEachOutboundEdge(
    node: unknown,
    callback: EdgeIterationCallback<NodeAttributes, EdgeAttributes>
  ): void;
  forEachOutboundEdge(
    source: unknown,
    target: unknown,
    callback: EdgeIterationCallback<NodeAttributes, EdgeAttributes>
  ): void;

  mapEdges<T>(
    callback: EdgeMapper<T, NodeAttributes, EdgeAttributes>
  ): Array<T>;
  mapEdges<T>(
    node: unknown,
    callback: EdgeMapper<T, NodeAttributes, EdgeAttributes>
  ): Array<T>;
  mapEdges<T>(
    source: unknown,
    target: unknown,
    callback: EdgeMapper<T, NodeAttributes, EdgeAttributes>
  ): Array<T>;
  mapUndirectedEdges<T>(
    callback: EdgeMapper<T, NodeAttributes, EdgeAttributes>
  ): Array<T>;
  mapUndirectedEdges<T>(
    node: unknown,
    callback: EdgeMapper<T, NodeAttributes, EdgeAttributes>
  ): Array<T>;
  mapUndirectedEdges<T>(
    source: unknown,
    target: unknown,
    callback: EdgeMapper<T, NodeAttributes, EdgeAttributes>
  ): Array<T>;
  mapDirectedEdges<T>(
    callback: EdgeMapper<T, NodeAttributes, EdgeAttributes>
  ): Array<T>;
  mapDirectedEdges<T>(
    node: unknown,
    callback: EdgeMapper<T, NodeAttributes, EdgeAttributes>
  ): Array<T>;
  mapDirectedEdges<T>(
    source: unknown,
    target: unknown,
    callback: EdgeMapper<T, NodeAttributes, EdgeAttributes>
  ): Array<T>;
  mapInEdges<T>(
    callback: EdgeMapper<T, NodeAttributes, EdgeAttributes>
  ): Array<T>;
  mapInEdges<T>(
    node: unknown,
    callback: EdgeMapper<T, NodeAttributes, EdgeAttributes>
  ): Array<T>;
  mapInEdges<T>(
    source: unknown,
    target: unknown,
    callback: EdgeMapper<T, NodeAttributes, EdgeAttributes>
  ): Array<T>;
  mapOutEdges<T>(
    callback: EdgeMapper<T, NodeAttributes, EdgeAttributes>
  ): Array<T>;
  mapOutEdges<T>(
    node: unknown,
    callback: EdgeMapper<T, NodeAttributes, EdgeAttributes>
  ): Array<T>;
  mapOutEdges<T>(
    source: unknown,
    target: unknown,
    callback: EdgeMapper<T, NodeAttributes, EdgeAttributes>
  ): Array<T>;
  mapInboundEdges<T>(
    callback: EdgeMapper<T, NodeAttributes, EdgeAttributes>
  ): Array<T>;
  mapInboundEdges<T>(
    node: unknown,
    callback: EdgeMapper<T, NodeAttributes, EdgeAttributes>
  ): Array<T>;
  mapInboundEdges<T>(
    source: unknown,
    target: unknown,
    callback: EdgeMapper<T, NodeAttributes, EdgeAttributes>
  ): Array<T>;
  mapOutboundEdges<T>(
    callback: EdgeMapper<T, NodeAttributes, EdgeAttributes>
  ): Array<T>;
  mapOutboundEdges<T>(
    node: unknown,
    callback: EdgeMapper<T, NodeAttributes, EdgeAttributes>
  ): Array<T>;
  mapOutboundEdges<T>(
    source: unknown,
    target: unknown,
    callback: EdgeMapper<T, NodeAttributes, EdgeAttributes>
  ): Array<T>;

  filterEdges(
    callback: EdgePredicate<NodeAttributes, EdgeAttributes>
  ): Array<string>;
  filterEdges(
    node: unknown,
    callback: EdgePredicate<NodeAttributes, EdgeAttributes>
  ): Array<string>;
  filterEdges(
    source: unknown,
    target: unknown,
    callback: EdgePredicate<NodeAttributes, EdgeAttributes>
  ): Array<string>;
  filterUndirectedEdges(
    callback: EdgePredicate<NodeAttributes, EdgeAttributes>
  ): Array<string>;
  filterUndirectedEdges(
    node: unknown,
    callback: EdgePredicate<NodeAttributes, EdgeAttributes>
  ): Array<string>;
  filterUndirectedEdges(
    source: unknown,
    target: unknown,
    callback: EdgePredicate<NodeAttributes, EdgeAttributes>
  ): Array<string>;
  filterDirectedEdges(
    callback: EdgePredicate<NodeAttributes, EdgeAttributes>
  ): Array<string>;
  filterDirectedEdges(
    node: unknown,
    callback: EdgePredicate<NodeAttributes, EdgeAttributes>
  ): Array<string>;
  filterDirectedEdges(
    source: unknown,
    target: unknown,
    callback: EdgePredicate<NodeAttributes, EdgeAttributes>
  ): Array<string>;
  filterInEdges(
    callback: EdgePredicate<NodeAttributes, EdgeAttributes>
  ): Array<string>;
  filterInEdges(
    node: unknown,
    callback: EdgePredicate<NodeAttributes, EdgeAttributes>
  ): Array<string>;
  filterInEdges(
    source: unknown,
    target: unknown,
    callback: EdgePredicate<NodeAttributes, EdgeAttributes>
  ): Array<string>;
  filterOutEdges(
    callback: EdgePredicate<NodeAttributes, EdgeAttributes>
  ): Array<string>;
  filterOutEdges(
    node: unknown,
    callback: EdgePredicate<NodeAttributes, EdgeAttributes>
  ): Array<string>;
  filterOutEdges(
    source: unknown,
    target: unknown,
    callback: EdgePredicate<NodeAttributes, EdgeAttributes>
  ): Array<string>;
  filterInboundEdges(
    callback: EdgePredicate<NodeAttributes, EdgeAttributes>
  ): Array<string>;
  filterInboundEdges(
    node: unknown,
    callback: EdgePredicate<NodeAttributes, EdgeAttributes>
  ): Array<string>;
  filterInboundEdges(
    source: unknown,
    target: unknown,
    callback: EdgePredicate<NodeAttributes, EdgeAttributes>
  ): Array<string>;
  filterOutboundEdges(
    callback: EdgePredicate<NodeAttributes, EdgeAttributes>
  ): Array<string>;
  filterOutboundEdges(
    node: unknown,
    callback: EdgePredicate<NodeAttributes, EdgeAttributes>
  ): Array<string>;
  filterOutboundEdges(
    source: unknown,
    target: unknown,
    callback: EdgePredicate<NodeAttributes, EdgeAttributes>
  ): Array<string>;

  reduceEdges<T>(
    callback: EdgeReducer<T, NodeAttributes, EdgeAttributes>,
    initialValue: T
  ): T;
  reduceEdges<T>(
    node: unknown,
    callback: EdgeReducer<T, NodeAttributes, EdgeAttributes>,
    initialValue: T
  ): T;
  reduceEdges<T>(
    source: unknown,
    target: unknown,
    callback: EdgeReducer<T, NodeAttributes, EdgeAttributes>,
    initialValue: T
  ): T;
  reduceUndirectedEdges<T>(
    callback: EdgeReducer<T, NodeAttributes, EdgeAttributes>,
    initialValue: T
  ): T;
  reduceUndirectedEdges<T>(
    node: unknown,
    callback: EdgeReducer<T, NodeAttributes, EdgeAttributes>,
    initialValue: T
  ): T;
  reduceUndirectedEdges<T>(
    source: unknown,
    target: unknown,
    callback: EdgeReducer<T, NodeAttributes, EdgeAttributes>,
    initialValue: T
  ): T;
  reduceDirectedEdges<T>(
    callback: EdgeReducer<T, NodeAttributes, EdgeAttributes>,
    initialValue: T
  ): T;
  reduceDirectedEdges<T>(
    node: unknown,
    callback: EdgeReducer<T, NodeAttributes, EdgeAttributes>,
    initialValue: T
  ): T;
  reduceDirectedEdges<T>(
    source: unknown,
    target: unknown,
    callback: EdgeReducer<T, NodeAttributes, EdgeAttributes>,
    initialValue: T
  ): T;
  reduceInEdges<T>(
    callback: EdgeReducer<T, NodeAttributes, EdgeAttributes>,
    initialValue: T
  ): T;
  reduceInEdges<T>(
    node: unknown,
    callback: EdgeReducer<T, NodeAttributes, EdgeAttributes>,
    initialValue: T
  ): T;
  reduceInEdges<T>(
    source: unknown,
    target: unknown,
    callback: EdgeReducer<T, NodeAttributes, EdgeAttributes>,
    initialValue: T
  ): T;
  reduceOutEdges<T>(
    callback: EdgeReducer<T, NodeAttributes, EdgeAttributes>,
    initialValue: T
  ): T;
  reduceOutEdges<T>(
    node: unknown,
    callback: EdgeReducer<T, NodeAttributes, EdgeAttributes>,
    initialValue: T
  ): T;
  reduceOutEdges<T>(
    source: unknown,
    target: unknown,
    callback: EdgeReducer<T, NodeAttributes, EdgeAttributes>,
    initialValue: T
  ): T;
  reduceInboundEdges<T>(
    callback: EdgeReducer<T, NodeAttributes, EdgeAttributes>,
    initialValue: T
  ): T;
  reduceInboundEdges<T>(
    node: unknown,
    callback: EdgeReducer<T, NodeAttributes, EdgeAttributes>,
    initialValue: T
  ): T;
  reduceInboundEdges<T>(
    source: unknown,
    target: unknown,
    callback: EdgeReducer<T, NodeAttributes, EdgeAttributes>,
    initialValue: T
  ): T;
  reduceOutboundEdges<T>(
    callback: EdgeReducer<T, NodeAttributes, EdgeAttributes>,
    initialValue: T
  ): T;
  reduceOutboundEdges<T>(
    node: unknown,
    callback: EdgeReducer<T, NodeAttributes, EdgeAttributes>,
    initialValue: T
  ): T;
  reduceOutboundEdges<T>(
    source: unknown,
    target: unknown,
    callback: EdgeReducer<T, NodeAttributes, EdgeAttributes>,
    initialValue: T
  ): T;

  findEdge(
    callback: EdgePredicate<NodeAttributes, EdgeAttributes>
  ): string | undefined;
  findEdge(
    node: unknown,
    callback: EdgePredicate<NodeAttributes, EdgeAttributes>
  ): string | undefined;
  findEdge(
    source: unknown,
    target: unknown,
    callback: EdgePredicate<NodeAttributes, EdgeAttributes>
  ): string | undefined;
  findUndirectedEdge(
    callback: EdgePredicate<NodeAttributes, EdgeAttributes>
  ): string | undefined;
  findUndirectedEdge(
    node: unknown,
    callback: EdgePredicate<NodeAttributes, EdgeAttributes>
  ): string | undefined;
  findUndirectedEdge(
    source: unknown,
    target: unknown,
    callback: EdgePredicate<NodeAttributes, EdgeAttributes>
  ): string | undefined;
  findDirectedEdge(
    callback: EdgePredicate<NodeAttributes, EdgeAttributes>
  ): string | undefined;
  findDirectedEdge(
    node: unknown,
    callback: EdgePredicate<NodeAttributes, EdgeAttributes>
  ): string | undefined;
  findDirectedEdge(
    source: unknown,
    target: unknown,
    callback: EdgePredicate<NodeAttributes, EdgeAttributes>
  ): string | undefined;
  findInEdge(
    callback: EdgePredicate<NodeAttributes, EdgeAttributes>
  ): string | undefined;
  findInEdge(
    node: unknown,
    callback: EdgePredicate<NodeAttributes, EdgeAttributes>
  ): string | undefined;
  findInEdge(
    source: unknown,
    target: unknown,
    callback: EdgePredicate<NodeAttributes, EdgeAttributes>
  ): string | undefined;
  findOutEdge(
    callback: EdgePredicate<NodeAttributes, EdgeAttributes>
  ): string | undefined;
  findOutEdge(
    node: unknown,
    callback: EdgePredicate<NodeAttributes, EdgeAttributes>
  ): string | undefined;
  findOutEdge(
    source: unknown,
    target: unknown,
    callback: EdgePredicate<NodeAttributes, EdgeAttributes>
  ): string | undefined;
  findInboundEdge(
    callback: EdgePredicate<NodeAttributes, EdgeAttributes>
  ): string | undefined;
  findInboundEdge(
    node: unknown,
    callback: EdgePredicate<NodeAttributes, EdgeAttributes>
  ): string | undefined;
  findInboundEdge(
    source: unknown,
    target: unknown,
    callback: EdgePredicate<NodeAttributes, EdgeAttributes>
  ): string | undefined;
  findOutboundEdge(
    callback: EdgePredicate<NodeAttributes, EdgeAttributes>
  ): string | undefined;
  findOutboundEdge(
    node: unknown,
    callback: EdgePredicate<NodeAttributes, EdgeAttributes>
  ): string | undefined;
  findOutboundEdge(
    source: unknown,
    target: unknown,
    callback: EdgePredicate<NodeAttributes, EdgeAttributes>
  ): string | undefined;

  someEdge(callback: EdgePredicate<NodeAttributes, EdgeAttributes>): boolean;
  someEdge(
    node: unknown,
    callback: EdgePredicate<NodeAttributes, EdgeAttributes>
  ): boolean;
  someEdge(
    source: unknown,
    target: unknown,
    callback: EdgePredicate<NodeAttributes, EdgeAttributes>
  ): boolean;
  someUndirectedEdge(
    callback: EdgePredicate<NodeAttributes, EdgeAttributes>
  ): boolean;
  someUndirectedEdge(
    node: unknown,
    callback: EdgePredicate<NodeAttributes, EdgeAttributes>
  ): boolean;
  someUndirectedEdge(
    source: unknown,
    target: unknown,
    callback: EdgePredicate<NodeAttributes, EdgeAttributes>
  ): boolean;
  someDirectedEdge(
    callback: EdgePredicate<NodeAttributes, EdgeAttributes>
  ): boolean;
  someDirectedEdge(
    node: unknown,
    callback: EdgePredicate<NodeAttributes, EdgeAttributes>
  ): boolean;
  someDirectedEdge(
    source: unknown,
    target: unknown,
    callback: EdgePredicate<NodeAttributes, EdgeAttributes>
  ): boolean;
  someInEdge(callback: EdgePredicate<NodeAttributes, EdgeAttributes>): boolean;
  someInEdge(
    node: unknown,
    callback: EdgePredicate<NodeAttributes, EdgeAttributes>
  ): boolean;
  someInEdge(
    source: unknown,
    target: unknown,
    callback: EdgePredicate<NodeAttributes, EdgeAttributes>
  ): boolean;
  someOutEdge(callback: EdgePredicate<NodeAttributes, EdgeAttributes>): boolean;
  someOutEdge(
    node: unknown,
    callback: EdgePredicate<NodeAttributes, EdgeAttributes>
  ): boolean;
  someOutEdge(
    source: unknown,
    target: unknown,
    callback: EdgePredicate<NodeAttributes, EdgeAttributes>
  ): boolean;
  someInboundEdge(
    callback: EdgePredicate<NodeAttributes, EdgeAttributes>
  ): boolean;
  someInboundEdge(
    node: unknown,
    callback: EdgePredicate<NodeAttributes, EdgeAttributes>
  ): boolean;
  someInboundEdge(
    source: unknown,
    target: unknown,
    callback: EdgePredicate<NodeAttributes, EdgeAttributes>
  ): boolean;
  someOutboundEdge(
    callback: EdgePredicate<NodeAttributes, EdgeAttributes>
  ): boolean;
  someOutboundEdge(
    node: unknown,
    callback: EdgePredicate<NodeAttributes, EdgeAttributes>
  ): boolean;
  someOutboundEdge(
    source: unknown,
    target: unknown,
    callback: EdgePredicate<NodeAttributes, EdgeAttributes>
  ): boolean;

  everyEdge(callback: EdgePredicate<NodeAttributes, EdgeAttributes>): boolean;
  everyEdge(
    node: unknown,
    callback: EdgePredicate<NodeAttributes, EdgeAttributes>
  ): boolean;
  everyEdge(
    source: unknown,
    target: unknown,
    callback: EdgePredicate<NodeAttributes, EdgeAttributes>
  ): boolean;
  everyUndirectedEdge(
    callback: EdgePredicate<NodeAttributes, EdgeAttributes>
  ): boolean;
  everyUndirectedEdge(
    node: unknown,
    callback: EdgePredicate<NodeAttributes, EdgeAttributes>
  ): boolean;
  everyUndirectedEdge(
    source: unknown,
    target: unknown,
    callback: EdgePredicate<NodeAttributes, EdgeAttributes>
  ): boolean;
  everyDirectedEdge(
    callback: EdgePredicate<NodeAttributes, EdgeAttributes>
  ): boolean;
  everyDirectedEdge(
    node: unknown,
    callback: EdgePredicate<NodeAttributes, EdgeAttributes>
  ): boolean;
  everyDirectedEdge(
    source: unknown,
    target: unknown,
    callback: EdgePredicate<NodeAttributes, EdgeAttributes>
  ): boolean;
  everyInEdge(callback: EdgePredicate<NodeAttributes, EdgeAttributes>): boolean;
  everyInEdge(
    node: unknown,
    callback: EdgePredicate<NodeAttributes, EdgeAttributes>
  ): boolean;
  everyInEdge(
    source: unknown,
    target: unknown,
    callback: EdgePredicate<NodeAttributes, EdgeAttributes>
  ): boolean;
  everyOutEdge(
    callback: EdgePredicate<NodeAttributes, EdgeAttributes>
  ): boolean;
  everyOutEdge(
    node: unknown,
    callback: EdgePredicate<NodeAttributes, EdgeAttributes>
  ): boolean;
  everyOutEdge(
    source: unknown,
    target: unknown,
    callback: EdgePredicate<NodeAttributes, EdgeAttributes>
  ): boolean;
  everyInboundEdge(
    callback: EdgePredicate<NodeAttributes, EdgeAttributes>
  ): boolean;
  everyInboundEdge(
    node: unknown,
    callback: EdgePredicate<NodeAttributes, EdgeAttributes>
  ): boolean;
  everyInboundEdge(
    source: unknown,
    target: unknown,
    callback: EdgePredicate<NodeAttributes, EdgeAttributes>
  ): boolean;
  everyOutboundEdge(
    callback: EdgePredicate<NodeAttributes, EdgeAttributes>
  ): boolean;
  everyOutboundEdge(
    node: unknown,
    callback: EdgePredicate<NodeAttributes, EdgeAttributes>
  ): boolean;
  everyOutboundEdge(
    source: unknown,
    target: unknown,
    callback: EdgePredicate<NodeAttributes, EdgeAttributes>
  ): boolean;

  edgeEntries(): IterableIterator<EdgeEntry<NodeAttributes, EdgeAttributes>>;
  edgeEntries(
    node: unknown
  ): IterableIterator<EdgeEntry<NodeAttributes, EdgeAttributes>>;
  edgeEntries(
    source: unknown,
    target: unknown
  ): IterableIterator<EdgeEntry<NodeAttributes, EdgeAttributes>>;
  undirectedEdgeEntries(): IterableIterator<
    EdgeEntry<NodeAttributes, EdgeAttributes>
  >;
  undirectedEdgeEntries(
    node: unknown
  ): IterableIterator<EdgeEntry<NodeAttributes, EdgeAttributes>>;
  undirectedEdgeEntries(
    source: unknown,
    target: unknown
  ): IterableIterator<EdgeEntry<NodeAttributes, EdgeAttributes>>;
  directedEdgeEntries(): IterableIterator<
    EdgeEntry<NodeAttributes, EdgeAttributes>
  >;
  directedEdgeEntries(
    node: unknown
  ): IterableIterator<EdgeEntry<NodeAttributes, EdgeAttributes>>;
  directedEdgeEntries(
    source: unknown,
    target: unknown
  ): IterableIterator<EdgeEntry<NodeAttributes, EdgeAttributes>>;
  inEdgeEntries(): IterableIterator<EdgeEntry<NodeAttributes, EdgeAttributes>>;
  inEdgeEntries(
    node: unknown
  ): IterableIterator<EdgeEntry<NodeAttributes, EdgeAttributes>>;
  inEdgeEntries(
    source: unknown,
    target: unknown
  ): IterableIterator<EdgeEntry<NodeAttributes, EdgeAttributes>>;
  outEdgeEntries(): IterableIterator<EdgeEntry<NodeAttributes, EdgeAttributes>>;
  outEdgeEntries(
    node: unknown
  ): IterableIterator<EdgeEntry<NodeAttributes, EdgeAttributes>>;
  outEdgeEntries(
    source: unknown,
    target: unknown
  ): IterableIterator<EdgeEntry<NodeAttributes, EdgeAttributes>>;
  inboundEdgeEntries(): IterableIterator<
    EdgeEntry<NodeAttributes, EdgeAttributes>
  >;
  inboundEdgeEntries(
    node: unknown
  ): IterableIterator<EdgeEntry<NodeAttributes, EdgeAttributes>>;
  inboundEdgeEntries(
    source: unknown,
    target: unknown
  ): IterableIterator<EdgeEntry<NodeAttributes, EdgeAttributes>>;
  outboundEdgeEntries(): IterableIterator<
    EdgeEntry<NodeAttributes, EdgeAttributes>
  >;
  outboundEdgeEntries(
    node: unknown
  ): IterableIterator<EdgeEntry<NodeAttributes, EdgeAttributes>>;
  outboundEdgeEntries(
    source: unknown,
    target: unknown
  ): IterableIterator<EdgeEntry<NodeAttributes, EdgeAttributes>>;

  neighbors(node: unknown): Array<string>;
  undirectedNeighbors(node: unknown): Array<string>;
  directedNeighbors(node: unknown): Array<string>;
  inNeighbors(node: unknown): Array<string>;
  outNeighbors(node: unknown): Array<string>;
  inboundNeighbors(node: unknown): Array<string>;
  outboundNeighbors(node: unknown): Array<string>;

  forEachNeighbor(
    node: unknown,
    callback: NeighborIterationCallback<NodeAttributes>
  ): void;
  forEachUndirectedNeighbor(
    node: unknown,
    callback: NeighborIterationCallback<NodeAttributes>
  ): void;
  forEachDirectedNeighbor(
    node: unknown,
    callback: NeighborIterationCallback<NodeAttributes>
  ): void;
  forEachInNeighbor(
    node: unknown,
    callback: NeighborIterationCallback<NodeAttributes>
  ): void;
  forEachOutNeighbor(
    node: unknown,
    callback: NeighborIterationCallback<NodeAttributes>
  ): void;
  forEachInboundNeighbor(
    node: unknown,
    callback: NeighborIterationCallback<NodeAttributes>
  ): void;
  forEachOutboundNeighbor(
    node: unknown,
    callback: NeighborIterationCallback<NodeAttributes>
  ): void;

  mapNeighbors<T>(
    node: unknown,
    callback: NeighborMapper<T, NodeAttributes>
  ): Array<T>;
  mapUndirectedNeighbors<T>(
    node: unknown,
    callback: NeighborMapper<T, NodeAttributes>
  ): Array<T>;
  mapDirectedNeighbors<T>(
    node: unknown,
    callback: NeighborMapper<T, NodeAttributes>
  ): Array<T>;
  mapInNeighbors<T>(
    node: unknown,
    callback: NeighborMapper<T, NodeAttributes>
  ): Array<T>;
  mapOutNeighbors<T>(
    node: unknown,
    callback: NeighborMapper<T, NodeAttributes>
  ): Array<T>;
  mapInboundNeighbors<T>(
    node: unknown,
    callback: NeighborMapper<T, NodeAttributes>
  ): Array<T>;
  mapOutboundNeighbors<T>(
    node: unknown,
    callback: NeighborMapper<T, NodeAttributes>
  ): Array<T>;

  filterNeighbors(
    node: unknown,
    callback: NeighborPredicate<NodeAttributes>
  ): Array<string>;
  filterUndirectedNeighbors(
    node: unknown,
    callback: NeighborPredicate<NodeAttributes>
  ): Array<string>;
  filterDirectedNeighbors(
    node: unknown,
    callback: NeighborPredicate<NodeAttributes>
  ): Array<string>;
  filterInNeighbors(
    node: unknown,
    callback: NeighborPredicate<NodeAttributes>
  ): Array<string>;
  filterOutNeighbors(
    node: unknown,
    callback: NeighborPredicate<NodeAttributes>
  ): Array<string>;
  filterInboundNeighbors(
    node: unknown,
    callback: NeighborPredicate<NodeAttributes>
  ): Array<string>;
  filterOutboundNeighbors(
    node: unknown,
    callback: NeighborPredicate<NodeAttributes>
  ): Array<string>;

  reduceNeighbors<T>(
    node: unknown,
    callback: NeighborReducer<T, NodeAttributes>,
    initialValue: T
  ): T;
  reduceUndirectedNeighbors<T>(
    node: unknown,
    callback: NeighborReducer<T, NodeAttributes>,
    initialValue: T
  ): T;
  reduceDirectedNeighbors<T>(
    node: unknown,
    callback: NeighborReducer<T, NodeAttributes>,
    initialValue: T
  ): T;
  reduceInNeighbors<T>(
    node: unknown,
    callback: NeighborReducer<T, NodeAttributes>,
    initialValue: T
  ): T;
  reduceOutNeighbors<T>(
    node: unknown,
    callback: NeighborReducer<T, NodeAttributes>,
    initialValue: T
  ): T;
  reduceInboundNeighbors<T>(
    node: unknown,
    callback: NeighborReducer<T, NodeAttributes>,
    initialValue: T
  ): T;
  reduceOutboundNeighbors<T>(
    node: unknown,
    callback: NeighborReducer<T, NodeAttributes>,
    initialValue: T
  ): T;

  findNeighbor(
    node: unknown,
    callback: NeighborPredicate<NodeAttributes>
  ): string | undefined;
  findUndirectedNeighbor(
    node: unknown,
    callback: NeighborPredicate<NodeAttributes>
  ): string | undefined;
  findDirectedNeighbor(
    node: unknown,
    callback: NeighborPredicate<NodeAttributes>
  ): string | undefined;
  findInNeighbor(
    node: unknown,
    callback: NeighborPredicate<NodeAttributes>
  ): string | undefined;
  findOutNeighbor(
    node: unknown,
    callback: NeighborPredicate<NodeAttributes>
  ): string | undefined;
  findInboundNeighbor(
    node: unknown,
    callback: NeighborPredicate<NodeAttributes>
  ): string | undefined;
  findOutboundNeighbor(
    node: unknown,
    callback: NeighborPredicate<NodeAttributes>
  ): string | undefined;

  someNeighbor(
    node: unknown,
    callback: NeighborPredicate<NodeAttributes>
  ): boolean;
  someUndirectedNeighbor(
    node: unknown,
    callback: NeighborPredicate<NodeAttributes>
  ): boolean;
  someDirectedNeighbor(
    node: unknown,
    callback: NeighborPredicate<NodeAttributes>
  ): boolean;
  someInNeighbor(
    node: unknown,
    callback: NeighborPredicate<NodeAttributes>
  ): boolean;
  someOutNeighbor(
    node: unknown,
    callback: NeighborPredicate<NodeAttributes>
  ): boolean;
  someInboundNeighbor(
    node: unknown,
    callback: NeighborPredicate<NodeAttributes>
  ): boolean;
  someOutboundNeighbor(
    node: unknown,
    callback: NeighborPredicate<NodeAttributes>
  ): boolean;

  everyNeighbor(
    node: unknown,
    callback: NeighborPredicate<NodeAttributes>
  ): boolean;
  everyUndirectedNeighbor(
    node: unknown,
    callback: NeighborPredicate<NodeAttributes>
  ): boolean;
  everyDirectedNeighbor(
    node: unknown,
    callback: NeighborPredicate<NodeAttributes>
  ): boolean;
  everyInNeighbor(
    node: unknown,
    callback: NeighborPredicate<NodeAttributes>
  ): boolean;
  everyOutNeighbor(
    node: unknown,
    callback: NeighborPredicate<NodeAttributes>
  ): boolean;
  everyInboundNeighbor(
    node: unknown,
    callback: NeighborPredicate<NodeAttributes>
  ): boolean;
  everyOutboundNeighbor(
    node: unknown,
    callback: NeighborPredicate<NodeAttributes>
  ): boolean;

  neighborEntries(
    node: unknown
  ): IterableIterator<NeighborEntry<NodeAttributes>>;
  undirectedNeighborEntries(
    node: unknown
  ): IterableIterator<NeighborEntry<NodeAttributes>>;
  directedNeighborEntries(
    node: unknown
  ): IterableIterator<NeighborEntry<NodeAttributes>>;
  inNeighborEntries(
    node: unknown
  ): IterableIterator<NeighborEntry<NodeAttributes>>;
  outNeighborEntries(
    node: unknown
  ): IterableIterator<NeighborEntry<NodeAttributes>>;
  inboundNeighborEntries(
    node: unknown
  ): IterableIterator<NeighborEntry<NodeAttributes>>;
  outboundNeighborEntries(
    node: unknown
  ): IterableIterator<NeighborEntry<NodeAttributes>>;

  // Serialization methods
  export(): SerializedGraph<NodeAttributes, EdgeAttributes, GraphAttributes>;
  import(
    data: Partial<
      SerializedGraph<NodeAttributes, EdgeAttributes, GraphAttributes>
    >,
    merge?: boolean
  ): this;
  import(
    graph: AbstractGraph<NodeAttributes, EdgeAttributes, GraphAttributes>,
    merge?: boolean
  ): this;

  // Utils
  nullCopy(
    options?: Partial<GraphOptions>
  ): AbstractGraph<NodeAttributes, EdgeAttributes, GraphAttributes>;
  emptyCopy(
    options?: Partial<GraphOptions>
  ): AbstractGraph<NodeAttributes, EdgeAttributes, GraphAttributes>;
  copy(
    options?: Partial<GraphOptions>
  ): AbstractGraph<NodeAttributes, EdgeAttributes, GraphAttributes>;

  // Well-known methods
  toJSON(): SerializedGraph<NodeAttributes, EdgeAttributes, GraphAttributes>;
  toString(): string;
  inspect(): any;

  static from<
    NA extends Attributes = Attributes,
    EA extends Attributes = Attributes,
    GA extends Attributes = Attributes
  >(
    data: SerializedGraph<NA, EA, GA> | AbstractGraph<NA, EA, GA>,
    options?: GraphOptions
  ): AbstractGraph<NA, EA, GA>;
}

interface GraphConstructor<
  NodeAttributes extends Attributes = Attributes,
  EdgeAttributes extends Attributes = Attributes,
  GraphAttributes extends Attributes = Attributes
> {
  new (options?: GraphOptions): AbstractGraph<
    NodeAttributes,
    EdgeAttributes,
    GraphAttributes
  >;
}

export {
  AbstractGraph,
  GraphConstructor,
  Attributes,
  GraphType,
  GraphOptions,
  GraphEvents,
  AdjacencyEntry,
  NodeEntry,
  NodeMergeResult,
  NeighborEntry,
  EdgeEntry,
  EdgeMergeResult,
  AdjacencyIterationCallback,
  AdjacencyIterationCallbackWithOrphans,
  NodeIterationCallback,
  NodePredicate,
  NodeMapper,
  NodeReducer,
  NeighborIterationCallback,
  NeighborPredicate,
  NeighborMapper,
  NeighborReducer,
  EdgeIterationCallback,
  EdgePredicate,
  EdgeMapper,
  EdgeReducer,
  SerializedNode,
  SerializedEdge,
  SerializedGraph,
  AttributeUpdateType,
  AttributeUpdatePayload
};

export default AbstractGraph;
