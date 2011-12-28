
assert = require "assert"
{Adler32} = require "../adler32"



describe "Adler32 checksum", ->

  # it "can get sum for simple string", ->
  #   a = new Adler32
  #   a.update new Buffer "car"
  #   assert.equal a.hexdigest(), "2600137"


  it "can find car from big string", (done) ->

    chunk = new Buffer "car"
    car = new Adler32
    car.update chunk
    carDigest = car.digest()
    console.log "car is ", car.hexdigest()

    a =  new Adler32 chunk.length, [ carDigest ]

    a.on "found", (e) ->
      assert.equal e.position, 7
      done()

    dataString = new Buffer "lol my car is on fire"

    a.update dataString





    # big = new Adler32 chunk.length

    # position = null

    # for i in [0...dataString.length]

    #   if i > chunk.length-1
    #     big.rollout dataString[i-chunk.length]
    #   big.rollin dataString[i]

    #   if big.hexdigest() is car.hexdigest()
    #     position = i - chunk.length

    # assert.equal position, 6
