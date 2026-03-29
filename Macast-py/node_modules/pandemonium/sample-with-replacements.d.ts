import {RNGFunction} from './types';

type SampleWithReplacementsFunction<T> = (
  k: number,
  array: Array<T>
) => Array<T>;

declare const naiveSampleWithReplacements: {
  <T>(k: number, array: Array<T>): Array<T>;
  createSampleWithReplacements<T>(
    rng: RNGFunction
  ): SampleWithReplacementsFunction<T>;
};

export function createSampleWithReplacements<T>(
  rng: RNGFunction
): SampleWithReplacementsFunction<T>;

export default naiveSampleWithReplacements;
