_ = require 'lodash'
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
        uuid: 'great-lightsaber'
        configureWhitelist: ['*']
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

  describe 'when constructed without a uuid', ->
    beforeEach ->
      @sut = new DeviceDatastore database: @db

    describe '->find', ->
      beforeEach (done) ->
        @sut.find {}, (@error, @devices) => done()

      it 'should yield an error indicating that a uuid is required', ->
        expect(@error).to.exist

      it 'should not yield any devices', ->
        expect(@devices).not.to.exist

    describe '->findOne', ->
      beforeEach (done) ->
        @sut.findOne {}, (@error, @devices) => done()

      it 'should yield an error indicating that a uuid is required', ->
        expect(@error).to.exist

      it 'should not yield any devices', ->
        expect(@devices).not.to.exist

    describe '->update', ->
      beforeEach (done) ->
        @sut.update {}, {}, (@error) => done()

      it 'should yield an error indicating that a uuid is required', ->
        expect(@error).to.exist

    describe '->remove', ->
      beforeEach (done) ->
        @sut.remove {}, (@error) => done()

      it 'should yield an error indicating that a uuid is required', ->
        expect(@error).to.exist

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

    describe 'if the user uses the $and keyword in their query', ->
      beforeEach (done) ->
        query =
          $and: [ {color: 'red'}, {type: 'light-saber'}]
        @sut.findOne query, (error, @device) => done()

      it 'should return the device', ->
        expect(@device).to.containSubset color: 'red', type: 'light-saber'

      describe 'if the user uses the $and keyword in their query and they\'re not allowed to see the result', ->
        beforeEach (done) ->
          query =
            $and: [ {color: 'blue'}, {type: 'light-saber'}]
          @sut.findOne query, (error, @device) => done()

        it 'should return the device', ->
          expect(@device).not.to.exist

  describe '->find', ->
    describe 'when searching for lightsabers', ->
      beforeEach (done) ->
        @sut.find type: 'light-saber', (@error, @devices) => done()

      it 'should yield the lightsabers I can see', ->
        expect(@devices.length).to.equal 3

  describe '->remove', ->
    describe 'when destroying a lightsaber device I own', ->
      beforeEach 'remove device', (done) ->
        @sut.remove uuid: 'underwater-lightsaber', done

      beforeEach 'find removed device', (done) ->
        @sut.findOne uuid: 'underwater-lightsaber', (error, @device) => done()

      it 'should remove the device', ->
        expect(@device).not.to.exist

    describe 'when attempting to destroy a lightsaber device I can see but not configure', ->
      beforeEach 'remove device', (done) ->
        @sut.remove uuid: 'curve-hilted', done

      beforeEach 'find removed device', (done) ->
        @db.devices.findOne uuid: 'curve-hilted', (error, @device) => done()

      it 'should not remove the device', ->
        expect(@device).to.exist

    describe 'when attempting to destroy a lightsaber device that has me in it\'s configureWhitelist', ->
      beforeEach 'remove device', (done) ->
        @sut.remove uuid: 'fire-saber', (error, @result) => done()

      beforeEach 'find removed device', (done) ->
        @db.devices.findOne uuid: 'fire-saber', (error, @device) => done()

      it 'should not remove the device', ->
        expect(@device).to.exist

      it 'should tell us it didn\'t update anything', ->
        expect(@result.n).to.equal 0

    describe 'when attempting to destroy a lightsaber device that has me listed as its owner', ->
      beforeEach 'remove device', (done) ->
        @sut.remove uuid: 'underwater-lightsaber', (error, @result) => done()

      beforeEach 'find removed device', (done) ->
        @db.devices.findOne uuid: 'underwater-lightsaber', (error, @device) => done()

      it 'should remove the device', ->
        expect(@device).to.not.exist

      it 'should tell us it removed the device', ->
        expect(@result.n).to.equal 1

    describe 'when attempting to destroy all lightsaber devices', ->
      beforeEach 'remove devices', (done) ->
        @sut.remove type: 'light-saber', (error, @result) => done()

      beforeEach 'find removed devices', (done) ->
        @db.devices.find type: 'light-saber', (error, @devices) => done()

      it 'should remove the devices we are allowed to', ->
        expect(@devices.length).to.equal 3

      it 'should tell us it removed the devices', ->
        expect(@result.n).to.equal 2

    describe 'when attempting to destroy one lightsaber device but the query matches more', ->
      beforeEach 'remove devices', (done) ->
        @sut.remove {type: 'light-saber'}, {justOne: true}, (error, @result) => done()

      beforeEach 'find removed devices', (done) ->
        @db.devices.find type: 'light-saber', (error, @devices) => done()

      it 'should remove just one device', ->
        expect(@devices.length).to.equal 4

      it 'should tell us it removed one device', ->
        expect(@result.n).to.equal 1

  describe '->update', ->
    describe 'when updating a lightsaber device I own', ->
      beforeEach 'updating device', (done) ->
        @sut.update {uuid: 'underwater-lightsaber'}, {$set: color: 'orange'}, done

      beforeEach 'find updated device', (done) ->
        @sut.findOne uuid: 'underwater-lightsaber', (error, @device) => done()

      it 'should update the device', ->
        expect(@device.color).to.equal 'orange'

    describe 'when attempting to update a lightsaber device I can\'t configure', ->
      beforeEach 'update device', (done) ->
        @sut.update {uuid: 'curve-hilted'}, {$set: side: 'dark'}, done

      beforeEach 'find removed device', (done) ->
        @db.devices.findOne uuid: 'curve-hilted', (error, @device) => done()

      it 'should not update the device', ->
        expect(@device.side).to.not.exist

    describe 'when attempting to update a lightsaber device I can configure', ->
      beforeEach 'update device', (done) ->
        @sut.update {uuid: 'great-lightsaber'}, {$set: side: 'dark'}, done

      beforeEach 'find removed device', (done) ->
        @db.devices.findOne uuid: 'great-lightsaber', (error, @device) => done()

      it 'should update the device', ->
        expect(@device.side).to.equal 'dark'

    describe 'when attempting to update all lightsaber devices', ->
      beforeEach 'update devices', (done) ->
        @sut.update type: 'light-saber', {$set: {side: 'dark'}}, {multi: true}, done

      beforeEach 'find updated devices', (done) ->
        @db.devices.find type: 'light-saber', side: 'dark', (error, @devices) => done()

      it 'should update all lightsabers we can see to the dark side', ->
        expect(@devices.length).to.equal 2

    describe 'when attempting to update one lightsaber device but the query matches more', ->
      beforeEach 'update device', (done) ->
        @sut.update {type: 'light-saber'},  {$set: side: 'dark'}, (error, @result) => done()

      beforeEach 'find updated devices', (done) ->
        @db.devices.find type: 'light-saber', side: 'dark', (error, @devices) => done()

      it 'should update just one device', ->
        expect(@devices.length).to.equal 1
