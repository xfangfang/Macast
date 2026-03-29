import {RNGFunction} from './types';

type ChoiceFunction<T> = (array: Array<T>) => T;

declare const choice: {
  <T>(array: Array<T>): T;
  createChoice<T>(rng: RNGFunction): ChoiceFunction<T>;
};

export function createChoice<T>(rng: RNGFunction): ChoiceFunction<T>;

export default choice;
