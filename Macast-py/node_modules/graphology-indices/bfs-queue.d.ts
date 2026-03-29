import Graph, {Attributes, NodePredicate} from 'graphology-types';
import FixedDeque from 'mnemonist/fixed-deque';

export default class BFSQueue<
  T = string,
  NodeAttributes extends Attributes = Attributes
> {
  graph: Graph<NodeAttributes>;
  size: number;
  seen: Set<T>;
  private queue: FixedDeque<T>;
  constructor(graph: Graph<NodeAttributes>);
  forEachNodeYetUnseen(callback: NodePredicate<NodeAttributes>): void;
  has(node: string): boolean;
  hasAlreadySeenEverything(): boolean;
  countUnseenNodes(): number;
  push(node: string): boolean;
  pushWith(node: string, item: T): boolean;
  shift(): T | undefined;
}
