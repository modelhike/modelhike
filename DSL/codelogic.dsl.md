# ModelHike — Code Logic DSL (Fenced Block Syntax)

**Version:** 0.3 • **Status:** Draft  

This document describes the **fenced block** syntax used to express method bodies inside a `.modelhike` model file. Logic is optional — a method may have no body at all, or it may be followed by a fenced logic block that is parsed into a `CodeLogic` tree attached to the `MethodObject`.

---

## Legend

Symbol | Meaning |
------ | ------- |
`~~~~~~` | Setext method header underline (6+ tildes) |
`~~~` | Opening / closing fence for **setext-style** logic blocks (opening optional) |
` ``` ` | Opening / closing fence for **tilde-prefix-style** logic blocks (both required) |
`keyword` | Top-level line statement (depth 1, no `\|` prefix) |
`\|> KEYWORD` | Depth-1 block opener — the `\|` marks it as a block, `>` confirms it |
`\|keyword` | Depth-2 line statement (one pipe = one nesting level down) |
`\|\|> KEYWORD` | Depth-2 block opener |
`\|\|keyword` | Depth-3 line statement |
expression | The payload / condition / argument on the same line as the keyword |

**Depth rules inside a fence:**
- **Block opener** (`\|> KEYWORD`, at least one `\|` before `>`): tree depth = N (count of leading `\|` chars).
- **Line statement** (no leading `>`): tree depth = N + 1.
- Block keywords are written in **UPPERCASE** by convention; matching is case-insensitive.

---

## 1. Attaching Logic to a Method

### Setext-header style — `~~~~~~` underline, `~~~` fence, opening optional

The `~~~~~~` tilde underline signals the method header. Setext style is for methods **with** a logic body. Logic starts immediately after the underline — no opening fence. The closing `~~~` is mandatory.

````modelhike
Order
=====
* id     : Id
* amount : Float

applyDiscount(percent: Float) : Float
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
|> IF percent <= 0
|return amount
|> ELSE
|assign discounted = amount * (1 - percent / 100)
|return discounted
~~~
````

### Tilde-prefix style — for stubs and methods without logic

Tilde-prefix is the natural choice when a method has no logic body. It also supports a ` ``` ` fenced logic block when logic is needed.

`````modelhike
Order
=====
* amount : Float
~ applyDiscount(percent: Float) : Float
```
|> IF percent <= 0
|return amount
|> ELSE
|return amount * 0.9
```
`````

Blank lines **inside** the fence are skipped. Only the closing fence terminates the block — the closing `~~~` is mandatory whenever a logic body is present.

---

## 2. Depth & Nesting

```
return x         ← depth 1 line stmt  (N=0)
|> IF condition  ← depth 1 block opener (N=1)
| return amount  ← depth 2 line stmt  (N=1)  — child of IF
| |> FOR items   ← depth 2 block opener (N=2)
| | return item  ← depth 3 line stmt  (N=2)  — child of FOR
|> ELSE          ← depth 1 block opener (sibling of IF)
| return default ← depth 2 line stmt  — child of ELSE
```

A space after pipes is allowed for readability — `| return x` equals `|return x`, and `| |> FOR` equals `||> FOR`.

Block openers (`|> KEYWORD`) gather the lines that immediately follow at a greater depth as their `children`. Line statements have no children.

---

## 3. Control Flow

### 3.1 If / Else

````modelhike
validate(amount: Float) : Bool
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
|> IF amount > 0
|return true
|> ELSE
|return false
~~~
````

````modelhike
classify(score: Int) : String
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
|> IF score >= 90
|return "A"
|> ELSEIF score >= 75
|return "B"
|> ELSEIF score >= 60
|return "C"
|> ELSE
|return "F"
~~~
````

### 3.2 For Loop

````modelhike
totalRevenue(orders: Order[]) : Float
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
assign total = 0
|> FOR order in orders
| assign total = total + order.amount
return total
~~~
````

### 3.3 While Loop

````modelhike
drain() : void
~~~~~~~~~~~~~~
|> WHILE queue.hasNext
| call process(queue.next())
~~~
````

### 3.4 Try / Catch / Finally

````modelhike
saveOrder(order: Order) : Order
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
|> TRY
| call repository.save(order)
| return order
|> CATCH ex: DatabaseException
| call logger.error(ex.message)
| return null
|> FINALLY
| call cleanup()
~~~
````

### 3.5 Switch / Case

````modelhike
describe(status: String) : String
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
|> SWITCH status
| |> CASE "PENDING"
| | return "Awaiting approval"
| |> CASE "ACTIVE"
| | return "In progress"
| |> DEFAULT
| | return "Unknown"
~~~
````

### 3.6 Compiler Directives

