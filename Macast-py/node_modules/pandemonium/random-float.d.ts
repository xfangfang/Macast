import {RNGFunction} from './types';

type RandomFloatFunction = (min: number, max: number) => number;

declare const randomFloat: {
  (min: number, max: number): number;
  createRandomFloat(rng: RNGFunction): RandomFloatFunction;
};

export function createRandomFloat(rng: RNGFunction): RandomFloatFunction;

export default randomFloat;
