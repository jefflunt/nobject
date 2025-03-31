`nobject` - network object

this gem lets you write a main program that ships code off to other client
programs, yet you can invoke methods on the remote code like it's present in
your main program.

here's how it works: the main program creates instaces of `ProxyNobject`, which
wrap objects within the main program, then serialize those objects, and send
them over to the `NobjectServer`. once the objects are on the `NobjectServer`
they stay on that server. now the main program can call methods on the
`ProxyObject` instances in the main program, but the computation is done on the
`Nobject` instances on the `NobjectServer`.

you can expand this to run as many `NobjectServer` instances as you want, with
as many `Nobject` instances per server as makes sense for the amount of compute
and RAM you have on each system.

you can also use this mechanism to spread in-memory objects in Ruby to be
multi-core programs on the same computer just be running a `NobjectServer` on
the local computer.

have 8 physical cores on your computer? then spawn 8 `NobjectServer` instances
on your local machine and you'll be able to use all 8 cores on your computer
while writing all your program login within the main program.

```
-------------------     -----------------
| main program    | --> | NobjectServer |
|                 |     |               |
| - ProxyNobject1 | --> | - Nobject 1   |
| - ProxyNobject2 | --> | - Nobject 2   |
| - ...           |     |   ...         |
| - ProxyNobject2 | --> | - Nobject n   |
------------------      -----------------
```

here's some example code:

```ruby
# for the server code, just load the game and start a server on port `1234`
require 'nobject'

NobjectServer.new(1234).start!
```

```ruby
# in the main program:
require 'nobject'

n = ProxyNobject.new('localhost', 1234, 5)
puts n + 7
```

this program will print "12", but the computation is happening within the
`NobjectServer`, and is returned to the `ProxyNobject`. this works because the
`ProxyNobejct` delegates its method calls to the remote `Nobject`, the
computation happens there, and the return value comes back to the main program
where it's printed, all with the main program code looking exactly like normal
ruby code.

there's just one catch: since you're technicall invoking methods on a remote
object over the network, any method call can throw an exception if the network
falls over.