````modelhike
debugInfo() : String
~~~~~~~~~~~~~~~~~~~~~
|> #IF DEBUG
| return "debug mode"
|> #ELSE
| return ""
|> #ENDIF
~~~
````

---

## 4. Core Imperative Statements

Statement | Syntax | Description |
--------- | ------ | ----------- |
`call` | `\|call Fn(args)` | Invoke a function or method |
`assign` | `\|assign lhs = rhs` | Assign a value to a variable |
`return` | `\|return expr` | Return a value from the method |
`expr` | `expr raw-expression` | Embed an arbitrary expression (line statement) |
`raw` | `raw source` | Embed raw source code, line statement (escape hatch) |

````modelhike
calculateTax(amount: Float, rate: Float) : Float
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
assign tax = amount * rate / 100
return tax
~~~
````

````modelhike
init(name: String) : void
~~~~~~~~~~~~~~~~~~~~~~~~~~
call super.init()
assign self.name = name
~~~
````

---

## 5. Functional / Pipeline Statements

Statement | Syntax | Description |
--------- | ------ | ----------- |
`pipe` | `\|> PIPE source` | Start a transformation pipeline |
`filter` | `\|> FILTER x -> predicate` | Filter items |
`select` | `\|> SELECT x -> projection` | Project items |
`map` | `\|> MAP x -> projection` | Alias of `select` (JS/TS style) |
`reduce` | `\|> REDUCE source -> (acc,x) -> expr -> init` | Reduce/fold |
`let` | `\|> LET name = _` | Bind the last pipeline result to a name |
`match` | `\|> MATCH expr` | Pattern match |
`when` | `\|> WHEN pattern` | Branch of a match |
`endmatch` | `\|> ENDMATCH` | Close a match block |

````modelhike
activeOrderTotals(orders: Order[]) : Float[]
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
|> PIPE orders
| |> FILTER o -> o.status == "ACTIVE"
| |> MAP o -> o.amount
| |> LET totals = _
return totals
~~~
````

---

## 6. Database Statements

### 6.1 Query

````modelhike
getOrder(orderId: Id) : Order
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
|> DB Orders
| |> WHERE o -> o.id == orderId
| |> FIRST
| |> LET order = _
return order
~~~
````

### 6.2 Paging

````modelhike
listOrders(skip: Int, take: Int) : Order[]
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
|> DB Orders
| |> ORDER-BY createdAt desc
| |> SKIP skip
| |> TAKE take
| |> TO-LIST
| |> LET orders = _
return orders
~~~
````

### 6.3 Insert / Update / Delete

````modelhike
createOrder(order: Order) : Order
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
|> DB-INSERT Orders -> order
return order
~~~
````

````modelhike
shipOrder(id: Id) : void
~~~~~~~~~~~~~~~~~~~~~~~~~
|> DB-UPDATE Orders -> o.id == id
| |> SET status    = "SHIPPED"
| |> SET shippedAt = now()
~~~
````

````modelhike
deleteOrder(id: Id) : void
~~~~~~~~~~~~~~~~~~~~~~~~~~~
|> DB-DELETE Orders -> o.id == id
~~~
````

### 6.4 Aggregation

````modelhike
orderCountByStatus() : any
~~~~~~~~~~~~~~~~~~~~~~~~~~~
|> DB Orders
| |> GROUP-BY o -> o.status
| |> AGGREGATE count
| |> LET countsByStatus = _
return countsByStatus
~~~
````

### 6.5 Stored Procedure Call

````modelhike
customerOrders(customerId: Id) : Order[]
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
|> DB-PROC-CALL dbo.usp_GetCustomerOrders
| |> PARAMS
| |  CustomerId = customerId
| |> LET orders = _
return orders
~~~
````

### 6.6 Raw SQL (Fallback)

````modelhike
legacySearch(term: String) : any[]
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
|> DB-RAW primary
| |> SQL
| |  SELECT * FROM Products WHERE Name LIKE @term
| |> PARAMS
| |  term = "%" + term + "%"
| |> LET results = _
return results
~~~
````

### DB Statement Reference

Statement | Syntax |
--------- | ------ |
`db` | `\|> DB EntityName` |
`where` | `\|> WHERE x -> predicate` |
`include` | `\|> INCLUDE RelationName` |
`order-by` | `\|> ORDER-BY field [asc\|desc]` |
`skip` | `\|> SKIP n` |
`take` | `\|> TAKE n` |
`to-list` | `\|> TO-LIST` |
`first` | `\|> FIRST` |
`single` | `\|> SINGLE` |
`db-insert` | `\|> DB-INSERT Entity -> data` |
`db-update` | `\|> DB-UPDATE Entity -> predicate` |
`set` | `\|> SET field = value` |
`db-delete` | `\|> DB-DELETE Entity -> predicate` |
`group-by` | `\|> GROUP-BY x -> key` |
`aggregate` | `\|> AGGREGATE count\|sum\|avg\|min\|max` |
`db-proc-call` | `\|> DB-PROC-CALL schema.procName` |
`params` | `\|> PARAMS` (block; children are `key = value` pairs) |
`sql` | `\|> SQL` (block; children are raw SQL lines) |
`db-raw` | `\|> DB-RAW connectionName` |

