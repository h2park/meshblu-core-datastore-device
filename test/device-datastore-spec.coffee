mongojs   = require 'mongojs'
DeviceDatastore = require '../'

describe 'DeviceDatastore', ->
  beforeEach (done) ->
    @db = mongojs 'datastore-device-find-test', ['devices']
    @db.devices.remove done

  beforeEach ->
    @sut = new DeviceDatastore
      uuid: 'darth-vader'
      database:   @db

  beforeEach 'insert devices', (done) ->
    sabers = [
      {
        uuid: 'curve-hilted'
        type: 'light-saber'
        color: 'blue'
      }
      {
        uuid: 'underwater-lightsaber'
        owner: 'darth-vader'
        type: 'light-saber'
      }
      {
        uuid: 'fire-saber'
        type: 'light-saber'
        discoverWhitelist: ['darth-vader']
      }
      {
        uuid: 'dual-phase-lightsaber'
        type: 'light-saber'
        color: 'red'
        discoverWhitelist: ['*']
      }
      {
        uuid: 'darth-vader'
        type: 'sith-lord'
      }
    ]
    @db.devices.insert sabers, done

  describe '->findOne', ->
    describe 'when finding a device without a discoverWhitelist or owner', ->

      beforeEach 'find device', (done)->
        @sut.findOne uuid: 'curve-hilted', (@error, @device) => done()

      it 'should not yield an error', ->
        expect(@error).to.not.exist

      it 'should not yield the device', ->
        expect(@device).to.not.exist

    describe 'when finding a device I own', ->

      beforeEach 'find device', (done)->
        @sut.findOne uuid: 'underwater-lightsaber', (error, @device) => done()

      it 'should yield the device', ->
        expect(@device).to.exist

    describe 'when finding a device with "*" in the discoverWhitelist', ->
      beforeEach 'find device', (done)->
        @sut.findOne uuid: 'dual-phase-lightsaber', (error, @device) => done()

      it 'should yield the device', ->
        expect(@device).to.exist

    describe 'when finding a device with my uuid in its discoverWhitelist', ->
      beforeEach 'find device', (done)->
        @sut.findOne uuid: 'fire-saber', (error, @device) => done()

      it 'should yield the device', ->
        expect(@device).to.exist

    describe 'when searching for myself', ->
      beforeEach 'find device', (done)->
        @sut.findOne uuid: 'darth-vader', (error, @device) => done()

      it 'should let me find myself', ->
        expect(@device).to.exist

    describe 'if the user uses the $or keyword in their query', ->
      beforeEach (done) ->
        query =
          $or: [{
            color: 'red'
          }]
        @sut.findOne query, (error, @device) => done()

      it 'should return the device', ->
        expect(@device).to.containSubset color: 'red'

    describe 'if the user uses the $or keyword in their query and they\'re not allowed to see it', ->
      beforeEach (done) ->
        query =
          $or: [{
            color: 'blue'
          }]
        @sut.findOne query, (error, @device) => done()

      it 'should not return the device', ->
        expect(@device).not.to.exist

  describe '->find', ->
    describe 'when searching for lightsabers', ->
      beforeEach (done) ->
        @sut.find type: 'light-saber', (@error, @devices) => done()

      it 'should yield the lightsabers I can see', ->
        expect(@devices.length).to.equal 3
