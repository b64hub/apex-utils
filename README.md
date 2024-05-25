# Apex Utils

| Package Name | Version | Version Id |
| ------------ | ------- | ---------- |
| `apex-utils` | 0.1.0   | ``         |

## Description

This package contains generic apex tools, frameworks and interfaces. These tools will make it easier to write and test code. It may require some learning, but the tools have been created with simplicity in mind. The classes are not org specific. Any org-specific logic does not belong in this package.

## Access

Explain how the user may get access to the metadata in the package. Either through permissions sets, permission set groups or profiles. Permissions sets or permission set groups are preferred.

### Permission Set Groups

### Permission Sets

List the different permission sets a user should be assigned to get access.

A permission set will be included which gives access to all classes.

# QueryBuilder

The `QueryBuilder` class is a powerful tool for constructing dynamic SOQL query strings in Salesforce. It provides a flexible interface for creating 'WHERE' filters, utilizing a binary tree for creating conditional filters. The builder holds one instance of the `Query` class and adds properties to this class through its methods.

## Usage

Here's a basic example of how to use the `QueryBuilder` class:

```apex
QueryBuilder qb = new QueryBuilder();
qb.selectFields(new List<String>{'Name', 'Industry'});
qb.addFilter('Industry = \'Technology\'');
qb.setLimit(10);
String queryString = qb.getQuery().toString();
```

In this example, we first create a new instance of `QueryBuilder`. We then add 'Name' and 'Industry' to the fields that we want to select, add a filter for the 'Industry' field, and set a limit of 10 records. Finally, we convert the query to a string.

## Extending Functionality

The `QueryBuilder.Query` class implements the `IQuery` interface, which provides a contract for query operations. You can create your own class that implements the `IQuery` interface to extend the functionality of the `QueryBuilder.Query` class.

Here's an example of how to do this:

```apex
public class CustomQuery implements IQuery {
    // Implement the methods required by the IQuery interface...
}

CustomQuery customQuery = new CustomQuery();
// Use the customQuery object...
```

In this example, we first create a `CustomQuery` class that implements the `IQuery` interface. We then create a new instance of `CustomQuery`.

## Methods

### selectFields

The `selectFields` method adds a list of fields to the query.

### selectField

The `selectField` method adds a single field to the query.

### addFilter

The `addFilter` method sets the 'WHERE' condition of the query. It can accept a string or an `ICondition` object.

### addSubQuery

The `addSubQuery` method adds a subquery to the query. It accepts an `IQuery` object.

### sortBy

The `sortBy` method sets the 'ORDER BY' clause of the query. It accepts a string representing the field to sort by.

### setLimit

The `setLimit` method sets the 'LIMIT' clause of the query. It accepts an integer representing the maximum number of records to return.

### getQuery

The `getQuery` method returns the `Query` object that the `QueryBuilder` is building.

Please note that this is a basic documentation and you might need to adjust it based on your specific requirements and the full implementation of your `QueryBuilder` class.

# ConditionBuilder

The `ConditionBuilder` class is a utility class that helps in constructing complex 'WHERE' conditions for SOQL queries using the QueryBuilder. It uses a binary tree structure to create nested conditions.

## Usage

Here's a basic example of how to use the `ConditionBuilder` class:

```apex
ConditionBuilder cb = new ConditionBuilder();
cb.andWith(new Condition('Industry').equals('Technology'));
cb.orWith(new Condition('AnnualRevenue').greaterThan(1000000));
String conditionString = cb.toString();
```

In this example, we first create a new instance of `ConditionBuilder`. We then add two conditions: one for the 'Industry' field and one for the 'AnnualRevenue' field. Finally, we convert the condition to a string.

## Extending Functionality

The `ConditionBuilder.Condition` class implements the `ICondition` interface, which provides a contract for condition operations. You can create your own class that implements the `ICondition` interface to extend the functionality of the `ConditionBuilder.Condition` class.

Here's an example of how to do this:

```apex
public class CustomCondition implements ICondition {
    // Implement the methods required by the ICondition interface...
}

CustomCondition customCondition = new CustomCondition();
// Use the customCondition object...
```

In this example, we first create a `CustomCondition` class that implements the `ICondition` interface. We then create a new instance of `CustomCondition`.

## Methods

### addCondition

The `addCondition` method adds a condition to the 'WHERE' clause of the query. It accepts three parameters: the field name, the operator, and the value.

### addCondition

The `addCondition` method also accepts an `ICondition` object as a parameter, allowing for nested conditions.

### toString

The `toString` method constructs the 'WHERE' clause of the query. It starts with the first condition, adds the 'AND' or 'OR' operator if there is more than one condition, and adds the remaining conditions.

Please note that this is a basic documentation and you might need to adjust it based on your specific requirements and the full implementation of your `ConditionBuilder` class.

# DML

