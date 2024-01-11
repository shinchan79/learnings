# AlwaysOn Availability Groups (2)

## Prerequisites
when deploying an AlwaysOn AG in a production environment, the following should be considered first:
- Number of availability groups to be configured.
- Availability databases to be grouped together in an availability group. For example, critical databases are in one availability group with automatic failover and non-critical databases in another availability group with manual failover.
- Number of synchronous and asynchronous replicas and their locations. Synchronous replicas can be used as reporting databases (offload reads from primary replica), as well as to perform backups and integrity checks.
- Instance failover or enhanced database failover.

**Note:**
A secondary replica being used either as a read or backup replica will incur licensing costs. A passive (only available during failover or when it's changed to a primary) secondary replica doesn't require a license. The cost, therefore, has an important role when deciding on the number of secondary replicas.

### Operating System
- Linux is supported from SQL Server 2017 onward.
- starting from Windows Server 2016, a failover cluster can be created without domain dependency. Therefore, a SQL Server 2016 instance running on Windows Server 2016 can have AlwaysOn set up on nodes in different domains, same domains, or workgroups (no domain).
- An AlwaysOn replica cannot be a domain controller. 
### SQL Server
- SQL Server 2012 Enterprise or later is required to configure AlwaysOn. Starting from SQL Server 2016, the Standard edition supports the basic availability group, as discussed earlier.
- Each SQL Server instance should be on a different node of a single WSFC node. A distributed availability group can be on nodes in different WSFCs. An availability group in Windows Server 2016 can be on nodes in different WSFCs or on nodes in workgroups.
- All SQL Server instances in an availability group should be on the same collation.
- All SQL Server instances in an availability group should have the availability group feature enabled.
- It's recommended to use a single SQL Server service account for all the SQL Server instances participating in an availability group.
- If the FILESTREAM feature is used, it should be enabled on all SQL Server instances in an availability group.
- If contained databases are used, the contained database authentication server option should be set to 1 on all SQL Server instances participating in an availability group.

### Availability Database
- It should not be a system database.
- It should have a full recovery model with at least one full backup.
- It should not be a part of database mirroring or an existing availability group.
- It should not be a read-only database.

A few important recommendations:
- Each availability group replica should run on the same OS and SQL Server version and configuration.
- Each availability group replica should have the same drive letters. This is to make sure that the database data and log files' paths are consistent across all replicas. If not, then the AlwaysOn setup will error out.
- A dedicated network card should be used for data synchronization between replicas and for WSFC communication.

The deployment consists of the following steps:
- Creating four Hyper-V VMs: one for the domain controller, one as the primary replica VM, and two as the secondary replica VMs.
- Configuring Active Directory Domain Controller.
- Configuring Windows Server Failover Cluster.
- Installing SQL Server 2016 Developer edition on all replicas.
- Creating availability groups. This includes enabling the availability group feature in all instances and using the Availability Group Wizard to set up AlwaysOn availability groups.

Steps 1, 2, and 3 are not part of the database administrator profile and are done by system administrators. However, they are prerequisites for AlwaysOn and are therefore included as setup steps.

## Creating Hyper-V VMs