---

## 7. HTTP / API Statements

### 7.1 REST

````modelhike
fetchUser(userId: Id) : User
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
|> HTTP GET https://users.example.com/api/users/{userId}
| |> PATH
| |  userId = userId
| |> HEADERS
| |  X-Correlation-Id = correlationId
| |> AUTH bearer
| |> EXPECT 200
| |> LET user = _
return user
~~~
````

````modelhike
createPayment(amount: Float, token: String) : Payment
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
|> HTTP POST https://payments.example.com/v1/payments
| |> BODY
| |  amount   = amount
| |  currency = "usd"
| |  source   = token
| |> AUTH api-key stripeKey
| |> EXPECT 201
| |> LET payment = _
return payment
~~~
````

### 7.2 GraphQL

````modelhike
getUserGraph(userId: Id) : User
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
|> HTTP-GRAPHQL https://api.example.com/graphql
| |> QUERY
| |  query GetUser($id: ID!) {
| |    user(id: $id) { id name email }
| |  }
| |> VARIABLES
| |  id = userId
| |> AUTH bearer
| |> EXPECT 200
| |> LET user = _
return user
~~~
````

### 7.3 gRPC

````modelhike
lookupUser(userId: Id) : User
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
|> GRPC UserService.GetUser
| |> PAYLOAD
| |  id = userId
| |> METADATA
| |  authorization = "Bearer " + token
| |> LET user = _
return user
~~~
````

### 7.4 Raw HTTP (Fallback)

````modelhike
legacyCall() : any
~~~~~~~~~~~~~~~~~~~
|> HTTP-RAW external
| |> RAW
| |  httpClient.SendAsync(request)
| |> NOTE
| |  could not parse url/method
~~~
````

### HTTP Statement Reference

Statement | Syntax |
--------- | ------ |
`http` | `\|> HTTP METHOD url` |
`path` | `\|> PATH` (block; children are `param = value` pairs) |
`query` | `\|> QUERY` (block; children are `param = value` pairs) |
`headers` | `\|> HEADERS` (block; children are `key = value` pairs) |
`auth` | `\|> AUTH none\|bearer\|api-key\|basic` |
`expect` | `\|> EXPECT statusCode` |
`body` | `\|> BODY` (block; children are `key = value` pairs) |
`http-graphql` | `\|> HTTP-GRAPHQL url` |
`variables` | `\|> VARIABLES` (block; children are `key = value` pairs) |
`grpc` | `\|> GRPC ServiceName.MethodName` |
`payload` | `\|> PAYLOAD` (block; children are `key = value` pairs) |
`metadata` | `\|> METADATA` (block; children are `key = value` pairs) |
`http-raw` | `\|> HTTP-RAW connectionName` |

---

## 8. Full Example

````modelhike
=== Order Service ===
+ Order Module

=== Order Module ===

Order
=====
* id       : Id
* amount   : Float
* status   : String
- discount : Float

# APIs ["/orders"]
@ apis:: create, get-by-id, list, delete
#

applyDiscount(percent: Float) : Order
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
|> IF percent <= 0
| return this
assign discounted = amount * (1 - percent / 100)
assign self.discount = percent
assign self.amount   = discounted
|> DB-UPDATE Orders -> o.id == id
| |> SET amount   = self.amount
| |> SET discount = self.discount
return this
~~~

fetchRelatedUser(userId: Id) : User
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
|> HTTP GET https://users.example.com/api/users/{userId}
| |> PATH
| |  userId = userId
| |> AUTH bearer
| |> EXPECT 200
| |> LET user = _
return user
~~~
````

---

## 9. How It Maps to the Domain Model

DSL element | Swift type |
----------- | ---------- |
`methodName(...)` followed by `~~~~~~` | `MethodObject` (setext style) |
`~ methodName(...)` | `MethodObject` (tilde-prefix style) |
Logic block between `~~~` or ` ``` ` fences | `MethodObject.logic: CodeLogic?` |
Each `\|`-prefixed line | `LogicStatement` |
Leading `\|` count | `LogicStatement.children` nesting depth |
Keyword (e.g. `if`, `return`) | `LogicStatementKind` |
Rest of the line after keyword | `LogicStatement.expression` |

Blueprints access the logic tree via `method.logic` in SoupyScript and can walk `statement.children` to emit target-language code.
