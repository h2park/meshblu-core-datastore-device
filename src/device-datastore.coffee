_ = require 'lodash'
MeshbluCoreDatastore = require 'meshblu-core-datastore'

class DeviceDatastore
  constructor: ({@uuid, database}) ->
    @datastore = new MeshbluCoreDatastore
      database: database
      collection: 'devices'

  find: (query, callback) =>
    secureQuery = @_getSecureDiscoverQuery query
    @datastore.find secureQuery, callback

  findOne: (query, callback) =>
    secureQuery = @_getSecureDiscoverQuery query
    @datastore.findOne secureQuery, callback

  remove: (query, options, callback) =>
    if _.isFunction options
      callback = options
      options = {}

    secureQuery = @_getSecureConfigureQuery query
    @datastore.remove secureQuery, options, callback

  _getSecureDiscoverQuery: (query)=> @_getSecureQuery query, 'discoverWhitelist'

  _getSecureConfigureQuery: (query) => @_getSecureQuery query, 'configureWhitelist'

  _getSecureQuery: (query, whitelistName) =>
    whitelistCheck = {}
    whitelistCheck[whitelistName] = $in: ['*', @uuid]
    whitelistQuery =
      $or: [
        {uuid: @uuid}
        {owner: @uuid}
        whitelistCheck
      ]

    @_mergeQueryWithWhitelistQuery query, whitelistQuery

  _mergeQueryWithWhitelistQuery: (query, whitelistQuery) =>
    whitelistQuery = $and : [whitelistQuery]
    whitelistQuery.$and.push $or: query.$or if query.$or?
    whitelistQuery.$and.push $and: query.$and if query.$and?

    saferQuery = _.omit query, '$or'

    _.extend saferQuery, whitelistQuery


module.exports = DeviceDatastore
