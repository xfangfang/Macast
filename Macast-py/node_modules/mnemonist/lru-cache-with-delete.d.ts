/**
 * Mnemonist LRUCacheWithDelete Typings
 * =====================================
 */
import LRUCache from './lru-cache';

export default class LRUCacheWithDelete<K, V> extends LRUCache<K, V> {

  delete(key: K): boolean;

  remove<T>(key: K, missing?: T): V | T;

}
