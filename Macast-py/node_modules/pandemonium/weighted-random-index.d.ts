import {RNGFunction} from './types';

type WeightedRandomIndexOptions<T> = {
  rng: RNGFunction;
  getWeight: (item: T, index?: number) => number;
};

type WeightedRandomIndexFunction<T> = (array: Array<T>) => number;
type CachedWeightedRandomIndexFunction = () => number;

declare const weightedRandomIndex: {
  <T>(array: Array<T>): number;

  createWeightedRandomIndex<T>(
    rng: RNGFunction
  ): WeightedRandomIndexFunction<T>;
  createWeightedRandomIndex<T>(
    options: WeightedRandomIndexOptions<T>
  ): WeightedRandomIndexFunction<T>;

  createCachedWeightedRandomIndex<T>(
    rng: RNGFunction,
    array: Array<T>
  ): CachedWeightedRandomIndexFunction;
  createCachedWeightedRandomIndex<T>(
    options: WeightedRandomIndexOptions<T>,
    array: Array<T>
  ): CachedWeightedRandomIndexFunction;
};

export function createWeightedRandomIndex<T>(
  rng: RNGFunction
): WeightedRandomIndexFunction<T>;
export function createWeightedRandomIndex<T>(
  options: WeightedRandomIndexFunction<T>
): WeightedRandomIndexFunction<T>;

export function createCachedWeightedRandomIndex<T>(
  rng: RNGFunction,
  array: Array<T>
): CachedWeightedRandomIndexFunction;
export function createCachedWeightedRandomIndex<T>(
  options: WeightedRandomIndexOptions<T>,
  array: Array<T>
): CachedWeightedRandomIndexFunction;

export default weightedRandomIndex;
