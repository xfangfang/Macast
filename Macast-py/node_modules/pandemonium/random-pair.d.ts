import {RNGFunction} from './types';

type RandomPairFunction<T> = (array: Array<T> | number) => number;

declare const randomPair: {
  <T>(array: Array<T> | number): number;
  createRandomPair<T>(rng: RNGFunction): RandomPairFunction<T>;
};

export function createRandomPair<T>(rng: RNGFunction): RandomPairFunction<T>;

export default randomPair;
