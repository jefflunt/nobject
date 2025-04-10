`nobject` - network-hosted objects + rpc

create objects locally
push them to a remote server across the network
use them like they're still local

```plaintext
                    -> rpc ->
----------------------     ---------------------------
| main program       | --> | Nobject::Server         |
|                    |     |                         |
| - Nobject::Local 1 | --> | - Nobject::Remote 1     |
| - Nobject::Local 2 | --> | - Nobject::Remote 2     |
| - ...              |     |   ...                   |
| - Nobject::Local n | --> | - Nobject::Remote n     |
---------------------      ---------------------------
```

with this gem you:
1. start a `nobject` server
2. instantiate almost any object* locally
3. push that object over the network to the server
4. invoke methods on the remote object as if it's local

## example

```ruby
# start a nobject server on port 1234
require 'nobject/server'

NobjectServer.new(1234).start!
```

```ruby
# in the main program:
require 'nobject/local'

n = Nobject::Local.new('localhost', 1234, 5)
puts n + 7

# => 12
```

this program will print "12", but the method execution is happening within the
`Nobject::Server`, and is returned via the `Nobject::Local`. this works because
the `Nobject::Local` delegates its method calls to a matching `Nobject::Remote`
object running on the `Nobject::Server`, the computation happens there, and the
return value comes back to the main program where it's printed.

all of this happens within the main program's code, giving you fully
remote/multi-process/multi-core computation in ruby without changing the
language syntax.

there's just one catch: since you're technically invoking methods on a remote
object over the network, calling methods can now fail due to network connection
issues.
