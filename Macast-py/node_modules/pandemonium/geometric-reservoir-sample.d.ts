import {RNGFunction} from './types';

type GeometricReservoirSampleFunction<T> =
  | ((k: number, array: Array<T>) => Array<T>)
  | ((k: number, length: number) => Array<number>);

declare const geometricReservoirSample: {
  (k: number, length: number): Array<number>;
  <T>(k: number, array: Array<T>): Array<T>;
  createGeometricReservoirSample<T>(
    rng: RNGFunction
  ): GeometricReservoirSampleFunction<T>;
};

export function createGeometricReservoirSample<T>(
  rng: RNGFunction
): GeometricReservoirSampleFunction<T>;

export default geometricReservoirSample;
