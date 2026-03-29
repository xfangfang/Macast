import {RNGFunction} from './types';

type SampleOrderedPairsFunction<T> =
  | ((k: number, array: Array<T>) => Array<T>)
  | ((k: number, length: number) => Array<number>);

declare const sampleOrderedPairs: {
  (k: number, length: number): Array<number>;
  <T>(k: number, array: Array<T>): Array<T>;
  createSampleOrderedPairs<T>(rng: RNGFunction): SampleOrderedPairsFunction<T>;
};

export function createSampleOrderedPairs<T>(
  rng: RNGFunction
): SampleOrderedPairsFunction<T>;

export default sampleOrderedPairs;
