/**
 * Mnemonist FixedReverseHeap Typings
 * ===================================
 */
import {IArrayLikeConstructor, TypedArray} from './utils/types';

type HeapComparator<T> = (a: T, b: T) => number;

export default class FixedReverseHeap<T> {

  // Members
  capacity: number;
  size: number;

  // Constructor
  constructor(ArrayClass: IArrayLikeConstructor, comparator: HeapComparator<T>, capacity: number);
  constructor(ArrayClass: IArrayLikeConstructor, capacity: number);

  // Methods
  clear(): void;
  push(item: T): number;
  consume(): Array<T> | TypedArray;
  toArray(): Array<T> | TypedArray;
  inspect(): any;
}
