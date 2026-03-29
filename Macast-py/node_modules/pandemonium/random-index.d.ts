import {RNGFunction} from './types';

type RandomIndexFunction<T> = (array: Array<T> | number) => number;

declare const randomIndex: {
  <T>(array: Array<T> | number): number;
  createRandomIndex<T>(rng: RNGFunction): RandomIndexFunction<T>;
};

export function createRandomIndex<T>(rng: RNGFunction): RandomIndexFunction<T>;

export default randomIndex;
