import {RNGFunction} from './types';

type RandomBooleanFunction = () => boolean;

declare const randomBoolean: {
  (): boolean;
  createRandomBoolean(rng: RNGFunction): RandomBooleanFunction;
};

export function createRandomBoolean(rng: RNGFunction): RandomBooleanFunction;

export default randomBoolean;
