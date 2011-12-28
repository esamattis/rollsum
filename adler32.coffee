{EventEmitter} = require "events"
fs = require "fs"

_  = require 'underscore'

assert = require "assert"

BASE=65521      # largest prime smaller than 65536
NMAX=5552       # largest n such that 255n(n+1)/2 + (n+1)(BASE-1) <= 2^32-1
OFFS=1          # default initial s1 offset

ROLLSUM_CHAR_OFFSET = 31

## Faster variant of Adler32
# class Adler32 extends EventEmitter
#
#
#   constructor: (@windowSize, @needleArray) ->
#     @count = 0
#     @a = 0
#     @b = 0
#     @s = new Uint32Array 2
#
#     @pos = 0
#
#     if @windowSize
#       @buf = new Buffer @windowSize
#       @arr = []
#       # @needles = new Uint8Array
#       @needles = {}
#       if @needleArray.length
#         for n in @needleArray
#           @needles[n] = true
#     else
#       @update = (data) ->
#         for byte in data
#           @s[0] += byte + ROLLSUM_CHAR_OFFSET
#           @s[1] += @s[0]
#         @_digest = (@s[1] << 16) | (@s[0] & 0xffff)
#
#   update: (data) ->
#
#     for byte in data
#
#       if @pos < @windowSize
#         # Just rollin and fill the window
#         @s[0] += byte + ROLLSUM_CHAR_OFFSET
#         @s[1] += @s[0]
#         @count += 1
#         @buf[@pos] = byte
#
#         # @arr.push byte
#       else
#         # Start rotating
#
#         inPos = @pos % @windowSize
#         outPos = (@pos + @windowSize) % @windowSize
#         byteOut = @buf[outPos]
#         # byteOut = @arr.shift()
#
#         @s[0] += (byte) - (byteOut)
#         @s[1] += @s[0] - @count * (byteOut + ROLLSUM_CHAR_OFFSET)
#
#         @buf[inPos] = byte
#         # @arr.push byte
#
#       @_digest = (@s[1] << 16) | (@s[0] & 0xffff)
#       console.log "now is", @windowToString(), @s[0], @s[1], @hexdigest(), @digest()
#       @pos += 1
#
#       if @needles[@_digest]
#         @emit "found",
#           digest: @_digest
#           position: @pos - @windowSize
#
#
#   digest: -> @_digest
#   hexdigest: -> @_digest.toString 16
#   windowToString: ->
#     s = for byte in @arr
#       String.fromCharCode byte
#     s.join ""




class Adler32 extends EventEmitter

  constructor: (@windowSize, @needleArray) ->
    @calc = new Uint32Array 3
    @calc[0] = 1
    @calc[1] = 0


    @count = 0

    @pos = 0

    @stage1 = new Buffer 256
    for k, i in @stage1
      @stage1[i] = 0

    if @windowSize
      @initWindow()
    else
      @update = Adler32::sumOnly

  initWindow: ->
    @buf = new Buffer @windowSize

    @needles = {}

    @intTable = for i in [0..3]
      b = new Buffer 256
      for k, j in b
        b[j] = 0
      b

    for value in @needleArray
      console.log "searching for digest", value, "hex:", value.toString(16)

      # Tear down the int
      @intTable[0][(value >>> 24) & 0xff] = 1
      @intTable[1][(value >>> 16) & 0xff] = 1
      @intTable[2][(value >>> 8) & 0xff] = 1
      @intTable[3][value & 0xff] = 1
      # console.log "INT", (value >>> 24) & 0xff, (value >>> 16) & 0xff, (value >>> 8) & 0xff, value & 0xff

      @needles[value] = true

    console.log @intTable
    # For debugging
    @arr = []

  sumOnly: (data) ->
    for byte in data
      @calc[0] = @calc[0] + byte
      @calc[1] = @calc[1] + @calc[0]
      @calc[0] %= BASE
      @calc[1] %= BASE

    @calc[2] = (@calc[1] << 16) | @calc[0]



  update: (data) ->
    for byte in data
      if @pos < @windowSize
        # Just rollin and fill the window
        @calc[0] = @calc[0] + byte
        @calc[1] = @calc[1] + @calc[0]

        @count += 1
        @buf[@pos] = byte
        @arr.push byte
      else
        # Start rotating

        inPos = @pos % @windowSize
        outPos = (@pos + @windowSize) % @windowSize
        byteOut = @buf[outPos]
        # assert.equal byteOut, @arr.shift()
        byteOut = @arr.shift()

        @calc[0] += byte - byteOut
        @calc[1] += @calc[0] - @count * byteOut - OFFS

        @buf[inPos] = byte
        @arr.push byte

      @calc[0] %= BASE
      @calc[1] %= BASE

      @pos += 1

      @calc[2] = ((@calc[1] << 16) | @calc[0])

      value = @calc[2]

      # console.log "digest", @_digest, @calc[0], @calc[1]

      # Test each byte of the integer individually for speed. It's slow as hell
      # to test the needle directly
      # if @intTable[0][(value >>> 24) & 0xff] is 1
      #   if @intTable[1][(value >>> 16) & 0xff] is 1
      #     if @intTable[2][(value >>> 8) & 0xff] is 1
      #       if @intTable[3][value & 0xff] is 1
      #         console.log "stage 4 ok"
      #         # Should not be required, but just to make sure.
      #         if @needles[@_digest]
      #           @emit "found",
      #             digest: @_digest
      #             position: @pos - @windowSize
      #         else
      #           console.log "table failed"

      console.log "current", @toString(), @hexdigest(), @digest()
      if @needles[@calc[2]]
        @emit "found",
          digest: @_digest
          position: @pos - @windowSize



  digest: -> @calc[2]
  hexdigest: -> @calc[2].toString 16

  toString: ->
    s = for byte in @arr
      String.fromCharCode byte
    s.join ""

exports.Adler32 = Adler32


createRandomData = (cb) ->
  size = 1024 * 1024 * 10
  chunk = null
  chunkPos = size / 2
  realChunkPos = null

  readBytes = 0

  inStream = fs.createReadStream "/dev/urandom"
  outStream = fs.createWriteStream "/tmp/randblob"
  inStream.on "data", (data) ->

    console.log "got", data.length, readBytes, "/", size

    outStream.write data

    if readBytes >= chunkPos
      realChunkPos = readBytes
      chunk = data


    readBytes += data.length
    if readBytes >= size
      inStream.destroy()
      outStream.destroy()
      cb
        data: chunk
        position: realChunkPos

if require.main is module
  createRandomData (doc) ->
  # do ->
  #   doc =
  #     data: [ 1,2,3 ]
  #     position: 10

    blobsum = new Adler32

    a = new Adler32
    chunk = doc.data
    a.update chunk
    console.log "FIND #{ chunk.length } bytes from #{ doc.position }", chunk

    searchAdler = new Adler32 chunk.length, [ a.digest() ]

    searchAdler.on "found", (e) ->
      console.log "FOUND", searchAdler.buf
      console.log "Found", e.digest, "from", e.position, "should", doc.position


    size = 0
    start = Date.now()
    i = setInterval update = ->

      diff = (Date.now() - start) / 1000

      megabytes = size / 1024 / 1024
      console.log "#{ megabytes / diff } MB/s. #{ megabytes }MB in #{ diff }s"
    , 1000



    stream = fs.createReadStream "/tmp/randblob"
    stream.on "data", (data) ->
      blobsum.update data
      searchAdler.update data
      size += data.length

    stream.on "end", ->
      clearInterval i
      update()
      console.log "done blob sum:", blobsum.hexdigest(), blobsum.digest()



