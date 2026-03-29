import {RNGFunction} from './types';

type SamplePairsFunction<T> =
  | ((k: number, array: Array<T>) => Array<T>)
  | ((k: number, length: number) => Array<number>);

declare const samplePairs: {
  (k: number, length: number): Array<number>;
  <T>(k: number, array: Array<T>): Array<T>;
  createSamplePairs<T>(rng: RNGFunction): SamplePairsFunction<T>;
};

export function createSamplePairs<T>(rng: RNGFunction): SamplePairsFunction<T>;

export default samplePairs;
