/**
 * Mnemonist Generic Types
 * ========================
 * 
 * Collection of types used throughout the library.
 */
export interface IArrayLike {
  length: number;
  slice(from: number, to?: number): IArrayLike;
}

export type ArrayLike = IArrayLike | ArrayBuffer;

export interface IArrayLikeConstructor {
  new(...args: any[]): ArrayLike;
}

export type TypedArray = Int8Array | Uint8Array | Uint8ClampedArray | Int16Array | Uint16Array | Int32Array | Uint32Array | Float32Array | Float64Array;