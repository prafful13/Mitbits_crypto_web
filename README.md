
# MitbitsCryptocurrencyWeb

# COP5615 – Fall 2018
# Project 4.2

- Siddhant Mohan Mittal UFID: 6061-8545
- Prafful Mehrotra UFID: 1099-5311


## Instructions for running the code

After unziping the file, go into the directory and start the surver.

```sh
$ cd mitbits_cryptocurrency_web
```

To start your Phoenix server:

  * Install dependencies with `mix deps.get`
  * Start Phoenix endpoint with `mix phx.server`

Now you can visit [`localhost:4000`](http://localhost:4000) from your browser.

# About the project

This project is been continue from our last implementation of mitbits; a online cyptocurrency based on the concept of blockchain. What have  we achieved in this project?

- A simulation of 100 participants taking part in transacting of money to each other and miners doing proof of work to approve transactions and mine mitbits.
- A web interface to show the on-going simulation
- Providing a web interface to add transactions to online simulation

# Defining Application Architecture
- The Application consist of a supervisor which manages miner supervisor and node supervisor under it. This protects us application for getting terminated, as it restarts the application in such situation.
- Miner supervisor and node supervisor hold beneath them miners and nodes genservers respectively. Why two different genservers for miners and nodes? This is because miners will be mining blocks asynchronous; competeting with each other to solve the puzzle of the block, this will slow down or maybe create a time out situations for the other processes like transactions, wallet updating etc.
- Each node has a public key to identify them. Also each node also have private key(secret key) which is not accessable to other nodes.  
- Only the nodes participates in transaction but to make a miner participate in the bitcoin exchange process, each miner node has a connected node which the same public key. The only difference it that the name of miner node is "miner_public_key" and connected node is "node_public_key"
- Each node maintains following states; sk (private key), pk (public key), list of blocks(blockchain), Indexed block chain, all pending transaction pool, wallet amount.
- Each node handle functions like adding transactions, updating wallet, validating blocks, performing forking and deleting transaction.
- Each miner only have mining functions. Where it validates sum pool of transaction and solve the block puzzle to mine mitbits. For transactions, block chain etc it calls it's associated node.

# Implementation
- How it really works under the hood? To start the application off, we created a gensis block by just spawing a single miner. This first miner mined the first block by hashing a random string "This is starting of something big in the year 2018" with a reward transaction of 1000 mitbits and thus creating our first genesis block. 
- Later we generate numNodes and numMiners. Since numNodes are some of the first nodes to join our application and to promote it futher we award 10 mitbits to each numNodes from the first miner and add these transaction to pending transaction pool of each node. The miner now compete to find the proof of work of new block. If a miner is successful this reward transaction of 100 mitbits is made part of the blockchain thus mining these 100 mitbits out of thin air.
- When ever a new block is mined it is broadcasted to all the nodes but since this can be fraud block all nodes first validate the transactions in the block, if there are correct all miners moves to never set of transaction other wise they still mine on the previous hash of the block.
- Then we give two different functions, one which allows you to make a random transaction between two nodes and other allows any node to join our system.
- This random transaction is used for simulation for 10K transactions.
- The other function is used to add new node which copy a blockchain from any node and makes a indexed block chain and then join other node is listening transactions and mined blocks.
 
# Web Interface

We have implemented a web interface using Elixir's phoenix. Bellow we explains various views of our interface and brief information about it and how you can navigate through them.

### Home View
- This is the base or we can call this home page for our simulation. It cointains link to all the other view so that we can navigate through the simulation. 
- When we run the command "mix phx.server" the simulation is started and only home page is available when genesis block is being created and participants are spwaned.
- To make it more user freindly we have included all view links in the footer of the web page of each view under the heading "userful links".
- This view is available at  http://localhost:4000

### Show Participants View
- This view is available shortly after the simulation is started. 
- This page displays the list of hashed values of the public keys of the participants.
- Private key is used by nodes to digitally sign the node. using a sign(messgae,sk) function. This sign function takes a transaction and convert it into a string, then it used sk to sign it. Changing even the smallest thing changes this digital signature making the omnce signed transcation irriverisble and also digital signature protects the information of who created.
- Public key which is used to identify a node, is also you to protect the authenticity of a transaction which we talked above. A verify(message, signature, pk) function turns true if the signature is created by the sk of this pk.
- We create a sha256 hash of pk to the base 16 to name a node and also store in the :ets so that very node is aware of the other public key, but note the sk is only known to the node itself not the application. 
- Each other's public key is hyperlinked to  this account. Clicking the public key  will re-direct you it's individual account.
- This view is available at  http://localhost:4000/showParticipants

### Individual Account View
- This view shows the account balance of the participant.
- To view this we need public key of the participant to sign in. We have not maintain a password for each participant login-in as the purpose of this web interface to show the simulation only.
- To reach this view: http://localhost:4000/participant/<public-key>

### Statistics view
- This is the most exciting view of all. This view is used to see the metrics which our simulation is being generated.
- We show a dynamic graph of size of blockchain(number of blocks) vs time of simulation. We have to refresh the page to see the updated graph. For this we periodically through data from our simulation to web interface using phoenix. For this we have run a background process in stats.ex file
- We also show other data like number transactions made, mitibits mined and a bar graph to show the individual wallets of the participants 
- View this at http://localhost:4000/stats

### Blockchain view
- This view displaces the complete blockchain at the time your hit this view.
- This view is used to see the transaction made by the simulation and approval of the them using proof of work.
- We use this view to verify transactions made.


# Bonus part
- For bonus part in the individual account view, we have added the API to make transactions from the individual's account to other participants in the simulation.

# Simulation Scenarios
Below are descriptions of some mining/transacting simulation scenarios which we covered in the video of this project

### Set-up
- This scenario shows the generation of 100 participants and creating of 10K transactions.
- We then navuagte through the stats view to show the results of our simulation.

### External-interference
- In this scenario we make some transactions from some individual's account to add transactions to on-going simulation
- We can then navigate though blockchain view to see these approved transactions

### Transaction-boom
- This scenario we generate after the first 10K transaction simulation is reached at it's saturation point. 
- Now we create one more API to create 10K random transactions, you can find this link in the userful link section in footer.
- Now we show the stats view to show our findings and changes in various metrics

# Protocols

### Public key and private key generation
- Public key and private key pairs are generating using Elliptic-curve cryptography. 
- Private key is used by nodes to digitally sign the node. using a sign(messgae,sk) function. This sign function takes a transaction and convert it into a string, then it used sk to sign it. Changing even the smallest thing changes this digital signature making the omnce signed transcation irriverisble and also digital signature protects the information of who created
- Public key which is used to identify a node, is also you to protect the authenticity of a transaction which we talked above. A verify(message, signature, pk) function turns true if the signature is created by the sk of this pk
- We create a sha256 hash of pk to the base 16 to name a node and also store in the :ets so that very node is aware of the other public key, but note the sk is only known to the node itself not the application. 

### Transactions
- A transaction is map having following keys: message that is a map log which contains keys from, to and amount; signature that is the digitally signature given to the transaction by sender using its private key; timestamp that is the time of creation.
- When a new transaction is created it is broadcasted to all the nodes in the system.


### Blocks
- A block in a block chain contains following values; Its hash value value, hash value of previous block, some set of transactions and timestamp.
- A block in our application have a maximum size restriction of 6 transaction that is 5 pending transaction and 1 reward transaction.

### Mining
- Mining is a process of doing proof of work to add a set of pending transaction into the block chain and get rewarded for your computation work.
- In mining a miner picks up 5 transaction, add previous block hash to it , add a reward trancation and add a randon number called as nonce. Then pass this created string into sha256 to create a string in base 16.
- If the value of the created sha256 is less than a target value then the miner has hit the jackpot and creating a block of approved transcation and adding a reward transaction of 100 mitbits to his account into blockchain. 
- If the value is greater than target he increase the nonce by one and redo the same process. If some other miner comes up with a valid block, he deletes transactions of new block from pending transaction pool and try the mining process again on the new set of transactions.
- Miner mining a block and hitting jackpot is actually beneficial to the system as this is a way application adds transaction to block chain and approve them.
- Target value in our system is sha256 string having first four bits as zeros
- The importance of hashing previous block hash in next block is that if a attacker goes and modifiy a block then he has to do proof of work for every other block after it. Hence making it computationaly impossible.

### Blockchain
- Blockchain is a list which is maintained by all the nodes. Each participant nodes first joining the system starts with the gensis block. But later on new node are joining system copies the blockchain from any other node.
- When ever a new block is mined it is broadcasted to all the nodes. Every node updates it's block chain.
- If we iterate over the complete blockchain we will notice that it  contains all the valid transactions so far. And going through each message of transactions we can see how mitbits are transferred using from, to and amount keys. 

### Wallets
- Wallet is the amount each node has. Each node initially have 10 mitbits for loyality of joining the system at start. The first miner node contains 1000 mitbits for creating genesis block.
- For any futher transactions as they get approved and the block is broadcasted to all the nodes, every node updates it wallet in following manner. If the block contains transaction having pk of this node in "from" value of the message then the amount is subtracted from the wallet; otherwise if it is in "to" value then amount is added to the wallet

### Indexed Blockchain
- Indexed blockchain is a extra protocol we have implemented to make the system more efficient. The idea is that each node maintains a state of indexed blockchain on "from" and "to" values of public keys of the node. - Before going into the importance of this first let us see how this is maintained. When ever a new block is broadcasted the nodes updates it's indexed blockchain by just reading one block. 
- If a new node joins the application it iterate over the complete Blockchain once to create a indexed blockchain. Now it behaving like other nodes which update indexed blockchain by just reading one broadcasted block
- This helps us in validation transactions that is we dont have to iterate over blockchain again and again. Creating a indexed blockchain is one time effort. And validating is a important part which can't be ignored due to no trust model of our application. Hence if every node validates new blocks and transaction by iterating over the blockchain will make the taken slower

### Authentication
- Authentication is a important protocol to protect our application from fraud nodes and fraud miners.
- Authentication is done by both miners and nodes. in this step verify() function is called to verify the digital signature; if is signed by the correct sender and on the correct transaction message
- Miners perform authentication while selecting transaction for their mining process. Thus eliminating fraud trancations from there blocks and void their block getting disapproved by Consensus protocol
- Node performs authentication when recieve a broadcasted block, if it contains any wrong signed trancation it gets disapproved. This ensures that no fraud miners broadcast a block of wrong transactions.

### Validation
- This is as important as authentication and both goes hand in hand and are performed in the same way at nodes and miners.
- But the way of doing this is different. The vaalidation checks every transaction according to the indexed blockchain to ensure the sender making the transaction actuall had the balance in this account to perform this. Thus no random coins are generated on the way. Also node validate the reward transactions in the block to verify that no miner cheated and gave himself more rewards

