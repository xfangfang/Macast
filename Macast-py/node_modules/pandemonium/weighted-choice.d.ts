import {RNGFunction} from './types';

type WeightedChoiceOptions<T> = {
  rng: RNGFunction;
  getWeight: (item: T, index?: number) => number;
};

type WeightedChoiceFunction<T> = (array: Array<T>) => T;
type CachedWeightedChoiceFunction<T> = () => T;

declare const weightedChoice: {
  <T>(array: Array<T>): T;

  createWeightedChoice<T>(rng: RNGFunction): WeightedChoiceFunction<T>;
  createWeightedChoice<T>(
    options: WeightedChoiceOptions<T>
  ): WeightedChoiceFunction<T>;

  createCachedWeightedChoice<T>(
    rng: RNGFunction,
    array: Array<T>
  ): CachedWeightedChoiceFunction<T>;
  createCachedWeightedChoice<T>(
    options: WeightedChoiceOptions<T>,
    array: Array<T>
  ): CachedWeightedChoiceFunction<T>;
};

export function createWeightedChoice<T>(
  rng: RNGFunction
): WeightedChoiceFunction<T>;
export function createWeightedChoice<T>(
  options: WeightedChoiceFunction<T>
): WeightedChoiceFunction<T>;

export function createCachedWeightedChoice<T>(
  rng: RNGFunction,
  array: Array<T>
): CachedWeightedChoiceFunction<T>;
export function createCachedWeightedChoice<T>(
  options: WeightedChoiceOptions<T>,
  array: Array<T>
): CachedWeightedChoiceFunction<T>;

export default weightedChoice;