The `DML` class is a powerful tool for managing DML operations in Salesforce. It acts as a wrapper around the `insert`, `update`, `upsert`, and `delete` DML operations, providing the possibility for adding checks, logging, and mocking during tests.

## Usage

Here's a basic example of how to use the `DML` class:

```apex
DML dml = new DML();
Account newAccount = new Account(Name='New Account');
dml.doInsert(newAccount);
```

In this example, we first create a new instance of `DML`. We then create a new `Account` record and use the `doInsert` method of the `DML` instance to insert the new `Account` record into the database.

## Extending Functionality

The `DML` class implements the `IDML` interface, which provides a contract for DML operations. You can create your own class that implements the `IDML` interface to extend the functionality of the `DML` class.

Here's an example of how to do this:

```apex
public class CustomDML implements IDML {
    // Implement the methods required by the IDML interface...
}

CustomDML customDml = new CustomDML();
Account newAccount = new Account(Name='New Account');
customDml.doInsert(newAccount);
```

In this example, we first create a `CustomDML` class that implements the `IDML` interface. We then create a new instance of `CustomDML` and a new `Account` record. We use the `doInsert` method of the `CustomDML` instance to insert the new `Account` record into the database.

## Methods

### doInsert

The `doInsert` method inserts a new record or a list of new records into the database. It logs any exceptions that occur during the operation.

### doUpdate

The `doUpdate` method updates an existing record or a list of existing records in the database. It logs any exceptions that occur during the operation.

Please note that this is a basic documentation and you might need to adjust it based on your specific requirements and the full implementation of your `DML` class.

### doDelete

The `doDelete` method deletes an existing record or a list of existing records from the database. It logs any exceptions that occur during the operation.

Here's an example of how to use the `doDelete` method:

```apex
DML dml = new DML();
Account accountToDelete = [SELECT Id FROM Account WHERE Name = 'Account to Delete' LIMIT 1];
dml.doDelete(accountToDelete);
```

In this example, we first create a new instance of `DML`. We then query an `Account` record from the database and use the `doDelete` method of the `DML` instance to delete the `Account` record from the database.

### doUpsert

The `doUpsert` method inserts a new record or updates an existing record in the database. It logs any exceptions that occur during the operation.

Here's an example of how to use the `doUpsert` method:

```apex
DML dml = new DML();
Account accountToUpsert = new Account(Id = existingAccountId, Name = 'Updated Account');
dml.doUpsert(accountToUpsert);
```

In this example, we first create a new instance of `DML`. We then create a new `Account` record with an existing ID and use the `doUpsert` method of the `DML` instance to insert the new `Account` record into the database if it doesn't exist, or update it if it does.

### doPublish

The `doPublish` method publishes a platform event or a list of platform events. It logs any exceptions that occur during the operation.

Here's an example of how to use the `doPublish` method:

```apex
DML dml = new DML();
MyPlatformEvent__e eventToPublish = new MyPlatformEvent__e(Name__c = 'New Event');
dml.doPublish(eventToPublish);
```

In this example, we first create a new instance of `DML`. We then create a new platform event and use the `doPublish` method of the `DML` instance to publish the event.

Please note that these are basic examples and you might need to adjust them based on your specific requirements and the full implementation of your `DML` class.

# UnitOfWork

The `UnitOfWork` class is a powerful tool for managing DML transactions, event publishing, and custom transactions in Salesforce. It provides a simple API for committing records to be saved to the database and mechanisms for resolving object-relationships.

## Usage

Here's a basic example of how to use the `UnitOfWork` class:

```apex
UnitOfWork uow = new UnitOfWork();
// Register transactions...
uow.save();
```

In this example, we first create a new instance of `UnitOfWork`. We then register transactions as needed. Finally, we call the `save` method to save all the registered transactions.

## Extending Functionality

The `UnitOfWork` class provides interfaces that you can implement to extend its functionality. Here's an example of how to do this:

```apex
public class CustomTransaction implements ITransaction {
    // Implement the methods required by the ITransaction interface...
}

UnitOfWork uow = new UnitOfWork();
CustomTransaction customTrx = new CustomTransaction();
uow.register(customTrx);
uow.save();
```

In this example, we first create a `CustomTransaction` class that implements the `ITransaction` interface. We then create a new instance of `UnitOfWork` and a new instance of `CustomTransaction`. We register the custom transaction with the `UnitOfWork` using the `register` method. Finally, we call the `save` method to save the registered transactions.

UnitOfWork is also utilizing the `DML` class for commiting records to the database. This dml handler can be substituted by any other class implementing the `IDML` interface, to further extend functionality.

## Methods

### save

The `save` method saves all the registered DML transactions. It sorts the transactions, logs the execution of each transaction, and executes each transaction. If a transaction fails, it logs the error, re-adds the transaction to the map, and rethrows the exception.

Based on the provided code, here's an explanation of the `registerNew`, `registerUpdate`, `registerDelete`, `registerPublish` methods and `addTransaction` method in the `UnitOfWork` class:

