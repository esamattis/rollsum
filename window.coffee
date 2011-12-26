


window = ["a", "b", "c", "d", "e", "f", "g"]
len = window.length


for i in [0..10]
  first = i % len
  last = (i+len) % len


  for v, j in window
    out = v

    if j is first
       out = "1"
    if j is last
       out = "0"

    process.stdout.write out + " "

  console.log ""



