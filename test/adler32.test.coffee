
assert = require "assert"
crypto = require "crypto"

_  = require 'underscore'

{Adler32} = require "../adler32"



describe "Checksum searcher", ->
  chunk = new Buffer "car"
  dataString = new Buffer "lol my car is on fire"

  car = new Adler32
  car.update chunk
  carDigest = car.digest()

  searchSum = null
  result = null

  beforeEach (done) ->
    searchSum = new Adler32 chunk.length, [ carDigest ]
    searchSum.on "found", (e) ->
      console.log e, searchSum.buf, new Buffer "car"
      result = e
      done()

    searchSum.update dataString

  afterEach ->
    console.log "after", searchSum.buf

  it "can find car from big string",  ->
    assert.equal result.position, 7


  it "can calculate strong sum of the window", ->
    hash = crypto.createHash "sha512"
    hash.update new Buffer "car"
    assert.equal hash.digest("hex"), searchSum.windowHash().digest("hex")


  # it "can get sum for simple string", ->
  #   a = new Adler32
  #   a.update new Buffer "car"
  #   assert.equal a.hexdigest(), "2600137"

    # big = new Adler32 chunk.length

    # position = null

    # for i in [0...dataString.length]

    #   if i > chunk.length-1
    #     big.rollout dataString[i-chunk.length]
    #   big.rollin dataString[i]

    #   if big.hexdigest() is car.hexdigest()
    #     position = i - chunk.length

    # assert.equal position, 6
