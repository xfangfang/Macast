import {RNGFunction} from './types';

type NaiveSampleFunction<T> =
  | ((k: number, array: Array<T>) => Array<T>)
  | ((k: number, length: number) => Array<number>);

declare const naiveSample: {
  (k: number, length: number): Array<number>;
  <T>(k: number, array: Array<T>): Array<T>;
  createNaiveSample<T>(rng: RNGFunction): NaiveSampleFunction<T>;
};

export function createNaiveSample<T>(rng: RNGFunction): NaiveSampleFunction<T>;

export default naiveSample;
