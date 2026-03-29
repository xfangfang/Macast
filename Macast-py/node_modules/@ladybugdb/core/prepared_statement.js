"use strict";

const assert = require("assert");

class PreparedStatement {
  /**
   * Internal constructor. Use `Connection.prepare` to get a
   * `PreparedStatement` object.
   * @param {Connection} connection the connection object.
   * @param {LbugNative.NodePreparedStatement} preparedStatement the native prepared statement object.
   */
  constructor(connection, preparedStatement) {
    assert(
      typeof connection === "object" &&
        connection.constructor.name === "Connection"
    );
    assert(
      typeof preparedStatement === "object" &&
        preparedStatement.constructor.name === "NodePreparedStatement"
    );
    this._connection = connection;
    this._preparedStatement = preparedStatement;
  }

  /**
   * Check if the prepared statement is successfully prepared.
   * @returns {Boolean} true if the prepared statement is successfully prepared.
   */
  isSuccess() {
    return this._preparedStatement.isSuccess();
  }

  /**
   * Get the error message if the prepared statement is not successfully prepared.
   * @returns {String} the error message.
   */
  getErrorMessage() {
    return this._preparedStatement.getErrorMessage();
  }
}

module.exports = PreparedStatement;
