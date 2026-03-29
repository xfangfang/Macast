import {RNGFunction} from './types';

type WeightedRerservoirSampleOptions<T> = {
  rng: RNGFunction;
  getWeight: (item: T, index?: number) => number;
};

type WeightedReservoirSampleFunction<T> = (
  k: number,
  array: Array<T>
) => Array<T>;

export class WeightedReservoirSampler<T> {
  constructor(k: number, rng?: RNGFunction);
  constructor(k: number, options?: WeightedRerservoirSampleOptions<T>);
  process(item: T): void;
  end(): Array<T>;
}

declare const weightedReservoirSample: {
  <T>(k: number, array: Array<T>): Array<T>;
  createWeightedReservoirSample<T>(
    rng: RNGFunction
  ): WeightedReservoirSampleFunction<T>;
  createWeightedReservoirSample<T>(
    options: WeightedRerservoirSampleOptions<T>
  ): WeightedReservoirSampleFunction<T>;
  WeightedReservoirSampler: typeof WeightedReservoirSampler;
};

export function createWeightedReservoirSample<T>(
  rng: RNGFunction
): WeightedReservoirSampleFunction<T>;

export function createWeightedReservoirSample<T>(
  options: WeightedRerservoirSampleOptions<T>
): WeightedReservoirSampleFunction<T>;

export default weightedReservoirSample;
