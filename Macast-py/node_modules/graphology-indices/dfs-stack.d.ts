import Graph, {Attributes, NodePredicate} from 'graphology-types';

export default class DFSStack<
  T = string,
  NodeAttributes extends Attributes = Attributes
> {
  graph: Graph<NodeAttributes>;
  size: number;
  seen: Set<T>;
  private stack: Array<T>;
  constructor(graph: Graph<NodeAttributes>);
  forEachNodeYetUnseen(callback: NodePredicate<NodeAttributes>): void;
  has(node: string): boolean;
  hasAlreadySeenEverything(): boolean;
  countUnseenNodes(): number;
  push(node: string): boolean;
  pushWith(node: string, item: T): boolean;
  pop(): T | undefined;
}
