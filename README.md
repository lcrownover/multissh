# MultiSSH

Do all the things everywhere at the same time


### Setup

Clone the repo and install the required gems with bundler
```
git clone https://github.com/lcrownover/multissh
cd multissh
bundle install
```

### Usage

*!! Make sure you enclose command with **double** quotes if not using @ sigil !!*
<br><br>

##### Run a command against a comma-separated list of nodes
```bash
ruby multissh.rb --username 'USERNAME' --nodes 'NODE1,NODE2' --command "COMMAND"
```

<br>

##### Run a command against a file containing a newline-separated list of nodes
```
node1.example.org
node2.example.org
```

```bash
ruby multissh.rb --username 'USERNAME' --nodes @nodes.txt --command "COMMAND"
```

<br>

##### Run a list of newline-separated commands against a newline-separated list of nodes
```
echo $(hostname)
yum install ruby
ruby -v
```

```bash
ruby multissh.rb --username 'USERNAME' --nodes @nodes.txt --command @commands.txt
```

<br>