### registerNew

The `registerNew` method is used to register new records that will be inserted into the database. This method is not shown in the provided code, but it would typically look similar to the `registerUpdate` and `registerDelete` methods.

### registerUpdate

The `registerUpdate` method is used to register existing records that have been modified and need to be updated in the database. There are four versions of this method, each accepting different parameters to handle different scenarios.

Here's an example of how to use the `registerUpdate` method:

```apex
Account existingAccount = [SELECT Id, Name FROM Account WHERE Name = 'Existing Account' LIMIT 1];
existingAccount.Name = 'Updated Account';
DmlTransaction trx = uow.registerUpdate(existingAccount);
uow.save();
```

### registerDelete

The `registerDelete` method is used to register records that will be deleted from the database. There are two versions of this method, each accepting different parameters.

Here's an example of how to use the `registerDelete` method:

```apex
Account accountToDelete = [SELECT Id FROM Account WHERE Name = 'Account to Delete' LIMIT 1];
DmlTransaction trx = uow.registerDelete(accountToDelete);
uow.save();
```

### registerPublish

The `registerPublish` method is used to register events that will be published. This method is not shown in the provided code, but it would typically look similar to the `registerUpdate` and `registerDelete` methods.

### addTransaction

The `addTransaction` method is used to add a custom transaction to the `UnitOfWork`. Here's an example of how it might be used:

```apex
CustomTransaction customTrx = new CustomTransaction();
uow.addTransaction('customTrx', customTrx);
uow.save();
```

In this example, a `CustomTransaction` object is created and added to the `UnitOfWork` using the `addTransaction` method. The `CustomTransaction` class would need to implement the `ITransaction` interface.

Please note that these are general examples and the actual usage may vary depending on the specific implementation of your `UnitOfWork` class. If you could provide the full `UnitOfWork` class or the specific `register*` and `addTransaction` methods, I could give a more accurate explanation and examples.

## Interfaces

### ITransaction

The `ITransaction` interface provides a contract for custom transactions. You can implement this interface in your own classes to extend the functionality of the `UnitOfWork` class.

Please note that this is a basic documentation and you might need to adjust it based on your specific requirements and the full implementation of your `UnitOfWork` class.

# SObjectSelector

`SObjectSelector` is a base class for selector classes, following Enterprise patterns. It defines which sObjectType to query and the defaultfields. It also implements some common queries, like getting where a field equals a certain value.

# SObjectDomain

`SObjectDomain` is a base class for domain classes, following Enterprise patterns. It defines sObjectType and defines a list of records.

# FilterBuilder

The `FilterBuilder` class is a utility class that provides an Object-Oriented Programming (OOP) interface for filtering lists of SObjects in Salesforce. It may run slower than a traditional for-loop, but it encapsulates large if-statements into a more readable format. By creating a custom class that extends the `IFilter` interface, it is simple to break if-checks of SObjects into more logical units and also reduce the mundande task of looping through one list and adding to a new one.

The `FilterBuilder` can dynamically construct complex filters, by building a binary tree of conditionals and logical operators. Complex filters run slower as the recurstion depth down the tree increases, so an option is to create a custom class (implementing `IFilter`) encapsulating complex logical checks and run it as a single filter to increase performance.

## Usage

Here's a basic example of how to use the `FilterBuilder` class:

```apex
List<Account> accounts = [SELECT Id, Name, Industry FROM Account];
IFilter filter = new Equals('Industry', 'Technology');
List<SObject> filteredAccounts = FilterBuilder.fastFilter(accounts, filter);
```

In this example, we first query a list of `Account` records. We then create an `Equals` filter for the 'Industry' field. Finally, we use the `fastFilter` method of the `FilterBuilder` class to apply the filter to the list of `Account` records.

## Extending Functionality

The `FilterBuilder` class uses the `IFilter` interface, which provides a contract for filter operations. You can create your own class that implements the `IFilter` interface to extend the functionality of the `FilterBuilder` class.

Here's an example of how to do this:

```apex
public class CustomFilter implements IFilter {
    // Implement the methods required by the IFilter interface...
}

CustomFilter customFilter = new CustomFilter();
// Use the customFilter object...
```

In this example, we first create a `CustomFilter` class that implements the `IFilter` interface. We then create a new instance of `CustomFilter`.

## Methods

### fastFilter

The `fastFilter` method applies a single filter to a list of records. It accepts two parameters: the list of records and the filter.

### newBuilder

The `newBuilder` method creates a new instance of `FilterBuilder`. It accepts one parameter: the list of records.

### setRecords

The `setRecords` method sets the list of records that the `FilterBuilder` will operate on. It accepts one parameter: the list of records.

Please note that this is a basic documentation and you might need to adjust it based on your specific requirements and the full implementation of your `FilterBuilder` class.
