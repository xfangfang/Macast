import {RNGFunction} from './types';

type ShuffleFunction<T> = (array: Array<T>) => Array<T>;

declare const shuffle: {
  <T>(array: Array<T>): Array<T>;
  createShuffle<T>(rng: RNGFunction): ShuffleFunction<T>;
};

export function createShuffle<T>(rng: RNGFunction): ShuffleFunction<T>;

export default shuffle;
