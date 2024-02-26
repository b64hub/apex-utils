# Apex Utils

| Package Name | Type     | Package Id           |
| ------------ | -------- | -------------------- |
| `apex-utils` | Unlocked | `` |

## Description

This package contains generic apex tools, frameworks and interfaces. These tools will make it easier to write and test code. It may require some learning, but the tools have been created with simplicity in mind. The classes are not org specific. Any org-specific logic does not belong in this package.

The `type-factory` package is a small package containing the `TypeFactory` apex class. This class is used to dynamically instantiate objects in runtime. It makes it simple to inject runtime dependencies and mocking for easier and faster unit-testing. This package is a work-in-progress and will develop as the project progresses and new functionality will be needed.

The `test-factory` package is a small package containing the `TestFactory` apex class, as well as `Mocker`. Together these classes provide simple yet powerful tools for writing effective tests. The `TestFactory` class is useful for creating test data. The `Mocker` class provides a lightweight mocking framework useful for writing unit tests.

## Access

Explain how the user may get access to the metadata in the package. Either through permissions sets, permission set groups or profiles. Permissions sets or permission set groups are preferred.

### Permission Set Groups

### Permission Sets

List the different permission sets a user should be assigned to get access.

A permission set will be included which gives access to all classes.

## Usage

How to use and interact with components in the package. How to add, alter or override functionality. Give examples.

### Apex

## QueryBuilder

`QueryBuilder` is a builder class which gives a OOP interface to constructing SOQL query strings. By using this OOP approach, one can utilize this class to dynamically create queries.

## DML

`DML` class works as a wrapper layer around database operations. If your code utilizes the `DML` class it is simple to inject a mock class as a runtime dependency, and this way avoid calls to the database to reduce unit test time.

## UnitOfWork

`UnitOfWork` is another layer of abstraction around DML transactions. It works as a registry for SObject records, where you can mark lists of records for either insertion, update or deletes. It handles the transaction of a list of records.

## TypeFactory

Create new object instances using `TypeFactory.newInstance()`

```

MyClass clsInstance = (MyClass) TypeFactory.newInstance('MyClass');

```

In testing, the type-factory together with the use of interfaces or stubbing is useful for mocking.

```

class MyClass implements IHello {
    public String hello() {
        return 'Hello World';
    }
}

class MyMockClass implements IHello {
    public String hello() {
        return 'Hello Mock';
    }
}


@IsTest
static void testHello() {

    // MyMockClass implements MyInterface
    MyMockClass mock = new MyMockClass();

    TypeFactory.setMock('MyClass', mock);

    methodToTest();

}


static void sayHello() {

    // MyClass implements IHello
    IHello clsInstance = (IHello) TypeFactory.newInstance('MyClass');

    // hello() is defined on IHello
    String hello = clsInstance.hello()

    System.debug(hello); // When run from testHello, will output 'Hello Mock';
}

```

## TestFactory

Create records using `TestFactory`. It makes it simple to create and modify records in bulk.

```

List<Account> accs = (List<Account>) TestFactory('Account')
    .createRecords(5)
    .setField('Name', 'Test Account');
    .getRecords();

System.debug(accs.size()) // 5
System.debug(accs[3].Name) // 'Test Account'


```

The mocker provides a simple framework for using the Stub API. Useful in combination with dependency injection using the `TypeFactory`.

```

class MyClass implements IHello {
    public String hello() {
        return 'Hello World';
    }
}

@IsTest
static void testMethod() {

    Mocker mocker = new Mocker();
    MyClass mockInstance = (MyClass) mocker.mock('MyClass');

    mocker.patch(mockInstance, 'hello').thenReturn('Hello Mock');

    System.debug(mockInstance.hello()); // 'Hello Mock'
}

```