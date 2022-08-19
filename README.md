# Mask SObject Framework

This framework allow users to configure some data masking operations on **Sandbox environments**.

# Disclaimer
Mask SObject Framework is not an official Salesforce product, it has not been officially tested or documented by Salesforce.



## How Do You Configure SObjects And Fields to Mask ?

The configuration is based on two objects:

- MaskSObject__c  : which define the object to mask with options such as the order sequence and the where clause
- MaskSObjectField___c : which define the fields to mask and the option of masking (erase, randomize ...)

[![SObjedt config](./screenshots/2022-08-10_09-42-09.png)](./screenshots/2022-08-10_09-42-09.png)

## How To Run Data Masking ?

- With execute anonymous and the following code
```java
Database.executeBatch(new MaskSObjectBatch());
```
- When creating / refreshing a sandbox:
<img alt="Configure post copy class" src="./screenshots/sandbox-postcopy.png" />
**WARNING**: if you choose this option, you need a Partial Copy Sandbox or a Full Copy Sandbox and data configuration on Production.

- (WIP) Manually using [Launch Batch LWC](https://github.com/tprouvot/launch-batch-lwc)

## Deploy to Salesforce

Checkout the repo and deploy it with sfdx:
```sh
sfdx force:source:deploy -p force-app
```

Use GitHub Salesforce Deploy Tool:

[<img alt="Deploy to Salesforce" src="https://raw.githubusercontent.com/afawcett/githubsfdeploy/master/src/main/webapp/resources/img/deploy.png" />](https://githubsfdeploy.herokuapp.com/?owner=tprouvot&repo=mask-sobject&ref=master)
