# MultiSSH

Do all the things everywhere at the same time


### Setup

Clone the repo and install the required gems with bundler
```
git clone https://github.com/lcrownover/multissh
cd multissh
bundle install
```

<br>

### Usage

```
Usage: multissh.rb --username 'USERNAME' --nodes "server1,server2" --command "echo 'hello'"
        --username 'USERNAME'        REQUIRED
        --password 'PASSWORD'        OPTIONAL: will prompt if not provided 
        --nodes NODES                REQUIRED: "server1,server2,server3" OR "@nodes.txt"
        --command COMMAND            REQUIRED: "echo 'hello'" OR @command.txt
        --stream                     OPTIONAL: stream mode for command ouptut
        --debug                      OPTIONAL: debug mode
```

By default, data is printed to the screen when all the commands have completed. 
Use the **stream** option to print lines as the data comes in.

*Make sure you enclose command with **double** quotes if not using @ sigil*
<br><br>

### Examples

Run a command against a comma-separated list of nodes
```bash
ruby multissh.rb --username 'USERNAME' --nodes 'NODE1,NODE2' --command "COMMAND"
```

<br>

Run a command against a file containing a newline-separated list of nodes
```
node1.example.org
node2.example.org
```

```bash
ruby multissh.rb --username 'USERNAME' --nodes @nodes.txt --command "COMMAND"
```

<br>

Run a list of newline-separated commands against a newline-separated list of nodes
```
echo $(hostname)
yum install ruby
ruby -v
```

```bash
ruby multissh.rb --username 'USERNAME' --nodes @nodes.txt --command @commands.txt
```

<br>