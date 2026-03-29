import {RNGFunction} from './types';

type RandomOrderedPairFunction<T> = (array: Array<T> | number) => number;

declare const randomOrderedPair: {
  <T>(array: Array<T> | number): number;
  createRandomOrderedPair<T>(rng: RNGFunction): RandomOrderedPairFunction<T>;
};

export function createRandomOrderedPair<T>(
  rng: RNGFunction
): RandomOrderedPairFunction<T>;

export default randomOrderedPair;
