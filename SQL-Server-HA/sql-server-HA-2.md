# Transactional Replication

## Understanding Transactional Replication
Once initialized, the transactions are replicated as follows:
- Steps 1 and 2: The log reader agent continuously scans for committed transactions in the publisher database transaction log and inserts the transactions to be replicated into the distribution database.
The log reader agent is at the distributor or at the publisher if the publisher acts as its own distributor.
- Steps 3 and 4: The distribution agent reads the transactions from the distribution database and applies them to the subscriber. The distribution agent is at the distributor if it's a push subscription and at the subscriber if it's a pull subscription.

## Configuring Transactional Replication
