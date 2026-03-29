"use strict";

const LbugNative = require("./lbug_native.js");

class Database {
  /**
   * Initialize a new Database object. Note that the initialization is done
   * lazily, so the database file is not opened until the first query is
   * executed. To initialize the database immediately, call the `init()`
   * function on the returned object.
   *
   * @param {String} databasePath path to the database file. If the path is not specified, or empty, or equal to
   `:memory:`, the database will be created in memory.
   * @param {Number} bufferManagerSize size of the buffer manager in bytes.
   * @param {Boolean} enableCompression whether to enable compression.
   * @param {Boolean} readOnly if true, database will be opened in read-only mode.
   * @param {Number} maxDBSize maximum size of the database file in bytes. Note that
   * this is introduced temporarily for now to get around with the default 8TB mmap
   * address space limit some environment.
   * @param {Boolean} autoCheckpoint If true, the database will automatically checkpoint when the size of
   * the WAL file exceeds the checkpoint threshold.
   * @param {Number} checkpointThreshold The threshold of the WAL file size in bytes. When the size of the
   * WAL file exceeds this threshold, the database will checkpoint if autoCheckpoint is true.
   * @param {Boolean} throwOnWalReplayFailure If true, any WAL replaying failure when loading the database
   * will throw an error. Otherwise, Lbug will silently ignore the failure and replay up to where
   * the error occured.
   * @param {Boolean} enableChecksums If true, the database will use checksums to detect corruption in the
   * WAL file.
   */
  constructor(
    databasePath,
    bufferManagerSize = 0,
    enableCompression = true,
    readOnly = false,
    maxDBSize = 0,
    autoCheckpoint = true,
    checkpointThreshold = -1,
    throwOnWalReplayFailure = true,
    enableChecksums = true,
  ) {
    if (!databasePath) {
      databasePath = ":memory:";
    }
    else if (typeof databasePath !== "string") {
      throw new Error("Database path must be a string.");
    }
    if (typeof bufferManagerSize !== "number" || bufferManagerSize < 0) {
      throw new Error("Buffer manager size must be a positive integer.");
    }
    if (typeof maxDBSize !== "number" || maxDBSize < 0) {
      throw new Error("Max DB size must be a positive integer.");
    }
    if (typeof checkpointThreshold !== "number" || maxDBSize < -1) {
      throw new Error("Checkpoint threshold must be a positive integer.");
    }
    bufferManagerSize = Math.floor(bufferManagerSize);
    maxDBSize = Math.floor(maxDBSize);
    checkpointThreshold = Math.floor(checkpointThreshold);
    this._database = new LbugNative.NodeDatabase(
      databasePath,
      bufferManagerSize,
      enableCompression,
      readOnly,
      maxDBSize,
      autoCheckpoint,
      checkpointThreshold,
      throwOnWalReplayFailure,
      enableChecksums
    );
    this._isInitialized = false;
    this._initPromise = null;
    this._isClosed = false;
  }

  /**
   * Get the version of the library.
   * @returns {String} the version of the library.
   */
  static getVersion() {
    return LbugNative.NodeDatabase.getVersion();
  }

  /**
   * Get the storage version of the library.
   * @returns {Number} the storage version of the library.
   */
  static getStorageVersion() {
    return LbugNative.NodeDatabase.getStorageVersion();
  }

  /**
   * Initialize the database. Calling this function is optional, as the
   * database is initialized automatically when the first query is executed.
   */
  async init() {
    if (!this._isInitialized) {
      if (!this._initPromise) {
        this._initPromise = new Promise((resolve, reject) => {
          this._database.initAsync((err) => {
            if (err) {
              reject(err);
            } else {
              try {
                this._isInitialized = true;
              } catch (e) {
                return reject(e);
              }
              resolve();
            }
          });
        });
      }
      await this._initPromise;
      this._initPromise = null;
    }
  }

  /**
   * Initialize the database synchronously. Calling this function is optional, as the
   * database is initialized automatically when the first query is executed. This function
   * may block the main thread, so use it with caution.
   */
  initSync() {
    if (this._initPromise) {
      throw new Error("There is an ongoing asynchronous initialization. Please wait for it to finish.");
    }
    if (this._isInitialized) {
      return;
    }
    this._database.initSync();
    this._isInitialized = true;
  }

  /**
   * Internal function to get the underlying native database object.
   * @returns {LbugNative.NodeDatabase} the underlying native database.
   * @throws {Error} if the database is closed.
   */
  async _getDatabase() {
    if (this._isClosed) {
      throw new Error("Database is closed.");
    }
    await this.init();
    return this._database;
  }

  /**
   * Internal function to get the underlying native database object synchronously.
   * @returns {LbugNative.NodeDatabase} the underlying native database.
   * @throws {Error} if the database is closed.
   */
  _getDatabaseSync() {
    if (this._isClosed) {
      throw new Error("Database is closed.");
    }
    if (!this._isInitialized) {
      this.initSync();
    }
    return this._database;
  }

  /**
   * Close the database.
   */
  async close() {
    if (this._isClosed) {
      return;
    }
    if (!this._isInitialized) {
      if (this._initPromise) {
        // Database is initializing, wait for it to finish first.
        await this._initPromise;
      } else {
        // Database is not initialized, simply mark it as closed and initialized.
        this._isInitialized = true;
        this._isClosed = true;
        delete this._database;
        return;
      }
    }
    // Database is initialized, close it.
    this._database.close();
    delete this._database;
    this._isClosed = true;
  }

  /**
   * Close the database synchronously.
   * @throws {Error} if there is an ongoing asynchronous initialization.
   */
  closeSync() {
    if (this._isClosed) {
      return;
    }
    if (!this._isInitialized) {
      if (this._initPromise) {
        throw new Error("There is an ongoing asynchronous initialization. Please wait for it to finish.");
      } else {
        this._isInitialized = true;
        this._isClosed = true;
        delete this._database;
        return;
      }
    }
    this._database.close();
    delete this._database;
    this._isClosed = true;
  }
}

module.exports = Database;
