import asyncdispatch
import threadpool
import os

proc foo(): Future[int] {.async.} =
  os.sleep(1000)
  echo("sleepy")

proc bar() {.async.} =
  echo("a")
  discard spawn foo()
  echo("b")

while true:
  discard bar()
  os.sleep(20)

