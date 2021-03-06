# MultiSSH

Do all the things everywhere at the same time


### Installation (gem)

```
gem install uoregon-multissh
```

### Installation (github)

Clone the repo and install the required gems with bundler
```
git clone https://github.com/lcrownover/multissh
cd multissh
bundle install
```


### Configuration

On the first run, you'll be prompted to generate a credential file. 
This file is stored at *~/.ssh/multissh.yaml*, with the owner as the current user and mode of 600.

If you decline to generate this file, it will prompt for password if not provided via command line.

If you don't have ssh-agent configured with your keys, it will prompt for a private key password during credential file generation, or during run if you opted out of the credential file.


<br>

### Usage

```
Usage: multissh.rb --nodes "server1,server2" --command "echo 'hello'"
        --nodes "NODES"              REQUIRED: "server1,server2,server3" OR "@nodes.txt"
        --command "COMMAND"          REQUIRED: "echo 'hello'" OR @command.txt
        --username "USERNAME"        OPTIONAL: current user by default
        --password "PASSWORD"        OPTIONAL: will prompt if needed
        --pkey_password "PASSWORD"   OPTIONAL: will prompt if needed
        --block                      OPTIONAL: block mode for command ouptut
        --regenerate_config          OPTIONAL: regenerate configuration file
        --debug                      OPTIONAL: debug mode
```

<br><br>

### Examples

Run a command against a comma-separated list of nodes
```bash
ruby multissh.rb --nodes "NODE1,NODE2" --command "COMMAND"
```

<br>

Run a command against a file containing a newline-separated list of nodes
```
node1.example.org
node2.example.org
```

```bash
ruby multissh.rb --nodes @nodes.txt --command "COMMAND"
```

<br>

Run a list of newline-separated commands against a newline-separated list of nodes
```
echo $(hostname)
yum install ruby
ruby -v
```

```bash
ruby multissh.rb --nodes @nodes.txt --command @commands.txt
```

<br>
