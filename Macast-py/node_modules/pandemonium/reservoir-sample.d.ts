import {RNGFunction} from './types';

type ReservoirSampleFunction<T> = (k: number, array: Array<T>) => Array<T>;

export class ReservoirSampler<T> {
  constructor(k: number, rng?: RNGFunction);
  process(item: T): void;
  end(): Array<T>;
}

declare const reservoirSample: {
  <T>(k: number, array: Array<T>): Array<T>;
  createReservoirSample<T>(rng: RNGFunction): ReservoirSampleFunction<T>;
  ReservoirSampler: typeof ReservoirSampler;
};

export function createReservoirSample<T>(
  rng: RNGFunction
): ReservoirSampleFunction<T>;

export default reservoirSample;
