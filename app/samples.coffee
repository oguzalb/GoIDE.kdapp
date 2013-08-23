class Requirements
  constructor: (options) ->
    {@requirementQuery} = options
    {@requirementCheck} = options
    {@fullfill} = options

sampleCodesItems = [
  ["Select", ""]
  ["Hello World", "helloworld"],
  ["Strings", "strings"],
  ["Functions", "functions"],
  ["structs", "structs"],
  ["methods", "methods"],
  ["webserver", "webserver"],
  ["goroutines", "goroutines"],
  ["channels", "channels"],
  ["mongo", "mongo"],
  ["redis", "redis"],
  ["sqlite3", "sqlite3"]
]

sampleCodesData = {
  "helloworld": ["""package main

import (
  "fmt"
)

func main() {
  fmt.Println("Hello world!")
}"""],
  "strings":["""package main

import (
  "fmt"
  "strings"
)

func main() {
  fmt.Println(strings.Contains("seafood", "foo"))
	fmt.Println(strings.Contains("seafood", "bar"))
	fmt.Println(strings.Contains("seafood", ""))
	fmt.Println(strings.Contains("", ""))
}"""],
  "functions": ["""package main

import "fmt"

func add(x int, y int) int {
    return x + y
}

func main() {
    fmt.Println(add(42, 13))
}"""],
  "structs":["""package main

import "fmt"

type Vertex struct {
    X int
    Y int
}

func main() {
    v := Vertex{1, 2}
    v.X = 4
    fmt.Println(v.X)
}"""],
  "range":["""package main

import "fmt"

var pow = []int{1, 2, 4, 8, 16, 32, 64, 128}

func main() {
    for i, v := range pow {
        fmt.Printf("2**%d = %d\n", i, v)
    }
}"""],
  "methods":["""package main

import (
    "fmt"
    "math"
)

type MyFloat float64

func (f MyFloat) Abs() float64 {
    if f < 0 {
        return float64(-f)
    }
    return float64(f)
}

func main() {
    f := MyFloat(-math.Sqrt2)
    fmt.Println(f.Abs())
}"""],
  "webserver":["""package main

import (
    "fmt"
    "net/http"
)

type Hello struct{}

func (h Hello) ServeHTTP(
    w http.ResponseWriter,
    r *http.Request) {
    fmt.Fprint(w, "Hello!")
}

func main() {
    var h Hello
    http.ListenAndServe("localhost:4000", h)
}"""],
"goroutines":["""package main

import (
    "fmt"
    "time"
)

func say(s string) {
    for i := 0; i < 5; i++ {
        time.Sleep(100 * time.Millisecond)
        fmt.Println(s)
    }
}

func main() {
    go say("world")
    say("hello")
}"""],
"channels":["""package main

import "fmt"

func sum(a []int, c chan int) {
    sum := 0
    for _, v := range a {
        sum += v
    }
    c <- sum // send sum to c
}

func main() {
    a := []int{7, 2, 8, -9, 4, 0}

    c := make(chan int)
    go sum(a[:len(a)/2], c)
    go sum(a[len(a)/2:], c)
    x, y := <-c, <-c // receive from c

    fmt.Println(x, y, x+y)
}"""],
"mongo":["""package main

import (
  "fmt"
	"labix.org/v2/mgo"
	"labix.org/v2/mgo/bson"
)

type Person struct {
	Name  string
	Phone string
}

func main() {
	session, err := mgo.Dial("server1.example.com,server2.example.com")
	if err != nil {
		panic(err)
	}
	defer session.Close()

	// Optional. Switch the session to a monotonic behavior.
	session.SetMode(mgo.Monotonic, true)

	c := session.DB("test").C("people")
	err = c.Insert(&Person{"Ale", "+55 53 8116 9639"},
		&Person{"Cla", "+55 53 8402 8510"})
	if err != nil {
		panic(err)
	}

	result := Person{}
	err = c.Find(bson.M{"name": "Ale"}).One(&result)
	if err != nil {
		panic(err)
	}

	fmt.Println("Phone:", result.Phone)
}
""",
new Requirements
  requirementQuery: "dpkg -s bzr mongodb"
  requirementCheck: /Status: install ok[\s\S]*Status: install ok/,
  fullfill: "sudo apt-get install bzr && sudo apt-get install mongodb"
],
"redis":["""package main

import (
  "github.com/garyburd/redigo/redis"
	"github.com/garyburd/redigo/redisx"
	"log"
)

type MyStruct struct {
	A int
	B string
}

func main() {
	c, err := redis.Dial("tcp", ":6379")
	if err != nil {
		log.Fatal(err)
	}

	v0 := &MyStruct{1, "hello"}

	_, err = c.Do("HMSET", redisx.AppendStruct([]interface{}{"key"}, v0)...)
	if err != nil {
		log.Fatal(err)
	}

	reply, err := c.Do("HGETALL", "key")
	if err != nil {
		log.Fatal(err)
	}

	v1 := &MyStruct{}

	err = redisx.ScanStruct(reply, v1)
	if err != nil {
		log.Fatal(err)
	}
	log.Printf("v1=%v", v1)
}""",
new Requirements
    requirementQuery: "dpkg -s redis-server"
    requirementCheck: /Status: install ok/
    fullfill: "sudo apt-get install redis-server"],
"sqlite3": ["""package main

import (
  "database/sql"
	"fmt"
	_ "github.com/mattn/go-sqlite3"
	"os"
)

func main() {
	os.Remove("./foo.db")

	db, err := sql.Open("sqlite3", "./foo.db")
	if err != nil {
		fmt.Println(err)
		return
	}
	defer db.Close()

	sqls := []string{
		"create table foo (id integer not null primary key, name text)",
		"delete from foo",
	}
	for _, sql := range sqls {
		_, err = db.Exec(sql)
		if err != nil {
			fmt.Printf("%q: %s", err, sql)
			return
		}
	}

	tx, err := db.Begin()
	if err != nil {
		fmt.Println(err)
		return
	}
	stmt, err := tx.Prepare("insert into foo(id, name) values(?, ?)")
	if err != nil {
		fmt.Println(err)
		return
	}
	defer stmt.Close()
	for i := 0; i < 4; i++ {
		_, err = stmt.Exec(i, fmt.Sprintf("こんにちわ世界%03d", i))
		if err != nil {
			fmt.Println(err)
			return
		}
	}
	tx.Commit()

	rows, err := db.Query("select id, name from foo")
	if err != nil {
		fmt.Println(err)
		return
	}
	defer rows.Close()
	for rows.Next() {
		var id int
		var name string
		rows.Scan(&id, &name)
		fmt.Println(id, name)
	}
	rows.Close()

	stmt, err = db.Prepare("select name from foo where id = ?")
	if err != nil {
		fmt.Println(err)
		return
	}
	defer stmt.Close()
	var name string
	err = stmt.QueryRow("3").Scan(&name)
	if err != nil {
		fmt.Println(err)
		return
	}
	fmt.Println(name)

	_, err = db.Exec("delete from foo")
	if err != nil {
		fmt.Println(err)
		return
	}

	_, err = db.Exec("insert into foo(id, name) values(1, 'foo'), (2, 'bar'), (3, 'baz')")
	if err != nil {
		fmt.Println(err)
		return
	}

	rows, err = db.Query("select id, name from foo")
	if err != nil {
		fmt.Println(err)
		return
	}
	defer rows.Close()
	for rows.Next() {
		var id int
		var name string
		rows.Scan(&id, &name)
		fmt.Println(id, name)
	}
	rows.Close()

}
""",
  new Requirements
    requirementQuery: "dpkg -s pkg-config sqlite3 libsqlite3-dev"
    requirementCheck: /Status: install ok[\s\S]*Status: install ok[\s\S]*Status: install ok/
    fullfill: "sudo apt-get install pkg-config sqlite3 && sudo apt-get install libsqlite3-dev"
  ]
}

