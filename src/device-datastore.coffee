_ = require 'lodash'
MeshbluCoreDatastore = require 'meshblu-core-datastore'

class DeviceDatastore
  constructor: ({@uuid, database}) ->
    @datastore = new MeshbluCoreDatastore
      database: database
      collection: 'devices'

  find: (query, callback) =>
    secureQuery = @_getSecureQuery query
    @datastore.find secureQuery, callback

  findOne: (query, callback) =>
    secureQuery = @_getSecureQuery query
    @datastore.findOne secureQuery, callback

  _getSecureQuery: (query)=>
    query = _.cloneDeep query
    whitelistQuery =
      $or: [
        {uuid: @uuid}
        {owner: @uuid}
        {discoverWhitelist: $in: ['*', @uuid]}
      ]

    @_mergeQueryWithWhitelistQuery query, whitelistQuery

  _mergeQueryWithWhitelistQuery: (query, whitelistQuery) =>
    whitelistQuery = $and : [whitelistQuery]
    whitelistQuery.$and.push $or: query.$or if query.$or?
    saferQuery = _.omit query, '$or'
    
    _.extend saferQuery, whitelistQuery


module.exports = DeviceDatastore
