defmodule Mix.Tasks.Start do

use Mix.Task

def run(args) do
  IO.puts AwesomeList.readme("sindresorhus/awesome")
end
end
