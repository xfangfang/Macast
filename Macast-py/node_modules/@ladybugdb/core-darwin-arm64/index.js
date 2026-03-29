"use strict";

const Connection = require("./connection.js");
const Database = require("./database.js");
const PreparedStatement = require("./prepared_statement.js");
const QueryResult = require("./query_result.js");

module.exports = {
  Connection,
  Database,
  PreparedStatement,
  QueryResult,
  get VERSION() {
    return Database.getVersion();
  },
  get STORAGE_VERSION() {
    return Database.getStorageVersion();
  },
};
